package AnyEvent::K;
BEGIN {
    $AnyEvent::K::VERSION = '0.01';
}
use Moose;
use namespace::autoclean;
use AnyEvent;
use Try::Tiny;

extends 'K';

has reader => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_build_reader',
    lazy_build => 1,
);

sub _build_reader {
    my ($self) = @_;

    return AnyEvent->io( fh => $self->handle, poll => 'r', cb => sub {
        try {
            $self->on_recv( $self->recv );
        }
        catch {
            $self->clear_reader;
            $self->clear_handle;
            $self->on_recv(undef, $_);
        };
    });
}

has recv_cb => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_recv_cb',
);

sub on_recv {
    my ($self, $msg, $err) = @_;

    confess 'Message received but no recv_cb is defined'
        if !$self->has_recv_cb;

    $self->recv_cb->($msg, $err);

    return;
}

override 'cmd' => sub {
    confess q/cmds that want responses aren't supported yet/;
};

sub BUILD {
    my ($self) = @_;

    $self->reader;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

AnyEvent::K - Non-blocking API for talking to K / Q / KDB

=head1 SYNOPSIS

    my $aek = AnyEvent::K->new(
        host     => 'kserver.example.com',
        port     => 5000,
        user     => 'awhitney',
        password => 'kdb4eva',

        # run whenever a message is received
        recv_cb  => sub {
            my ($msg, $err) = @_;
            say 'I got a msg!';
        };
    );

    # no response expected
    $aek->async_cmd('.u.upd[`t1; (`foo; 1.23)]');

    # response expected (not yet implemented)
    $aek->cmd('2 + 5', sub {
        my ($resp, $err) = @_;
        confess $err if $err;
        say 'I got a response!';
    });

    EV::loop();

    #
    # or
    #

    package My::Listener;
    use Moose;
    extends 'AnyEvent::K';

    # run whenever a message is received
    override on_recv => {
        my ($msg, $err) = @_;
        confess $err if $err;
        say 'I got a response!';
    };

    package main;
    my $listener = My::Listener->new(...);
    EV::loop();

=head1 DESCRIPTION

C<AnyEvent::K> is a subclass of L<K>.  It has a similar interface except that
none of its methods block.  This lets you do other things while waiting for
messages or responses to arrive.

=head1 SEE ALSO

L<K>, L<http://kx.com>

=head1 REPOSITORY

L<http://github.com/wjackson/anyevent-k>

=head1 AUTHORS

Whitney Jackson C<< <whitney@cpan.org> >>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011 Whitney Jackson. All rights reserved This program is
    free software; you can redistribute it and/or modify it under the same
    terms as Perl itself.

=cut
