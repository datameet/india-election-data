#!/usr/bin/perl

use DBI;
use utf8;

system("cp actopc.sqlite electors.sqlite");

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('electors.sqlite');

$dbh->do("CREATE TABLE electors (state CHAR, ac INTEGER, booth INTEGER, male INTEGER, female INTEGER, other INTEGER, total INTEGER)");

# Andaman Nicobar

my $state='Andaman & Nicobar Islands';
my @files = `find as1.and.nic.in/Voter-List-2014/ -name *pdf`;
my @lowerleft = (340,988);
my @upperright = (737,961);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+).pdf/;
    my $booth = $1/1;
    my $ac = 1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Andhra Pradesh

my $state='Andhra Pradesh';
my @files = `find ceoandhra.nic.in/Voter-List-2014/ -name *-Telugu.pdf`;
my @lowerleft = (298,1086);
my @upperright = (797,1031);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Arunachal Pradesh

my $state='Arunachal Pradesh';
my @files = `find ceoarunachal.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (316,1043);
my @upperright = (791,1000);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Assam

my $state='Assam';
my @files = `find ceoassam.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (319,976);
my @upperright = (798,936);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Bihar

my $state='Bihar';
my @files = `find ceobihar.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (323,1054);
my @upperright = (781,1025);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# # Chandigarh

# my $state='Chandigarh';
# my @files = `find ceochandigarh.nic.in/Voter-List-2014/ -name *pdf`;
# my @lowerleft = (390,1040);
# my @upperright = (750,994);

# my $x = $lowerleft[0];
# my $y = $upperright[1];
# my $w = $upperright[0]-$lowerleft[0];
# my $h = $lowerleft[1]-$upperright[1];

# my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
# $state=$$ref[0];

# foreach my $file (@files) {
#     chomp($file);
#     $file =~ /(\d+).pdf/;
#     my $booth = $1/1;
#     my $ac = 1;
#     system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
#     open (FILE,"temp.txt");
#     my @line = <FILE>;
#     close (FILE);
#     system("rm -f temp.txt");
#     my $line = join("",@line);
#     $line =~ s/[^0-9 ]//gs;
#     $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
#     my $male = $1; 
#     my $female = $2;
#     undef(my $other);
#     my $total = $3;
#     $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
# }

# $dbh->sqlite_backup_to_file("electors.sqlite");

# Daman & Diu

my $state='Daman & Diu';
my @files = `find ceodaman.nic.in/Voter-List-2014/ -name *-English.pdf`;
my @lowerleft = (254,1101);
my @upperright = (777,1069);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+).pdf/;
    my $booth = $1/1;
    my $ac = 1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Delhi

my $state='Nct Of Delhi';
my @files = `find ceodelhi.gov.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (390,1098);
my @upperright = (791,1033);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Dadra Nagar Haveli

my $state='Dadra & Nagar Haveli';
my @files = `find ceodnh.nic.in/Voter-List-2014/ -name *-English.pdf`;
my @lowerleft = (73,1093);
my @upperright = (768,1038);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+).pdf/;
    my $booth = $1/1;
    my $ac = 1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Goa

my $state='Goa';
my @files = `find ceogoa.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (385,966);
my @upperright = (789,934);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Gujarat

my $state='Gujarat';
my @files = `find ceogujarat.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (365,1085);
my @upperright = (754,1055);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Haryana

my $state='Haryana';
my @files = `find ceoharyana.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (389,1043);
my @upperright = (749,991);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Himachal Pradesh

my $state='Himachal Pradesh';
my @files = `find ceohimachal.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (202,1084);
my @upperright = (619,1034);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $4;
    undef(my $other);
    my $total = $7;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Jammu & Kashmir

my $state='Jammu & Kashmir';
my @files = `find ceojk.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (362,1001);
my @upperright = (808,946);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Karnataka

my $state='Karnataka';
my @files = `find ceokarnataka.kar.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (171,1079);
my @upperright = (789,1044);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Kerala

my $state='Kerala';
my @files = `find ceo.kerala.gov.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (460,1047);
my @upperright = (787,1021);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# # Lakshadweep

# my $state='Lakshadweep';
# my @files = `find ceolakshadweep.gov.in/Voter-List-2014/ -name *.pdf`;
# my @lowerleft = (451,1017);
# my @upperright = (762,992);

# my $x = $lowerleft[0];
# my $y = $upperright[1];
# my $w = $upperright[0]-$lowerleft[0];
# my $h = $lowerleft[1]-$upperright[1];

# my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
# $state=$$ref[0];

# foreach my $file (@files) {
#     chomp($file);
#     $file =~ /(\d+).pdf/;
#     my $ac = 1;
#     my $booth = $1/1;
#     system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
#     open (FILE,"temp.txt");
#     my @line = <FILE>;
#     close (FILE);
#     system("rm -f temp.txt");
#     my $line = join("",@line);
#     $line =~ s/[^0-9 ]//gs;
#     $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
#     my $male = $1; 
#     my $female = $2;
#     undef(my $other);
#     my $total = $3;
#     $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
# }

# $dbh->sqlite_backup_to_file("electors.sqlite");

# Madhya Pradesh

my $state='Madhya Pradesh';
my @files = `find ceomadhyapradesh.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (396,1086);
my @upperright = (784,1052);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Maharashtra

my $state='Maharashtra';
my @files = `find ceo.maharashtra.gov.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (312,1101);
my @upperright = (788,1063);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Manipur

my $state='Manipur';
my @files = `find ceomanipur.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (379,1061);
my @upperright = (771,1022);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Meghalaya

my $state='Meghalaya';
my @files = `find ceomeghalaya.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (323,1024);
my @upperright = (764,995);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

# Mizoram

$dbh->sqlite_backup_to_file("electors.sqlite");

my $state='Mizoram';
my @files = `find ceomizoram.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (352,1045);
my @upperright = (780,1002);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

# Nagaland

$dbh->sqlite_backup_to_file("electors.sqlite");

my $state='Nagaland';
my @files = `find ceonagaland.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (290,982);
my @upperright = (795,939);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

# Pondicherry

$dbh->sqlite_backup_to_file("electors.sqlite");

my $state='Puducherry';
my @files = `find ceopondicherry.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (549,1158);
my @upperright = (782,705);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/.*\n(.*\d+.*)/$1/gs;
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

# Orissa

$dbh->sqlite_backup_to_file("electors.sqlite");

my $state='Orissa';
my @files = `find ceoorissa.nic.in/Voter-List-2014/ -name *-Supp.pdf`;
my @lowerleft = (534,657);
my @upperright = (772,621);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    my $pagecount=`gs -q -dNODISPLAY -c "($file) (r) file runpdfbegin pdfpagecount = quit" `;
    chomp($pagecount);
    system("pdftotext -f $pagecount -l $pagecount -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/.*\n(.*\d+.*)/$1/gs;
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

# Punjab

$dbh->sqlite_backup_to_file("electors.sqlite");

my $state='Punjab';
my @files = `find ceopunjab.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (331,1050);
my @upperright = (791,1022);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Rajasthan

my $state='Rajasthan';
my @files = `find ceorajasthan.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (242,970);
my @upperright = (786,938);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    undef(my $other);
    my $total = $3;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Sikkim

my $state='Sikkim';
my @files = `find ceosikkim.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (586,997);
my @upperright = (628,142);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $male=0; my $female=0;
    foreach my $line (@line) {
	if ($line =~ /M/) {$male++}
	elsif ($line =~ /F/) {$female++}
    }
    my $total=$male+$female;
    undef(my $other);
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Tripura

my $state='Tripura';
my @files = `find ceotripura.nic.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (300,1048);
my @upperright = (761,1018);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Uttar Pradesh

my $state='Uttar Pradesh';
my @files = `find ceouttarpradesh.nic.in/Voter-List-2014/ -name *-Mother.pdf`;
my @lowerleft = (278,977);
my @upperright = (787,945);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# West Bengal

my $state='West Bengal';
my @files = `find ceowestbengal.nic.in/Voter-List-2014/ -name *-Mother.pdf`;
my @lowerleft = (443,1109);
my @upperright = (780,1083);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Tamil Nadu

my $state='Tamil Nadu';
my @files = `find elections.tn.gov.in/Voter-List-2014/ -name *-Tamil.pdf`;
my @lowerleft = (428,919);
my @upperright = (749,890);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $2;
    my $other = $3;
    my $total = $4;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("electors.sqlite");

# Jharkhand

my $state='Jharkhand';
my @files = `find jharkhand.gov.in/Voter-List-2014/ -name *.pdf`;
my @lowerleft = (204,1097);
my @upperright = (639,1055);

my $x = $lowerleft[0];
my $y = $upperright[1];
my $w = $upperright[0]-$lowerleft[0];
my $h = $lowerleft[1]-$upperright[1];

my $ref = $dbh->selectcol_arrayref("SELECT state FROM actopc WHERE state_name = ? LIMIT 1",undef,$state);
$state=$$ref[0];

foreach my $file (@files) {
    chomp($file);
    $file =~ /(\d+)-(\d+)/;
    my $ac = $1/1;
    my $booth = $2/1;
    system("pdftotext -f 1 -l 1 -nopgbrk -x $x -y $y -W $w -H $h -layout -r 100 $file temp.txt");
    open (FILE,"temp.txt");
    my @line = <FILE>;
    close (FILE);
    system("rm -f temp.txt");
    my $line = join("",@line);
    $line =~ s/[^0-9 ]//gs;
    $line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/gs;
    my $male = $1; 
    my $female = $4;
    undef(my $other);
    my $total = $7;
    $dbh->do("INSERT INTO electors VALUES (?,?,?,?,?,?,?)",undef,$state,$ac,$booth,$male,$female,$other,$total);
}

$dbh->sqlite_backup_to_file("booth-wise-electors.sqlite");

$dbh->disconnect;

# Assemble it

system("cat booths-wise-electors.sql | sqlite3 booth-wise-electors.sqlite");
