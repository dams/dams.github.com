---
layout: post
title: "MooX::LvalueAttribute - improved"
---

# {{ page.title }}

![New and Improved!](/images/val_approuve.png "I borrowed the image from @yenzie -
 hope you don't mind, Yannick !")

Just a quick note to mention that following [Mike Doherty's bug report](https://github.com/dams/moox-lvalueattribute/issues/1), I've released a new version of [MooX::LvalueAttribute](https://metacpan.org/module/DAMS/MooX-LvalueAttribute-0.12/lib/Method/Generate/Accessor/Role/LvalueAttribute.pm).

This release (version 0.12) allows you to use MooX::LvalueAttribute in a Moo::Role, like this;

{% highlight perl %}
{
    package MyRole;
    use Moo::Role;
    use MooX::LvalueAttribute;
}

{
    package MyApp;
    use Moo;

    with ('MyRole');

    has name => ( is => 'rw',
                  lvalue => 1,
                );
}

my $object = MyApp->new();
$object->name = 'Joe';

{% endhighlight %}

So now it's easier to specify which classes will have lvalue attributes and
which one won't. Until now I avoided adding a flag to globally enable lvalue
attributes across all Moo classes (without having to say `lvalue => 1`). Maybe
that's something some of you would like ?

Anyway, that's all folks! Nothing revolutionary, but I've been told we should
talk more about what we do, so that's what I'm doing.

For more detail about Moox::LvalueAttribute, see my [original post](http://damien.krotkine.com/2013/02/11/lvalue-accessors-in-moo.html)


