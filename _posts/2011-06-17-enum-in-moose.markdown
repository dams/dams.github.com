---
layout: post
title: Moose and enum
---

# {{ page.title }}

At $work, we are using Moose a lot. So I spend a lot of time declaring
attributes, and some of them are Strings that should be picked from a fixed
list of values.

For instance, I need to be able to define a `task` that can be only one of `'profit'`, `'world_domination'`. And use it like so:

{% highlight perl %}
# works fine
$attribute->task('profit');

# fails
$attribute->task('failure');
{% endhighlight %}

So basically, the attribute is an `enum`.

## The painful way

Until now, I was defining a new subtype for each `enum` I needed. Something like:

{% highlight perl %}
# type definition
use Moose::Util::TypeConstraints;
subtype 'My:Type:Task' => as 'Str' =>
  where { my $r = join( '|', __PACKAGE__->get_possible_tasks ); /^(?:$r)$/ };
coerce 'My:Type:Task' => from 'Str' => via {lc};
sub get_possible_tasks {qw(profit world_domination)}

# attribute declaration
has task => ( isa => 'My:Type:Task' );
{% endhighlight %}

It's very verbose, painful and not readable, isn't it ?

## The right way

`Moose::Util::TypeConstraints` provides the `enum` method, that serves exactly
our purpose. It's basically a shortcut to create a subtype based on 'Str',
limited to a list of possible values. You can use it to build a *named* enum
subtype, or an *anonymous* subtype. See the usage in our case :

{% highlight perl %}
# using a named enum subtype:
use Moose::Util::TypeConstraints;
enum 'My:Enum:Task', [qw(profit world_domination)];
has task => ( isa => 'My:Enum:Task' );

# using an anonymous enum subtype:
use Moose::Util::TypeConstraints;
has task => ( isa => enum([qw(profit world_domination)]) );
{% endhighlight %}

So that's all, I guess this kind of feature is nothing new for seasoned Moose
developers, but it may help beginners, as there is no mention of `enum` in
`Moose::Manual::Attributes`.

