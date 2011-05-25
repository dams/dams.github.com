---
layout: post
title: DateTime duration in seconds
---

# {{ page.title }}

It has been too many times that I forget how to get a `DateTime::Duration`
between two `DateTime` objects in seconds (and nanoseconds). That is, where I
can then do `->seconds` and have the duration in seconds between the two dates.

I know it's in the `DateTime` POD, but I keep forgetting it, and it takes me
always a lot of time to find it back.

Here it is so that the next time I search for it on the Intarwoob, it shows up.

{% highlight perl %}
my $duration = $dt2->subtract_datetime_absolute($dt1);
{% endhighlight %}

