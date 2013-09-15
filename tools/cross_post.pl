#!/usr/bin/env perl

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

my $cfg = (values %{Config::Any->load_files({files => [ $ENV{HOME} . '/.crosspost.ini' ], use_ext => 1 })->[0]})[0];

my $main_blog_title = $cfg->{main_blog}{title};
my $main_blog_url = $cfg->{main_blog}{url};

my $flag = 0;
my $flag2 = 0;
my $title='';
my $text;
foreach ($file->slurp) {
    /^---$/
      and $flag = !$flag, next;
    $flag && /title:\s*(.*)/
      and $title = $1, $title =~ s/^"|"$//g;
    $flag
      and next;
    /^\s*{% highlight .*? %}\s*$/
      and $flag2 = 1, next;
    /^\s*{% endhighlight %}\s*$/
      and $flag2 = 0, next;
    $flag2 and $_ = '    ' . $_;
    s/{{\s*page.title\s*}}/$title/g;
    $text .= $_;
}

say "TITLE : $title";

$text = "\n <i>cross-posted from [$main_blog_title]($main_blog_url)</i>\n\n" . $text;

my $html = markdown($text);

foreach my $site (grep { $_ ne 'main_blog'} keys %$cfg) {
    say "posting to $site";
    my %properties = %{$cfg->{$site}};
    if ($properties{type} eq 'mt') {
        my $username = $properties{username};
        my $password = $properties{password};
        my $url = $properties{url};

        my $mt = Net::MovableType->new($url);
        $mt->username($username)
        or croak $mt->errstr;
        $mt->password($password)
        or croak $mt->errstr;
        my $user_blogs = $mt->getUsersBlogs
          or croak $mt->errstr;
        $mt->blogId($user_blogs->[0]->{blogid})
          or croak $mt->errstr;

        $mt->newPost({
                      title       => $title,
                      description => $html,
                      mt_allow_comments => $properties{allow_comments} // 1,
                     },
                     1, # publish
                    );

    }
    # if ($properties{type} eq 'twitter') {
    #     use Net::Twitter;
    #     use Scalar::Util 'blessed';
    #     use Try::Tiny;

    #     my $nt;

    #     while(1) {
    #         say Dumper(\%properties); use Data::Dumper;
    #         try {
    #             $nt = Net::Twitter->new(
    #                                     traits   => [qw/OAuth API::REST/],
    #                                     consumer_key        => $properties{consumer_key},
    #                                     consumer_secret     => $properties{consumer_secret},
    #                                     access_token        => $properties{access_token},
    #                                     access_token_secret => $properties{access_secret},
    #                                    );
    #             my $result = $nt->update('New blog entry: "' . $title . '" at ' . $main_blog_url);
    #             1;
    #         } catch {
    #             say " Error : $_";
    #             my $auth_url = $nt->get_authorization_url;
    #             say "Go to $auth_url to authorize this application";
    #             say "Enter the PIN:";
    #             my $pin = <STDIN>;
    #             chomp $pin;
    #             say "pin was : $pin";
    #             my @access_tokens = $nt->request_access_token(verifier => $pin);
    #             say "Please update your cross.ini file with these tokens";
    #             say "    access_token = $access_tokens[0]";
    #             say "    access_secret = $access_tokens[1]";
    #             $properties{access_token} = $access_tokens[0];
    #             $properties{access_token_secret} = $access_tokens[1];
    #             0;
    #         }
    #           and last;
    #     }
    # }
}
 
