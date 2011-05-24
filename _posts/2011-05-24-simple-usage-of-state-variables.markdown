---
title: Simple usage of Perl state variables
---

# {{ page.title }}

I see this type of code too often:

{% highlight perl %}
package Foo;
{
  my $structure = {};
  sub plop {
      #...
      $structure->{$foo} = 'bar';
      #...
  }
}
{% endhighlight %}

Or things like that:

{% highlight perl %}
package Foo;
{
  my $cache;
  sub plop {
      #...
      defined $cache or $cache = _load_cache();
      #...
  }
}
{% endhighlight %}

If you are using a non-ancient version of Perl (that is, 5.10 or more), you should consider using the `state` keyword. It's similar to the static variables inherited from C.

From the [documentation](http://perldoc.perl.org/functions/state.html) :
> `state` declares a lexically scoped variable, just like `my` does. However, those
> variables will never be reinitialized, contrary to lexical variables that are
> reinitialized each time their enclosing block is entered.

So the two code snippets become :

{% highlight perl %}
package Foo;
sub plop {
    state $structure = {};
    $structure->{$foo} = 'bar';
    #...
}
{% endhighlight %}

and:

{% highlight perl %}
package Foo;
sub plop {
    #...
    state $cache = _load_cache();
    #...
}
{% endhighlight %}

Nothing terribly amazing here, but it's really easy, saves keystrokes and makes
the code more readable. So why not use it more widely ?
