---
layout: post
title: "Dancer::Exception"
---

# {{ page.title }}

##Introducing a new concept in Dancer : the Dancer Exception.

This post is about a new stuff I've added in [Dancer](http://perldancer.org), `Dancer::Exception`

Some people like to use exceptions to halt a process. Some people even like to
use exceptions to alter the workflow of their programs. This way of doing is
not always recommended, but it can be useful in some situations.

## Current behaviour

In Dancer, there is the concept of `Dancer::Error`. This can be seen roughly as
a object representation of an HTTP error. You can forge a Dancer::Error by
hand, but most of the time it is automatically created because `die` (or
`croak`) was issued anywhere in your Dancer app.

There is also the keyword `halt` from Dancer DSL (Domain Specific Language).
This function stops the current Dancer workflow, and renders the current
response.

Now we have a real **Exception** concept.

## Enter Dancer::Exception

So a Dancer::Exception is an exception that can be raised, and caught later on.
There are two types of exceptions : internal ones (raised and caught by Dancer
code), and custom exceptions, that can be registered, then raised and caught.
Dancer::Exceptions can be actually merged and tested, like that :

{% highlight perl %}
E_HALTED | E_CUSTOM | E_GENERIC
{% endhighlight %}

There is a limited number of exceptions : 16 internal exceptions, and 16 slots
for custom exceptions.

Why a limited numbers of exceptions ? That is so they can be implemented as
integers of the form of 2**n, with n from 0 to 31. That way they can be mixed
and compared using `&` and `|`, but the implementation can still be very light and
fast. If you need more exceptions, feel free to use other exception systems from
the CPAN for instance.

## raising an exception

That's done easily:

{% highlight perl %}
use Dancer::Exception qw(:all);

raise E_SOME_ERROR;
{% endhighlight %}

Want to know the full list of exception names ?

{% highlight perl %}
my @names = list_exceptions;
{% endhighlight %}

## catching an exception

Catching a dancer exception is actually the same as catching any Perl
exception, so using `eval { ... };` or any wrapper (like `Try::Tiny` from the
CPAN). Then `Dancer::Exception` provides a function to test if the exception is
a Dancer exception, or a normal standard Perl exception.

{% highlight perl %}

eval { ... };
if ( my $value = is_dancer_exception(my $exception = $@) ) {
  # it's a Dancer::Exception
  if ($value == ( E_HALTED | E_FOO ) ) {
      # it's a halt or foo exception...
  }
} elsif (defined $exception) {
  # do something with $exception (don't use $@ as it may have been reset)
}
{% endhighlight %}

