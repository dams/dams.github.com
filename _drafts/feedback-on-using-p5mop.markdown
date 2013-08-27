---
layout: post
title: Feedback on using p5-mop
---

# {{ page.title }}

I guess that you've heard about p5-mop by now.

In a nutshell, p5-mop is an attempt to implement a subtract of
[Moose](http://moose.iinteractive.com/) into the core of Perl. Moose provides a
Meta Object Protocol to Perl. So does p5-mop, however p5-mop is implemented in
a way that it can be properly included in the Perl core.

As far as I understood, after trying to hack directly in the core, Stevan
Little restarted the p5-mop implementation ( the so called p5-mop-redux github
project), using [Devel::Declare](https://metacpan.org/module/Devel::Declare), (
then [Parse::Keyword](https://metacpan.org/module/Parse::Keyword) ), so that he
can experiment and release often, while keeping the implementation
core-friendly. Once he's happy with the features and all, he'll make sure it
finds its way to the core.

A small team (Steven Little, Jesse Luers) is actively developping p5-mop, and moreover he's blogging about it.
Few months ago I tried to use it. More precisely, as soon as p5-mop-redux was
announced, I tried to give it a go. And you should too ! Here is why.


## install it ##

p5-mop is very easy to install:
1. if you're using github, just fork the p5-mop-redux project. Otherwise get
   the tarball here.
2. use cpanm

The syntax somewhat similar to the Mo* modules.

## attributes ##

Creating an attribute is done like this:

has foo;

## traits ##

After the attribute name, you can add 'is', which is followed by a list of 'traits':

has foo is ro, lazy = 'default value';

* ro/rw means it's read-only / read-write
* lazy means the attribute constructor won't be 

## types ##

I haven't really played with types, but

## default value / constructor ##

has foo = 'default value';

which is actually

has foo = sub { 'default value' };

So, there is no default value, only constructors. Meaning that

has foo = {};

will work properly ( creating a new hashref each time )

There has been some comments about using '=' instead of // or || or 'default',
but this syntax is used in a lot of other programing language, and considered
somehow the default (hehe) syntax. I think it's worth sticking with '=' for an
easier learning curve for newcomers.

## getter / setter ##

they are

## methods ##

use the word 'method'

method append {
  $self
}

## clearer / predicate ##

Because the constructor is already implemented using '=', what about clearer
and predicate?

clearer:
method clear_foo { undef $foo }

predicate:
method has_foo { defined $foo }



## meta ##

Going meta is not difficult either but I won't describe it here, as I just want
to showcase default OO programming syntax. On that note, it looks like Stevan
will make classes immutable by default, unless specified. I think that this is
a good idea (how many time have you written make_immutable ?).

# my humble consructive remarks #

* undef versus not set: In Moose there is a difference between an attribute
  being unset, and an attribute being undef. I likes 

* sometimes $self doesn't work
* modifiers
  around foo
  method foo is modifier(around)
  method foo is around
* ${^NEXT} : not very nice
* ${^SELF}
* modifiers in roles
* 'is' ? why use has + is ? isn't one verb enough ? in Moo*, the 'is' was just
  one property. we had default, lazy, etc. Now, 'is' is just a seperator
  between the name and the 'traits'



