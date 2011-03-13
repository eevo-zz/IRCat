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
$defaultchan = "#0x7c0.org";
$takeover = "26dedb51f78f282d5a7dd693454c3756";
@admins = ("eevo");

sub hug {
    my ($self, $sender) = @_;
    $self->emote(
        channel => $defaultchan,
        body => "hugs $sender",
    );
}

sub handle_command {
    our $phrases;
    our $admins;
    our $defaultchan;
    my $self = shift;
    my $body = shift;
    my $sender = shift;
    if ($body =~ /^!hug/) {
        hug($self, $sender);
    }
    elsif ($body =~ /^!help/) {
        return "Nobody's going to help you."
    }
    elsif ($body =~ /^!add/) {
    if (grep {m|^$sender?$|} @admins) {
        $body =~ s/^!add //;
        my @args = split(" ",$body);
        my $name = shift(@args);
        my $phrase = join(" ", @args);
        if ($phrases{$name}) {
            return "$name already exists!";
        }
        else {
            $phrases{$name} = $phrase;
            return "Meow!";
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
        $body =~ s/^!admin//;
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
    elsif ($message->{channel} eq "msg") {
        my @body = split(" ", $message->{body});
        my $cmd = shift(@body);
        my $args = join(" ", @body);
        if ($cmd eq "takeover") {
            if ($args eq $takeover) {
                if (grep {m|^$message->{who}?$|} @admins) {
                    return "No need to take over, you're an admin!";
                }
                else {
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
    }
}


sub emoted {
    my ($self, $message) = @_;
    if ($message->{body} =~ /^hugs $self->{nick}$/) {
        hug($self, $message->{who});
    }
}

my $bot = InternetRelayCat->new(
    server    => "elser.de.libertirc.net",
    channels  => [ $defaultchan ],
    nick      => "IRCat",
    username  => "ircat",
    name      => "Internet Relay Cat",
    charset   => "utf-8",
);
$bot->run();

# vim: set sw=4 tw=0 ts=4 expandtab: