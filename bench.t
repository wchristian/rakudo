use lib <lib>;
use Test;
my $scale = 100;

for ^(100*$scale) {
    pass;
    pass 'some description for the test';
    ok 1;
    ok 1, 'some description for the test';
    nok 0;
    nok 0, 'some description for the test';
    is 1, 1;
    is 1, 1, 'some description for the test';
    isnt 1, 0;
    isnt 1, 0, 'some description for the test';
    isnt 1, Int;
    isnt 1, Int, 'some description for the test';
    isnt 1, Str;
    isnt 1, Str, 'some description for the test';
}

for ^($scale) {
    flunk 'some description for the test';
    ok 0;
    ok 0, 'some description for the test';
    nok 1;
    nok 1, 'some description for the test';
    is 1, 0;
    is 1, 0, 'some description for the test';
    is 1, Int;
    is 1, Int, 'some description for the test';
    is 1, Str;
    is 1, Str, 'some description for the test';
    isnt 1, 1;
    isnt 1, 1, 'some description for the test';
}

done-testing;
