# $Id$

=head1 NAME

NCIPIR::Compiler - NCI PIR Compiler for NCIGENAST trees.

=head1 DESCRIPTION

NCIPIR::Compiler defines a compiler that converts a NCIGENAST tree into PIR

=head1 METHODS

=over

=cut

.namespace [ 'NCIPIR';'Compiler' ]

.sub '__onload' :load :init
    .local pmc p6meta, cproto
    p6meta = new 'P6metaclass'
    cproto = p6meta.'new_class'('NCIPIR::Compiler', 'parent'=>'PCT::HLLCompiler', 'attr'=>'$!code')
    cproto.'language'('NCIPIR')
    $P1 = split ' ', 'pir evalpmc'
    cproto.'stages'($P1)

    $P0 = new 'String'
    set_global '$?NAMESPACE', $P0
    .return ()
.end


.sub 'to_pir' :method
    .param pmc ast
    .param pmc adverbs         :slurpy :named

    .local pmc newself
    newself = new ['NCIPIR';'Compiler']

    ##  start with empty code
    .local pmc code
    code = new 'CodeString'
    newself.'code'(code)

    ##  if the root node isn't a Sub, wrap it
    $I0 = isa ast, ['NCIGENAST';'Decls']
    if $I0 goto have_sub
    $P0 = get_hll_global ['NCIGENAST'], 'Decls'
    ast = $P0.'new'(ast, 'name'=>'anon')
  have_sub:

    .local string raw

    raw = adverbs['raw']
    if raw goto Lgenpir
    $P0 = newself.'gen_preamble'(adverbs :flat :named)
  Lgenpir:
    ##  now generate the pir
    newself.'pir'(ast)

    ##  and return whatever code was generated
    .tailcall newself.'code'()
.end

.sub 'gen_preamble' :method
    .param pmc adverbs         :slurpy :named
    .local string nsname
    .local string libname
    .local string fmt

    nsname = adverbs['nsname']
    libname = adverbs['libname']

fmt = <<'FMT'
.namespace ['%n']
.sub __load_lib_dlfunc_init__ :anon :init :load
FMT

    .local pmc code
    code = new 'CodeString'
    code.'emit'(fmt, 'n'=>nsname)
    if null libname goto LNOLIBNAME
fmt = <<'FMT'
loadlib $P1, '%l'
if $P1 goto has_lib
FMT
    goto LEMITLIBNAME
  LNOLIBNAME:
fmt = <<'FMT'
$P1 = null
goto has_lib
FMT
  LEMITLIBNAME:
    code.'emit'(fmt, 'l'=>libname)


fmt = <<'FMT'
$P2 = new 'Exception'
$P2[0] = 'error loading %l - loadlib failed'
throw $P2
has_lib:
FMT
    code.'emit'(fmt, 'l'=>libname)
    $P0 = self.'code'()
    $P0 .= code
    .return(code)
.end


=item code([str])

Get/set the code generated by this compiler.

=cut

.sub 'code' :method
    .param pmc code            :optional
    .param int has_code        :opt_flag

    if has_code goto set_code
    code = getattribute self, '$!code'
    .return (code)
  set_code:
    setattribute self, '$!code', code
    .return (code)
.end


=item pir_children(node)

Return generated PIR for C<node> and all of its children.

=cut

.sub 'pir_children' :method
    .param pmc node
    .local pmc code, it
    code = new 'CodeString'
    it   = iter node
  iter_loop:
    unless it goto iter_end
    .local string key
    .local pmc cast
    key = shift it
    cast = node[key]
    $P0 = self.'pir'(cast)
    code .= $P0
    goto iter_loop
  iter_end:
    .return (code)
.end


=item pir(Any node)

Return generated pir for any POST::Node.  Returns
the generated pir of C<node>'s children.

=cut

.sub 'pir' :method :multi(_,_)
    .param pmc node
    .local string code
    code = self.'pir_children'(node)
    $P0 = self.'code'()
    $P0 .= code
    .return ($P0)
.end


=item pir(POST::Op node)

Return pir for an operation node.

=cut

.sub 'pir' :method :multi(_,['NCIGENAST';'FuncDecl'])
    .param pmc node

    ##  get list of arguments to operation
    .local pmc arglist
    arglist = node.'list'()

    .local string fmt, name, type
    type = param_to_code(node, 1)

    .local pmc itera
    .local pmc param
    iter itera, arglist
    LIS:
    unless itera, LI0
    param = shift itera
    $S0 = param_to_code(param)
    #say $S0
    type .= $S0
    goto LIS

    LI0:
    name = node.'name'()
    fmt = "dlfunc $P2, $P1, '%n', '%s'\nstore_global '%n', $P2"

    #$S0 = "##"
    #$S1 = node.'attr'('source', '', 0)
    #$S0 .= $S1
    #print $S0

    .local pmc code
    code = new 'CodeString'
    code.'emit'(fmt, 's'=>type, 'n'=>name)
    #$S0 = code
    #say $S0

    .return (code)
.end

.sub 'param_to_code'
  .param pmc node
  .param int returncode :optional
  $I0 = node.'pointer'()
  $I2 = node.'pointer_cnt'()
  $S0 = node.'primitive_type'()


  if $I0, LPOINTER

  iseq $I1, $S0, 'void'
  unless $I1, LL2
  if returncode, LL11
    .return("")
  LL11:
    .return("v")
  LL2:
  iseq $I1, $S0, 'int'
  unless $I1, LL3
    .return("i")
  LL3:
  iseq $I1, $S0, 'long'
  unless $I1, LL4
    .return("l")
  LL4:
  iseq $I1, $S0, 'char'
  unless $I1, LL5
    .return("c")
  LL5:
  iseq $I1, $S0, 'short'
  unless $I1, LL6
    .return("s")
  LL6:
    .return("p")

  LPOINTER:
  isgt $I3, $I2, 1
  if $I3, LL18 # pointer_cnt > 1

  iseq $I1, $S0, 'void' #void *
  unless $I1, LL7
  if returncode, LL111
    .return("p")
  LL111:
    .return("p")
#    .return("V") #probably should be this
  LL7:
  iseq $I1, $S0, 'char' #char *
  unless $I1, LL8
    .return("t")
  LL8:
  iseq $I1, $S0, 'int' #int *
  unless $I1, LL13
    .return("V")
  LL13:
  iseq $I1, $S0, 'long' #long *
  unless $I1, LL14
    .return("V")
  LL14:
  iseq $I1, $S0, 'short' #short *
  unless $I1, LL15
    .return("V")
  LL15: #struct *, typedef *,
    say "ERROR"
    say $S0
    say "what is this"
    .return("p")

#something **
  LL18:
    .return("V")
.end

=item pir(POST::Label node)

Generate a label.

=cut

.sub 'pir' :method :multi(_, ['NCIGENAST';'TypeDef'])
    .param pmc node
    .return ('')
    .tailcall pir_dump(node)
.end

=item pir(POST::Label node)

Generate a label.

=cut

.sub 'pir' :method :multi(_, ['NCIGENAST';'VarDecl'])
    .param pmc node
    .return ('')
    .tailcall pir_dump(node)
.end

=item pir(POST::Label node)

Generate a label.

=cut

.sub 'pir_dump'
    .param pmc node
    .local string code
    code = '#'
    code .= 'typedef '
    $S0 = node.'type'()
    code .= $S0
    code .= ' '
    $S0 = node.'name'()
    code .= $S0
    $S0 = node.'builtin_type'()
    unless $S0 goto LN1
    code .= ' builtin '
    code .= $S0
  LN1:
    $S0 = node.'pointer'()
    unless $S0 goto LN2
    code .= ' pointer '
    code .= $S0
  LN2:
    code .= ":\n"
    print code
    .return ('')
.end


=back

=head1 AUTHOR

Patrick Michaud <pmichaud@pobox.com> is the author and maintainer.
Please send patches and suggestions to the Parrot porters or
Perl 6 compilers mailing lists.

=head1 HISTORY

2007-11-21  Significant refactor as part of Parrot Compiler Toolkit

=head1 COPYRIGHT

Copyright (C) 2006-2008, Parrot Foundation.

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir: