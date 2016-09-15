# plan 2;

sub failure { fail 'tis a failure' }
my $Class = class {}
my $Instance = class {}.new;
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


done-testing;
