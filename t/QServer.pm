package t::QServer;
use strict;
use warnings;
use Test::More;
use Test::TCP;
use File::Which qw(which);

use base qw(Exporter);
our @EXPORT = qw(test_qserver);

sub test_qserver(&;$) {
    my $cb        = shift;
    my $args      = shift;

    my $q = which 'q';
    unless ($q && -e $q && -x _) {
        plan skip_all => 'q not found in your PATH';
        return;
    }

    test_tcp
        server => sub {
            my $port = shift;
            open STDOUT, '>', '/dev/null' or die q/Can't redirect STDOUT/;
            open STDERR, '>', '/dev/null' or die q/Can't redirect STDERR/;
            exec 'q', '-p', $port;
        },
        client => sub {
            my $port = shift;
            $cb->($port);
        };
}

1;
