---
layout: post
title: Cross Posting to blogs.perl.org
---

# {{ page.title }}

So, a while ago, I moved [my blog](http://damien.krotkine.com) to github, using
[jekyll](https://github.com/mojombo/jekyll) and
[markdown](http://daringfireball.net/projects/markdown/), with [jekyll
integration](http://metajack.im/2009/01/02/manage-jekyll-from-emacs/) in
[Emacs](http://www.gnu.org/software/emacs/).

That works great, and I like the fasct that posting a blog entry is just a regular git push.

My blog is aggregated in some places, but it doesn't appear on
[blogs.perl.org](http://blogs.perl.org), because it's not an aggregator (and that's
cool, it's not its purpose). But, blogs.perl.org audience is big, and I'm
missing all these potential readers (in improbable case people would actually
be interested in what I have to say :) )

Anyway, so I decided to bite the bullet and write a script that would cross
post my entry to blogs.perl.org. I made the script generic enough to work with
different type of blogs, but here I'm going to explain only the blogs.perl.org
specific case.

blogs.perl.org is a [Movable Type](http://www.movabletype.org/) blog engine. A
look on [Metacpan](http://metacpan.org) indicates us there is a
[Net::MovableType](https://metacpan.org/module/Net::MovableType) module. That's
great, let's use that.

There is a catch: to use this module, you need your login, and your *API
password*, not your regular password. You can get it easily though, by [following these instructions](https://github.com/davorg/blogs.perl.org/issues/137) (thanks to davorg for directing me to it).

To avoid storing the user / password in the script, and to have to pass it on
the command line, let's have a configuration file, that will lie at
`~/.crosspost.ini`, and that we'll load with
[Config::Any::Merge](https://metacpan.org/module/Config::Any::Merge).

The file name of the original post will have to be passed on the command line,
using [Getopt::Long](https://metacpan.org/module/Getopt::Long) and
[Path::Class](https://metacpan.org/module/Path::Class) to retrieve and slurp
it.

Here is the configuration file.

    # file ~/.corsspost.ini
    [ main_blog ]
    title = dams blog
    url = http://damien.krotkine.com
    
    [ blogs.perl.org ]
    type = mt
    username = foo
    password = bar
    url = http://blogs.perl.org/rsd.xml


And here's the code:

{% highlight perl %}

# file crosspost.plcorsspost.ini

use Modern::Perl;
use Carp;

use Net::MovableType;
use Config::Any::Merge;
use Getopt::Long;
use Path::Class;
use Text::Markdown qw(markdown);

my $file;
GetOptions ("file=s"   => \$file)
  or croak "failed to parse command line options";

$file
  or croak "need a file";

$file = file($file);

# Get a hash representing the config file
my $cfg = (values %{Config::Any->load_files({files => [ $ENV{HOME} . '/.crosspost.ini' ], use_ext => 1 })->[0]})[0];

# Grab some main info
my $main_blog_title = $cfg->{main_blog}{title};
my $main_blog_url = $cfg->{main_blog}{url};

my $text = $file->slurp;
# In reality, I do some transformation on $text to interpret jekyll specific
# syntax

$text = "\n <i>cross-posted from [$main_blog_title]($main_blog_url)</i>\n\n" . $text;

# So now we have the content to be posted, but it's in markdown. Let's
# transform it in HTML
my $html = markdown($text);

# Then we loop on all the other blog to cross post to
foreach my $site (grep { $_ ne 'main_blog'} keys %$cfg) {
    say "posting to $site";
    my %properties = %{$cfg->{$site}};

    # for now we handle only movable type
    if ($properties{type} eq 'mt') {
        my $username = $properties{username};
        my $password = $properties{password};
        my $url = $properties{url};

        my $mt = Net::MovableType->new($url);
        $mt->username($username)
          or croak $mt->errstr;
        $mt->password($password)
          or croak $mt->errstr;
        We need to get the user's blog id
        my $user_blogs = $mt->getUsersBlogs
          or croak $mt->errstr;
        $mt->blogId($user_blogs->[0]->{blogid})
          or croak $mt->errstr;

        # finally, the post
        $mt->newPost({
                      title       => $title,
                      description => $html,
                      mt_allow_comments => $properties{allow_comments} // 1,
                     },
                     # uncomment this line to directly post it
                     # 1
                    );

    }
    
}
{% endhighlight %}

Missing in this code is some mungling of the text to manage jekyll specific syntax. And while I was at it, I improved it so that it supports cross-posting to twitter, using [Net::Twitter](https://metacpan.org/module/Net::Twitter), and posting only a short description of the entry. Here is an example (I had to create a custom Twitter app called blog-cross-poster)

![Twitter cross posting](/images/twitter_cross_post.png)
 
Now, I just need to add a git hook to be executed at push time, check if there is a new post or a modified one, and cross post it. Yay !

