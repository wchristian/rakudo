unit module Test;
my $Tester;

$Tester = .new given class {
    has int $.die-on-fail = ?%*ENV<PERL6_TEST_DIE_ON_FAIL>;
    has int $.failed    = 0;
    has int $.tests-run = 0;
    has     $.planned   = *;
    has Bool $.no-plan = True;
    has $!out = $PROCESS::OUT;
    has $!err = $PROCESS::ERR;

    method plan ($!planned) { $.no-plan = False; }

    method done-testing {
        $!out.say: "1..$!tests-run" if $!no-plan;
    }

    method test ($cond, $desc is copy) {
        $desc .= subst: :g, '#', '\\#'; # escape '#'
        $!tests-run++;
        my $tap;
        unless $cond {
            $tap ~= "not ";
            $!failed++;
        }
        $tap ~= "ok $!tests-run - $desc";
        $!out.say: $tap;

        unless $cond {
            my $caller = callframe 2;
            # sub proclaim is not called directly, so 2 is minimum level
            # my int $level = 2;
            #repeat until !$?FILE.ends-with($caller.file) {
            #    $caller = callframe($level++);
            #}

            self!diag: "\nFailed test {"'$desc'\n" if $desc} at {$caller.file} line {$caller.line}";
        }

        $cond
    }
    method !diag (Str() $message, :$err!) {
        $!err.say: $message.subst: :g, rx/^^/, '# ';
    }
    method diag (Str() $message) {
        $!out.say: $message.subst: :g, rx/^^/, '# ';
    }
}

multi plan (Int $n) is export { $Tester.plan: $n; }
multi plan ($n?)    is export {} # no plan, by default

# sub done-testing () is export { $Tester.done-testing; }
# sub plan ($n) is export { $Tester.plan: $n }
# sub pass ($desc = '') is export { $Tester.pass: $desc }
# sub ok (Mu $cond, $desc = '') is export { $Tester.test: ?$cond, $desc; }
# sub nok (Mu $cond, $desc = '') is export { $Tester.test: !$cond, $desc; }
# sub is (Mu $got, Mu:U $expected, $desc = '') is export {
#     $Tester.is: !$cond, $desc;
# multi sub is(Mu $got, Mu:D $expected, $desc = '') is export {
# multi sub isnt(Mu $got, Mu:U $expected, $desc = '') is export {
# multi sub isnt(Mu $got, Mu:D $expected, $desc = '') is export {
# multi sub cmp-ok(Mu $got, $op, Mu $expected, $desc = '') is export {
# sub bail-out ($desc?) is export {
# multi sub is_approx(Mu $got, Mu $expected, $desc = '') is export {
# multi sub is-approx(Numeric $got, Numeric $expected, $desc = '') is export {
# multi sub is-approx(
# multi sub is-approx(
# multi sub is-approx(
# multi sub is-approx(
# sub is-approx-calculate (
# multi sub todo($reason, $count = 1) is export {
# multi sub skip() {
# multi sub skip($reason, $count = 1) is export {
# sub skip-rest($reason = '<unknown>') is export {
# multi sub subtest(Pair $what)            is export { subtest($what.value,$what.key) }
# multi sub subtest($desc, &subtests)      is export { subtest(&subtests,$desc)       }
# multi sub subtest(&subtests, $desc = '') is export {
#     subtests();
# sub diag(Mu $message) is export {
# sub _diag(Mu $message, :$force-stderr) {
# multi sub flunk($reason) is export {
# multi sub isa-ok(Mu $var, Mu $type, $msg = ("The object is-a '" ~ $type.perl ~ "'")) is export {
# multi sub does-ok(Mu $var, Mu $type, $msg = ("The object does role '" ~ $type.perl ~ "'")) is export {
# multi sub can-ok(Mu $var, Str $meth, $msg = ( ($var.defined ?? "An object of type '" !! "The type '" ) ~ $var.WHAT.perl ~ "' can do the method '$meth'") ) is export {
# multi sub like(Str $got, Regex $expected, $desc = '') is export {
# multi sub unlike(Str $got, Regex $expected, $desc = '') is export {
# multi sub use-ok(Str $code, $msg = ("The module can be use-d ok")) is export {
# multi sub dies-ok(Callable $code, $reason = '') is export {
# multi sub lives-ok(Callable $code, $reason = '') is export {
# multi sub eval-dies-ok(Str $code, $reason = '') is export {
# multi sub eval-lives-ok(Str $code, $reason = '') is export {
# multi sub is-deeply(Mu $got, Mu $expected, $reason = '') is export {
# sub throws-like($code, $ex_type, $reason?, *%matcher) is export {
#     subtest {
# sub _is_deeply(Mu $got, Mu $expected) {
# sub die-on-fail {
# sub eval_exception($code) {
# sub proclaim($cond, $desc is copy ) {
# sub done-testing() is export {


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

Routines in category: `plan`, `done-testing`, `skip`, `skip-rest`, `output`,
`failure-output`, `todo-output`

Env vars in category: `PERL6_TEST_DIE_ON_FAIL`

### Grouping Routines

* Mark next X amount of tests as TODO
* Group X amount of tests as a separate mini-test-suite

Routines in category: `todo`, `subtest`

### Testing Routines

* Take operation that produces True/False and input
    - Do X on True
    - Do Y on False

Routines in category: `pass`, `ok`, `nok`, `is`, `isnt`, `cmp-ok`, `is-approx`,
`flunk`, `isa-ok`, `does-ok`, `can-ok`, `like`, `unlike`, `use-ok`, `dies-ok`,
`lives-ok`, `eval-dies-ok`, `eval-lives-ok`, `is-deeply`, `throws-like`

### Auxiliary Routines

* Display arbitrary messages requested by test author

Routines in category: `diag`

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
