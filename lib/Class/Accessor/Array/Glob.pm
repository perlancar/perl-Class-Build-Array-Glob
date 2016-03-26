package Class::Accessor::Array::Glob;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Hook::AfterRuntime;

sub import {
    my $class = shift;

    say "import";

    my $caller = caller();
    *{"$caller\::has"} = sub { say "declaring $_[0]" };
    after_runtime { say "finalizing class" };
}

1;
# ABSTRACT:

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::Array::Glob;

 has foo => (is => 'rw');
 has bar => (is => 'rw');
 has baz => (is => 'rw', glob=>1);

In code that uses your class, use your class as usual:

 use Your::Class;

 my $obj = Your::Class->new(foo => 1);
 $obj->bar(2);

 my $obj2 = Your::Class->new(foo=>11, bar=>12, baz=>[13, 14, 15]);

C<$obj1> is now:

 bless([1, 2], "Your::Class");

C<$obj2> is now:

 bless([11, 12, 13, 14, 15], "Your::Class");


=head1 DESCRIPTION

This module is a class builder for array-backed classes. With it you can declare
your attributes using Moose-style C<has>. Only these C<has> predicates are
currently supported: C<is> (ro/rw), C<glob> (bool). Array index will be
determined by the order of declaration, so in the example in Synopsis, C<foo>
will be stored in element 0, C<bar> in element 1.

The predicate C<glob> can be specified for the last attribute. It means the
attribute has an array value that are put in the end of the object backend
array's elements. So in the example in Synopsis, C<baz>value's elements will
occupy object backend array's elements 2 and subsequent.

There can only be at most one attribute with B<glob> set to true. After the
globbing attribute, there can be no more arguments (so subclassing a class with
a globbing attribute is not possible).

Note that without globbing attribute, you can still store arrays or other
complex data in your attributes. It's just that with a globbing attribute, you
can keep a single flat array backend, so the overall number of arrays is
minimized.


=head1 SEE ALSO

Other class builders for array-backed objects: L<Class::XSAccessor::Array>,
L<Class::ArrayObjects>, L<Object::ArrayType::New>.
