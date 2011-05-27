---
layout: post
title: Perlbrew, Emacs, Flymake
---

# {{ page.title }}

Perl + Emacs / Flymake
======================

So I'm a seasoned user of [Emacs](http://www.gnu.org/software/emacs/) (I
started using it back to 1999). I'm using it for all things, especially Perl
coding, using the `cperl-mode` Emacs mode.

Lately, I've come to using `flymake`.
[Flymake](http://flymake.sourceforge.net/) is a tool in Emacs, which tries to
compile the file you are editing, and displays compilation errors in your
buffer. There is a mode for Perl, so the result is really nice : realtime
syntax checking of the current Perl file you're editing. It looks like that :

![Perl and Flymake in Emacs](/images/perl_flymake.png 'Perl and Flymake in Emacs')

Perl + Emacs + Flymake + PerlBrew
=================================

Then comes [perlbrew](http://search.cpan.org/perldoc?App::perlbrew), which
allows you to have multiple Perl interpretors installed on your machine, and
switching between them easily.

Alas, flymake is not working by default with Perlbrew, as it uses
`/usr/bin/perl`. So one needs to configure Emacs to recognize various perls
installed via Perlbrew, and tell Flymake to use one of them.

kentaro has made a Perlbrew mode, and [explained how to use it with
flymake](http://d.hatena.ne.jp/antipop/20110413/1302671667)

However, for various reasons, this Perlbrew mode it doesn't work well on my
machine and Franck ( [lumperjaph](http://lumberjaph.net/) ) reported similar
issues.

So I went on and rewrote a simple Perlbrew mode that would do almost nothing.
It would only play with directories path, to allow you to say where the various
Perlbrew perls are installed, and which one to use. `perlbrew-mini.el` was
born.

perlbrew-mini.el
================

Requirements : you need Emacs, a functional perlbrew with at least one Perl
installed, and you need
[Project::Libs](http://search.cpan.org/perldoc?Project::Libs).

Then, download perlbrew-mini.el [from
github](https://github.com/dams/perlbrew-mini.el), and put it in a place where
Emacs will see it.

Then, edit your `.emacs` so that it contains these lines:

    (require 'perlbrew-mini)
    ;; change to your username below
    (perlbrew-mini-set-perls-dir "/home/uername/perl5/perlbrew/perls/")
    ;; change the version you wish to use
    (perlbrew-mini-use "perl-5.12.2")
    
    (require 'flymake)
    
    (defun flymake-perl-init ()
      (let* ((temp-file (flymake-init-create-temp-buffer-copy
                         'flymake-create-temp-inplace))
             (local-file (file-relative-name
                          temp-file
                          (file-name-directory buffer-file-name))))
        (list (perlbrew-mini-get-current-perl-path) (list "-MProject::Libs" "-wc" local-file))))
    
    (add-hook 'cperl-mode-hook (lambda () (flymake-mode t)))

And _voilà_, Flymake will work with your Perlbrew Perl, as it used to work with the system Perl.