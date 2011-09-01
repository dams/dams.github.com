---
layout: post
title: protect a screen session with a password
---

# {{ page.title }}

I use [Gnu Screen](http://www.gnu.org/software/screen/) a lot. It's a must have
tool when working on remote servers.

Long time ago, I spent time to craft a good screenrc configuration file for my
needs. But I only discovered yesterday that I could protect my screen session
from being recovered from a super user on the remote server. The documentation is lacking precise description on how to set it up, so here is it a quick tutorial.

The idea is that when a screen is running, it can be detached and reattached.
However, a super user has the possibility to attach any screen launched by a
user of the system. Now, what if inside the screen, you use sensitive
information, or connect to other remote servers ? The super user will have
access to these as well. To protect yourself from that, it's possible to have
screen ask for a password when trying to reattach it.

## Launch a new screen

{% highlight bash %}
$ screen
{% endhighlight %}

## Encrypt a new password

screen provides a way to encrypt a password right from a screen session. In the following snippets, I assume the default screen key is A, as default.

{% highlight bash %}
# hit ctrl A :password
# enter the new password twice
{% endhighlight %}

Now, the encrypted password is in the screen clipboard. We need to retrieve it

## Paste the crypted password

{% highlight bash %}
# hit ctrl A ]
# the encrypted password should be pasted in the console
{% endhighlight %}

## Edit the screen configuration file

Copy the encrypted password and paste it in `~/.screenrc` (or whatever your screen configuration file is)

{% highlight bash %}
# add this line, with your encrypted password
password VGdGzMopF
{% endhighlight %}

## Restart screen

You need to restart screen to take the password in account. Now, next time a
screen is reattached, the password will be prompted.

{% highlight bash %}
dams@foo:~$ screen -r -d plop
Screen password: 
{% endhighlight %}

