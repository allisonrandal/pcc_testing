# Copyright (C) 2001-2007, Parrot Foundation.
# $Id$

=head1 NAME

config/init/defaults.pm - Configuration Defaults

=head1 DESCRIPTION

Sets up the configuration system's default values and data structures.

=cut

package init::defaults;

use strict;
use warnings;

use base qw(Parrot::Configure::Step);

use Config;
use FindBin;    # see build_dir
use Parrot::Configure::Step;
use Parrot::BuildUtil;
use Cwd qw(abs_path);
use File::Spec;


sub _init {
    my $self = shift;
    my %data;
    $data{description} = q{Set Configure's default values};
    $data{result}      = q{};
    return \%data;
}

my $parrot_version = Parrot::BuildUtil::parrot_version();
my @parrot_version = Parrot::BuildUtil::parrot_version();

sub runstep {
    my ( $self, $conf ) = @_;

    # Later configuration steps need access to values from the Perl 5
    # %Config.  However, other later configuration steps may change
    # the corresponding values in the Parrot::Configure object.  In
    # order to provide access to the original values from Perl 5
    # %Config, we grab those settings we need now and store them in
    # special keys within the Parrot::Configure object.
    # This is a multi-stage process.

    # Stage 1:
    foreach my $orig ( qw|
        archname
        ccflags
        d_socklen_t
        longsize
        optimize
        sig_name
        scriptdirexp
        use64bitint
    | ) {
        $conf->data->set_p5( $orig => $Config{$orig} );
    }

    # Stage 2 (anticipating needs of config/auto/headers.pm):
    $conf->data->set_p5(
        map { $_ => $Config{$_} } grep { /^i_/ } keys %Config
    );

    # Stage 3 (Along similar lines, look up values from Perl 5 special
    # variables and stash them for later lookups.  Name them according
    # to their 'use English' names as documented in 'perlvar'.)
    $conf->data->set_p5( OSNAME => $^O );

    my $ccdlflags = $Config{ccdlflags};
    $ccdlflags =~ s/\s*-Wl,-rpath,\S*//g if $conf->options->get('disable-rpath');

    # We need a Glossary somewhere!
    $conf->data->set(
        debugging => $conf->options->get('debugging') ? 1 : 0,
        optimize  => '',
        verbose   => $conf->options->get('verbose'),
        build_dir => abs_path($FindBin::Bin),
        configured_from_file =>
            $conf->options->get('configured_from_file') || '',
        configuration_steps => ( join q{ } => $conf->get_list_of_steps() ),

        # Compiler -- used to turn .c files into object files.
        # (Usually cc or cl, or something like that.)
        cc      => $Config{cc},
        ccflags => $Config{ccflags},
        ccwarn  => exists( $Config{ccwarn} ) ? $Config{ccwarn} : '',

        # Flags used to indicate this object file is to be compiled
        # with position-independent code suitable for dynamic loading.
        cc_shared => $Config{cccdlflags},    # e.g. -fpic for GNU cc.

        # C++ compiler -- used to compile parts of ICU.  ICU's configure
        # will try to find a suitable compiler, but it prefers GNU c++ over
        # a system c++, which might not be appropriate.  This setting
        # allows you to override ICU's guess, but is otherwise currently
        # unset.  Ultimately, it should be set to whatever ICU figures
        # out, or parrot should look for it and always tell ICU what to
        # use.
        cxx => 'c++',

        # Linker, used to link object files (plus libraries) into
        # an executable.  It is usually $cc on Unix-ish systems.
        # VMS and Win32 might use "Link".
        # Perl5's Configure doesn't distinguish linking from loading, so
        # make a reasonable guess at defaults.
        link      => $Config{cc},
        linkflags => $Config{ldflags},

        # Linker Flags to have this binary work with the shared and dynamically
        # loadable libraries we're building.  On HP-UX, for example, we need to
        # allow dynamic libraries to access the binary's symbols
        link_dynamic => $ccdlflags,    # e.g. -Wl,-E on HP-UX

        # ld: Tool used to build shared libraries and dynamically loadable
        # modules. Often $cc on Unix-ish systems, but apparently sometimes
        # it's ld.
        ld      => $Config{ld},
        ldflags => $Config{ldflags},

        # Some operating systems (e.g. Darwin) distinguish between shared
        # libraries and modules that can be dynamically loaded.  Flags to tell
        # ld to build a shared library, e.g.  -shared for GNU ld.
        ld_share_flags => $Config{lddlflags},

        # Flags to tell ld to build a dynamically loadable module, e.g.
        # -shared for GNU ld.
        ld_load_flags => $Config{lddlflags},

        libs => $Config{libs},

        cc_inc     => "-I./include",
        cc_debug   => '-g',
        link_debug => '',

        o         => $Config{_o},       # object files extension
        share_ext => ".$Config{so}",    # shared library extension

        # dynamically loadable module extension
        load_ext => ".$Config{so}",
        a        => $Config{_a},        # library or archive extension
        exe      => $Config{_exe},      # executable files extension
        cc_o_out => '-o ',              # cc object output file

        # cc executable output file (different on Win32)
        cc_exe_out => '-o ',

        # prefix for ldflags (necessary for Win32)
        cc_ldflags => '',

        # ld output file.  Keep the trailing space.
        ld_out => '-o ',

        # include debug info in executable
        ld_debug => '',

        # Way to decorate a function to mark it as an exportable or
        # importable symbol.
        sym_export => '',
        sym_import => '',

        # Library build directory
        blib_dir => 'blib/lib',

        # libparrot library names
        libparrot_static => 'libparrot' . $Config{_a},
        libparrot_shared => 'libparrot.' . $Config{so},

        # does the system know about static/dynamic linking?
        has_static_linking  => 1,
        has_dynamic_linking => 0,

        # default behaviour for linking parrot to a static or shared libparrot
        parrot_is_shared => 0,

        #avoid a warning during Configure.pl
        libparrot_soname => '',

        perl      => $^X,
        perl_inc  => $self->find_perl_headers(),
        test_prog => 'parrot',

        # some utilities in Makefile
        cat       => '$(PERL) -MExtUtils::Command -e cat',
        chmod     => '$(PERL) -MExtUtils::Command -e ExtUtils::Command::chmod',
        cp        => '$(PERL) -MExtUtils::Command -e cp',
        mkpath    => '$(PERL) -MExtUtils::Command -e mkpath',
        mv        => '$(PERL) -MExtUtils::Command -e mv',
        rm_f      => '$(PERL) -MExtUtils::Command -e rm_f',
        rm_rf     => '$(PERL) -MExtUtils::Command -e rm_rf',
        touch     => '$(PERL) -MExtUtils::Command -e touch',

        ar        => $Config{ar},
        ar_flags  => 'cr',

        # for Win32
        ar_out => '',

        # for Borland C
        ar_extra      => '',
        ranlib        => $Config{ranlib},
        rpath         => '',
        make          => $Config{make},
        make_set_make => $Config{make_set_make},
        make_and      => '&&',

        # make_c: Command to emulate GNU make's C<-C directory> option:  chdir
        # to C<directory> before executing $(MAKE)
        make_c => '$(PERL) -e \'chdir shift @ARGV; system q{$(MAKE)}, @ARGV; exit $$? >> 8;\'',

        # if platform has a .s file that needs to be assembled
        platform_asm => 0,
        as           => 'as',    # assembler

        lns   => $Config{lns},                          # soft link
        slash => '/',

        VERSION => $parrot_version,
        MAJOR   => $parrot_version[0],
        MINOR   => $parrot_version[1],
        PATCH   => $parrot_version[2],
        DEVEL   => ( -e 'DEVELOPING' ? '-devel' : '' ),

        configdate => scalar gmtime() . " GMT",
        PQ         => "'",
        dquote     => "\\\"",

        # yacc = Automatic parser generator
        # lex  = Automatic lexer  generator
        # Some systems may lack these
        yacc => 'bison -v -y',
        lex  => 'flex',

        # Extra flags needed for libnci_test.so
        ncilib_link_extra => '',

        # Flag determines if pmc2c.pl and ops2c.pl also
        # generate #line directives. These can confuse
        # debugging internals.
        no_lines_flag => $conf->options->get('no-line-directives') ? '--no-lines' : '',

        tempdir => File::Spec->tmpdir,
    );

    # add profiling if needed
    # RT #41497 gcc syntax
    if ( $conf->options->get('profile') ) {
        $conf->data->set(
            cc_debug => " -pg ",
            ld_debug => " -pg ",
        );
    }

    #clock_id used to call the clock_gettime() in the profiling runcore.
    $conf->data->set( clock_best => '-DCLOCK_BEST=CLOCK_PROF' );

    $conf->data->set( 'archname', $Config{archname});
    # adjust archname, cc and libs for e.g. --m=32
    # RT#41499 this is maybe gcc only
    # remember corrected archname - jit.pm was using $Config('archname')
    _64_bit_adjustments($conf);

    return 1;
}

sub find_perl_headers {
    my $self = shift;
    return File::Spec->catdir( $Config::Config{archlib}, 'CORE' );
}

sub _64_bit_adjustments {
    my $conf = shift;
    my $m = $conf->options->get('m');
    if ($m) {
        my $archname = $conf->data->get('archname');
        if ( $archname =~ /x86_64/ && $m eq '32' ) {
            $archname =~ s/x86_64/i386/;

            # adjust gcc?
            for my $cc qw(cc cxx link ld) {
                $conf->data->add( ' ', $cc, '-m32' );
            }

            # and lib flags
            for my $lib qw(ld_load_flags ld_share_flags ldflags linkflags) {
                my $item = $conf->data->get($lib);
                ( my $ni = $item ) =~ s/lib64/lib/g;
                $conf->data->set( $lib, $ni );
            }
        }
        $conf->data->set( 'archname', $archname );
    }
    return 1;
}

1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
