# plan 2;

sub failure { fail 'tis a failure' }
my $Class = class { method foo {} }
my $Instance = $Class.new;
class Foo { method foo {} }
my $Foo = Foo.new;
my $Role = role {};
role FooRole {};

is $Class, Int, 'just a test';
is $Class, Int;
is $Class, 42, 'just a test';
is $Class, 42;
is $Instance, 42, 'just a test';
is $Instance, 42;
is Foo, $Foo, 'just a test';
is Foo, $Foo;
is $Foo, 42, 'just a test';
is $Foo, 42;

isnt $Class, $Class, 'just a test';
isnt $Class, $Class;
isnt $Instance, $Instance, 'just a test';
isnt $Instance, $Instance;

cmp-ok $Instance, &[===], $Class, 'just a test';
cmp-ok $Instance, &[===], $Class;
cmp-ok $Class, &[===], $Instance, 'just a test';
cmp-ok $Class, &[===], $Instance;

is_approx 1e-7, 1e-6, 'just a test';
is_approx 1e-7, 1e-6;
is_approx 5, 6, 'just a test';
is_approx 5, 6;

isa-ok $Foo, $Class, 'just a test';
isa-ok $Foo, $Class;
isa-ok $Class, $Class;
isa-ok $Instance, $Class;
isa-ok $Foo, Foo;

does-ok $Foo but $Role, $Role;
does-ok $Foo but role {}, $Role;
does-ok $Foo but role {}, $Role, 'just a test';
does-ok $Foo but role {}, FooRole, 'just a test';
does-ok $Foo but role {}, FooRole;

can-ok $Instance, 'foo';
can-ok $Class, 'foo';

like 'foo', /bar/, 'just a test';
like 'foo', /bar/;

done-testing;
