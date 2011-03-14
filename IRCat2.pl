#!/usr/bin/env perl
# -*- coding: utf-8 -*-

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

use warnings;
use strict;

package InternetRelayCat;
use base qw( Bot::BasicBot );

use LWP::UserAgent;
use URI::Find::Rule;
use URI::Escape;

our (@admins, %phrases, $password, $channel);
@admins   = ("eevo");
$password = "724b9c2d7158734437dd27de7234f388";
$channel  = "#bottest";

#own methods

sub admin {
    our $admins;
    my $message = shift;
    return unless $message->{body} =~ /^!admin/i;
    return unless grep {m|^$message->{who}?$|} @admins;
    $message->{body} =~ s/^!admin\s+//;
    if ($message->{body} =~ /^list/i) {
        my $adminlist = join(", ", @admins);
        return "Admins: $adminlist";
    }
    elsif (my ($addarg) = $message->{body} =~ /^add(?:\s+(.*))?/i) {
        if ($addarg) {
            if (grep {m|^$addarg?$|} @admins) {
                return "$addarg is already an admin.";
            }
            else {
                push(@admins, $addarg);
                return "Added $addarg to admins.";
            }
        }
        else {
            return "Argument required.";
        }
    }
    elsif (my ($delarg) = $message->{body} =~ /^del(?:\s+(.*))?/i) {
        if ($delarg) {
            my $i = 0;
            foreach(@admins) {
                if ($delarg eq $admins[$i]) {
                    delete $admins[$i];
                    return "Deleted $delarg from admins.";
                }
                else {
                    $i++;
                }
            }
        }
        else {
            return "Argument required.";
        }
    }  
}

sub phrase_get {
    our $phrases;
    my $message = shift;
    return unless $message->{body} =~ /^!/;
    $message->{body} =~ s/^!//;
    my @args = split(" ", $message->{body});
    my $phrase = shift(@args);
    return unless $phrases{$phrase};
    my $argcount = 0;
    foreach(0 .. 9) {
        if ($phrases{$phrase} =~ /\%$_/) {
            $argcount++;
        }
    }
    return unless (scalar(@args) >= $argcount);
    my $i=0;
    my $curphrase = $phrases{$phrase};
    foreach(@args) {
        $curphrase =~ s/\%$i/$args[$i]/g;
        $i++;
    }
    $curphrase =~ s/\%s/$message->{who}/g;
    $curphrase =~ s/\%\d//g;
    return $curphrase;
}

sub phrase_add {
    our ($phrases, $admins);
    my $message = shift;
    return unless grep {m|^$message->{who}?$|} @admins;
    return unless $message->{body} =~ /^!rem /i;
    my ($newphrase) = $message->{body} =~ /^!rem(?:\s+(.*))?/i;
    if ($newphrase) {
        my @args = split(" ", $newphrase);
        my $name = shift(@args);
        return "Argument required." unless @args;
        if ($phrases{$name}) {
            return "$name already exists!"
        }
        else {
            $newphrase = join(" ", @args);
            $phrases{$name} = $newphrase;
            return "Meow!"
        }
    }
    else {
        return "Argument required."
    }
}
sub phrase_del {
    our ($phrases, $admins);
    my $message = shift;
    return unless grep {m|^$message->{who}?$|} @admins;
    return unless $message->{body} =~ /^!del /i;
    $message->{body} =~ s/^!del\s+//;
    my @args = split(" ", $message->{body});
    my $to_delete = shift(@args);
    return unless $to_delete;
    if ($phrases{$to_delete}) {
        delete $phrases{$to_delete};
        return "Meow!"
    }
}

sub phrase_list {
    our $phrases;
    return "I don't know any phrases." unless scalar(keys(%phrases)) > 0;
    my $message = shift;
    my @phrasenames = keys(%phrases);
    my $phraselist = join(", ", @phrasenames);
    return "I know these phrases: $phraselist";
}

sub phrase_show {
    our $phrases;
    my $message = shift;
    return unless $message->{body} =~ /^!show /i;
    $message->{body} =~ s/^!show\s+//;
    my @args = split(" ", $message->{body});
    my $phrase = shift(@args);
    return unless $phrases{$phrase};
    return "$phrase is: $phrases{$phrase}";
}

sub handle_commands {
    my ($self, $message) = @_;
    if ($message->{body} =~ /^!help/i) {
        return help();
    }
    elsif ($message->{body} =~ /^!admin /i) {
        return admin($message);
    }
    elsif ($message->{body} =~ /^!rem /i) {
        return phrase_add($message);
    }
    elsif ($message->{body} =~ /^!del /i) {
        return phrase_del($message);
    }
    elsif ($message->{body} =~ /^!phrases/i) {
        return phrase_list($message);
    }
    elsif ($message->{body} =~ /^!show /i) {
        return phrase_show($message);
    }
    elsif ($message->{body} =~ /^!shorten /i) {
        my @uris = map { $_->[1] } URI::Find::Rule->http->in($message->{body});
        if (@uris) {
            my $uri = shift(@uris);
            my  ( $short_link, $title ) = shorten_url($uri);
            return "$message->{who}: $short_link - $title";
        }
    }
    elsif ($message->{body} =~ /^!xkcd /i) {
        $message->{body} =~ s/^!xkcd\s+//;
        my @args = split(" ",$message->{body});
        my $num = shift(@args);
        return unless $num;
        return xkcd($num);
    }
    elsif ($message->{body} =~ /^!/) {
        return phrase_get($message);
    } 
}

sub handle_address {
    my ($self, $message) = @_;
    if ($message->{body} =~ /\*hug[s]?\*/i) {
        $self->emote (
            channel => $message->{channel},
            body => "hugs $message->{who}",
        );
    }
    elsif ($message->{body} =~ /\*slap[s]?\*/i) {
        $self->emote (
            channel => $message->{channel},
            body => "slaps $message->{who} around the channel",
        );
    }
    elsif (my ($string) = $message->{body} =~ /^you(?:\s+(.*))?/i) {
        if ($string) {
            return "No, you $string!";
        }
    }
}

sub handle_query {
    our ($admins, $channel);
    my ($self, $message) = @_;
    if ($message->{body} =~ /^say /i) {
        return unless grep {m|^$message->{who}?$|} @admins; 
        $message->{body} =~ s/^say\s+//;
        $self->say(
            channel => $channel,
            body    => $message->{body},
        );
    }
    elsif ($message->{body} =~ /^emote /i) {
        return unless grep {m|^$message->{who}?$|} @admins;
        $message->{body} =~ s/^emote\s+//;
        $self->emote(
            channel => $channel,
            body    => $message->{body},
        );
    }
    elsif ($message->{body} =~ /^auth /i) {
        return if grep {m|^$message->{who}?$|} @admins; 
        $message->{body} =~ s/^auth\s+//;
        if ($message->{body} eq $password) {
            push(@admins, $message->{who});
            return "Successfully authed!";
        }
    }
    elsif ($message->{body} =~ /^takeover /i) {
        return if grep {m|^$message->{who}?$|} @admins; 
        $message->{body} =~ s/^takeover\s+//;
        if ($message->{body} eq $password) {
            @admins = ();
            push(@admins, $message->{who});
            return "Successfully taken over!";
        }
    }
}

sub shorten_url {
    my $uri = shift;
    my ( $short_link, $title );
    my $ua = LWP::UserAgent->new(
        max_size => 8192,
        timeout => 30,
    );
    my $response = $ua->get($uri);
    $title = $response->title;
    my $uri_escaped = uri_escape($uri);
    my $shorten = $ua->get("http://v.gd/create.php?format=simple&url=$uri_escaped");
    $short_link = $shorten->content;
    return ($ short_link, $title);
}

sub xkcd {
    my $num = shift;
    my $ua = LWP::UserAgent->new(
        max_size => 8192,
        timeout => 30,
    );
    my $response = $ua->get("http://xkcd.com/$num/");
    return unless $response->is_success;
    my $title = $response->title;
    $title =~ s/xkcd\:\s+//;
    return "http://xkcd.com/$num/ - $title";
}

#override methods

sub help {
    return "I'm a bot! Available commands are: !admin, !rem, !del, !phrases, !show, !shorten"
}

sub said {
    my ($self, $message) = @_;
    if ($message->{address} eq "msg") {
        return handle_query($self, $message);
    }
    elsif ($message->{address} =~ /^$self->{nick}/) {
        return handle_address($self, $message);
    }
    elsif ($message->{body} =~ /^!/) {
        return handle_commands($self, $message);
    }
    else {
        my @uris = map { $_->[1] } URI::Find::Rule->http->in($message->{body});
        if (@uris) {
            my $uri = shift(@uris);
            return if length $uri < 40;
            my  ( $short_link, $title ) = shorten_url($uri);
            return "$short_link - $title (original link by $message->{who})";
        }
    }
}

sub emoted {
    my ($self, $message) = @_;
    if ($message->{body} =~ /^hugs $self->{nick}$/i) {
        $self->emote (
            channel => $message->{channel},
            body => "hugs $message->{who}",
        );
    }
    elsif ($message->{body} =~ /^slaps $self->{nick}$/i) {
        $self->emote (
            channel => $message->{channel},
            body => "slaps $message->{who} around the channel",
        );
    }
}

sub chanpart {
    my ($self, $message) = @_;
    our $admins;
    my $i = 0;
    foreach(@admins) {
        if ($admins[$i] eq $message->{who}) {
            delete $admins[$i];
        }
        else {
            $i++;
        }
    }
}

#run bot

my $irc = InternetRelayCat->new(
    server    => "elser.de.libertirc.net",
    channels  => [ $channel ],
    nick      => "serverkitty",
    username  => "cat",
    name      => "Internet Relay Cat",
    charset   => "utf-8",
);

$irc->run();

# vim: set sw=4 tw=0 ts=4 foldmethod=indent expandtab:
