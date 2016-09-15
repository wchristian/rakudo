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

done-testing;
