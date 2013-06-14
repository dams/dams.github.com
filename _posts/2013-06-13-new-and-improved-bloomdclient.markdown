---
layout: post
title: "New And Improved: Bloomd::Client"
---

# {{ page.title }}

![New and Improved!](/images/val_approuve.png "I borrowed the image from @yenzie -
 hope you don't mind, Yannick !")

_thanks to @yenzie for the picture :P_

## Bloom filters

[Bloom filters](http://en.wikipedia.org/wiki/Bloom_filter) are statistical data
structures. The most common use of them is to consider them as buckets. In one
bucket, you add elements. Once you've added a bunch of elements, it's ready to
be used.

You use it by presenting it yet an other element, and it'll be able to say
almost always if the element is already in the bucket or not.

More precisely, when asking the question _"is this element in the filter ?"_, if it
answers **no**, then you are sure that it's **not** in there. If it answers **yes**,
then there is a **high probability** that it's there.

So basically, you never have false negatives, but you can get a few false
positives. The good thing is that depending on the space you allocate to the
filter, and the number of elements it contains, you know what will be the
probability of having false positives.

The **huge** benefit is that a bloom filter is very small, compared to a hash
table.

## bloomd

At work, I replaced a heavy Redis instance ( using 60g of RAM) that was used primarily as a
huge hash table, by a couple of bloom filters ( using 2g ). For that I used
[bloomd](https://github.com/armon/bloomd), from _Armon Dadgar_. It's light,
fast, has enough features, and the code looks sane.

All I needed was a Perl client to connect to it.

## Bloomd::Client

So I wrote [Bloomd::Client](https://metacpan.org/module/Bloomd::Client). It is a light
client that connects to bloomd using a regular INET socket, and speaks the
simple ASCII protocol (very similar to Redis' one) that bloomd implements.

{% highlight perl %}
    use Bloomd::Client;
    my $b = Bloomd::Client->new;

    my $filter = 'test_filter';
    $b->create($filter);
    my $hash_ref = $b->info($filter);

    $b->set($filter, 'u1');
    if ($b->check($filter, 'u1')) {
	  say "it exists!"
    }
{% endhighlight %}

When you use bloomd it usually means that you are in a high availibility
environment, where you can't get stuck waiting on a socket, just because
something went wrong. So Bloomd::Client implements non-blocking timeouts on the
socket. It'll die if bloomd didn't answer fast enough or if something broke.
That allows you to incorporate the bloomd connection in a retry strategy to try
again later, or fallback to another server...

To implement such a strategy, I recommend using
[Action::Retry](https://metacpan.org/module/Action::Retry). There is a blog
post about it [here](http://damien.krotkine.com/2013/01/21/new-module-actionretry.html) :)

dams.
