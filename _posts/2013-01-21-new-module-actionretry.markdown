---
layout: post
title: "New Perl module: Action::Retry"
---

# {{ page.title }}

I've just released a new module called
[Action::Retry](https://metacpan.org/module/Action::Retry).

Use it when you want to run some code until it succeeds, waiting between two
retries.

A simple way to use it is :

    Action::Retry->new( attempt_code => sub { ... } )->run();

The purpose of this module is similar to `Retry`, `Sub::Retry`, `Attempt` and
`AnyEvent::Retry`. However, it's highly configurable, more flexible and has
more features.

You can specify the code to try, but also a callback that will be executed to
check the success or failure of the attempt. There is also a callback to execute code on
failure.

The module also supports different sleep strategies ( Constant, Linear,
Fibonacci...) and it's easy to build yours. Strategies can have their options
as well.

    my $action = Action::Retry->new(
      attempt_code => sub { ... },
      retry_if_code => sub { $_[0] =~ /Connection lost/ || $_[1] > 20 },
      strategy => { Fibonacci => { multiplicator => 2000,
                                   initial_term_index => 3,
                                   max_retries_number => 5,
                                 }
                  },
      on_failure_code => sub { say "Given up retrying" },
    );
    $action->run();

Strategies can decide if it's worthwhile continuing trying, or if it should fail.

[Action::Retry](https://metacpan.org/module/Action::Retry) also supports a
pseudo "non-blocking" mode, in which it doesn't actually sleep, but instead
returns immediately, and won't perform the action code until required time has
elapsed. Basicaly it allows to do this:

    my $action = Action::Retry->new(
      attempt_code => sub { ... },
      non_blocking => 1,
      strategy => { 'Constant' }
    );
    while (1) {
      # if the action failed, it doesn't sleep
      # next time it's called, it won't do anything until it's time to retry
      $action->run();

      do_something_else();
      # do something else while time goes on
    }

of course `do_something_else` should be very fast, so that the loop goes back
quickly to retrying the `attempt_code`.

[Action::Retry](https://metacpan.org/module/Action::Retry) is based on
[Moo](https://metacpan.org/module/Moo) for performance (and because the module
is simple enough to not require Moose). Moo classes properly expand to Moose
ones if needed, so there is no excuse not to use it.

So, please give a try to
[Action::Retry](https://metacpan.org/module/Action::Retry), and let me know
what you think.

