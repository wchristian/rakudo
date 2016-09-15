# plan 2;

sub failure { fail 'tis a failure' }

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
is failure, Int, 'just a test';
is failure, Int;

is Int, 42, 'just a test';
is Int, 42;
is 42, 42, 'just a test';
is 42, 42;
is failure, 42, 'just a test';
is failure, 42;

isnt Int, Int, 'just a test';
isnt Int, Int;
isnt 42, Int, 'just a test';
isnt 42, Int;
isnt failure, Int, 'just a test';
isnt failure, Int;

isnt 42, 42, 'just a test';
isnt 42, 42;
isnt Int, 42, 'just a test';
isnt Int, 42;
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
