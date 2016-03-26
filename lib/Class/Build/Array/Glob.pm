package Class::Build::Array::Glob;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Hook::AfterRuntime;

our %all_attribute_specs; # key=class, value=[$attr, \%predicates, ...]

sub _collect_attributes {
    my ($target_class, $package, $attrs) = @_;

    for my $parent (@{"$package\::ISA"}) {
        _collect_attributes($target_class, $parent, $attrs);
    }
    push @$attrs, @{ $all_attribute_specs{$package} // [] };
}

sub import {
    my $class0 = shift;

    my $caller = caller();
    *{"$caller\::has"} = sub {
        my ($attr_name, %predicates) = @_;
        push @{ $all_attribute_specs{$caller} }, [$attr_name, \%predicates];
    };
    after_runtime {
        my @attr_specs;

        # prepend the parent classes' attributes
        _collect_attributes($caller, $caller, \@attr_specs);

        # generate the accessor methods
        my $idx = 0;
        my $glob_attr;
        my %attr_indexes;
        for my $attr_spec (@attr_specs) {
            my ($attr_name, $predicates) = @$attr_spec;
            next if defined $attr_indexes{$attr_name};
            $attr_indexes{$attr_name} = $idx;
            die "Class $caller attribute $attr_name: can't declare ".
                "another attribute after globbing attribute ($glob_attr)"
                    if defined $glob_attr;
            if ($predicates->{glob}) {
                $glob_attr = $attr_name;
            }
            my $is = $predicates->{is} // 'ro';
            my $code_str = $is eq 'rw' ? 'sub (;$) { ' : 'sub () { ';
            if (defined $glob_attr) {
                $code_str .= "splice(\@{\$_[0]}, $idx, scalar(\@{\$_[0]}), \@{\$_[1]}) if \@_ > 1; "
                    if $is eq 'rw';
                $code_str .= "[ \@{\$_[0]}[$idx .. \$#{\$_[0]}] ]; ";
            } else {
                $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; "
                    if $is eq 'rw';
                $code_str .= "\$_[0][$idx]; ";
            }
            $code_str .= "}";
            #say "D:accessor code for attr $attr_name: ", $code_str;
            *{"$caller\::$attr_name"} = eval $code_str;
            die if $@;
            $idx++;
        }

        # generate constructor
        {
            my $code_str = 'sub { ';
            $code_str .= 'my ($class, %args) = @_; ';
            if (defined $glob_attr) {
                $code_str .= 'my $obj = bless [(undef) x '.scalar(keys %attr_indexes).'], $class; ';
            } else {
                $code_str .= 'my $obj = bless [], $class; ';
            }
            for my $attr_name (sort keys %attr_indexes) {
                my $idx = $attr_indexes{$attr_name};
                if (defined($glob_attr) && $attr_name eq $glob_attr) {
                    $code_str .= "if (exists \$args{'$attr_name'}) { splice(\@\$obj, $idx, scalar(\@\$obj), \@{ \$args{'$attr_name'} }) } ";
                } else {
                    $code_str .= "if (exists \$args{'$attr_name'}) { \$obj->[$idx] = \$args{'$attr_name'} } ";
                }
            }
            $code_str .= '$obj; }';
            #say "D:constructor code for class $caller: ", $code_str;
            unless (*{"$caller\::new"}{CODE}) {
                *{"$caller\::new"} = eval $code_str;
                die if $@;
            };
        }
    };
}

1;
# ABSTRACT:

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Build::Array::Glob;

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

An example of application: tree node objects, where the first attribute (array
element) is the parent, then zero or more extra attributes, then the last
attribute is a globbing one storing zero or more children. This is how
L<Mojo::DOM> stores its HTML tree node, for example.


=head1 SEE ALSO

Other class builders for array-backed objects: L<Class::XSAccessor::Array>,
L<Class::ArrayObjects>, L<Object::ArrayType::New>.
