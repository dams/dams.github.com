---
layout: post
title: p5-mop: external feedback
---

# {{ page.title }}

## p5-mop

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

## Why is it important to try it out ? ##

It's important to have at least a vague idea of where p5-mop stands at, because
this project is shaping a big part of Perl's future. There will be a _before_
and an _after_ having a mop in core. And it is being designed and tested right
now. So as Perl users, it's our chance to have a look at it, test it, and give
our feedback.

Do we like the syntax ? Do we find it easy enough? What did we prefer more/less
in Moose ? etc. In few months, things will be decided and it'll only be a
matter of time and implementation details. Now is the most exciting time to
participate in the project. You don't need to hack on it, just try it out, and
provide feedback.

## Install it ##

p5-mop is very easy to install:

1. if you're using github, just fork the `p5-mop-redux` project. Otherwise you can get a zip [here](https://github.com/stevan/p5-mop-redux/archive/master.zip).
2. if you don't have cpanm, get it with `curl -L http://cpanmin.us | perl - App::cpanminus`
3. using cpanm, execute `cpanm .` from within the p5-mop-redux directory.
4. you'll need to do the same with twigil: either fork the `twigils` project,
   or get a zip [here](https://github.com/rafl/twigils/archive/master.zip).
5. then cpanm, execute `cpanm .` from within the twigils directory.

## Classes ##

Here is the classical point example from the [p5-mop test suite](https://github.com/stevan/p5-mop-redux/blob/master/t/001-examples/001-point.t)
 
```perl

    use mop;
    
    class Point {
        has $!x is ro = 0;
        has $!y is ro = 0;
    
        method set_x ($x) {
            $!x = $x;
        }
    
        method set_y ($y) {
            $!y = $y;
        }
    
        method clear {
            ($!x, $!y) = (0, 0);
        }
    
        method pack {
            +{ x => $self->x, y => $self->y }
        }
    }
    
    # ... subclass it ...
    
    class Point3D extends Point {
        has $!z is ro = 0;
    
        method set_z ($z) {
            $!z = $z;
        }
    
        method pack {
            my $data = $self->next::method;
            $data->{z} = $!z;
            $data;
        }
    }
```

So this examples shows how straightforward it is to declare a class and a
subclass. The syntax is very friendly and similar to what you may find in other
langauges. A class can inherit from an other one by `extend`ing it.

Few notes:
* Classes can have a `BUILD` method, as with Moose.
* In a inheriting class, calling the parent method is not done using `SUPER`,
  but `$self->next::method`.
* A class `Foo` declared in the package `Bar` will be defined as `Bar::Foo`.

## Roles

```perl
role Bar {
    has $!additional_attr = 42;
    method more_feature { say $!additional_attr }
}
```

Roles are defined in a straightforward way. They are consumed by the class
right in the class declaration line:

```perl
class Foo with Bar, Baz {
    # ...
}
```

## Attributes traits ##

As you can see in the example, an attribute is declared using `has`. However
the attribute declaration is not a simple name, it's a twigil variable name.

After the attribute name, you can add 'is', which is followed by a list of
'traits':

    has $!foo is ro, lazy = 42;

* `ro` / `rw` means it's read-only / read-write
* `lazy` means the attribute constructor we'll be called only when the
attribute is being used
* `weak_ref` enables an attribute to be a weak reference, 

## methods ##

methods definitions are done using the `method` keyword, followed by the method
name, plus optional _method traits_

## types ##

Types are not yet core to the p5-mop, and the team is questioning this idea.
The concensus is currently that types should not be part of the mop, to


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
method clear_foo { undef $!foo }

# predicate
method has_foo { defined $!foo }
```

That was pretty easy, right? Predicates and clearers have been introduced in
Moose because writing them ourselves would requirer to access the underlying
HashRef behind an instance (for instance, `sub predicate { exists
$self->{$attr_name} }`) and that's very bad. To work around that, Moose has to
generate that kind of code and provie a way to enable it or not. But because of
the twigils in p5-mop, there is no issue in writing predicates and cleare
ourselves.

But I hear you say "Wait, these are no clearer nor predicate ! They are not testing the
existence of the attributes, but their defineness!" You're right, but read on!

# My humble constructive remarks #

## Undef versus not set
In Moose there is a difference between an attribute being unset, and an
attribute being undef. In p5-mop, there is no such distinction. The reason for
this is partially technical, and maybe partially a design decision.

Because the attributes get a twigil variable created, it's currently impossible
to make the distinction between an attribute being unset or undef. That could
be changed, by adding a marker on the variable, having a special method to know
if an attribute has been set, or a different technique.

But Stevan said that it wasn't bothering him too much. For developers new to
OO, it seems weird to tell them that their attributes can have

* no value
* an undef value
* a false value
* a true value

That's probably too many cases... Getting rid of one of them looks sane to me.
Plus, in standard Perl programming, if an optional argument is not passed to a
function, it's not "non-existent", it's _undef_. So it makes sense to have a
similar behavior in mop. After all, we got this "not set" state only because
objects are stored in HashRef, so it looks like it's an implementation detail
that made its way into becoming a concept on its own.

## meta ##

Going meta is not difficult either but I won't describe it here, as I just want
to showcase default OO programming syntax. On that note, it looks like Stevan
will make classes immutable by default, unless specified. I think that this is
a good idea (how many time have you written make_immutable ?).


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
most Perl developers (I think) implement classes by inheriting from Exporter
(that's also what the documentation of Exporter recommends).

You could argue that one should code clean classes (that don't export anything,
and clean modules (that export stuff but don't do OO). Mixing OO in a class
with methods and exportable subs looks a bit un-orthodox. But that's what we do
all day long and it is almost part of the Perl culture now. Think about all the
modules that provides 2 APIs, a functional one and an OO one. All in the same
namespace. So, _somehow_, being able to easily export subs is needed.

However, as per Jesse Luehrs and Stevan Little, they don't think a MOP
implementation should be in charge of implementing an Exporter module, and I
can totally agree with this. So it looks like the solution will be a method
trait, like `exportable`:

```perl
sub foo is exportable { ... }
```

But that is not yet impemented.


## Inside Out objects versus blessed structure objects

p5-mop is not using the standard scheme where an object is simply a blessed
structure (usually a `HashRef`). Instead, it's using InsideOut objects, where
all you get as an object is some kind of identification number (usually a
simple reference), which is used internally to retreieve the object properties,
only accessible from within the class.

This way of doing may seem odd at first: if I recall correctly, there a time
where InsideOut objects were trendy, especially using `Class::Std`. But that
didn't last long, when Moose and its follow ups came back to using regular
blessed structured objects. So why use inside out objects?

At first it 

## Where now ?

Now, it's your turn to try it out, make up your mind, try to port an
module or write on from scratch using p5-mop, and give your feedback. To do
that, go to the IRC channel #p5-mop on the irc.mongueurs.net server, say hi,
and explain what you tried, what went well and what didn't, and how you feel
about the syntax and concepts.

Also, spread the word by writing about your experience with p5-mop, for
instance on [blogs.perl.org](blogs.perl.org)

Lastly, don't hesitate to participate in the comments below :) Especially if
you don't agree with my remarks above.

## Reference

* [p5-mop-redux on github](https://github.com/stevan/p5-mop-redux)
* [twigils on github](https://github.com/rafl/twigils)
* [Moose to mop tutorial](https://github.com/stevan/p5-mop-redux/blob/master/lib/mop/manual/tutorials/moose_to_mop.pod)

