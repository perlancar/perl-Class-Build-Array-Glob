package # hide from PAUSE
    Local::C2;

use Class::Accessor::Array::Glob;

use parent qw(Local::C1);

has qux  => (is=>'rw');
has quux => (is=>'rw', glob=>1);

1;
