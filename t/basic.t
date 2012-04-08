use strict;
use warnings;
use Test::More;
use List::MoreUtils qw/all/;
use AnyEvent;
use Time::HiRes;
use t::QServer;

test_qserver {
    my $port = shift;

    use_ok 'AnyEvent::K';

    my $cv = AE::cv;

    my $aek = new_ok 'AnyEvent::K' => [
        port    => $port,
        recv_cb => sub {
            my ($msg) = @_;
            $cv->send($msg);
        },
    ];

    # have q send us a msg in 50 ms
    $aek->async_cmd(q/system"t 50"/);
    $aek->async_cmd(q/.z.ts: { h:first key .z.W; (neg h)[(1;2;3)] }/);

    # do some work while we're waiting for q to get in touch
    my @work;
    my $w = AnyEvent->timer(
        after    => .010,
        interval => .010,
        cb       => sub { push @work, Time::HiRes::time },
    );

    my ($msg, $err) = $cv->recv;
    my $msg_time    = Time::HiRes::time;
    is_deeply $msg, [1, 2, 3], 'recv message';

    $aek->async_cmd(q/system"t 0"/);

    # check on the work that was done before the msg arrived
    is scalar(@work), 5, 'work 5 times while waiting';
    ok all(sub { $_ < $msg_time }, @work), 'work before msg';
};

END { done_testing; }
