#! parrot
# Copyright (C) 2001-2009, Parrot Foundation.
# $Id$

=head1 NAME

t/pmc/fixedpmcarray.t - FixedPMCArray PMC

=head1 SYNOPSIS

    % prove t/pmc/fixedpmcarray.t

=head1 DESCRIPTION

Tests C<FixedPMCArray> PMC. Checks size, sets various elements, including
out-of-bounds test. Checks INT and PMC keys.

=cut

.sub main :main
    .include 'test_more.pir'
    plan(76)
    test_setting_array_size()
    test_assign_from_another()
    test_assign_self()
    test_assign_non_array()
    test_resize_exception()
    test_truthiness()
    test_tt991()
    test_setting_first_elem()
    test_setting_second_elem()
    test_negative_index()
    test_oob_elem()
    test_set_pmc_keys_access_ints()
    test_set_ints_access_pmc_keys()
    test_interface()
    test_get_uninitialized()
    test_get_null_elem()
    test_definedness()
    test_splice_oob()
    test_get_repr()
    test_elements()
    test_equality()
    test_multi_keys()
    test_splice()
    test_sort()
    test_exists()
.end

.sub test_exists
    .local pmc fpa
    fpa = new ['FixedPMCArray']
    fpa = 5
    $I0 = exists fpa[3]
    nok($I0,'FixedPMCArray element existence')
    fpa[2] = 42
    $I0 = exists fpa[2]
    ok($I0,'FixedPMCArray element existence')

    new $P1, ['Key']
    set $P1, 0
    fpa[$P1] = 99
    $I0 = exists fpa[$P1]
    ok($I0,'FixedPMCArray element existence')
.end

.sub test_sort
     .local pmc compares, cmp_fun
     # RT #46855 doesnt work wit prederef of JIT
     bounds 1
     compares = new ['Integer']
     compares = 0
     set_global "compares", compares
     cmp_fun = get_global "cmp_fun"
     sort_ar()
     sort_ar(cmp_fun)
.end

# this is used by test_sort
.sub sort_ar
    .param pmc cmp_fun :optional
    .local pmc compares
    compares = get_global "compares"
    compares = 0
    .local pmc array
    array = new ['FixedPMCArray']
    array = 5
    array[0] = 10
    array[1] = 2
    array[2] = 5
    array[3] = 9
    array[4] = 1
    array."sort"(cmp_fun)
    ok(1,'call sort on FixedPMCArray')

    .local pmc test1
    test1 = new ['FixedPMCArray']
    test1 = 5
    test1[0] = 1
    test1[1] = 2
    test1[2] = 5
    test1[3] = 9
    test1[4] = 10

    is_deeply( array, test1 )

.end

# this is used by test_sort
.sub cmp_fun
    .param pmc a
    .param pmc b
    $I0 = cmp a, b
    .local pmc compares
    compares = get_global "compares"
    inc compares
    .begin_return
    .set_return $I0
    .end_return
.end

.sub test_splice
    .local pmc one
    .local pmc test1, test2, test3
    one = new ['Integer']
    one = 1

    .local pmc fpa
    fpa = new ['FixedPMCArray']
    fpa = 5

    splice fpa, one, 0, 5
    test1 = new ['FixedPMCArray']
    test1 = 5
    test1[0] = 1
    test1[1] = 1
    test1[2] = 1
    test1[3] = 1
    test1[4] = 1

    is_deeply(fpa, test1 )

    .local pmc two
    two = new ['Integer']
    two = 2

    splice fpa, two, 1, 3
    test2 = new ['FixedPMCArray']
    test2 = 5
    test2[0] = 1
    test2[1] = 2
    test2[2] = 2
    test2[3] = 2
    test2[4] = 1
    is_deeply(fpa, test2 )

    .local pmc three
    three = new ['Integer']
    three = 3

    splice fpa, three, 2, 3
    test3 = new ['FixedPMCArray']
    test3 = 5
    test3[0] = 1
    test3[1] = 2
    test3[2] = 3
    test3[3] = 3
    test3[4] = 3
    is_deeply(fpa, test3 )
.end

.sub test_multi_keys
    .local pmc    matrix, row
    .local pmc    elem_in_pmc
    .local pmc    elem_out_pmc
    .local int    elem_out_int
    .local num    elem_out_num
    .local string elem_out_string

    matrix = new ['FixedPMCArray']
    matrix = 1
    row = new ['FixedPMCArray']
    row = 4           # set the size by assigning an integer, number or pmc
    matrix[0] = row
    matrix[0;0] = 128
    matrix[0;1] = 128.128
    elem_in_pmc = new ['Integer']
    elem_in_pmc = 256
    matrix[0;2] = elem_in_pmc
    matrix[0;3] = "asdf"

    elem_out_int = matrix[0;0]
    is(elem_out_int,128)

    elem_out_pmc = matrix[0;0]
    is(elem_out_pmc,128)

    elem_out_num = matrix[0;0]
    is(elem_out_num,128)

    elem_out_string = matrix[0;0]
    is(elem_out_string,128)

    elem_out_pmc = matrix[0;1]
    is(elem_out_pmc,"128.128")

    elem_out_num = matrix[0;1]
    is(elem_out_num,"128.128")

    elem_out_string = matrix[0;1]
    is(elem_out_string,"128.128")

    elem_out_int = matrix[0;2]
    is(elem_out_int,256)

    elem_out_pmc = matrix[0;2]
    is(elem_out_pmc,256)

    elem_out_num = matrix[0;2]
    is(elem_out_num,256)

    elem_out_string = matrix[0;2]
    is(elem_out_string,256)

    elem_out_int = matrix[0;0]
    is(elem_out_int,128)

    elem_out_pmc = matrix[0;0]
    is(elem_out_pmc,128)

    elem_out_num = matrix[0;0]
    is(elem_out_num,128)

    elem_out_string = matrix[0;0]
    is(elem_out_string,128)

.end

.sub test_equality
    .local pmc fpa1, fpa2, p1, p2
    .local int i
    fpa1 = new ['FixedPMCArray']
    fpa2 = new ['FixedPMCArray']

    is(fpa1,fpa2)

    fpa1 = 3
    isnt(fpa1,fpa2)

    fpa2 = 3

    p1 = new ['String']
    p1 = "foobarx"
    p2 = new ['String']
    p2 = "foobarx"

    fpa1[0] = p1
    fpa2[0] = p2

    is(fpa1,fpa2)

    p1 = new ['String']
    p2 = new ['String']
    p1 = ''
    p2 = ''

    fpa1[1] = p1

    isnt(fpa1,fpa2)

    fpa2[1] = p2

    is(fpa1,fpa2)

.end

.sub test_elements
    .local pmc arr1
    .local int elems_i
    .local num elems_f
    arr1 = new ['FixedPMCArray']
    arr1 = 0
    elems_i = elements arr1
    is(elems_i,0)

    elems_i = arr1
    is(elems_i,0)

    elems_f = arr1
    is(elems_f,0)

    arr1 = new ['FixedPMCArray']
    arr1 = 2048
    elems_i = elements arr1
    is(elems_i,2048)

    elems_i = arr1
    is(elems_i,2048)

    elems_f = arr1
    is(elems_f,2048)
.end

.sub test_get_repr
    .local string s, aux
    s = get_repr_fpa_n(0)
    aux = get_repr_fpa_n(1)
    concat s, aux
    aux = get_repr_fpa_n(2)
    concat s, aux
    aux = get_repr_fpa_n(3)
    concat s, aux
    like(s,'\(\)\(0\)\(0\,\s*1\)\(0\,\s*1\,\s*2\)','get_repr')
.end

.sub get_repr_fpa_n
    .param int n
    .local int i
    .local pmc fpa, p
    .local string s
    fpa = new ['FixedPMCArray']
    fpa = n
    i = 0
next:
    if i == n goto done
    p = box i
    fpa[i] = p
    inc i
    goto next
done:
    s = get_repr fpa
    .return(s)
.end

.sub test_splice_oob
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds','splice oob, offset 0')
    .sub main
        .local pmc fpa
        fpa = new ['FixedPMCArray']
        fpa = 5

        .local pmc nil
        nil = new ['Undef']

        splice fpa, nil, 0, 6
    .end
CODE
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds','splice oob, big offset')
    .sub main
        .local pmc fpa
        fpa = new ['FixedPMCArray']
        fpa = 5

        .local pmc nil
        nil = new ['Undef']

        splice fpa, nil, 6, 0
    .end
CODE
.end

.sub test_definedness
    .local pmc arr1
    arr1 = new ['FixedPMCArray']
    arr1 = 2005
    .local int defined_elem_1956
    defined_elem_1956 = defined arr1[1956]
    is(defined_elem_1956,0,'definedness')
    arr1[1956] = 42
    defined_elem_1956 = defined arr1[1956]
    is(defined_elem_1956,1,'definedness')
    .local pmc val
    null val
    arr1[1956] = val
    defined_elem_1956 = defined arr1[1956]
    is(defined_elem_1956,0,'definedness')
.end

.sub test_get_null_elem
  .local pmc arr1, n
  .local int i
  .local string s
  arr1 = new ['FixedPMCArray']
  arr1 = 1
  arr1[0] = n
  i = arr1[0]
  is(i,0,'null int is 0')
  s = arr1[0]
  is(s,"",'null string is empty string')
.end

.sub test_get_uninitialized
    throws_like(<<'CODE',':s Null PMC access in name','get uninitialized')
    .sub main
        .local pmc arr1
        arr1 = new ['FixedPMCArray']
        arr1 = 2005
        .local pmc elem_1956
        elem_1956 = arr1[1956]
        .local string type_1956
        type_1956 = typeof elem_1956
        print type_1956
    .end
CODE
.end

.sub test_interface
    .local pmc pmc1
    pmc1 = new ['FixedPMCArray']
    .local int bool1
    does bool1, pmc1, "scalar"
    nok(bool1,'FixedPMCArray does not scalar')
    does bool1, pmc1, "array"
    ok(bool1,'FixedPMCArray does array')
    does bool1, pmc1, "no_interface"
    nok(bool1,'no interface')
.end
.sub test_set_ints_access_pmc_keys
     new $P0, ['FixedPMCArray']
     set $P0, 1024

     set $P0[25], 125
     set $P0[128], 10.2
     set $P0[513], "cow"
     new $P1, ['Integer']
     set $P1, 123456
     set $P0[1023], $P1

     new $P2, ['Key']
     set $P2, 25
     set $I0, $P0[$P2]
     is($I0, 125,'got int with pmc key')

     set $P2, 128
     set $N0, $P0[$P2]
     is($N0,10.2,'got float with pmc key',0.00001)

     set $P2, 513
     set $S0, $P0[$P2]
     is($S0, "cow", 'got string with pmc key')

     set $P2, 1023
     set $P3, $P0[$P2]
     set $I1, $P3
     is($I1, 123456, 'got another int with pmc key')
.end

.sub test_set_pmc_keys_access_ints
     new $P0, ['FixedPMCArray']
     set $P0, 3
     new $P1, ['Key']

     set $P1, 0
     set $P0[$P1], 25

     set $P1, 1
     set $P0[$P1], 2.5

     set $P1, 2
     set $P0[$P1], "bleep"

     set $I0, $P0[0]
     is($I0, 25,'got integer with int lookup')
     set $N0, $P0[1]
     is($N0,2.5,'got float with int lookup',0.00001)

     set $S0, $P0[2]
     is($S0, "bleep",'got string with int lookup')
.end

.sub test_oob_elem
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds\!','set out-of-bounds index')
        .sub main
            new $P0, ['FixedPMCArray']
            set $P0, 1
            set $P0[1], -7
        .end
CODE
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds\!','set out-of-bounds index')
        .sub main
            new $P0, ['FixedPMCArray']
            set $P0, 1
            set $I0, $P0[1]
        .end
CODE

.end

.sub test_negative_index
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds\!','set negative index')
.sub main
    new $P0, ['FixedPMCArray']
    set $P0, 1
    set $P0[-1], -7
.end
CODE
    throws_like(<<'CODE',':s FixedPMCArray\: index out of bounds\!','get negative index')
.sub main
    new $P0, ['FixedPMCArray']
    set $P0, 1
    set $I0, $P0[-1]
.end
CODE

.end

.sub test_setting_second_elem
    new $P0, ['FixedPMCArray']
    set $P0, 2

    set $P0[1],-7
    set $I0,$P0[1]
    is($I0,-7,'set second elem to int')

    set $P0[1],3.7
    set $N0,$P0[1]
    is($N0,3.7,'set second elem to float')

    set $P0[1],"muwhahaha"
    set $S0,$P0[1]
    is($S0,"muwhahaha",'set second elem to string')
.end

.sub test_setting_first_elem
    new $P0, ['FixedPMCArray']
    set $P0, 1

    set $P0[0],-7
    set $I0,$P0[0]
    is($I0,-7,'set first elem to int')

    set $P0[0],3.7
    set $N0,$P0[0]
    is($N0,3.7,'set first elem to float')

    set $P0[0],"muwhahaha"
    set $S0,$P0[0]
    is($S0,"muwhahaha",'set first elem to string')
.end

.sub test_truthiness
    new $P0, ['FixedPMCArray']
    set $P0, 0
    nok($P0,'length 0 FixedPMCArray is falsey')
    set $P0, 1
    ok($P0, 'length 1 FixedPMCArray is truthy')
.end

.sub test_tt991
    throws_like(<<'CODE',':s FixedPMCArray\: Cannot set array size to a negative number','cannot create a negative length array')
        .sub main
            new $P0, ['FixedPMCArray']
            set $P0, -1
        .end
CODE
.end

.sub test_resize_exception
    throws_like(<<'CODE',':s FixedPMCArray\: Can.t resize','cannot resize FixedPMCArray')
        .sub main
            new $P0, ['FixedPMCArray']
            set $I0,$P0
            set $P0,1
            set $P0,2
        .end
CODE

    throws_like(<<'CODE',":s set_number_native.* not implemented in class .*FixedPMCArray", 'cannot use float as length to FixedPMCArray')
        .sub main
            new $P0, ['FixedPMCArray']
            set $P0, 42.0
        .end
CODE

    throws_like(<<'CODE',":s set_string_native.* not implemented in class .*FixedPMCArray", 'cannot use string as length to FixedPMCArray')
        .sub main
            new $P0, ['FixedPMCArray']
            set $P0,"GIGO"
        .end
CODE
.end

.sub test_assign_non_array
    throws_like(<<'CODE', ':s Can.t set self from this type','assign from non-array')
    .sub main
        .local pmc arr, other
        .local int n
        arr = new ['FixedPMCArray']
        other = new ['Integer']
        assign arr, other
    .end
CODE
.end

.sub test_assign_self
    .local pmc arr
    arr = new ['FixedPMCArray']
    assign arr, arr
    ok(1, 'Can assign FixedPMCArray to itself')
.end

.sub test_assign_from_another
    .local pmc arr1, arr2
    .local int n
    arr1 = new ['FixedPMCArray']
    arr1 = 32
    arr2 = new ['FixedPMCArray']
    arr2 = 15
    assign arr1, arr2
    n = arr1
    is(n,15,'assigning to FixedPMCArray from another FixedPMCArray')
.end

.sub test_setting_array_size
    new $P0, ['FixedPMCArray']

    set $I0, $P0
    is($I0,0,'size of new FixedPMCArray is 0')

    set $P0, 1
    set $I0, $P0

    is($I0,1,'size of FixedPMCArray is 1')
.end

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
