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

our %phrases;
our @admins;
our $takeover;
our $defaultchan;
$defaultchan = "#bottest";
$takeover = "password"; #rescue your bot if someone has deleted you from the admin list
@admins = ("admin"); #add default admin nicks

sub hug {
    our $defaultchan;
    my ($self, $sender) = @_;
    $self->emote(
        channel => $defaultchan,
        body => "hugs $sender",
    );
}

sub help {
    return "Nobody's going to help you."
}

sub handle_command {
    our $phrases;
    our $admins;
    our $defaultchan;
    my $self = shift;
    my $body = shift;
    my $sender = shift;
    if ($body =~ /^!pad/) {
        return "http://typewith.me/ep/pad/newpad";
    }
    if ($body =~ /^!hug/) {
        hug($self, $sender);
    }
    elsif ($body =~ /^!help/) {
        return help();
    }
    elsif ($body =~ /^!add/) {
    if (grep {m|^$sender?$|} @admins) {
        $body =~ s/^!add //;
        my @args = split(" ",$body);
        my $name = shift(@args);
        my $phrase = join(" ", @args);
        if ($phrase) {
            if ($phrases{$name}) {
                return "$name already exists!";
            }
            else {
                $phrases{$name} = $phrase;
                return "Meow!";
            }
        }
    }
    }
    elsif ($body =~ /^!del/) {
    if (grep {m|^$sender?$|} @admins) {
        $body =~ s/^!del //;
        if ($phrases{$body}) {
            delete $phrases{$body};
            return "Meow!";
        }
        else {
            return "$body doesn't exist!";
        }
    }
    }
    elsif ($body =~ /^!admin/) {
    if (grep {m|^$sender?$|} @admins) {
        $body =~ s/^!admin //;
        my @args = split(" ", $body);
        my $command = shift(@args);
        my $cmdargs = join(" ", @args);
        if ($command eq "add") {
            if (grep {m|^$cmdargs?$|} @admins) {
                return "$cmdargs is already an admin.";
            }
            else {
                push(@admins, $cmdargs);
                return "$cmdargs added to the admin list.";
            }
        }
        elsif ($command eq "list") {
            my $temp = join(", ", @admins);
            return "Admins: $temp"
        }
        elsif ($command eq "del") {
            if (scalar(@admins) > "1") {
                my $i = 0;
                foreach(@admins) {
                    if ($admins[$i] eq $cmdargs) {
                        delete $admins[$i];
                        return "$cmdargs deleted from the admin list.";
                        last;
                    }
                    else {
                        $i++;
                    }
                }
            }
            else {
                return "Won't delete last admin."
            }
        }
        elsif ($command eq "quit") {
            $self->shutdown("Bye.");
        }
    }
    }
    else {
        $body =~ s/^!//;
        my @args = split(" ",$body);
        my $phrase = shift(@args);
        if ($phrases{$phrase}) {
            my @splitphrase = split(" ", $phrases{$phrase});
            my $argcount = 0;
            foreach(@splitphrase) {
                if ($_ =~ /^\%$argcount$/) {
                    $argcount++;
                }
            }
            if (scalar(@args) >= $argcount) {
                my $curphrase = $phrases{$phrase};
                my $i = 0;
                foreach(@args) { #replace arguments with their values
                    my $curarg = $args[$i];
                    $curphrase =~ s/\%$i/$curarg/g;
                    $i++;
                }
                $curphrase =~ s/\%s/$sender/g; #replace %s with $sender
                $curphrase =~ s/\%\d//g; #strip remaining arguments (shouldn't happen)
                return $curphrase;
            }
        }
    }
}

sub said {
    my ($self, $message) = @_;
    our $takeover;
    our $admins;
    our $defaultchan;
    if ($message->{body} =~ /^!/) {
        return handle_command($self, $message->{body}, $message->{who});
    }
    elsif ($message->{address}) {
        if ($message->{body} =~ /\*hug[s]?\*/) {
           hug($self, $message->{who});
       }
    }
    if ($message->{channel} eq "msg") {
        my @body = split(" ", $message->{body});
        my $cmd = shift(@body);
        my $args = join(" ", @body);
        if ($cmd eq "takeover") {
            if ($args eq $takeover) {
                if (grep {m|^$message->{who}?$|} @admins) {
                    return "No need to take over, you're an admin!";
                }
                else {
                    my $i = 0;
                    foreach(@admins) {
                        delete $admins[$i];
                        $i++;
                    }
                    push(@admins, $message->{who});
                    $self->say(
                        channel => $defaultchan,
                        body => "$message->{who} took control!",
                    );
                    return "Takeover successful!";
                }
            }
        }
        elsif ($cmd eq "say") {
            if (grep {m|^$message->{who}?$|} @admins) {
                $self->say(
                    channel => $defaultchan,
                    body => $args,
                );
            }
        }
        elsif ($cmd eq "emote") {
            if (grep {m|^$message->{who}?$|} @admins) {
                $self->emote(
                    channel => $defaultchan,
                    body => $args,
                );
            }
        }
    }
}


sub emoted {
    my ($self, $message) = @_;
    if ($message->{body} =~ /^hugs $self->{nick}$/) {
        hug($self, $message->{who});
    }
}

my $bot = InternetRelayCat->new(
    server    => "irc.freenode.net",
#    ssl       => 1,
#    port      => "6697",
    channels  => [ $defaultchan ],
    nick      => "serverkitty",
    username  => "cat",
    name      => "Internet Relay Cat",
    charset   => "utf-8",
);
$bot->run();

# vim: set sw=4 tw=0 ts=4 expandtab:
