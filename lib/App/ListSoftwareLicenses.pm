package App::ListSoftwareLicenses;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

use CHI;

our %SPEC;

my $cache = CHI->new(
    driver => 'File', root_dir=>$ENV{TMP} // $ENV{TEMP} // '/tmp');
my $table_spec = {
    summary => 'List of Software::License\'s',
    fields  => {
        module => {
            schema   => 'str*',
            index    => 0,
            sortable => 1,
        },
        meta_name => {
            schema   => 'str*',
            index    => 1,
            sortable => 1,
        },
        meta2_name => {
            schema   => 'str*',
            index    => 2,
            sortable => 1,
        },
        name => {
            schema   => 'str*',
            index    => 3,
            sortable => 1,
        },
        version => {
            schema   => 'str*',
            index    => 4,
            sortable => 1,
        },
        url => {
            schema   => 'str*',
            index    => 5,
            sortable => 1,
        },
        notice => {
            schema   => 'str*',
            index    => 6,
            sortable => 1,
        },
        text => {
            schema   => 'str*',
            index    => 7,
            sortable => 1,
            include_by_default => 0,
        },
    },
    pk => 'module',
};

# cache data for a day
my @excluded = qw(Software::License::Custom);
my $table_data = $cache->compute(
    'software_licenses', '24 hours', sub {
        require Module::List;
        require Module::Load;
        my $res = Module::List::list_modules(
            'Software::License::', {list_modules=>1});
        my $data = [map {[$_]} sort keys %$res];
        for my $row (@$data) {
            next if $row->[0] ~~ @excluded;
            Module::Load::load($row->[0]);
            my $o;
            eval { $o = $row->[0]->new({holder => 'Copyright_Holder'}) };
            if ($@) {
                # some modules are not really software license, like
                # Software::License::CCpack which are just the main/placeholder
                # module for the Software-License-CCpack distribution.
                next;
            }
            $row->[1] = $o->meta_name;
            $row->[2] = $o->meta2_name;
            $row->[3] = $o->name;
            $row->[4] = $o->version;
            $row->[5] = $o->url;
            $row->[6] = $o->notice;
            $row->[7] = $o->license;
        }
        $data;
    });

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

my $res = gen_read_table_func(
    name       => 'list_software_licenses',
    summary    => 'List all Software::License\'s',
    table_data => $table_data,
    table_spec => $table_spec,
    enable_paging => 0, # there are only a handful of rows
    enable_random_ordering => 0,
);
die "Can't generate list_software_licenses function: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{list_software_licenses}{args}{query}{pos} = 0;
$SPEC{list_software_licenses}{examples} = [
    {
        argv    => [qw/perl/],
        summary => 'String search',
    },
];

1;
# ABSTRACT:

=head1 SEE ALSO

L<Software::License>

L<App::Software::License> to print out license text

=cut
