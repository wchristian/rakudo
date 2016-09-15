# plan 2;

sub failure { fail 'tis a failure' }
my $Class = class {}
my $Instance = class {}.new;
class Foo {}
my $Foo = Foo.new;

note ok 0, 'just a test';
ok 0;
ok 1, 'just a test';
ok 1;
ok failure, 'just a test';
ok failure;

nok 1, 'just a test';
nok 1;
nok 0, 'just a test';
nok 0;
nok failure, 'just a test';
nok failure;

is 42, Int, 'just a test';
is 42, Int;
is Int, Int, 'just a test';
is Int, Int;
is $Class, $Class, 'just a test';
is $Class, $Class;
is Foo, Foo, 'just a test';
is Foo, Foo;
is failure, Int, 'just a test';
is failure, Int;

is Int, 42, 'just a test';
is Int, 42;
is 42, 42, 'just a test';
is 42, 42;
is $Instance, $Instance, 'just a test';
is $Instance, $Instance;
is Foo, 42, 'just a test';
is Foo, 42;
is $Foo, $Foo, 'just a test';
is $Foo, $Foo;
is failure, 42, 'just a test';
is failure, 42;
is 'foo ', 'foo', 'just a test'; # only whitespace differs
is 'foo ', 'foo';

isnt Int, Int, 'just a test';
isnt Int, Int;
isnt 42, Int, 'just a test';
isnt 42, Int;
isnt $Class, Int, 'just a test';
isnt $Class, Int;
isnt Foo, Int, 'just a test';
isnt Foo, Int;
isnt failure, Int, 'just a test';
isnt failure, Int;
isnt Foo, Foo, 'just a test';
isnt Foo, Foo;
isnt 42, 42, 'just a test';
isnt 42, 42;
isnt Int, 42, 'just a test';
isnt Int, 42;
isnt $Class, 42, 'just a test';
isnt $Class, 42;
isnt Foo, 42, 'just a test';
isnt Foo, 42;
isnt Foo, $Foo, 'just a test';
isnt Foo, $Foo;
isnt $Foo, 42, 'just a test';
isnt $Foo, 42;
isnt $Foo, $Foo, 'just a test';
isnt $Foo, $Foo;
isnt failure, 42, 'just a test';
isnt failure, 42;

sub matcher { $^a == $^b }
cmp-ok 42, &matcher, 42, 'just a test';
cmp-ok 42, &matcher, 42;
cmp-ok 42, &matcher, 72, 'just a test';
cmp-ok 42, &matcher, 72;
cmp-ok failure, &matcher, 42, 'just a test';
cmp-ok failure, &matcher, 42;

cmp-ok 42, &[==], 42, 'just a test';
cmp-ok 42, &[==], 42;
cmp-ok 42, &[==], 72, 'just a test';
cmp-ok 42, &[==], 72;
cmp-ok failure, &[==], 42, 'just a test';
cmp-ok failure, &[==], 42;

cmp-ok 42, '==', 42, 'just a test';
cmp-ok 42, '==', 42;
cmp-ok 42, '==', 72, 'just a test';
cmp-ok 42, '==', 72;
cmp-ok failure, '==', 42, 'just a test';
cmp-ok failure, '==', 42;

cmp-ok 42, 'not-it', 42, 'just a test';
cmp-ok 42, 'not-it', 42;
cmp-ok 42, 'not-it', 72, 'just a test';
cmp-ok 42, 'not-it', 72;
cmp-ok failure, 'not-it', 42, 'just a test';
cmp-ok failure, 'not-it', 42;

cmp-ok $Instance, &[===], $Instance, 'just a test';
cmp-ok $Instance, &[===], $Instance;
cmp-ok $Class, &[===], $Class, 'just a test';
cmp-ok $Class, &[===], $Class;

is-approx 5, 5-.5e-5, 'just a test';
is-approx 5, 5-.5e-5;
is-approx 5, 5-1.5e-5, 'just a test';
is-approx 5, 5-1.5e-5;

is-approx 1, 2, 1, 'just a test';
is-approx 1, 2, 1;
is-approx 1, 3, 1, 'just a test';
is-approx 1, 3, 1;

is-approx 1, 2,  :rel-tol<.5>, 'just a test';
is-approx 1, 2,  :rel-tol<.5>;
is-approx 1, 20, :rel-tol<.5>, 'just a test';
is-approx 1, 20, :rel-tol<.5>;

is-approx 1, 2, :abs-tol<1>, 'just a test';
is-approx 1, 2, :abs-tol<1>;
is-approx 1, 3, :abs-tol<1>, 'just a test';
is-approx 1, 3, :abs-tol<1>;

is-approx 1e0, 1e1, :abs-tol<9>,    :rel-tol<.9>;
is-approx 1e2, 1e3, :abs-tol<900>,  :rel-tol<.9>;
is-approx 1e3, 1e5, :abs-tol<99e3>, :rel-tol<.99>;
is-approx   1, 1.5, :abs-tol<1>,    :rel-tol<.4>;
is-approx 1e0, 1e1, :abs-tol<9>,    :rel-tol<.9>,  'test desc one';
is-approx 1e2, 1e3, :abs-tol<900>,  :rel-tol<.9>,  'test desc two';
is-approx 1e3, 1e5, :abs-tol<99e3>, :rel-tol<.99>, 'test desc three';
is-approx   1, 1.5, :abs-tol<1>,    :rel-tol<.4>,  'test desc four';
is-approx 1, 10, :abs-tol<5>,  :rel-tol<.9>;
is-approx 1, 10, :abs-tol<90>, :rel-tol<.5>;
is-approx 1, 10, :abs-tol<5>,  :rel-tol<.5>;
is-approx 1, 10, :abs-tol<5>,  :rel-tol<.9>, 'test desc five';
is-approx 1, 10, :abs-tol<90>, :rel-tol<.5>, 'test desc six';
is-approx 1, 10, :abs-tol<5>, :rel-tol<.5>, 'test desc seven';

is_approx 1e-7, 1.1e-7, 'just a test';
is_approx 1e-7, 1.1e-7;
is_approx 5, 5-1e-6, 'just a test';
is_approx 5, 5-1e-6;

done-testing;
