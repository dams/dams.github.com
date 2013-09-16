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

