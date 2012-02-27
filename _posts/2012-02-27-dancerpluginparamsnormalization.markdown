---
layout: post
title: "Dancer::Plugin::Params::Normalization"
---

# {{ page.title }}

Just released a new version of [Dancer::Plugin::Params::Normalization](https://metacpan.org/module/Dancer::Plugin::Params::Normalization). This plugin allows to normalize or alter parameters recieved by a Dancer route.

An example of what developers usually want is to accept mixedcased request parameters, and have them all lowercased. Thatis done easily :

    # In your configuration file
    plugins:
      Params::Normalization:
        method: lowercase

And that's it, now you are sure that all your parameter names will be lowercases.

Now this plugin goes further by being very flexible and powerful. It supports standard methods like *lowercase*, *uppoercase*, *ucfirst*. But you can also give it a class name, which have to implement a *normalize* method, thus giving you full flexibility.

If you don't want all parameters of all routes to be normalized, you can set *general_rule* to *ondemand*, and use the added keyword *normalize* to trigger the normalization. Or, you can instead specify a filter to be applied on parameters. Only those matching it will be normalized.

But that's not the end. This plugin also allows you to specify which parameters should be normalized: *query* parameters, *body* parameters, or the parameters from the *route* definitions.

I tried to be pretty exhaustive with this plugin, but if anything happen to be missing for your usage, let me know :)

