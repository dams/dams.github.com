---
layout: post
title: "Dancer::Exception"
---

# {{ page.title }}

##Introducing a new concept in Dancer : the Dancer Exception.

This post is about a new stuff I've added in [Dancer](http://perldancer.org),
`Dancer::Exception`.

The concept is simple: in Dancer, sometimes things get wrong, and an exception
is raised. Until now, Dancer was using `croak`. That's not bad, but when trying
to catch an exception, it's not trivial to programatically know if it was
raised by Dancer's code, or the web application's code, or some other module
used. `Dancer::Exception` fixes this : all exceptions raised in Dancer's code
will be `Dancer::Exception`s. It's also possible for the developer of the web
application to create and raise their own `Dancer::Exception`.

## Enter Dancer::Exception

These are called internal Dancer's exceptions.

So a Dancer::Exception is an exception that can be raised, and caught later on.
There are two types of exceptions : internal ones (raised and caught by Dancer
code), and custom exceptions, that can be registered, then raised and caught.


As a bonus feature, Dancer::Exception allows Dancer users to create their own
Dancer exceptions. They are called *custom* Dancer exceptions. When using them,
it is then possible to make the distinction between an exception coming from
the core code of Dancer, or from the code of the web application, or from
something else (likely a module used in the code).

## Raising an exception

That's done easily:

{% highlight perl %}
use Dancer::Exception qw(:all);

raise E_SOME_ERROR;
{% endhighlight %}

Want to know the full list of exception names ?

{% highlight perl %}
my @names = list_exceptions;
{% endhighlight %}

## Catching an exception

Catching a dancer exception is actually the same as catching any Perl
exception, so using `eval { ... };` or any wrapper (like `Try::Tiny` from the
CPAN). Then `Dancer::Exception` provides a function to test if the exception is
a Dancer exception, or a normal standard Perl exception.

{% highlight perl %}

eval { ... };
if ( my $value = is_dancer_exception(my $exception = $@) ) {
  # it's a Dancer::Exception
  if ($value == ( E_HALTED ) ) {
      # it's a halt exception...
  }
} elsif (defined $exception) {
  # do something with $exception (don't use $@ as it may have been reset)
}
{% endhighlight %}

You can also directly test if the exception is a Dancer internal exception, or
a custom one :

{% highlight perl %}

if ( my $value = is_dancer_exception(my $exception = $@, type => 'custom') ) {
  # it's a Dancer::Exception internal exception (use 'internal' to test for
  # internal ones )
}

{% endhighlight %}

## Dancer::Exception is not Dancer::Error

In Dancer, there is the concept of `Dancer::Error`. This can be seen roughly as
a object representation of an HTTP error. You can forge a Dancer::Error by
hand, but most of the time it is automatically created because an exception was
not caught before, thus Dancer creates a Dancer::Error to be displayed (or
processed by the web application code).

But once a `Dancer::Error` is generated, the Dancer workflow is almost at its
end. It's possible for the Dancer user to add hooks to be executed before or
after a `Dancer::Error` generation, but it's not handy for catching errors, and
rewind Dancer's workflow.

Now we have a real **Exception** concept, and they are easy to catch and decide
what to do.

## Numbers of exceptions

There is a limited number of exceptions : 16 internal exceptions, and 16 slots
for custom exceptions.

Why a limited numbers of exceptions ? That is so they can be implemented as
integers of the form of 2**n, with n from 0 to 31. That way they can be mixed
and compared using `&` and `|`, but the implementation can still be very light and
fast. If you need more exceptions, feel free to use other exception systems from
the CPAN for instance.

`Dancer::Exceptions` can be merged and tested by using this kind of code :

{% highlight perl %}

# raise a ( FOO and BAR ) exception
eval { raise E_FOO | E_BAR };
if ( my $value = is_dancer_exception(my $exception = $@) ) {
    if ($value == ( E_HALTED & E_FOO ) ) {
        # it's a (HALT and FOO) exception
    }
}
{% endhighlight %}
