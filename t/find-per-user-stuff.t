#!/usr/bin/perl -wl

use lib qw(t/lib lib);
use Test::UBH;
my $t = Test::UBH->new('find-per-user-stuff');
my $demodir1 = '.foobar/fnord';
my $demofile1 = "$demodir1/bla";
my $demotarget1 = 'foobar-fnord-bla';
my $demodir2 = '.foobar/blafasel';
my $demofile2 = "$demodir2/bla";
my $demotarget2 = 'foobar-blafasel-bla';

foreach my $configtype (qw(write_configs write_xdg_configs)) {
    $t->setup_test_environment($demofile1);

    ok( symlink($demodir1, $t->HOME."/.fnord"),
        "Create test environment (Symlink 1)" );
    ok( -l $t->HOME."/.fnord",
        "Symlink 1 has been created" );
    ok( symlink("fnord", $t->HOME."/$demodir2"),
        "Create test environment (Symlink 2)" );
    ok( -l $t->HOME."/$demodir2",
        "Symlink 2 has been created" );

    $t->$configtype("m d $demofile1 $demotarget1\n".
                    "m d .fnord/bla fnord-bla\n".
                    "m d $demofile2 $demotarget2\n");

    $t->call_unburden_home_dir_user;

    my $wanted =
        "Skipping '".$t->HOME."/.fnord/bla' due to symlink in path: ".$t->HOME."/.fnord\n" .
        "Skipping '".$t->HOME."/$demofile2' due to symlink in path: ".$t->HOME."/$demodir2\n";
    unless (which('lsof')) {
        $wanted = "WARNING: lsof not found, not checking for files in use.\n".$wanted;
    }

    my $stderr = read_file($t->BASE."/stderr");
    eq_or_diff_text( $stderr, $wanted, "Check command STDERR output" );

    $wanted =
        "Moving ".$t->HOME."/$demofile1 -> ".$t->TARGET."/u-$demotarget1\n" .
        "sending incremental file list\n" .
        "created directory ".$t->TARGET."/u-$demotarget1\n" .
        "./\n" .
        "Symlinking ".$t->TARGET."/u-$demotarget1 ->  ".$t->HOME."/$demofile1\n";

    my $output = read_file($t->BASE."/output");
    eq_or_diff_text( $output, $wanted, "Check command STDOUT" );

    ok( -d $t->TARGET."/".$t->PREFIX."-$demotarget1", "First directory moved" );
    ok( ! -e $t->TARGET."/".$t->PREFIX."-fnord-bla", "Symlink 1 not moved" );
    ok( ! -e $t->TARGET."/".$t->PREFIX."-$demotarget2", "Symlink 2 not moved" );

    $t->cleanup();
}

done_testing();
