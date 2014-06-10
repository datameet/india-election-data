#!/usr/bin/perl

use WWW::Mechanize::Firefox;
use DBD::SQLite;
use Text::CSV;
use HTML::TableExtract;

use utf8;

my $ua = WWW::Mechanize::Firefox->new();

for ($pc=1;$pc<=80;$pc++) {
    
    $ua->get("http://164.100.180.4/ceouptemp/districtwiseform20report.aspx");
    $ua->form_name("aspnetForm");
    $ua->set_fields('ctl00$ContentPlaceHolder1$ddlPCName' => $pc);
    
    sleep 5; while ($ua->content !~ /\<\/html\>\s*$/) {}
    
    my @acraw = $ua->xpath('.//select[@id="ctl00_ContentPlaceHolder1_ddlAcNo"]/option/@value');
    my @ac;
    foreach my $temp (@acraw) {next if $temp->{'value'} ==0; push (@ac,$temp->{'value'});}
    
    foreach my $c (@ac) {

	next if -e "$c.csv";
	
	print "Download constituency $c\n";

	$ua->form_name("aspnetForm");
	$ua->set_fields('ctl00$ContentPlaceHolder1$ddlAcNo' => "$c");
	
	sleep 5; while ($ua->content !~ /grdCandidateVotes/) {sleep 5}
	my $csv = Text::CSV->new;
	my $te = HTML::TableExtract->new( attribs => {id => 'grdCandidateVotes'} );
	$te->parse($ua->content);

	open (FILE, ">$c.csv");
	foreach my $row ($te->rows) {
	    # my @field=@$row;
	    $csv->print(\*FILE,$row);
	    print FILE "\n";
	}
	close (FILE);
	
    }
    
}

# copy actopc, prepare tables

system("cp actopc.sqlite results.sqlite");

$dbh = DBI->connect("DBI:SQLite:dbname=results.sqlite", "","", {sqlite_unicode=>1});
$dbh->do ("CREATE TABLE results (pc INTEGER, ac INTEGER, booth INTEGER, candidate CHAR, votes INTEGER)");
$dbh->do ("CREATE TABLE candidates (id INTEGER PRIMARY KEY AUTOINCREMENT, pc INTEGER, rank INTEGER, name CHAR, party CHAR)");

# first read candidate list prepared by Dilip Damle

my $csv = Text::CSV->new();

open (CSV,"Political_parties.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

my %party;
foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $party{$fields[0]}=$fields[1];
}

my $csv = Text::CSV->new();

open (CSV,"Candidates.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $fields[0] =~ /(...)PC(\d+)CA(\d+)/gs;
    my $state=$1; my $pc=$2/1; my $rank=$3/1;
    next if $state ne 'S24';
    next if $fields[1] =~ /none of the above/i;
    $dbh->do ("INSERT INTO candidates (pc,rank,name,party) VALUES (?,?,?,?)",undef,$pc,$rank,$fields[1],$party{$fields[2]});
}

# then read actual form20 results

undef(my %print); undef(my %troubleac);

$dbh->begin_work;

# iterate through PCs
for ($pc=1;$pc<=80;$pc++) {

    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'valid');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'rejected');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'nota');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'total');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'tendered');
    
    my $ref = $dbh->selectcol_arrayref("SELECT ac FROM actopc WHERE state_name = 'Uttar Pradesh' AND pc = ?",undef,$pc);

    # iterate through relevant ACs
    foreach my $ac (@$ref) {
		
	my $code=$ac;
	
	my $csv = Text::CSV->new({binary=>1});
	
	# read in CSV file, prepare stuff
	open (CSV,"$code.csv");
	my @csv = <CSV>;
	close (CSV);

	undef(my %cand);
	undef(my $pscol);
	my $toggle=0;
	
	# iterate through CSV file
	foreach my $line (@csv) {
	    
	    if ($toggle == 0) { # filter garbage and register general names
		if ($line =~ /Polling Station/gsi) {
		    $toggle=1; 
		    $csv->parse($line);
		    my @fields=$csv->fields();
		    for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {if (!defined($cand{$i})) {$cand{$i}=$fields[$i]}}}
		}
	    } elsif ($toggle == 1) { # read in candidate names
		$toggle=2; 
		$csv->parse($line);
		my @fields=$csv->fields();
		if ($fields[0] =~ /\d/ and $fields[0] !~ /\D/ and $fields[0] ne '') {push (@csv,$line)}
		else {for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {$cand{$i}=$fields[$i]}}}		
		

		key: foreach my $key (sort(keys(%cand))) {
		    $cand{$key} =~ s/\s*\(.*//gs;
		    $cand{$key} =~ s/[^A-Za-z\.\(\) ]/ /gs;
		    $cand{$key} =~ s/\s+/ /gs;
		    $cand{$key} =~ s/\s+$//gs;
		    $cand{$key} =~ s/^\s+//gs;
		    
		    $pscol=0;
		    
		    if ($cand{$key} eq 'Tendered Voter' ) {$cand{$key}='tendered'}
		    elsif ($cand{$key} =~ /None of the Above/) {$cand{$key}='nota'}
		    elsif ($cand{$key} eq 'Total Votes Secured') {$cand{$key}='total'}
		    elsif ($key<12) {undef($cand{$key})}
		    else {
			$cand{$key} =~ s/^\d+ - //gs;
			if ($pc==1 && $cand{$key} eq 'MOHD. FIROZ AFTAB') {$cand{$key}='MOHD FIROZ AFTAB'}
			elsif ($pc==1 && $cand{$key} eq 'SHAZAN MASOOD URF SHADAN MASOOD') {$cand{$key}='SHAZAN MASOOD ALIAS SHADAN MASOOD'}
			elsif ($pc==10 && $cand{$key} eq 'DR. EX. MAJ HIMANSHU SINGH') {$cand{$key}='DR. (EX. MAJ) HIMANSHU SINGH'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD. SAJID SAIFI') {$cand{$key}='MOHD SAJID SAIFI'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD.SHAHID AKHLAK') {$cand{$key}='MOHD SHAHID AKHLAK'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD.USMAN GHAZI') {$cand{$key}='MOHD USMAN GHAZI'}
			elsif ($pc==13 && $cand{$key} eq 'DR.MAHESH SHARMA') {$cand{$key}='DR. MAHESH SHARMA'}
			elsif ($pc==13 && $cand{$key} eq 'MOHD. SABIR ANSARI') {$cand{$key}='MOHD SABIR ANSARI'}
			elsif ($pc==14 && $cand{$key} eq 'ANJU URF MUSKAN') {$cand{$key}='ANJU ALIAS MUSKAN'}
			elsif ($pc==15 && $cand{$key} eq 'MOHD. SABIR RAHI') {$cand{$key}='MOHD SABIR RAHI'}
			elsif ($pc==17 && $cand{$key} eq 'FAKKAR BABA RAMAYANI') {$cand{$key}='FAKKAR BABA (RAMAYANI)'}
			elsif ($pc==17 && $cand{$key} eq 'HEMA MALINI') {$cand{$key}='HEMA MALINI'}
			elsif ($pc==17 && $cand{$key} eq 'PT. UDYAN SHARMA') {$cand{$key}='PT. UDYAN SHARMA (MUNNA)'}
			elsif ($pc==20 && $cand{$key} eq 'PROF. S.P. SINGH BAGHEL') {$cand{$key}='Prof. S. P. SINGH BAGHEL'}
			elsif ($pc==22 && $cand{$key} eq 'RAJVEER SINGH RAJU BHAIYA') {$cand{$key}='RAJVEER SINGH (RAJU BHAIYA)'}
			elsif ($pc==23 && $cand{$key} eq 'AKMAL KHAN URF CHAMAN') {$cand{$key}='AKMAL KHAN ALIAS CHAMAN'}
			elsif ($pc==23 && $cand{$key} eq 'SANTOSH KUMAR GUPTA SATYMARGI') {$cand{$key}='SANTOSH KUMAR GUPTA (SATYMARGI)'}
			elsif ($pc==24 && $cand{$key} eq 'CAPTAIN P.C. SHARMA') {$cand{$key}='CAPTAIN P. C. SHARMA'}
			elsif ($pc==24 && $cand{$key} eq 'MOHD. ZARRAR KHAN') {$cand{$key}='MOHD ZARRAR KHAN'}
			elsif ($pc==25 && $cand{$key} eq 'MASSARAT WARSI PAPPU BHAI') {$cand{$key}='MASSARAT WARSI (PAPPU BHAI)'}
			elsif ($pc==28 && $cand{$key} eq 'AJAY KUMAR') {$cand{$key}='AJAY'}
			elsif ($pc==29 && $cand{$key} eq 'REKHA') {$cand{$key}='REKHA Verma'}
			elsif ($pc==32 && $cand{$key} eq 'RAJESH KUMAR S O BABOORAM') {$cand{$key}='RAJESH KUMAR S/O BABOORAM'}
			elsif ($pc==32 && $cand{$key} eq 'RAJESH KUMAR S O PARMESHWAR DEEN') {$cand{$key}='RAJESH KUMAR S/O PARMESHWAR DEEN'}
			elsif ($pc==33 && $cand{$key} eq 'GIRJA SHANKAR RAJU') {$cand{$key}='GIRJA SHANKAR Alias RAJU'}
			elsif ($pc==33 && $cand{$key} eq 'SWAMI SACHCHIDANAND HARI SAKSHI') {$cand{$key}='SAKSHI Maharaj'}
			elsif ($pc==34 && $cand{$key} eq 'R.K CHAUDHARY') {$cand{$key}='R. K. CHAUDHARY'}
			elsif ($pc==35 && $cand{$key} eq 'MOHD. SARWAR MALIK') {$cand{$key}='MOHD SARWAR MALIK'}
			elsif ($pc==37 && $cand{$key} eq 'C L MAURYA') {$cand{$key}='C. L. MAURYA'}
			elsif ($pc==39 && $cand{$key} eq 'ASHOK SHUKLA SENANI') {$cand{$key}='ASHOK SHUKLA (SENANI)'}
			elsif ($pc==4 && $cand{$key} eq 'KUNWAR BHARTENDRA') {$cand{$key}='KUNWAR BHARATENDRA'}
			elsif ($pc==40 && $cand{$key} eq 'MUKESH RAJPUT') {$cand{$key}='MUKESH RAJPUT'}
			elsif ($pc==43 && $cand{$key} eq 'DR.MURLI MANOHAR JOSHI') {$cand{$key}='DR. MURLI MANOHAR JOSHI'}
			elsif ($pc==43 && $cand{$key} eq 'DR.NIKHIL GUPTA') {$cand{$key}='DR. NIKHIL GUPTA'}
			elsif ($pc==43 && $cand{$key} eq 'MOHD.NASIR KHAN') {$cand{$key}='MOHD NASIR KHAN'}
			elsif ($pc==44 && $cand{$key} eq 'DEVENDRA SINGH BHOLE SINGH') {$cand{$key}='DEVENDRA SINGH Alias BHOLE SINGH'}
			elsif ($pc==46 && $cand{$key} eq 'PRADEEP JAIN ADITYA') {$cand{$key}='PRADEEP JAIN (ADITYA)'}
			elsif ($pc==46 && $cand{$key} eq 'RAM KUMAR ANK SHASTRI') {$cand{$key}='RAM KUMAR (ANK SHASTRI)'}
			elsif ($pc==47 && $cand{$key} eq 'KUNWAR PUSHPENDRA SINGH CHANDEL') {$cand{$key}='KUNWAR CHANDEL PUSHPENDRA SINGH'}
			elsif ($pc==47 && $cand{$key} eq 'PRITAM SINGH LODHI') {$cand{$key}='PRITAM SINGH LODHI (KISAAN)'}
			elsif ($pc==5 && $cand{$key} eq 'YASHWANT SINGH') {$cand{$key}='Dr. YASHWANT SINGH'}
			elsif ($pc==51 && $cand{$key} eq 'GYANENDRA KUMAR SRIVASTAVA GYANI BHAI') {$cand{$key}='GYANENDRA KUMAR SRIVASTAVA (GYANI BHAI)'}
			elsif ($pc==51 && $cand{$key} eq 'MOHD. KAIF') {$cand{$key}='MOHD KAIF'}
			elsif ($pc==52 && $cand{$key} eq 'CHANDRA PRAKASH TIWARI ALIAS C. P. TIWARI ADVOCATE') {$cand{$key}='CHANDRA PRAKASH TIWARI ALIAS C. P. TIWARI (ADVOCATE)'}
			elsif ($pc==52 && $cand{$key} eq 'MOHD. AMEEN AZHAR ANSARI') {$cand{$key}='MOHD AMEEN AZHAR ANSARI'}
			elsif ($pc==54 && $cand{$key} eq 'JITENDRA KUMAR SINGH BABLU BHAIYA') {$cand{$key}='JITENDRA KUMAR SINGH (BABLU BHAIYA)'}
			elsif ($pc==55 && $cand{$key} eq 'JAHAR SINGH KASHYAP') {$cand{$key}='J. S. KASHYAP(JAHAR SINGH KASHYAP)'}
			elsif ($pc==56 && $cand{$key} eq 'COMANDO KAMAL KISHOR') {$cand{$key}='(COMANDO) KAMAL KISHOR'}
			elsif ($pc==56 && $cand{$key} eq 'DR.VIJAY KUMAR') {$cand{$key}='DR. VIJAY KUMAR'}
			elsif ($pc==58 && $cand{$key} eq 'VINAY KUMAR PANDEY') {$cand{$key}='VINAY KUMAR PANDEY (VINNU)'}
			elsif ($pc==6 && $cand{$key} eq 'BEGUM NOOR BANO URF MEHTAB') {$cand{$key}='BEGUM NOOR BANO ALIAS MEHTAB'}
			elsif ($pc==6 && $cand{$key} eq 'DR S T HASAN') {$cand{$key}='DR S. T. HASAN'}
			elsif ($pc==60 && $cand{$key} eq 'DR. MOHD. AYUB') {$cand{$key}='DR. MOHD AYUB'}
			elsif ($pc==60 && $cand{$key} eq 'MUKESH NARAYAN SHUKLA URF GYANESH NARAYAN SHUKLA') {$cand{$key}='MUKESH NARAYAN SHUKLA ALIAS GYANESH NARAYAN SHUKLA'}
			elsif ($pc==61 && $cand{$key} eq 'BRIJ KISHOR SINGH') {$cand{$key}='BRIJ KISHOR SINGH (DIMPAL)'}
			elsif ($pc==61 && $cand{$key} eq 'RAM KARAN ALIAS R.K. GAUTAM') {$cand{$key}='RAM KARAN ALIAS R. K. GAUTAM'}
			elsif ($pc==62 && $cand{$key} eq 'LOTAN URF LAUTAN PRASAD') {$cand{$key}='LOTAN ALIAS LAUTAN PRASAD'}
			elsif ($pc==64 && $cand{$key} eq 'MOHD. WASEEM KHAN') {$cand{$key}='MOHD WASEEM KHAN'}
			elsif ($pc==65 && $cand{$key} eq 'RAJESH PANDEY URF GUDDU') {$cand{$key}='RAJESH PANDEY ALIAS GUDDU'}
			elsif ($pc==71 && $cand{$key} eq 'DR.BHOLA PANDEY') {$cand{$key}='DR. BHOLA PANDEY'}
			elsif ($pc==71 && $cand{$key} eq 'RAVI SHANKER SINGH') {$cand{$key}='RAVI SHANKER SINGH (PAPPU)'}
			elsif ($pc==72 && $cand{$key} eq 'COL RETD. BHARAT SINGH SHAURYA CHAKRA') {$cand{$key}='COL(RETD) BHARAT SINGH SHAURYA CHAKRA'}
			elsif ($pc==73 && $cand{$key} eq 'KRISHNA PRATAP') {$cand{$key}='KRISHNA PRATAP (K. P.)'}
			elsif ($pc==74 && $cand{$key} eq 'BHOLANATH ALIAS B.P. SAROJ') {$cand{$key}='BHOLANATH ALIAS B. P. SAROJ'}
			elsif ($pc==75 && $cand{$key} eq 'DHARM YADAV') {$cand{$key}='DHARM YADAV ALIAS D. P. YADAV'}
			elsif ($pc==76 && $cand{$key} eq 'DR MAHENDRA NATH PANDEY') {$cand{$key}='DR. MAHENDRA NATH PANDEY'}
			elsif ($pc==76 && $cand{$key} eq 'TARUN PATEL URF TARUNENDRA CHAND PATEL') {$cand{$key}='TARUN PATEL ALIAS TARUNENDRA CHAND PATEL'}
			elsif ($pc==77 && $cand{$key} eq 'A.K. AGGARWAL') {$cand{$key}='A. K. AGGARWAL'}
			elsif ($pc==77 && $cand{$key} eq 'RAJENDRA PRASAD GARIB DAS') {$cand{$key}='RAJENDRA PRASAD (GARIB DAS)'}
			elsif ($pc==79 && $cand{$key} eq 'GIRJA SHANKAR URF CHUNMUN') {$cand{$key}='GIRJA SHANKAR ALIAS CHUNMUN'}
			elsif ($pc==79 && $cand{$key} eq 'SUKCHARA NAND URF AALOO BABA') {$cand{$key}='SUKCHARA NAND ALIAS AALOO BABA'}
			elsif ($pc==8 && $cand{$key} eq 'AQEEL UR REHMAN KHAN') {$cand{$key}='AQEEL-UR -REHMAN KHAN'}
			elsif ($pc==8 && $cand{$key} eq 'DHARAM YADAV') {$cand{$key}='DHARAM YADAV ALIAS D. P. YADAV'}
			elsif ($pc==8 && $cand{$key} eq 'DR SHAFIQ UR RAHMAN BARQ') {$cand{$key}='DR SHAFIQ- UR RAHMAN BARQ'}
			elsif ($pc==8 && $cand{$key} eq 'MOHD ASLAM URF PASHA') {$cand{$key}='MOHD ASLAM ALIAS PASHA'}
			elsif ($pc==80 && $cand{$key} eq 'ARUN SINGH CHERO') {$cand{$key}='ARUN SINGH(CHERO)'}
			elsif ($pc==80 && $cand{$key} eq 'GUN DEVI GYANI DEVI') {$cand{$key}='GUN DEVI (. GYANI DEVI)'}
			
			# check if candidate remains unknown
			my $re2f = $dbh->selectcol_arrayref("SELECT id FROM candidates WHERE pc = ? AND name LIKE ?",undef,$pc,$cand{$key});
			if (scalar(@$re2f) != 1) {$print{'elsif ($pc=='.$pc.' && $cand{$key} eq \''.$cand{$key}.'\') {$cand{$key}=\''."'} # in AC $ac\n"}++;  $troubleac{$ac}=1; undef($cand{$key}); next key;}
			$cand{$key}=$$re2f[0];
		    }
		}
	    } else { # read in results
		$csv->parse($line);
		my @fields=$csv->fields();
		
		$fields[$pscol]=~s/^(\d+)*/$1/gs;
		
		my $booth = $fields[$pscol]/1;
		undef(my $total); undef(my $control);
		for ($i=0;$i<scalar(@fields);$i++) {
		    if ($fields[$i] =~ /\d/) {
			next if !defined($cand{$i});
#			$fields[$i] =~ s/\D//gs;
			if ($cand{$i} eq 'total') {$total=$fields[$i]} 
			elsif ($cand{$i} eq 'valid' or $cand{$i} eq 'tendered') {}
			else {$control=$control+$fields[$i]}
			$dbh->do("INSERT INTO results VALUES (?,?,?,?,?)",undef,$pc,$ac,$booth,$cand{$i},$fields[$i]);
		    }
		}
		# check if vote counts add up
#		if ($total != $control) {$print{"Vote count mismatch in AC $ac, booth ".$fields[$pscol].": votes add up to $control, but total column says $total!\n"}++;  $troubleac{$ac}=1; }
	    }
	    
	}
	
	# check if AC has all relevant candidates!
	if (defined($pscol)) {
	    my $re2f = $dbh->selectcol_arrayref("select name from candidates where id not in (select candidate from results where ac=? group by candidate) and pc=? and name is not null",undef,$ac,$pc);
	    foreach my $candidate (@$re2f) {$print{"Missing candidate $candidate from AC $ac!\n"}++; $troubleac{$ac}=1;}
	# TODO implement boothcount check, using GIS data as reference
	} else {
	    $print{"Empty file for AC $ac!\n"}=1; # $troubleac{$ac}=1;
	}
	    
    }
    
}

# print diagnostics
foreach my $key (sort(keys(%print))) {print $key}
# foreach my $key (sort {$a <=> $b} (keys(%troubleac))) {print "Troubling AC: ".$key."\n"}


# cleanup

$dbh->commit;

$dbh->disconnect;

system("cat extract.sql | sqlite3 results.sqlite");
