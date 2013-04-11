#!/usr/bin/perl -wl

use lib qw(t/lib lib);
use Test::UBH;
my $t = Test::UBH->new('skip-non-home');

foreach my $example (qw(/foobar ../foobar)) {
    $t->setup_test_environment_without_target("foobar");

    file_not_exists_ok( $t->BASE."/foobar" );
    file_not_exists_ok( "/foobar" );

    $t->write_configs("m d $example foobar");
    $t->call_unburden_home_dir_default;

    my $wanted = $t->prepend_lsof_warning(
        "$example would be outside of the home directory, skipping...\n");

    my $stderr = read_file($t->BASE."/stderr");
    eq_or_diff_text( $stderr, $wanted, "Check command STDERR output" );

    my $output = read_file($t->BASE."/output");
    eq_or_diff_text( $output, '', "Check command STDOUT (should be empty)" );

    file_not_exists_ok( $t->TP."-foobar" );
    file_not_exists_ok( $t->TP );

    file_not_exists_ok( $t->BASE."/foobar" );
    file_not_exists_ok( "/foobar" );

    $t->cleanup;
}

done_testing();
