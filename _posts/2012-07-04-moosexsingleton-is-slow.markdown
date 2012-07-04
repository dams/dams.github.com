---
layout: post
title: "MooseX::Singleton is slow"
---

# {{ page.title }}

Just a quick note : if you plan to use
[MooseX::Singleton](https://metacpan.org/module/MooseX::Singleton), beware ! It
is easy to use and it implements properly what it claims, however it is quite
slow.

If my profilings are corrects, each call to `->instance()` calls `meta()`,
`get_metaclass_by_name()` one time, and `blessed()` two times.

So for now I'll avoid it and implement a simplified version using something
similar to this :

{% highlight perl %}

use Moose;

my $singleton;

sub instance {
    return $singleton //= $CLASS->new();
}

# to protect against people using new() instead of instance()
around 'new' => sub {
    my $orig = shift;
    my $self = shift;
    return $singleton //= $self->$orig(@_);
};

sub initialize {
    defined $singleton
      and croak __PACKAGE__ . ' singleton has already been instanciated'; 
    shift;
    return __PACKAGE__->new(@_);
}
{% endhighlight %}

dams.
