# this module should die when loaded

package # hide from PAUSE
    Local::C3;

use parent qw(Local::C2);

use Class::Accessor::Array::Glob;

has moreglob => (is => 'rw', glob => 1);

1;
