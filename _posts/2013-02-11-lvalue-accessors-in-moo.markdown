---
layout: post
title: MooX::LvalueAttribute - Lvalue accessors in Moo
---

# {{ page.title }}

Yesterday I was reading [Joel's
post](http://blogs.perl.org/users/joel_berger/2013/02/in-the-name-of-create-great-things-in-perl.html),
where he lists great Perl things he's seen done lately. Indeed these are great
stuff. I was particulary interested by his try at playing with [Lvalue accessors](https://gist.github.com/jberger/4740303).

I thought that it would be a great exercise to try to implement it in Moo, as
an additional feature, trying to get rid of the `AUTOLOAD`. Also, I was willing
to avoid doing a `tie` every time an instance attribute accessor was called.
Surely, I needed to tie only *once* per instance and per attribute, not each
time the attribute is accessed.

So I started hacking on the code of Moo. Getting rid of the AUTOLOAD was easy,
as I could change the way the accessor generator was, well, generating the,
err, accessors.

Shortly after I started having issues to cache a tied variable. I asked the
all-mighty [Vincent Pit](https://metacpan.org/author/VPIT), and he found a
solution for my tied variables, but more importanlty pointed me to
[Variable::Magic](https://metacpan.org/module/Variable::Magic), which is
faster, more flexible and powerful.

All I needed was to move my hacks in a proper Role, and wrap the whole in a
module, and push it on CPAN. Tadaa, [MooX::LvalueAttribute](https://metacpan.org/module/MooX::LvalueAttribute) was born.

In the process I used [play-perl](http://play-perl.org) to register my quests,
and exchanged [thoughts with Joel
Berger](http://play-perl.org/quest/511800ae94f611130b000025). I think I'm going
to use this website more, see if it can boost my productivity, and help me
figure out what's really important to do.

On IRC, haarg discovered a bug and recommended to use so-called *fieldhashes*,
from
[Hash::Util::FieldHash::Compat](https://metacpan.org/module/Hash::Util::FieldHash::Compat).
At the end of the day, I only acted as a glue between different pieces of
knowledges, and that was very satisfactory.

## TL:DR

[MooX::LvalueAttribute](https://metacpan.org/module/MooX::LvalueAttribute) is a
module that provides Lvalue attributes:

{% highlight perl %}
package App;
use Moo;
use MooX::LvalueAttribute;

has name => (
  is => 'rw',
  lvalue => 1,
);

# Elsewhere
my $app = App->new(name => 'foo');

$app->name = 'Bar';

print $app->name;  # Bar

{% endhighlight %}

Enjoy!