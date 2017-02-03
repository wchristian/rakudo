class REPL { ... }

do {
    my sub sorted-set-insert(@values, $value) {
        my $low        = 0;
        my $high       = @values.end;
        my $insert_pos = 0;

        while $low <= $high {
            my $middle = floor($low + ($high - $low) / 2);
            my $middle_elem = @values[$middle];

            if $middle == @values.end {
                return if $value eq $middle_elem;
                if $value lt $middle_elem {
                    $high = $middle - 1;
                    next;
                }
                $insert_pos = +@values;
                last;
            }

            my $middle_plus_one_elem = @values[$middle + 1];
            return if $value eq $middle_elem || $value eq $middle_plus_one_elem;

            if $value lt $middle_elem {
                $high = $middle - 1;
            } elsif $value gt $middle_plus_one_elem {
                $low = $middle + 1;
            } else {
                $insert_pos = $middle + 1;
                last;
            }
        }

        splice(@values, $insert_pos, 0, $value);
    }

    my sub mkpath(IO::Path $full-path) {
        my ( :$directory, *% ) := $full-path.parts;
        my @parts = $*SPEC.splitdir($directory);

        for [\~] @parts.map(* ~ '/') -> $path {
            mkdir $path;
            fail "Unable to mkpath '$full-path': $path is not a directory"
              unless $path.IO ~~ :d;
        }
    }

    my role ReadlineBehavior[$WHO] {
        my &readline    = $WHO<&readline>;
        my &add_history = $WHO<&add_history>;
        my $Readline = try { require Readline }
        my $read = $Readline.new;
        if not $*DISTRO.is-win {
            $read.read-init-file("/etc/inputrc");
            $read.read-init-file("~/.inputrc");
        }
        method init-line-editor {
            $read.read-history($.history-file);
        }
        method repl-read(Mu \prompt) {
            my $line = $read.readline(prompt);
            return if not $line.defined;

            $read.add-history($line);
            $read.append-history(1, $.history-file);
            $line
        }
    }

    my role LinenoiseBehavior[$WHO] {
        my &linenoise                      = $WHO<&linenoise>;
        my &linenoiseHistoryAdd            = $WHO<&linenoiseHistoryAdd>;
        my &linenoiseSetCompletionCallback = $WHO<&linenoiseSetCompletionCallback>;
        my &linenoiseAddCompletion         = $WHO<&linenoiseAddCompletion>;
        my &linenoiseHistoryLoad           = $WHO<&linenoiseHistoryLoad>;
        my &linenoiseHistorySave           = $WHO<&linenoiseHistorySave>;

        method completions-for-line(Str $line, int $cursor-index) { ... }

        method history-file() returns Str { ... }

        method init-line-editor {
            linenoiseSetCompletionCallback(sub ($line, $c) {
                eager self.completions-for-line($line, $line.chars).map(&linenoiseAddCompletion.assuming($c));
            });
            linenoiseHistoryLoad($.history-file);
        }

        method teardown-line-editor {
            my $err = linenoiseHistorySave($.history-file);
            return if not $err;
            note "Couldn't save your history to $.history-file";
        }

        method repl-read(Mu \prompt) {
            self.update-completions;
            my $line = linenoise(prompt);
            return if not $line.defined;

            linenoiseHistoryAdd($line);
            $line
        }
    }

    my role FallbackBehavior {
        method repl-read(Mu \prompt) {
            print prompt;
            get
        }
    }

    my role Completions {
        # RT #129092: jvm can't do CORE::.keys
        has @!completions = $*VM.name eq 'jvm'
            ?? ()
            !! CORE::.keys.flatmap({
                    /^ "&"? $<word>=[\w* <.lower> \w*] $/ ?? ~$<word> !! []
                }).sort;

        method update-completions {
            my $context := self.compiler.context;
            return unless $context;

            my $it := nqp::iterator(nqp::ctxlexpad($context));
            while $it {
                my $k := nqp::iterkey_s(nqp::shift($it));
                my $m = $k ~~ /^ "&"? $<word>=[\w* <.lower> \w*] $/;
                next if not $m;

                sorted-set-insert(@!completions, ~$m<word>);
            }

            my $PACKAGE = self.compiler.eval('$?PACKAGE', :outer_ctx($context));
            sorted-set-insert(@!completions, $_) for $PACKAGE.WHO.keys;
        }

        method extract-last-word(Str $line) {
            my $m = $line ~~ /^ $<prefix>=[.*?] <|w>$<last_word>=[\w*]$/;
            return ( $line, '') unless $m;

            ( ~$m<prefix>, ~$m<last_word> )
        }

        method completions-for-line(Str $line, int $cursor-index) {
            return @!completions unless $line;

            # ignore $cursor-index until we have a backend that provides it
            my ( $prefix, $word-at-cursor ) = self.extract-last-word($line);

            # XXX this could be more efficient if we had a smarter starting index
            gather for @!completions -> $word {
                take $prefix ~ $word if $word ~~ /^ "$word-at-cursor" /;
            }
        }
    }

    class REPL {
        also does Completions;

        has Mu $.compiler;
        has Bool $!multi-line-enabled;
        has IO::Path $!history-file;

        has $!save_ctx;

        # Unique internal values for out-of-band eval results
        has $!need-more-input = {};
        has $!control-not-allowed = {};

        sub do-mixin($self, Str $module-name, $behavior, Str :$fallback) {
            my Bool $problem = False;
            try {
                CATCH {
                    when X::CompUnit::UnsatisfiedDependency & { .specification ~~ /"$module-name"/ } {
                        # ignore it
                    }
                    default {
                        say "I ran into a problem while trying to set up $module-name: $_";
                        say "Falling back to $fallback (if present)"
                          if $fallback;
                        $problem = True;
                    }
                }

                my $module = do require ::($module-name);
                my $new-self = $self but $behavior.^parameterize($module.WHO<EXPORT>.WHO<ALL>.WHO);
                $new-self.?init-line-editor();
                return ( $new-self, False );
            }

            ( Any, $problem )
        }

        sub mixin-readline($self, |c) {
            do-mixin($self, 'Readline', ReadlineBehavior, |c)
        }

        sub mixin-linenoise($self, |c) {
            do-mixin($self, 'Linenoise', LinenoiseBehavior, |c)
        }

        sub mixin-line-editor($self) {
            my %editor-to-mixin = (
                :Linenoise(&mixin-linenoise),
                :Readline(&mixin-readline),
                :none(-> $self { ( $self but FallbackBehavior, False ) }),
            );

            if %*ENV<RAKUDO_LINE_EDITOR> -> $line-editor {
                if not %editor-to-mixin{$line-editor} {
                    say "Unrecognized line editor '$line-editor'";
                    return $self but FallbackBehavior;
                }

                my $mixin = %editor-to-mixin{$line-editor};
                my ( $new-self, $problem ) = $mixin($self);
                return $new-self if $new-self;

                say "Could not find $line-editor module" unless $problem;
                return $self but FallbackBehavior;
            }

            my ( $new-self, $problem ) = mixin-readline($self, :fallback<Linenoise>);
            return $new-self if $new-self;

            ( $new-self, $problem ) = mixin-linenoise($self);
            return $new-self if $new-self;

            say $problem ?? "Continuing without tab completions or line editor\nYou may want to consider using rlwrap for simple line editor functionality"
                :: not $*DISTRO.is-win ?? 'You may want to `zef install Readline` or `zef install Linenoise` or use rlwrap for a line editor'
                :: '';

            $self but FallbackBehavior
        }

        method new(Mu \compiler, Mu \adverbs) {
            my $multi-line-enabled = not %*ENV<RAKUDO_DISABLE_MULTILINE>;
            my $self = self.bless();
            $self.init(compiler, $multi-line-enabled);
            $self = mixin-line-editor($self);
            $self
        }

        method init(Mu \compiler, $multi-line-enabled) {
            $!compiler := compiler;
            $!multi-line-enabled = $multi-line-enabled;
        }

        method teardown {
            self.?teardown-line-editor;
        }

        method repl-eval($code, *%adverbs) {

            CATCH {
                when X::Syntax::Missing {
                    return $!need-more-input
                      if $!multi-line-enabled && .pos == $code.chars;
                    .throw;
                }

                when X::Comp::FailGoal {
                    return $!need-more-input
                      if $!multi-line-enabled && .pos == $code.chars;
                    .throw;
                }

                when X::ControlFlow::Return {
                    return $!control-not-allowed;
                }

                default {
                    # Use the exception as the result of the eval, to be printed
                    return $_;
                }
            }

            CONTROL {
                when CX::Emit | CX::Take { .rethrow; }
                when CX::Warn { .gist.say; .resume;  }
                return $!control-not-allowed;
            }

            self.compiler.eval($code, |%adverbs);
        }

        method interactive_prompt() { '> ' }

        method repl-loop(*%adverbs) {
            say "To exit type 'exit' or '^D'";

            my $prompt;
            my $code;
            sub reset(--> Nil) { # this name should be a little more verbose
                $code = '';
                $prompt = self.interactive_prompt;
            }
            reset;

            REPL: loop {
                my $newcode = self.repl-read(~$prompt);

                my $initial_out_position = $*OUT.tell; # XXX why is this here? is it affected by the repl-read above?
                                                       # what would be the next location where it is affected?
                                                       # i think it should be moved to the last possible location,
                                                       # and gain an explanatory comment

                last if not $newcode.defined; # An undef $newcode implies ^D or similar

                $code = $code ~ $newcode ~ "\n";
                next if $code ~~ /^ <.ws> $/;

                my $*CTXSAVE := self;
                my $*MAIN_CTX;

                my $output = self.repl-eval(
                    $code,
                    :outer_ctx($!save_ctx),
                    |%adverbs);

                if self.input-incomplete($output) {
                    $prompt = '* ';
                    next;
                }

                if self.input-toplevel-control($output) {
                    say "Control flow commands not allowed in toplevel";
                    reset;
                    next;
                }

                $!save_ctx := $*MAIN_CTX if $*MAIN_CTX;
                reset;

                # Only print the result if there wasn't some other output
                self.repl-print($output) if $initial_out_position == $*OUT.tell;

                # Why doesn't the catch-default in repl-eval catch all?
                CATCH {
                    default { say $_; reset }
                }
            }

            self.teardown;
        }

        # Inside of the EVAL it does like caller.ctxsave
        method ctxsave() {
            $*MAIN_CTX := nqp::ctxcaller(nqp::ctx());
            $*CTXSAVE := 0;
        }

        method input-incomplete(Mu $value) {
            $value.WHERE == $!need-more-input.WHERE
        }

        method input-toplevel-control($value) {
            $value.WHERE == $!control-not-allowed.WHERE
        }

        method repl-print(Mu $value) {
            say $value;
            CATCH {
                default { say $_ }
            }
        }

        method history-file returns Str {
            return ~$!history-file if $!history-file.defined;

            $!history-file = $*ENV<RAKUDO_HIST>
                ?? IO::Path.new($*ENV<RAKUDO_HIST>)
                !! IO::Path.new($*HOME).child('.perl6').child('rakudo-history');
            try {
                mkpath($!history-file);

                CATCH {
                    when X::AdHoc & ({ .Str ~~ m:s/Unable to mkpath/ }) {
                        note "I ran into a problem trying to set up history: $_";
                        note 'Sorry, but history will not be saved at the end of your session';
                    }
                }
            }
            ~$!history-file
        }
    }
}
