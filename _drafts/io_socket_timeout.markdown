---
layout: post
title: "IO::Socket::Timeout: socket timeout made easy"
---

# {{ page.title }}

## TL;DR ##

use `IO::Socket::Timeout` to add read/write timeouts to any net socket you've created with
`IO::Socket::INET`, on any platform:

{% highlight perl %}
  # 1. creates a socket as usual
  my $socket = IO::Socket::INET->new( ... );
  
  # 2. enable read and write timeouts on the socket
  IO::Socket::Timeout->enable_timeouts_on($socket);
  
  # 3. setup the timeouts
  $socket->read_timeout(0.5);
  $socket->write_timeout(0.5);
  
  # 4. use the socket as usual
  $socket->...
  
  # 5. Profit!
{% endhighlight %}

Yes, it works with any INET socket. Yes, it should work on any platform (see
below). Yes, it inflates `$socket` with new methods on the fly. See
[IO::Socket::Timeout on metacpan](https://metacpan.org/pod/IO::Socket::Timeout).

## Intro ##

It's been a long time since last time I blogged, more than one year. That was
for various reasons, one of them being that I changed job to work at
Booking.com (awesome company) roughly at that time. Anyway, I'll try to catch
up with things I've been working on, so expect some more blog posts soon.

The `IO::Socket::Timeout` idea came from a recurrent requirement. I was then
working on `Bloomd::Client` (see blog post here), `Redis` (see blog post here),
and `Riak::Light`, which are basically client library to ease the communication
with dedicated servers (namely bloomd, Redis and Riak). Such client libraries
need to be easy to use, and provide useful features, especially regarding
handling errors and issues. Indeed these libraries are going to be used in code
that need to be performant, and realize very quickly that something goes wrong.
If business code needs to get critical information from a Redis server, and it
takes 30 seconds to realize that the server has gone MIA, it's not good. So
basically, these kind of client libraries need to provide an easy way to
specify *timeouts*.

## Connection timeout ##

`IO::Socket` provides a `timeout` method, and `IO::Socket::INET` provides a
`Timeout` option. This is already a good step, this `Timeout` option can be
used to set a tomeout on the connection to the server. For example, this is how
to connect to a local http server on port 80, with a connection timeout of 3
seconds:

{% highlight perl %}
  my $socket = IO::Socket::INET->new(
    PeerHost  => '127.0.0.1',
    PeerPort  => 80,
    Timeout   => 3,
);
{% endhighlight %}

So far so good. Now what about read or write timeouts. What if the server
accepts connection, but then at some point the server stops communicating ? the
client socket needs to realize that soon enough, and acknowledge that there is
an issue. For that, we need read and write timeouts.

## Read/Write timeouts via setsockopt ##

It is relatively easy to change the option of a socket to change its read and
write timeouts. This is an example that works on linux, given `$timeout:` in
(possibly fractional) seconds:

{% highlight perl %}
  my $seconds = int( $timeout );
  my $useconds = int( 1_000_000 * ($timeout-$seconds) );
  my $t = pack( 'l!l!', $seconds, $useconds );
  $socket->setsockopt(SOL_SOCKET, SO_RCVTIMEO, $t)
  # then use $socket as usual
{% endhighlight %}

It is simple enough, but it works only on some architecture/OS. As I wanted a
generic solution, I had to look at a different solutions, for systems that
couldn't use `setsockopt`.

## Read/Write timeouts via select ##

An other and more portable (although slower) way to simulate a timeout on a
socket, is to check if the socket is readable/writable, with a timeout, in a
non blocking way. `socket(2)` can do that, and the Perl `socket()` function
gives access to it. Here is a simplified version of a function that returns
true if we can read on the socket with the given timeout:

{% highlight perl %}
  sub _can_read {
    my ($file_desc, $timeout) = @_;
    vec(my $fdset = '', $file_desc, 1) = 1;
    $nfound = select($fdset, undef, undef, $timeout);
}
{% endhighlight %}

## Provide a nice API ##

Let's step back for a moment. We now have two ways to setup a timeout on a
socket:

  - the `setsocket` way, which is a one time setting on the socket
  - the `select` way, which implies changing the way we interact with the
    socket

What I wanted to achieve, is to abstract these two ways of setting timeouts,
behind a simple and easy to use API. Let's consider this example:

{% highlight perl %}
  my $socket = IO::Socket::INET->new( ... );
  print $socket "something";
{% endhighlight %}

You'll note that I have not used object oriented notations on the socket (like
`$socket->print("something")`) on purpose.

What we want is an easiest way to be able to set timeout to the `$socket`. For
example this:

{% highlight perl %}
  my $socket = IO::Socket::INET->new( ... );

  # set timeouts
  $socket->read_timeout(0.5);

  # use the socket as before
  print $socket "something";

  # later, get the timeout value
  my $timeout = $socket->read_timeout();

{% endhighlight %}

### when using setsockopt

If we can use `setsockopt`, then setting the timeout using
`->read_timeout(0.5)` is easy, it can be implemented as a method that we add to
`IO::Socket::INET` class. Probably by using a Role (we'll see that later). This
method would just fire `setsockopt` with the right parameters, and save the
timeout value into $socket for later retrieval. Then we can carry on using
`$socket` as before.

There is actually a subtlety because the `$socket` is not a classic HashRef
instance, but an anonymous typeglob on a HashRef, so instead of doing
`$socket->{ReadTimeout} = 0.5` we need to do `${*$socket}{ReadTimeout} = 0.5`.
But that's an implementation detail.

### when using select

However, if we need to use the `select` method, then we have a problem. Because
we're not using object oriented programming, operation on the socket is not
done via a method, that we could easily override, but directly using the
builtin function `print`. Overwriting a core function is not a good practise,
for various reasons. Luckily, Perl provides a clean way to implement custom
behaviour in the IO layer.

## PerlIO layers ##

Perl intput/output mechanism is based on a layers system. It is documented in
the perliol(1) man page.

What is the PerlIO API? It's a stack of layers, that live between the system and
the perl generic filehandle API. Perl provides core layers (some of them
`:unix`, `:perlio`, `:stdio`, `:crlf`). It also provides extension layers, like
`:encoding`, or `:via`. Layers can be stacked and removed, to basically provide
more features (when layers are added), or more performance (when layers are
removed).

The huge benefit is that whatever layers is setup on a file handle or a socket,
the API doesn't change, and read/write operations are the same, calls to them
will go through the specified layers attached to the handle, until they
potentially reach the system calls. Here is an example:

{% highlight perl %}
  open(my $fh, 'filename');
  # for direct binary non-buffered access
  binmode($fh, ':raw');
  # specify that the file is in utf8, and enforce validation
  binmode($fh, ':encoding(UTF-8)'); 
{% endhighlight %}

The `:via` layer is a special layer that allows anyone to implement a PerlIO
layer in pure Perl. Contrary to implementing a PerlIO layer in C, using the
`:via` layer is rather easy: it is just a Perl class, with some specific
methods. The name of the class is given when setting the layer:

{% highlight perl %}
  binmode($fh, ':via(MyOwnLayer)');
{% endhighlight %}

Many `:via` layers already exist, they all start with `PerlIO::via::` and are
available on CPAN. For instance, `PerlIO::via::json` will automatically and
transparently decode and encode the content of a file or a socket from/to JSON.

So, back to the problem: the idea is to implement a `:via` layer that makes
sure that read and write operations on the underlying handle are performed
within the given timeout. Let's see how to do that.

## Implementing a timeout PerlIO layer ##

A `:via` layer is a class that should start with `PerlIO::via::` and implement
a set of methods, like `READ`, `WRITE`, `PUSHED`, `POPPED` (see the
PerlIO::via(3) man page for more details). I'll show here only the `READ`
method as an illustration. This is a very simplified version. The real version
handles things like `EINTR` and other corner cases.

{% highlight perl %}
  package PerlIO::via::Timeout;
  sub READ {
      my ($self, $buf, $len, $fh) = @_;
      my $fd = fileno($fh);
      # we use the same can_read as previously
      can_read($fd, $timeout)
      or return 0;
      return sysread($fh, $buf, $len, 0);
  }
{% endhighlight %}

The idea is to check if we can read on the filesystem using `select`, in the
given allowed timeout. If not, return 0. If yes, call the normal sysread
operation. It's simple and it works great. We've justimplemented a new PerlIO
layer using the `:via` mechanism ! A perlIO works on any handle, including file
an socket, so let's try to use it on a filehandle:

{% highlight perl %}
  use PerlIO::via::Timeout;
  open my $fh, '<:via(Timeout)', 'foo.html';
  my $line = <$fh>;
  if ($line == undef && 0+$! == ETIMEDOUT) {
    # timed out reading
    ...
  } else {
    # we read one line fast enough, success!
    ...
  }
}
{% endhighlight %}

You can see that there is an issue in this code: at no point do we *set* the
read timeout value. The `:via` pseudo layer doesn't allow to easily pass a
parameter to the layer creation. Actually, it is possible, but then the
parameter can't be changed afterward. If we want to be able to set, change,
remove the timeout on the handle at any time, we need to somehow *attach*
this information to the handle, and be able to change it.

## Add a properties to a Handle unsing InsideOut OO ##

A handle is not an object. So we cannot just add a new timeout attribute to a
handle, and set/get it.

Luckily, during the time that a handle is opened, it has a unique id: its
file descriptor. A file descriptor is not unique all the time, as they are
rcycled and reused, but if we can be warned when a handle is opened and closed,
we can be sure that between these actions, a given file descriptor uniquely
identifies a handle. The `:via` PerlIO layer allows to implement `PUSHED`, `POPPED`
and `CLOSE`, functions that are called when the layer is added to the handle,
when it's removed, and when the handle is closed. So These function can be used
to know if and when to consider the file descriptor as a unique id for the
given handle.

So let's create a hash table as a class attribute of our new layer, where keys
will be file descriptors, and values a set of properties on the associated
handle. That is essentially the basic way to implement InsideOut OO, with the
object not being its data structure, but only an id. With this hash table, we
can associate a set of properties to a file descriptor, and set the timeout
value when the PerlIO layer is added:

{% highlight perl %}
  my %fd_properties;
  
  sub PUSHED {
    my ($class, $mode, $fh) = @_;
    $fd_properties{fileno($fh)} = { read_timeout => 0.5 };
    # ...
  }
{% endhighlight %}

By doing the same thing at removal of the layer, we have now implemented a way
to associate the timeout values to the filehandle.

Wrapping up all the bits of code and features, the full package that implements
this timeout layer is `PerlIO::via::Timeout`, available on github and CPAN.

## Implement the API ##

So now we have all the ingredients we need to implement the desired behaviours.
`enable_timeouts_on` will receive the socket, and modify its class (it should
be or inherit from `IO::Socket::INET`) to implement these methods:

* `read_timeout`: get/set the read timeout
* `write_timeout`: get/set the write timeout
* `disable_timeout`: switch off timeouts (but till remember their values)
* `enable_timeout`: switch back on the timeouts
* `timeout_enabled`: returns wether the timeouts are enabled

However, we want to modify the `IO::Socket::INET` class in a clean way. For
that, we'll create a role and apply it to the class. Actually we'll create two
roles, one that will implement the various methods the `setsockopt` way, and an
other role using the `select` (so with the `PerlIO::via`) way.

Detailing the implementation of the role mechanism here is a bit out of the
scope, but it's still interesting to note that to keep
`IO::Socket::Timeout`lightweight, we didn't use `Moose::Role`, nor `Moo::Role`,
but basically applied a stripped down variant of `Role::Tiny`, which uses
single inheritance of a special class crafted in real time specificaly for the
targeted class. The code is short and can be seen here
https://github.com/dams/io-socket-timeout/blob/master/lib/IO/Socket/Timeout.pm#L187

## Wrapp it up



