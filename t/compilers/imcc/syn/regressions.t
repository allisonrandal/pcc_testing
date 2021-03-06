#!perl
# Copyright (C) 2008-2009, Parrot Foundation.
# $Id$

use strict;
use warnings;
use lib qw( . lib ../lib ../../lib );
use Test::More;
use Parrot::Test tests => 17;

pir_error_output_like( <<'CODE', <<'OUT', 'invalid get_results syntax');
.sub main :main
    get_results '(0)'
.end
CODE
/syntax error/
OUT

pir_output_is( <<'CODE', <<'OUT', 'cannot constant fold div by 0');
.sub fold_by_zero
  push_eh ok1
    $I1 = 1/0
  pop_eh
  print "not "
 ok1:
  say "ok 1 - caught div_i_ic_ic exception"

  push_eh ok2
    $N1 = 1.0/0.0
  pop_eh
  print "not "
 ok2:
  say "ok 2 - caught div_n_nc_nc exception"
.end
CODE
ok 1 - caught div_i_ic_ic exception
ok 2 - caught div_n_nc_nc exception
OUT

pir_output_is( <<'CODE', <<'OUT', 'comments before .param(TT #1035)');
.sub main :main
  comments(1,2)
.end
.sub comments
  # Testing
  .param pmc a
  .param pmc b
  say 'hello'
.end
CODE
hello
OUT

pir_output_is( <<'CODE', <<'OUT', 'comments between .param(TT #1035)', todo => 'broken');
.sub main :main
  comments(1,2)
.end
.sub comments
  .param pmc a
  # Testing
  .param pmc b
  say 'hello'
.end
CODE
hello
OUT

pir_output_is( <<'CODE', <<'OUT', 'whitespace before .param(TT #1035)');
.sub main :main
  comments(1,2)
.end
.sub comments

  .param pmc a
  .param pmc b
  say 'hello'
.end
CODE
hello
OUT

pir_output_is( <<'CODE', <<'OUT', 'whitespace between .param(TT #1035)', todo => 'broken');
.sub main :main
  comments(1,2)
.end
.sub comments
  .param pmc a

  .param pmc b
  say 'hello'
.end
CODE
hello
OUT

pir_error_output_like( <<'CODE', <<'OUT', 'off by one error message (TT #1016)', todo=>'broken');
.sub foo :main
  $P0 = new 'Hash'
  $P1 = $P0['x']
  unless $P1 goto no
  print "yes\n"
no:
.end
CODE
/(?s:Null PMC access in get_bool.*current instr.*:4\))/
OUT

pir_error_output_like( <<'CODE', <<'OUT', 'bare method names not allowed (RT #45859)');
.sub foo :main
  $P0 = new 'String'
  $P0 = 'HI'
  $P0.lower()
  say $P0
.end
CODE
/Bareword method name 'lower' not allowed/
OUT

pir_error_output_like( <<'CODE', <<'OUT', ':: not allowed in identifiers (RT #48735)');
.sub foo :main
  .local string a::b
  a::b = 'HI' 
  say a::b
.end
CODE
/syntax error/
OUT

pir_output_is( <<'CODE', <<'OUT', 'unicode lexical identifiers (TT #575)');
 .sub main :main
    $P0 = box 'hello world'
    .lex unicode:"$\u03b2\u03bf\u03bf", $P0

    $P1 = find_lex unicode:"$\u03b2\u03bf\u03bf"
    say $P1
 .end
CODE
hello world
OUT

pir_output_is( <<'CODE', <<'OUT', 'unicode named identifiers (TT #654)');
 .sub 'main' :main
    'foo'(1 :named(unicode:"\x{e4}"))
 .end

 # Perl 6:  sub foo(:$ä) { say "ok $ä"; }
 .sub 'foo'
    .param int x :named(unicode:"\x{e4}")
    print "ok "
    say x
 .end
CODE
ok 1
OUT

my $register = "9" x 4096;
pir_output_is( <<"CODE", <<'OUT', 'long register numbers in PIR (TT #1025)');
.sub main
      \$P$register = new 'Integer'
      \$P$register = 3
  say \$P$register
.end
CODE
3
OUT

TODO: {
    local $TODO = "works in PIR, not PASM";

pasm_output_is( <<"CODE", <<'OUT', 'long register numbers in PASM (TT #1025)');
      new P$register, 'Integer'
      assign P$register, 3
  say P$register
CODE
3
OUT

}

TODO: {
    local $TODO = 'Broken with CGP'
        if defined $ENV{TEST_PROG_ARGS}
        &&         $ENV{TEST_PROG_ARGS} =~ /--run-pbc/;

pir_error_output_like( <<'CODE', <<'OUT', 'die in immediate, TT #629');
.sub 'foo' :immediate
  die 'no'
.end
CODE
/no\ncurrent inst.*:[\d-]+\)$/
OUT

}

pir_error_output_like( <<'CODE', <<'OUT', 'No segfault from syntax error, RT #60172');
.sub 'main'
    ($S0) = 'blah'(:pir_only=>1)
.end
CODE
/syntax error.+unexpected/
OUT

SKIP: {
    skip( 'Hang on Linux i386 and amd64', 1 );
pir_output_like( <<'CODE', <<'OUT', 'Segfault, TT #1027', todo=>'segfaulting');
.sub main :main
push_eh handler
test()
## NB: This makes sure the sub call PC is sufficiently
## different from the exception handler PC.
print "foo\n"
print "bar\n"
.return ()
handler:
.local pmc exception
.local string message
.get_results (exception, message)
print "Error: "
print message
.end

.sub test
## Throw an exception.
$P0 = new 'Exception'
$P0 = 'oops'
throw $P0
.end
CODE
/.*/
OUT
}

# We shouldn't crash (and valgrind shoudn't report invalid reads)
pir_output_is( <<'CODE', <<'OUT', 'exit is last op in sub (TT#1009)');
.sub main :main
    exit 0
.end
CODE
OUT




# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
