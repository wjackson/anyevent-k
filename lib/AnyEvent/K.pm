package AnyEvent::K;

use Moose;
use namespace::autoclean;

extends 'K';

has reader => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_build_reader',
);

sub _build_reader {
    my ($self) = @_;

    return AnyEvent->io( fh => $self->handle, poll => 'r', cb => sub {
        $self->on_recv( $self->recv );
    });
}

has recv_cb => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_recv_cb',
);

sub on_recv {
    my ($self, $msg) = @_;

    confess 'Message received but no recv_cb is defined'
        if !$self->has_recv_cb;

    $self->recv_cb->($msg);

    return;
}

override 'cmd' => sub {
    confess q/cmds that want responses aren't supported yet/;
};

__PACKAGE__->meta->make_immutable;
1;
