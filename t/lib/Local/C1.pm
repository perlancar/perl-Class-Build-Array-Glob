package # hide from PAUSE
    Local::C1;

use Class::Accessor::Array::Glob;

has foo => (is=>'rw');
has bar => (is=>'rw');
has baz => (is=>'rw');

1;
