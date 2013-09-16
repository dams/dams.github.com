---
layout: post
title: "p5-mop: a gentle introduction"
---

# {{ page.title }}

## p5-mop

I guess that you've heard about p5-mop by now.

If not, in a nutshell, p5-mop is an attempt to implement a subset of
[Moose](http://moose.iinteractive.com/) into the core of Perl. Moose provides a
Meta Object Protocol (MOP) to Perl. So does p5-mop, however p5-mop is
implemented in a way that it can be properly included in the Perl core.

Keep in mind that p5-mop goal is to implement a _subset_ of Moose, and. As
Stevan Little says:

> We are not putting "Moose into the core" because Moose is too opinionated,
> instead we want to put a minimal and less opinionated MOP in the core that is
> capable of hosting something like Moose

As far as I understood, after a first attempt that failed, Stevan Little
restarted the p5-mop implementation: the so-called p5-mop-redux
[github project](https://github.com/stevan/p5-mop-redux), using
[Devel::Declare](https://metacpan.org/module/Devel::Declare), ( then
[Parse::Keyword](https://metacpan.org/module/Parse::Keyword) ), so that he can
experiment and release often, while keeping the implementation core-friendly.
Once he's happy with the features and all, he'll make sure it finds its way to
the core. A small team (Stevan Little, [Jesse Luehrs](http://tozt.net/), and
other contributors) is actively developping p5-mop, and Stevan is regularly
[blogging about it](http://blogs.perl.org/users/stevan_little/).

If you want more details about the failing first attempt, there is a bunch of
backlog and mailing lists archive to read. However, here is how Stevan would
summarize it:

> We started the first prototype, not remembering the old adage of "write the
> first one to throw away" and I got sentimentally attached to my choice of
> design approach. This new approach [p5-moop-redux] was purposfully built with
> a firm commitment to keeping it as simple as possible, therefore making it
> simpler to hack on.
> Also, instead of making the MOP I always wanted, I approached as building the
> mop people actually needed (one that worked well with existing perl classes,
> etc)

