# plan 2;

ok 0, 'just a test'; #1
ok 0;
ok 1, 'just a test';
ok 1;

nok 1, 'just a test'; # 5
nok 1;
nok 0, 'just a test';
nok 0;

is 42, Int, 'just a test'; # 9
is 42, Int;
is Int, Int, 'just a test';
is Int, Int;

is Int, 42, 'just a test'; # 13
is Int, 42;
is 42, 42, 'just a test';
is 42, 42;

is 42, Int, 'just a test'; # 17
is 42, Int;
is Int, Int, 'just a test';
is Int, Int;

done-testing;
