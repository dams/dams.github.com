---
layout: post
title: Moose trick with MooseX-Getopt and roles
published: true
---

# {{ page.title }}

<p class="meta"> 18 May 2011 - Paris</p>

On MooseX::Getopt
=================

At work I extensively use Moose in my everyday Perl coding. I also use
[MooseX::Getopt](http://search.cpan.org/perldoc?MooseX::Getopt) to
automatically handle command line arguments as attributes, thus simplifying the
implementation of scripts.

By default, MooseX::Getopt consider all public attributes to be mapped on a
command line argument. There are many ways to tell MooseX::Getopt to ignore a
public attribute:
* you can turn your attribut to a private one, but with public accessors
* you can have the attribute use [MooseX::Getopt::Meta::Attribute::Trait::NoGetopt](http://search.cpan.org/perldoc?MooseX::Getopt::Meta::Attribute::Trait::NoGetopt)
* you can have the attribute use the [MooseX::Getopt::Meta::Attribute::NoGetopt](http://search.cpan.org/perldoc?MooseX::Getopt::Meta::Attribute::NoGetopt)

Act on distant attributes
=========================

The previous actions are to be performed on the attribute definition. But what about
the situations where you don't write the attribute definition yourself ? Like,
for instance, if you inherits the attributes from an other class, or if you got
the attributes by consuming a role ?

In this case, you'll need to perform an action on the attribute **from a
distance**. Here are two solutions, that were given to me by the nice folks on
\#moose (namely *sartak* and *doy*)

Apply the trait from a distance
-------------------------------

The first solution is to run this code after having consumed a role, or inherited a class, that provides the attribute 'some_attr':

{% highlight perl %}
   MooseX::Getopt::Meta::Attribute::Trait::NoGetopt->apply(
       __PACKAGE__->meta->get_attribute('some_attr')
   );
{% endhighlight %}

Adds the trait to the attribute definition
------------------------------------------

A syntactically simpler solution is to add the trait in the attribute, in our class:

{% highlight perl %}
    has '+some_attr' => (traits => ['NoGetopt'])
{% endhighlight %}

The '+' character allows to add things to an already defined attribute, instead
of trying to overwrite its definition altogether.

