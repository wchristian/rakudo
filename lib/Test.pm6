unit module Test;

use MONKEY-SEE-NO-EVAL;
use MONKEY-GUTS;

class Tester { ... }
my @Testers = my $Tester
            = Tester.new: :die-if-fail(%*ENV<PERL6_TEST_DIE_ON_FAIL>);
END $Tester.cleanup;

our sub output         is rw { $Tester.out  }
our sub failure_output is rw { $Tester.err  }
our sub todo_output    is rw { $Tester.todo }

sub MONKEY-SEE-NO-EVAL() is export { 1 }
sub bail-out ($desc?)    is export { $Tester.bail-out: $desc; }
sub diag (Mu $message)   is export { $Tester.diag: $message.Str, :stderr; }
multi plan (Cool \n)     is export { $Tester.plan: n; }
multi plan (Whatever $)  is export {} # no plan, by default
multi plan ()            is export {} # no plan, by default
sub done-testing()       is export { $Tester.done-testing }
sub pass  (\desc = '')         is export { $Tester.test: True,  desc; }
sub flunk (\desc = '')         is export { $Tester.test: False, desc; }
sub ok  (Mu \cond, \desc = '') is export { $Tester.test: ?cond, desc; }
sub nok (Mu \cond, \desc = '') is export { $Tester.test: !cond, desc; }

multi sub is(Mu \got, Mu:U \expected, \desc = '') is export {
    $Tester.test: (not got.defined and got === expected), desc, {
        exgo "($(expected.perl))",
            got.defined ?? "'$(got.perl)'" !! "($(got.^name))";
    };
}
multi sub is(Mu \got, Mu:D \expected, \desc = '') is export {
    my $test;
    my $failure;
    if got.defined {
        unless $test = got eq expected {
            if try [eq] (got, expected)».Str».subst(/\s+/, '', :g) {
                # only white space differs, so better show it to the user
                $failure = { exgo expected.perl, got.perl };
            }
            else {
                $failure = { exgo "'$(expected)'", "'$(got)'" };
            }
        }
    }
    else {
        $failure = { exgo "'$(expected)'", "($(got).^name())" };
    }
    $Tester.test: ?$test, desc, $failure;
}

multi sub isnt(Mu \got, Mu:U \expected, \desc = '') is export {
    $Tester.test: (got.defined or got !=== expected), desc,
        { exgo "anything except '$(expected.perl)'", "'$(got.perl)'" };
}
multi sub isnt(Mu \got, Mu:D \expected, \desc = '') is export {
    $Tester.test: (not got.defined or got ne expected), desc,
        { exgo "anything except '$(expected.perl)'", "'$(got.perl)'" };
}

multi sub cmp-ok(Mu \got, &op, Mu \expected, \desc = '') is export {
    got.defined; # mark Failures as handled
    $Tester.test: ?op(got,expected), desc, {
          "expected: '$(expected // expected.^name)'\n"
        ~ " matcher: '$(&op.?name || &op.^name)'\n"
        ~ "     got: '$(got)'"
    };
}
multi sub cmp-ok(Mu \got, \op, Mu \expected, \desc = '') is export {
    got.defined; # mark Failures as handled
    # the three labeled &CALLERS below are as follows:
    #  #1 handles ops that don't have '<' or '>'
    #  #2 handles ops that don't have '«' or '»'
    #  #3 handles all the rest by escaping '<' and '>' with backslashes.
    #     Note: #3 doesn't eliminate #1, as #3 fails with '<' operator
    my &matcher
            =  &CALLERS::("infix:<$(op)>") #1
            // &CALLERS::("infix:«$(op)»") #2
            // &CALLERS::("infix:<$(op).subst(/<?before <[<>]>>/, "\\", :g)>")#3
            // return $Tester.test: False, desc, {
                "Could not use '$(op.perl)' as a comparator."
            };

    $Tester.test: ?matcher(got,expected), desc, {
          "expected: '$(expected // expected.^name)'\n"
        ~ " matcher: '$(&matcher.?name || &matcher.^name)'\n"
        ~ "     got: '$(got)'"
    };
}

multi sub is_approx(Mu \got, Mu \expected, \desc = '') is export {
    DEPRECATED('is-approx'); # Remove at 20161217 release (6 months from today)

    my \tol = expected.abs < 1e-6 ?? 1e-5 !! expected.abs * 1e-6;
    $Tester.test: (got - expected).abs <= tol, desc, { exgo expected, got };
}
multi sub is-approx(Numeric \got, Numeric \expected, \desc = '') is export {
    is-approx-calculate got, expected, 1e-5, Nil, desc;
}
multi sub is-approx(
    Numeric \got, Numeric \expected, Numeric \abs-tol, \desc = ''
) is export {
    is-approx-calculate got, expected, abs-tol, Nil, desc;
}
multi sub is-approx(
    Numeric \got, Numeric \expected, \desc = '', Numeric :$rel-tol is required
) is export {
    is-approx-calculate got, expected, Nil, $rel-tol, desc;
}
multi sub is-approx(
    Numeric \got, Numeric \expected, \desc = '', Numeric :$abs-tol is required
) is export {
    is-approx-calculate got, expected, $abs-tol, Nil, desc;
}
multi sub is-approx(
    Numeric \got, Numeric \expected, \desc = '',
    Numeric :$rel-tol is required, Numeric :$abs-tol is required
) is export {
    is-approx-calculate got, expected, $abs-tol, $rel-tol, desc;
}
sub is-approx-calculate (
    \got,
    \expected,
    \abs-tol where { !.defined or $_ >= 0 },
    \rel-tol where { !.defined or $_ >= 0 },
    \desc,
) {
    my Bool    ($abs-tol-ok, $rel-tol-ok) = True, True;
    my Numeric ($abs-tol-got, $rel-tol-got);
    if abs-tol.defined {
        $abs-tol-got = abs(got - expected);
        $abs-tol-ok = $abs-tol-got <= abs-tol;
    }
    if rel-tol.defined {
        $rel-tol-got = abs(got - expected) / max(got.abs, expected.abs);
        $rel-tol-ok = $rel-tol-got <= rel-tol;
    }

    $Tester.test: $abs-tol-ok && $rel-tol-ok, desc, {
        join "\n",(
              "maximum absolute tolerance: $(abs-tol)\n"
            ~ "actual absolute difference: $abs-tol-got"
                unless $abs-tol-ok
        ), (
              "maximum relative tolerance: $(rel-tol)\n"
            ~ "actual relative difference: $rel-tol-got"
                unless $rel-tol-ok
        )
    };
}

sub isa-ok(
    Mu \var, Mu \type, \desc = "The object is-a '$(type.perl)'"
) is export {
    $Tester.test: var.isa(type), desc, { "Actual type: $(var.^name)" };
}

sub does-ok(
    Mu \var, Mu \type, \desc = "The object does role '$(type.perl)'"
) is export {
    $Tester.test: var.does(type), desc,
        { "Type: $(var.^name) doesn't do role $(type.perl)" };
}

sub can-ok(
    Mu \var, Str \meth,
    \desc = (
        (var.defined ?? "An object of type" !! "The type" )
        ~ " '$(var.WHAT.perl)' can do the method '$(meth)'"
    )
) is export {
    $Tester.test: var.^can(meth), desc;
}

sub like(Str \got, Regex \expected, \desc = '') is export {
    $Tester.test: got ~~ expected, desc,
        { exgo "'$(expected.perl)'", "'$(got)'" };
}

sub unlike(Str \got, Regex \expected, \desc = '') is export {
    $Tester.test: !(\got ~~ \expected), desc,
        { exgo "'$(expected.perl)'", "'$(got)'" };
}

sub use-ok(Str \module, \desc = "The module can be use-d ok") is export {
    try EVAL "use $(module)";
    my \error = $!;
    $Tester.test: !error.defined, desc, { error };
}

sub dies-ok(&code, \desc = '') is export {
    my int $death = 1;
    try { code(); $death = 0; }
    $Tester.test: $death, desc;
}

sub lives-ok(&code, \desc = '') is export {
    try code();
    my \error = $!;
    $Tester.test: !error.defined, desc, { error };
}

sub eval-dies-ok(Str \code, \desc = '') is export {
    my \error = eval-exception code;
    $Tester.test: error.defined, desc;
}

sub eval-lives-ok(Str \code, \desc = '') is export {
    my \error = eval-exception code;
    $Tester.test: !error.defined, desc, { "Error: $(error)" };
}

sub is-deeply(Mu \got, Mu \expected, \desc = '') is export {
    $Tester.test: got eqv expected, desc, { exgo got.perl, expected.perl };
}

multi sub subtest(Pair \in)           is export { subtest in.value, in.key }
multi sub subtest(\desc, &tests)      is export { subtest &tests,   desc   }
multi sub subtest(&tests, \desc = '') is export {
    my \new-t = Tester.new:
        :indent(.indent ~ '    ')
        :die-if-fail(.die-if-fail and not .todo-num)
        :in-subtest
    given $Tester;

    @Testers.unshift: new-t;
    $Tester := new-t;
    tests();
    new-t.done-testing;
    @Testers.shift;
    $Tester := @Testers[0];
    $Tester.test: new-t.is-success, desc;
}

multi sub skip() {
    $Tester.test: True, "# SKIP";
}
multi sub skip(\desc, Numeric \count = 1) is export {
    for ^count {
        $Tester.test: True, "# SKIP $(desc)";
    }
}
multi sub skip($, $) is export {
    die "skip() was passed a non-numeric number of tests.  "
        ~ "Did you get the arguments backwards?";
}

sub throws-like(
    $code, \ex-type, \desc = "did we throws-like $(ex-type.^name)?",
    *%matcher
) is export {
    subtest {
        plan 2 + %matcher.keys;
        my $msg = '';
        if $code ~~ Callable {
            $msg = 'code dies';
            $code()
        } else {
            $msg = "'$code' died";
            EVAL $code, context => CALLER::CALLER::CALLER::CALLER::;
        }
        flunk $msg;
        skip 'Code did not die, can not check exception', 1 + %matcher.elems;
        CATCH {
            default {
                # TODO: remove the undefined check once we properly handle
                # messages for Failures. Currently, this replicates behaviour
                # of old Test.pm6
                pass $msg;
                my \got-type = $_;
                my \type-ok = got-type ~~ ex-type;
                $Tester.test: type-ok,
                    "right exception type ($(ex-type.^name))",
                    {
                          "Expected: $(ex-type.^name)\n"
                        ~ "Got:      $(got-type.^name)\n"
                        ~ "Exception message: $(got-type.message)"
                    },;

                if type-ok {
                    for %matcher.kv -> \k, \v {
                        my \got = got-type."$(k)"();
                        $Tester.test: got ~~ v,
                            ".$(k) matches $(v.gist)",
                            {
                                  "Expected: $(v ~~ Str ?? v !! v.perl)\n"
                                ~ "Got:      $(got)";
                            };
                    }
                } else {
                    skip 'wrong exception type', %matcher.elems;
                }
            }
        }
    }, desc;
}

sub todo(\desc, \count = 1) is export {
    $Tester.todo: "# TODO $(desc.subst(:g, '#', '\\#'))", count;
}

sub skip-rest(\desc = '<unknown>') is export {
    with $Tester {
        die "A plan is required in order to use skip-rest" if .no-plan;
        skip desc, .planned - .tests-run;
    }
}

class Tester {
    has int $.die-on-fail = ?%*ENV<PERL6_TEST_DIE_ON_FAIL>;
    has int $.failed    = 0;
    has int $.tests-run = 0;
    has     $.planned   = *;
    has Bool $.in-subtest = False;
    has Bool $!cleaned-up = False;
    has Bool $.no-plan is rw = True;
    has $.die-if-fail = False;
    has Str $.indent = '';
    has Str $!todo-reason = '';
    has Int $.todo-num = 0;

    has Bool $!done = False;
    has $.out  is rw = $PROCESS::OUT;
    has $.todo is rw = $PROCESS::OUT;
    has $.err  is rw = $PROCESS::ERR;

    method is-success {
        $!failed == 0 and ($!no-plan or $!planned == $!tests-run)
    }

    method plan ($!planned) {
        $.no-plan = False;
        $!out.say: $!indent ~ "1..$!planned";
    }

    method bail-out (\desc) {
        $!out.put: join ' ', 'Bail out!', (desc if desc);
        $!cleaned-up = True;
        exit 255;
    }

    method done-testing (:$automated){
        return if $!done;
        $!done = True;
        $!out.say: $!indent ~ "1..$!tests-run"
            if $!no-plan and not $automated;

        # Wrong quantity of tests
        not $!no-plan
            and $!planned != $!tests-run
            and self.diag: :stderr, "Looks like you planned $!planned test{
                    's' unless $!planned == 1
                }, but ran $!tests-run";

        $!failed
            and self.diag: :stderr, "Looks like you failed $!failed test{
                's' unless $!failed == 1
            } of $!tests-run";
    }

    method cleanup {
        return if $!cleaned-up;
        self.done-testing: :automated;
        # Clean up and exit
        .?close unless $_ === $*OUT | $*ERR or $!in-subtest
            for $!out, $!err, $!todo;

        exit $!failed min 254 if $!failed;
        exit 255 if not $!no-plan and $!planned != $!tests-run;
    }

    method test (\cond, $desc is copy = '', $failure?) {
        $desc .= subst: :g, '#', '\\#'; # escape '#'
        $!tests-run++;
        my $tap;
        unless cond {
            $tap ~= "not ";
            $!failed++ unless $!todo-num;
        }
        my $is-todo = False;
        $tap ~= "ok $!tests-run - $desc$(
                if $!todo-num { $!todo-num--; $is-todo = True; $!todo-reason }
            )";
        $!out.say: $!indent ~ $tap;

        unless cond {
            my int $level = 2;
            my $caller = callframe $level;
            repeat until !$?FILE.ends-with($caller.file) {
                $caller = callframe(++$level);
            }
            self.diag: |(:stderr unless $is-todo),
                "\nFailed test $("'$desc'\n" if $desc)at $($caller.file) line "
                ~ $caller.line ~ ("\n" ~ $failure() if $failure);

            $!die-if-fail and not $is-todo and self!die-on-fail;
        }

        cond
    }

    method !die-on-fail {
        self.diag: :stderr, 'Test failed. Stopping test suite, because'
                ~ ' PERL6_TEST_DIE_ON_FAIL environmental variable is set'
                ~ ' to a true value.';
        exit 255;
    }

    method todo ($!todo-reason, $!todo-num, --> Nil) {}

    multi method diag (Str \message, :$stderr!) {
        $!err.say: $!indent ~ "# $(message)".subst(:g, "\n", "\n# ")
                                          .subst(:g, rx/^^'#' \s+ $$/, '');
    }
    multi method diag (Str \message) {
        $!out.say: $!indent ~ "# $(message)".subst(:g, "\n", "\n# ")
                                          .subst(:g, rx/^^'#' \s+ $$/, '');
    }
}

sub exgo (\expected, \got) { 'expected: ' ~ expected ~ "\n     got: " ~ got }
sub eval-exception(\code) { try EVAL code; $! }

=finish

## Goals:

* Remove code spaghettification
* Remove duplicate logic
* Avoid having a whole bunch of global variables
* Try to improve performance
* ???
* Profit!

-----------------------------------------------------

## Routine Categories

### Control Routines

* Plan number of tests
* Indicate we're done testing
* Skip X amount of tests
* Bail out of the test suite
* Die on failures
* Alter output handler

Routines in category: ✓`plan`, ✓`done-testing`, ✓`skip`, ✓`skip-rest`,
✓`bail-out`, ✓`output`, ✓`failure-output`, ✓`todo-output`

Env vars in category: ✓`PERL6_TEST_DIE_ON_FAIL`

### Grouping Routines

* Mark next X amount of tests as TODO
* Group X amount of tests as a separate mini-test-suite

Routines in category: ✓`todo`, ✓`subtest`

### Testing Routines

* Take operation that produces True/False and input
    - Do X on True
    - Do Y on False

Routines in category: ✓`pass`, ✓`ok`, ✓`nok`, ✓`is`, ✓`isnt`, ✓`cmp-ok`,
✓`is-approx`, ✓`flunk`, ✓`isa-ok`, ✓`does-ok`, ✓`can-ok`, ✓`like`,
✓`unlike`, ✓`use-ok`, ✓`dies-ok`, ✓`lives-ok`,
✓`eval-dies-ok`, ✓`eval-lives-ok`, ✓`is-deeply`, ✓`throws-like`

### Auxiliary Routines

* Display arbitrary messages requested by test author

Routines in category: ✓`diag`

-----------------------------------------------------

## Structure

The module uses a `Tester` class that keeps state as well as provides
a single pass/fail testing interface on which all other test routines rely on.
Only one instance of `Tester` exists per test *level*, which means a
`subtest` invocation creates its own instance, with its own state.

### State

State is stored in `Tester` class that is set during object's instantiation
and can be altered by the routines in the **Control Routines** category.

The object is pushed into a module-wide array that functions as a stack of
Tester classes, each handling subtests. A subtest entry pushes a new Tester
object onto the stack and exit from subtest pops one off.

### Testing

*speculative section; needs trial implementanions and benching*

Each of the routines in **Testing Routines** will invoke `Tester`'s single
test subroutine by telling it the operation to perform and what to do on
True/False.

The test routine will handle marking the test as TODO, correctly directing
the output, dying on failures, and emitting proper TAP output, depending on
the outcome of the provided test operation.

-----------------------------------------------------------

Issues in the old Test.pm6 found during refactoring:

* like (Failure, Regex) and unlike (Failure, Regex) candidates do not exist,
despite existing candidates having logic to handle failures (they won't ever
get there)

* unlike() generates confusing diag() message one failure:
<TestNinja> m: use Test; unlike 'foo', /foo/
<camelia> rakudo-moar 2c95f7: OUTPUT«not ok 1 - ␤␤# Failed test at <tmp>
    line 1␤#      expected: '/foo/'␤#      got: 'foo'␤»

* Inconsistency of failure output between lives-ok and eval-lives-ok

* multi-line diag() in subtests does not indent subsequent lines correctly

* Double-space in non-Numeric skip count warning: die "skip() was passed a
non-numeric number of tests.  Did you get the arguments backwards?" if $count
!~~ Numeric;

* skip backslashes the '#' before SKIP, even thought that's not needed

* throws-like has incosistent "code died/dies" message on failure to die;
as well as capitalization of Expected/Got messages. Different indent
for the expected got messages. Also, Test.pm6 is referenced in failures.
ALSO, the message for "code dies" is not printed when the code given is a
Failure

* todo() does not have the same API as skip() [check count is numeric; let
omit description]

* Test whether we actually need to escape hashmarks in TODO reasons

-------------------------------------

TODO:

Refactor diag()
Add --> Nil to all routines that matter

* Some sort of a crash with large number of failing tests. Present in both
new and old version:
https://gist.github.com/zoffixznet/98e8e5a01d07c47e0487d68354142f27
