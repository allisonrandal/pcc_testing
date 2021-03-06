# $Id$

=head1 TITLE

Stream;Sub - a PIR sub as source for a Stream

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    # create the stream
    new stream, ['Stream'; Sub']

    # set the source sub
    .const 'Sub' temp = "_test"
    stream."source"( temp )

    ...

    .sub _test :method
	self."write"( "hello, world" )
    .end

=head1 DESCRIPTION

Like every stream, Stream;Sub as has a C<read> method.
The benefit is that this stream also has a C<write> method, though it
can not be called from arbitrary locations.

You have to provide a Sub PMC that gets called when you call C<read> for the
first time. This sub gets the stream passed in as P2 ("self" if you declare it
as a method). You can pass it to other functions if you want.
Arguments passed to read on its first invokation are forwarded to the sub you
provide. This invokation looks like a method call, but it isn't one from a
technical point of view.

This special "method" can call C<write>, which will internally create a
Continuation to return to the current execution point when read is called the
next time. The C<read> method creates a continuation before invoking the
provided sub or the continuation captured by the write method. C<read>'s
continuation is used to return the string parameter passed to C<write> as the
return value of the read method.
The parameters passed to C<read> will be the return values of C<write()>.

So, if you call the C<read> method, a part of the provided sub will be run,
until it calls the C<write> method. At this point, the original program
execution will continue, until you call the C<read> method again, which will
run the next part of your sub.

The stream will be disconnected automatically if the provided sub returns.

=cut

.sub onload :load :anon
    .local int i
    .local pmc base
    .local pmc sub

    $P0 = get_class ['Stream'; 'Sub']
    unless null $P0 goto END

    load_bytecode 'Stream/Base.pbc'

    get_class base, ['Stream'; 'Base']
    subclass sub, base, ['Stream'; 'Sub']

    addattribute sub, "write_cont"
END:
.end

.namespace ['Stream'; 'Sub']

=head1 METHODS

=over 4

=cut

=item source."write"()

...

=cut

.sub write :method
    .param string str
    .local pmc _write
    .local pmc ret

    getattribute _write, self, 'write_cont'

    $P0 =self."_call_writer"(_write, str)
.end

.sub _call_writer :method
    .param pmc writer
    .param string str
    .local pmc cont
.include "interpinfo.pasm"
    cont = interpinfo .INTERPINFO_CURRENT_CONT
    assign self, cont
    writer(str)
.end

=item source."rawRead"() (B<internal>)

...

=cut

.sub rawRead :method
    .local pmc temp
    .local string str

    temp = self."source"()
    $I0 = defined temp
    unless $I0 goto END
    .include "interpinfo.pasm"
    $P0 = interpinfo .INTERPINFO_CURRENT_CONT
    setattribute self, 'write_cont', $P0

    str = temp( self )

    # sub exited, delete source
    null temp
    self."setSource"( temp )

    # write null-string to terminate the read request
TERMINATED:
    null str
    self."write"( str )
    # if we are here,
    # someone tried to read again, just return null again
    branch TERMINATED

END:
    # return a null string to indicate end of stream
    null str

    .return(str)
.end

=back

=head1 AUTHOR

Jens Rieks E<lt>parrot at jensbeimsurfen dot deE<gt> is the author
and maintainer.
Please send patches and suggestions to the Perl 6 Internals mailing list.

=head1 COPYRIGHT

Copyright (C) 2004-2009, Parrot Foundation.

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
