# Copyright (C) 2001-2003, Parrot Foundation.
# $Id$

=head1 NAME

t/configure/testlib/init/kappa.pm - Module used in configuration tests

=cut

package init::kappa;
use strict;
use warnings;

use base qw(Parrot::Configure::Step);

sub _init {
    my $self = shift;
    my %data;
    $data{description} = 'Determining if your computer does kappa';
    $data{args}        = [  ];
    $data{result}      = q{};
    return \%data;
}

sub runstep {
    my ( $self, $conf ) = @_;
    return 1;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4: