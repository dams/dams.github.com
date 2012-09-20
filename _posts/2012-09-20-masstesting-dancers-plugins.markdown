---
layout: post
title: Mass-Testing Dancer's Plugins
---

# {{ page.title }}

So, as I said at YAPC::EU 2012, one thing that remains to be done before Dancer
2 can be released : migrating the plugins, making sure they work with it.

To be able to do that, what's best than an automatic testing facility ?

The goal is to get all Dancer plugins, test them with Dancer1, and Dancer2, and
produce a report, to check which one fails and need fixing.

## Step 1. Get the list of Dancer plugins.

Easy ! let's use [Metacpan](https://metacpan.org/). After searching, I finally
got a way to get the list of all modules that depend on Dancer. Then filtering
out the ones that don't contain `"Plugin"` will do the trick.

{% highlight perl %}
#!/usr/bin/env perl

use Modern::Perl;
use ElasticSearch;

my $es = ElasticSearch->new( servers => 'api.metacpan.org', no_refresh => 1 );

my $scroller = $es->scrolled_search(
    query       => { match_all => { } },
    search_type => 'scan',
    scroll      => '5m',
    index       => 'v0',
    type        => 'release',
    size        => 100,
    filter => {
            term => {
                     'release.dependency.module' => 'Dancer'
                    }
              },

);

my $result = $scroller->next;

my %plugins;
while ( my $result = $scroller->next ) {
    $result->{_source}->{name} =~ /Dancer-Plugin/
      or next;
    my $name = $result->{_source}->{name};
    $name =~ s/-\d.*//;
    $name =~ s/-/::/g;
    $plugins{$name} = 1;
}
say $_ foreach sort keys %plugins;
{% endhighlight %}

Cool, let's save this script as `get_modules_list.pl`.

## Step 2. Prepare two Perl environments

We want two instance of Perl, without polluting anything. We'll use
[perlbrew](http://www.perlbrew.pl/) for that. Easy. The small trick is to have
`PERLBREW_ROOT` initialized to a local directory to not polute existing `~/perl5`
installation.

## Step 3. Have a way to test modules

Well, let's use [cpanm](http://cpanmin.us/), which has an option `--test-only`
to only test a module without installing it. Oh but plugin modules that we'll
test may require dependances. We'll install them using `cpanm --installdeps`,
which does just that.

## Step 4. Create a result file

I was lazy and just output to a `.csv` text file, but I may store the results
somewhere else later.

## Step 5. Let's glue all that in a Makefile

The beauty of this is that by writing a proper Makefile, we can install this
auto-tester anywhere. The requirements are minimal : `bash`, `curl`, and
`perl`, with `ElasticSearch` and `Modern::Perl` installed.

( This post is intentionally named the same as
[the one from Yannick](http://babyl.dyndns.org/techblog/entry/test-dancer-plugins),
because he proposed a different implementation. We'll try to merge the good
ideas together )

{% highlight bash %}
HERE=${PWD}

# set up the local Perlbrew location
PERLBREW_DIR=${HERE}/perlbrew
PERLBREW=export PERLBREW_ROOT=${PERLBREW_DIR} \
    && source ${PERLBREW_DIR}/etc/bashrc \
    && PERLBREW_ROOT=${PERLBREW_DIR} ${PERLBREW_DIR}/bin/perlbrew

# This will run the cpanm from the local Perlbrew, on each of the 2 perls
CPANM_DANCER1=${PERLBREW} exec --with dancer1_plugin_tests ${PERLBREW_DIR}/bin/cpanm
CPANM_DANCER2=${PERLBREW} exec --with dancer2_plugin_tests ${PERLBREW_DIR}/bin/cpanm

# loop on the plugin list, install the deps and test each plugin and output result
all: got_curl got_bash got_perlbrew_perl plugins_list
	echo "Plugin name,Pass on Dancer 1,Pass on Dancer 2" > result.csv
	@for i in `cat plugins_list`; do pass_d1=0; pass_d2=0; \
	  echo " ---------- TESTING on Dancer 1 : $$i"; \
          ${CPANM_DANCER1} -n --installdeps $$i \
              && ${CPANM_DANCER1} --test-only $$i && pass_d1=1; \
	  echo " ---------- TESTING on Dancer 2 : $$i"; \
          ${CPANM_DANCER2} -n --installdeps $$i \
              && DANCER_FORCE_PLUGIN_REGISTRATION=1 ${CPANM_DANCER2} --test-only $$i \
              && pass_d2=1; \
          echo "$$i,$$pass_d1,$$pass_d2" >> result.csv; \
        done;

clean:
	rm -rf plugins_list

fullclean:
	rm -rf ${PERLBREW_DIR}

# Get and install Perlbrew locally
${PERLBREW_DIR}/bin/perlbrew:
	@echo " - creating a local perlbrew"
	export PERLBREW_ROOT=${PERLBREW_DIR} && curl -kL http://install.perlbrew.pl | bash

# Get and install cpanm in the local Perlbrew
${PERLBREW_DIR}/bin/cpanm:
	${PERLBREW} install-cpanm

got_curl:
	@which curl >/dev/null \
        || ( echo "you don't have curl, please install it and retry" && false )

got_bash:
	@which bash >/dev/null \
        || ( echo "you don't have bash, please install it and retry" && false )

got_perlbrew_perl: ${PERLBREW_DIR}/bin/perlbrew ${PERLBREW_DIR}/bin/cpanm perlbrew_dancer1_plugin_tests perlbrew_dancer2_plugin_tests

# Build perl from scratch and call this instance dancer1
perlbrew_dancer1_plugin_tests:
	${PERLBREW} list | grep dancer1_plugin_tests > /dev/null \
        || ( ${PERLBREW} install -j 2 -n perl-5.16.1 --as dancer1_plugin_tests )

# Build perl from scratch and call this instance dancer2
perlbrew_dancer2_plugin_tests:
	${PERLBREW} list | grep dancer2_plugin_tests > /dev/null \
        || ( ${PERLBREW} install -j 2 -n perl-5.16.1 --as dancer2_plugin_tests \
             && ${CPANM_DANCER2} ${HERE}/../.. )

# This gets the list of plugins, as previously described
plugins_list:
	${HERE}/get_modules_list.pl > plugins_list

{% endhighlight %}

It's really cool to see what you can do with modern tools of the Perl ecosystem !
