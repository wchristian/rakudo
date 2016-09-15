# plan 2;

sub failure { fail 'tis a failure' }
my $Class = class {}
my $Instance = $Class.new;
class Foo {}
my $Foo = Foo.new;

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

done-testing;
