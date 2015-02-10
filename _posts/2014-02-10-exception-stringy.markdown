---
layout: post
title: Exception::Stringy - Modern exceptions for legacy code
---

# {{ page.title }}

# A small recap of Perl exceptions

## Basic Usage Of Exceptions

In Perl, exceptions are a well known and widely used mechanism. It is an old
feature that has been enhanced over time. At the basic level, exceptions are
triggered by the keyword `die`. Exceptions were initially used as a way to stop
the execution of a program in case of a fatal error. The too famous line:

{% highlight perl %}
    open my $fh, $file or die "failed to open '$file', error: $!";
{% endhighlight %}

is a good example. 

The original way to catch exceptions in Perl has a somewhat strange syntax,
it's based on the `eval` keyword and the special variable `$@`:

{% highlight perl %}
    eval { code_that_may_die(); 1; }
      or say "exception has been caught: $@"
{% endhighlight %}

Nowadays, exceptions are usually thrown using `croak` and friends, from the
[`Carp`][carp] module. It allows for a much better flexibility about where the exception
seems to originate, and how to display the stack trace, if any.

Catching exceptions with `eval` is also supersed by try/catch mechanisms. The
most used one is via the [`Try::Tiny`][try-tiny] module by Yuval Kogman and Jesse Luehrs,
and goes like this:

{% highlight perl %}
    try {
      croak "exception";
    } catch {
      warn "caught error: $_";
    };
{% endhighlight %}

## Throwing Objects

The good thing about `die` (or `croak`), is that it's very easy to use, when
given a string. It's perfect for using in scripts, or moderately big
projects. However, for more features, or extensive usage of exceptions, then
it's better to throw objects instead of strings, like this:

{% highlight perl %}
    open $file or die MyExceptions::IO::File->new(
      filename => $file,
      error => $!
    );
{% endhighlight %}

For this snippet of code to work, the `MyExceptions::IO::File` class has to be
declared, its fields as well, and the it should probably inherit from
`MyExceptions::IO`. So it requires some amount of work.

Some modules have been created - long time ago - to automate or help with
declaring exception classes. The most well known one is [`Exception::Class`][exception-class], by
Dave Rolsky. For instance, here is how to declare two exceptions matching with
previous example:

{% highlight perl %}
    package MyExceptions;

    use Exception::Class (
        'MyException::IO',
        'MyException::IO::File' => {
            isa => 'MyException::IO',    
            fields => [ 'filename' ],
        },
    );
{% endhighlight %}

And then, here is the code to make use of that and throw an exception when
failing to open a file:

{% highlight perl %}
    use MyExceptions;

    open $file or MyException::IO::File->throw(
      filename => $file,
      error => $!
    );
{% endhighlight %}


## Catching Objects Exceptions

When using objects as exceptions, a set of features becomes available, thanks
to Object Oriented Programming. Inheritance, attributes and introspection are
some of them. However the most visible and used feature is about catching such
exceptions:

{% highlight perl %}
    use MyException;

    try {
        open $file or MyException::IO::File->throw(
          filename => $file,
          error => $!
        );
    } catch {
        my $exception = $_;
        if ($exception->isa(MyException::IO)) {
            # we know how to handle these
        } else {
            $exception->rethrow
        }
    };
{% endhighlight %}

As you can see, it's easy to introspect an exception if it's an object. In this
case we use the `isa` keyword to know if the exception is or inherits from a
given class name.

# When things go wrong


## Mixing Objects And String Exceptions

As we saw in the previous chapter, Perl allows exceptions being whatever you
like (string, objects, but actually numbers, structures, etc, work as well).

Usually, when starting a project, the author decides whether to use simple
strings or objects with a class hierarchy. With very big projects, it is
sometimes not possible to impose one kind of exceptions. This may be due to
legacy code, a subproject that was included, or the wish to give people freedom
about what they want to use depending on the context.

In these cases, the code may have to handle exceptions of two kinds: strings
and objects. This can be done via this kind of code:

{% highlight perl %}
    use MyException;
    use Scalar::Util qw(blessed);

    try {
        # ... code that may die
    } catch {
        my $exception = $_;
        if (blessed $exception) {
            # exception is an object
            # ...
        } else {
            # exception is a normal string
            # ...
        }
    };
{% endhighlight %}

## Mixed Exceptions Issues

The previous code snippet suffers from increased complexity due to the
additional checks and two different codepaths for handling potential errors.
This is clearly both suboptimal and error prone.

Another issue is that some code may consider that the exception it is catching
is of one type, whereas it could be of an other type, especially because of the
action-at-distance nature of the exception. Consider this function:

{% highlight perl %}
    sub do_stuff {
        try {
            # ... code that can only throw objects exceptions
        } catch {
            my $exception = $_;
            # exception is always an object
            if ($exception->isa(...)) {
                # ...
            }
        };
    }
{% endhighlight %}

This code assumes that the exception will always be an object. However,
let's consider this: in following example, the function `do_stuff` is called
(its original code is unchanged), but before doing so, the special signal
handler for `__DIE__` is changed.

{% highlight perl %}
    $SIG{__DIE__} = sub { die "FATAL: $_[0]" };
    do_stuff();
{% endhighlight %}

The first line of the example is being called when an exception is raised, and
will be executed instead of propagating the exception. What this code does is
prepending `FATAL: `to it, then propagate the exception again by using `die`.

Alas, it is doing so in a naive way, by forcing the exception (in `$_[0]`) to be
evaluated as a string. So when the exception is then re-thrown, it is now a
string ! and Boom, the `->isa` call in `do_stuff` won't work.

The worst thing about this kind of issue is that it doesn't appear at compile
time, nor at execution time, but at *exception time*, which is the worst
time...


## The Overloaded Stringification Route

So at that point, most developers will choose the following strategy. Use
object exceptions for their code, but guard against receiving string exceptions,
and also make their object exceptions nicely degrade into strings, by using
stringification overloading. That means that if an object exception is managed
by a handler that threats it as a string, the exception will transform itself
into a string, and try to present some meaningful aspect of itself.

The issue is that handling exception is now back to square one, having to deal
with strings, trying to parse it looking for meaningful information to
hopefully make a good decision.

What if, instead of taking an object exception and **downgrading it to a
string** while keeping as much information as possible, one **starts from a
string, and enhance it until it looks like an object**, without being one ? That
way we would have the best of both worlds

This is what `Exception::Stringy` tries to achieve.


# Exceptions::Stringy from scratch

## The Needed Features

A perfect exception would have these features:

* be a string, containing an error message
* be an instance of a class
* be able to inherit from an other exception
* have simple fields with values
* provide a way to introspect itself

This set of features is not big, but it's probably enough for a start. Let's
see how we can implement them in a simple string. We're going to use an
exception with these attributes:

* an error message 'permission denied'
* from the class MyException::IO
* which inherits from MyException
* with a field `filename`

## Class Instance

Let's start with the first feature: *be a string, containing an error message*.
That's easy:

{% highlight perl %}
    "permission denied"
{% endhighlight %}

Being an instance of a class is usually done in Perl by using `bless` on a
ScalarRef. But we don't want the eception to be an object. What `bless` does -
and what it ultimately means to "be an instance of a class", is just attaching
a *label* to a value. Let's do that, by having a label as a substring in our
exception. For instance:

{% highlight perl %}
    "[MyException::IO]permission denied"
{% endhighlight %}

We could add a magic mark or have a more complex label syntax to make sure it's
a legit label.

To know what the class of a given exception is, we just need to extract the
label, for instance with a regex.

## Class Inheritance

Inheritance is easy, it only requires that standard Perl classes be created to
map the exception labels, and then Perl usual inheritance can be used.

So, following our example, we need two packages, `MyException` and
`MyException::IO`, and `@MyException::IO::ISA` set to `['MyException']`. This can
be made automatically at exception declaration time.

## Fields

For simplicity, `Exception::Stringy` only handles simple field values, that is
strings and numbers basically. To put fields into our string, we need to be
able to identify them, so for instance with a separator between the different
fields, and an other one between a field name and its value. Like this:

{% highlight perl %}
    "[MyException::IO|filename:/tmp/file|]permission denied"
{% endhighlight %}

And if the field name or value contains one of the separators ( `[`, `|`, `:`
or `]`), let's encode them in base64, and mark it as such.

So, by now, we have fleshed out a string with useful data, which is properly
parseable, and can be described. Let's add methods to the data now.

## Introspection and Modification

Given an exception, it is mandatory to be able to introspect and modify it, namely be able to:

* get/set the class of the exception,
* get/set the fields values attached to the exception,
* get/set the exception message,
* other useful methods.

In an ideal world, we would want methods, that we can call on our exception
instances. However because our exceptions are regular strings, we can't do
this:

{% highlight perl %}
    $exception->message();
{% endhighlight %}

Usually, this way of calling a method (the arrow notation) works only if
$exception is a blessed reference (that is, an object). However, there are
other cases in which we can use the arrow notation, and have it work in a
similar way. One of it is this one:

{% highlight perl %}
    $exception->$message();
{% endhighlight %}

If $message is a variable that contains a reference on a subroutine, then the previous line will translate into:

{% highlight perl %}
    $message->($exception);
{% endhighlight %}

And it works whatever the type of `$exception`, like in our case, a string. So,
`Exception::Stringy` creates the needed subroutine references for the user and
allow such arrow notation, which is very similar to the OO method invocation. I
call these **pseudo methods**.

However, to avoid clobbering an existing variable, the pseudo methods need to
have names that are unlikely to be already used in the target package. It's
even better if there is an option to add a prefix to these pseudo-methods.
Once again, `Exception::Stringy` provides these features. The default pseudo
method names are :

{% highlight perl %}
    $exception->$xthrow()
    $exception->$xrethrow()
    $exception->$xraise()
    $exception->$xclass()
    $exception->$xisa()
    $exception->$xfields()
    $exception->$xfield()
    $exception->$xmessage()
    $exception->$xerror()
{% endhighlight %}

## Launching The Exception

Finally, once we have created the exception, let's throw it. The first think to
do is to implement a `throw`or `raise class method on all the exception class,
so that we can do

{% highlight perl %}
    MyException->throw(...)
{% endhighlight %}

That will basically craft a new exception string, with all the properties
encoded in it, and call `die` or `croak` on it.

We can also use a **pseudo method** on an existing exception to (re)throw it:

{% highlight perl %}
    $exception->$xthrow();
{% endhighlight %}

# Exceptions::Stringy example

## Synopsis

Below is the synopsis of the `Exceptions::Stringy` module. It's basically a
wrap up of what has been explained above. The exceptions definition is heavily
inspired from `Exception::Class`.

{% highlight perl %}
    use Exception::Stringy;
    Exception::Stringy->declare_exceptions(
        'MyException',
     
        'YetAnotherException' => {
            isa         => 'AnotherException',
        },
     
        'ExceptionWithFields' => {
            isa    => 'YetAnotherException',
            fields => [ 'grandiosity', 'quixotic' ],
            throw_alias  => 'throw_fields',
        },
    );
    
    ### with Try::Tiny
    
    use Try::Tiny;
     
    try {
        # throw an exception
        MyException->throw('I feel funny.');
    
        # or use an alias
        throw_fields 'Error message', grandiosity => 1;
  
        # or with fields
        ExceptionWithFields->throw('I feel funny.',
                                   quixotic => 1,
                                   grandiosity => 2);
  
        # you can build exception step by step
        my $e = ExceptionWithFields->new("The error message");
        $e->$xfield(quixotic => "some_value");
        $e->$xthrow();
    
    }
    catch {
        if ( $_->$xisa('Exception::Stringy') ) {
            warn $_->$xerror, "\n";
        }
    
        if ( $_->$xisa('ExceptionWithFields') ) {
            if ( $_->$xfield('quixotic') ) {
                handle_quixotic_exception();
            }
            else {
                handle_non_quixotic_exception();
            }
        }
        else {
            $_->$xrethrow;
        }
    };
   
    ### without Try::Tiny
   
    eval {
        # ...
        MyException->throw('I feel funny.');
        1;
    } or do {
        my $e = $@;
        # .. same as above with $e instead of $_
    }
{% endhighlight %}


# Conclusion

This was an in-depth look at why and how to build up a resilient and
non-intrusive exception mecanism. I hope to have demonstrated one aspect of the
extreme flexibility of Perl.

Feel free to use `Exception::Stringy`, it is being used in production code for
some time now. Feedback welcome !

# Links

[Exception::Stringy]: https://metacpan.org/pod/Exception::Stringy
[carp]: https://metacpan.org/pod/Carp
[try::tiny]: https://metacpan.org/pod/Try::Tiny
[Exception::Class]: https://metacpan.org/pod/Exception::Class

