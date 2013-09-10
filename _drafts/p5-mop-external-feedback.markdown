---
layout: post
title: p5-mop: external feedback
---

# {{ page.title }}

## using p5-mop

I guess that you've heard about p5-mop by now.

If not, in a nutshell, p5-mop is an attempt to implement a subset of
[Moose](http://moose.iinteractive.com/) into the core of Perl. Moose provides a
Meta Object Protocol to Perl. So does p5-mop, however p5-mop is implemented in
a way that it can be properly included in the Perl core.

As far as I understood, after trying to hack directly in the core, Stevan
Little restarted the p5-mop implementation: the so called p5-mop-redux [github
project](https://github.com/stevan/p5-mop-redux), using
[Devel::Declare](https://metacpan.org/module/Devel::Declare), ( then
[Parse::Keyword](https://metacpan.org/module/Parse::Keyword) ), so that he can
experiment and release often, while keeping the implementation core-friendly.
Once he's happy with the features and all, he'll make sure it finds its way to
the core. A small team (Steven Little, Jesse Luehrs, and other contributors) is
actively developping p5-mop, and Stevan is regularly [blogging about
it](http://blogs.perl.org/users/stevan_little/).

Few months ago, when p5-mop-redux was announced, I tried to give it a go. And
you should too ! Because it's easy.

## install it ##

p5-mop is very easy to install:

1. if you're using github, just fork the p5-mop-redux project. Otherwise you can get a zip [here](https://github.com/stevan/p5-mop-redux/archive/master.zip).
2. If you don't have cpanm, get it with `curl -L http://cpanmin.us | perl - App::cpanminus`
3. using cpanm, execute `cpanm .` from within the p5-mop-redux directory.

## syntax ##

Here is the classical point example from the [p5-mop test suite](https://github.com/stevan/p5-mop-redux/blob/master/t/001-examples/001-point.t)
 
```perl
use mop;

class Point {
    has $x is ro = 0;
    has $y is ro = 0;

    method set_x ($new_x) {
        $x = $new_x;
    }

    method set_y ($new_y) {
        $y = $new_y;
    }

    method clear {
        ($x, $y) = (0, 0);
    }

    method pack {
        +{ x => $self->x, y => $self->y }
    }
}

# ... subclass it ...

class Point3D extends Point {
    has $z is ro = 0;

    method set_z ($new_z) {
        $z = $new_z;
    }

    method pack {
        my $data = $self->next::method;
        $data->{z} = $z;
        $data;
    }
}
```

Note: a class Foo defined in the package Bar will be declared as Bar::Foo.

## attributes traits ##

As you can see in the example, an attribute is declared using `has`. After the
attribute name, you can add 'is', which is followed by a list of 'traits':

    has foo is ro, lazy = 42;

* ro/rw means it's read-only / read-write
* lazy means the attribute constructor won't be 
* weak_ref

## methods ##

methods definitions are done using the `method` keyword, followed by the method name, plus optional _method traits_

## types ##

Types are not yet core to the p5-mop, and the team is questioning this idea. The concensus is currently that 

## default value / constructor ##

```perl
has foo = 'default value';
```

which is actually

```perl
has foo = sub { 'default value' };
```

So, there is no default value, only constructors. Meaning that

```perl
has foo = {};
```

will work properly ( creating a new hashref each time )

There has been some comments about using `=` instead of `//` or `||` or
`default`, but this syntax is used in a lot of other programing language, and
considered somehow the default (hehe) syntax. I think it's worth sticking with
`=` for an easier learning curve for newcomers.

## getter / setter ##

they are

## methods ##

use the word 'method'

method append {
  $self
}

## clearer / predicate ##

Because the constructor is already implemented using `=`, what about clearer
and predicate?


```perl
# clearer
method clear_foo { undef $foo }

# predicate
method has_foo { defined $foo }
```

## meta ##

Going meta is not difficult either but I won't describe it here, as I just want
to showcase default OO programming syntax. On that note, it looks like Stevan
will make classes immutable by default, unless specified. I think that this is
a good idea (how many time have you written make_immutable ?).

# my humble constructive remarks #

## Undef versus not set
In Moose there is a difference between an attribute being unset, and an
attribute being undef. In p5-mop, there is no such distinction. The reason for
this is partially technical, and maybe partially a dising decision.


## Method Modifiers

Method modifiers are not yet implemented, but they won't be difficult to
implement. Actually, here is an example of how to implement method modifiers
using p5-mop very own meta. It implements `around`:

```perl
sub modifier {
    if ($_[0]->isa('mop::method')) {
        my $method = shift;
        my $type   = shift;
        my $meta   = $method->associated_meta;
        if ($meta->isa('mop::role')) {
            if ( $type eq 'around' ) {
                $meta->bind('after:COMPOSE' => sub {
                    my ($self, $other) = @_;
                    if ($other->has_method( $method->name )) {
                        my $old_method = $other->remove_method( $method->name );
                        $other->add_method(
                            $other->method_class->new(
                                name => $method->name,
                                body => sub {
                                    local ${^NEXT} = $old_method->body;
                                    my $self = shift;
                                    $method->execute( $self, [ @_ ] );
                                }
                            )
                        );
                    }
                });
            } elsif ( $type eq 'before' ) {
                die "before not yet supported";
            } elsif ( $type eq 'after' ) {
                die "after not yet supported";
            } else {
                die "I have no idea what to do with $type";
            }
        } elsif ($meta->isa('mop::class')) {
            die "modifiers on classes not yet supported";
        }
    }
}```

It is supposed to be used like this:

```perl
method my_method is modifier('around') ($arg) {
    $arg % 2 and return $self->${^NEXT}(@_);
    die "foo";
}
```

  around foo
  method foo is modifier(around)
  method foo is around
* ${^NEXT} : not very nice
* ${^SELF}
* modifiers in roles
* 'is' ? why use has + is ? isn't one verb enough ? in Moo*, the 'is' was just
  one property. we had default, lazy, etc. Now, 'is' is just a seperator
  between the name and the 'traits'

## Exporter

p5-mop doesn't use @ISA for inheritance, so `use base 'Exporter'` won't work.
You have to do `use Exporter 'import'`. That is somewhat disturbing because
most Perl developers (I think) implements classes by inheriting from Exporter
(that's also what the documentation of Exporter recommends).

You could argue that one should code clean classes (that don't export anything,
and clean modules (that export stuff but don't do OO). Mixing OO in a class
with methods and exportable subs looks a bit un-orthodox. But that's what we do
all day long and it is almost part of the Perl culture now. Think about all the
modules that provides 2 API, a functional one and an OO one. All in the same
namespace. So, _somehow_, being able to easily export subs is needed.

However, as per Jesse Luehrs and Stevan Little, they don't think a MOP
implementation should be in charge of implementing an Exporter module, and I
can only agree with this. So it looks like the solution will be a method trait,
like `exportable`:

```perl
sub foo is exportable { ... }
```

But that is not yet impemented.


## Inside Out objects versus blessed structure objects


