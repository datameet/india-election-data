#!/usr/bin/perl

use WWW::Mechanize;
use DBD::SQLite;
use Text::CSV;

system("cp actopc.sqlite results.sqlite");

$dbh = DBI->connect("DBI:SQLite:dbname=results.sqlite", "","", {sqlite_unicode=>1});
$dbh->do ("CREATE TABLE results (ac INTEGER, booth INTEGER, candidate CHAR, votes INTEGER)");
$dbh->do ("CREATE TABLE candidates (id INTEGER PRIMARY KEY AUTOINCREMENT, ac INTEGER, rank INTEGER, name CHAR, party CHAR, symbol CHAR)");

# first read candidate list

system("pdftotext -layout Downloads_AC2014_Candidatelistfinal.pdf");

open (CSV,"Downloads_AC2014_Candidatelistfinal.txt");
my @csv = <CSV>;
close (CSV);

system("rm -f Downloads_AC2014_Candidatelistfinal.txt");

my $ac=0; my $namelength=0; my $partycol=0; my $partylength=0; my $name=''; my $party=''; my $symbol='';
foreach my $line (@csv) {
    if ($line =~ /Address Of Candidate/) {
	$namelength = index ($line,'Address Of Candidate');
	$partycol = index ($line,'Party Affiliation');
	$partylength = index ($line,'Symbol Allottted') - $partycol;
    } elsif ($line =~ /^\s+(\d+)-\w/) {
	$ac = $1;
	$rank ++;
	$name =~ s/^\s+\d+\s//gs;
	$name =~ s/\s+$//gs;
	$name =~ s/\s+/ /gs;
	$party =~ s/\s+$//gs;
	$party =~ s/\s+/ /gs;
	$party =~ s/^\s//gs;
	$symbol =~ s/\s+$//gs;
	$symbol =~ s/\s+/ /gs;
	$symbol =~ s/^\s//gs;
	if ($ac != 1 && $name ne '') {$dbh->do ("INSERT INTO candidates (ac,rank,name,party,symbol) VALUES (?,?,?,?,?)",undef,$ac-1,$rank,$name,$party,$symbol)}
	$name='';
	$party='';
	$symbol='';
    } elsif ($line =~ /^\s+(\d+) \w/) {
	$rank = $1-1;
	$name =~ s/^\s+\d+\s//gs;
	$name =~ s/\s+$//gs;
	$name =~ s/\s+/ /gs;
	$party =~ s/\s+$//gs;
	$party =~ s/\s+/ /gs;
	$party =~ s/^\s//gs;
	$symbol =~ s/\s+$//gs;
	$symbol =~ s/\s+/ /gs;
	$symbol =~ s/^\s//gs;
	if ($ac != 0 && $name ne '') {$dbh->do ("INSERT INTO candidates (ac,rank,name,party,symbol) VALUES (?,?,?,?,?)",undef,$ac,$rank,$name,$party,$symbol)}
	$name = substr ($line,0,$namelength) . " ";
	$party = substr ($line,$partycol,$partylength) . " ";
	$symbol = substr ($line,$partycol+$partylength) . " ";
    } elsif ($ac != 0 && $line =~ /\w/ && $line !~ /MAHARSHTRA STATE/ && $line !~ /MAHARASHTRA STATE/ && $line !~ /Page\s+\d/) {
	$name .= substr ($line,0,$namelength) . " ";
	$party .= substr ($line,$partycol,$partylength) . " ";
	$symbol .= substr ($line,$partycol+$partylength) . " ";
    }
}

# then read actual form20 results

undef(my %print); undef(my %troubleac);

# iterate through ACs (whole Maharashtra would be 1-288, Mumbai is just 152-187)
for ($ac=152;$ac<=187;$ac++) { 

    # skip known trouble ACs
    next if ($ac==154 or $ac==166 or $ac==169 or $ac==178 or $ac==183 or $ac==182 or $ac==185);
    
    $dbh->begin_work;
    
    $dbh->do ("INSERT INTO candidates (ac,name) VALUES (?,?)",undef,$ac,'valid');
    $dbh->do ("INSERT INTO candidates (ac,name) VALUES (?,?)",undef,$ac,'rejected');
    $dbh->do ("INSERT INTO candidates (ac,name) VALUES (?,?)",undef,$ac,'nota');
    $dbh->do ("INSERT INTO candidates (ac,name) VALUES (?,?)",undef,$ac,'total');
    $dbh->do ("INSERT INTO candidates (ac,name) VALUES (?,?)",undef,$ac,'tendered');
    
    my $code=$ac;
    if ($code<10) {$code="00$code"}
    elsif ($code<100) {$code="0$code"}
    
    # generate CSV file if not yet there
    my $pagecount=`cd Complete && gs -q -dNODISPLAY -c "(AC_$code.pdf) (r) file runpdfbegin pdfpagecount = quit" && cd ..`;
    chomp($pagecount);
    
    my %x_of_cands;
    my $x_of_ps;
    
    for ($page=1;$page<=$pagecount;$page++) {
	system("pdf-table-extract -p $page -i Complete/AC_$code.pdf -o AC$code.$page.csv -l 3 -t cells_csv");
	
	open (CSV,"AC$code.$page.csv");
	my @csv = <CSV>;
	close (CSV);
	
	system("rm -f AC$code.$page.csv");
	
	my $csv = Text::CSV->new({binary=>1});

	undef(my $y_of_cands);
	undef(my %y_of_ps);
	
	# iterate through CSV to identify candidate line
	foreach my $line (@csv) {
	    
	    $csv->parse($line);
	    my @fields=$csv->fields();
	    
	    if ($fields[5] =~ /nota/i) {$y_of_cands=$fields[3]; last}
	    
	}

	if (defined($y_of_cands)) {
	    
	    # iterate through CSV to identify candidates
	    foreach my $line (@csv) {
		
		$csv->parse($line);
		my @fields=$csv->fields();
		
		if ($fields[3] == $y_of_cands and $fields[5] ne '') {$x_of_cands{$fields[0]}=$fields[5]}
		
	    }
	    
	    if ($ac==184) {
		$x_of_ps = '952'; 
		undef(%x_of_cands);
		$x_of_cands{'1051'} = 'Pravin Shivram Pawar';
		$x_of_cands{'1218'} = 'Madhu (Dada) Chavan';
		$x_of_cands{'1405'} = 'Anna Alias Madhu Chavan';
		$x_of_cands{'1563'} = 'Sanjay Naik';
		$x_of_cands{'1736'} = 'Aejaaz Alimiya Mukadam';
		$x_of_cands{'1917'} = 'Geeta Ajay Gawli';
		$x_of_cands{'2088'} = 'Rehan Khan';
		$x_of_cands{'2285'} = 'Adv. Waris Yusuf Pathan';
		$x_of_cands{'2484'} = 'Ujwal Shashikant Rane';
		$x_of_cands{'2639'} = 'Lokhande Rohidas Madhukar';
		$x_of_cands{'2806'} = 'Shahe Alam Khan';
		$x_of_cands{'2966'} = 'nota';
		$x_of_cands{'3110'} = 'total';
		$x_of_cands{'3300'} = 'tendered';
	    }
	    
	    key: foreach my $key (sort(keys(%x_of_cands))) {
		
		$x_of_cands{$key} =~ s/\s*\(.*//gs;
		$x_of_cands{$key} =~ s/[^A-Za-z\.\(\) ]/ /gs;
		$x_of_cands{$key} =~ s/\s+/ /gs;
		$x_of_cands{$key} =~ s/\s+$//gs;
		$x_of_cands{$key} =~ s/^\s+//gs;
		
		if ($x_of_cands{$key} eq 'Valid' or $x_of_cands{$key} =~ /valied votes/i or $x_of_cands{$key} =~ /valid\s* votes/i or $x_of_cands{$key} eq 'valid' or $x_of_cands{$key} =~ /total\s* of\s* valid/i) {$x_of_cands{$key}='valid'}
		elsif ($x_of_cands{$key} =~ /rejected/i or $x_of_cands{$key} =~ /rejecte d vote/i or $x_of_cands{$key} eq 'No. of Reject votes' or $x_of_cands{$key} eq 'No. of reje cted votes' or $x_of_cands{$key} eq 'reje cted votes' or $x_of_cands{$key} eq 'Total of Reject - ed Votes' or $x_of_cands{$key} =~ /rejec\s*t\s*e\s*d vote/i or $x_of_cands{$key} =~ /rejected\/ missing/ or $x_of_cands{$key} eq 'rejected' ) {$x_of_cands{$key}='rejected'}
		elsif ($x_of_cands{$key} =~ /[\'\" ]N\s*O\s*T\s*A[\'\" ]/i or $x_of_cands{$key} eq 'N O T A' or $x_of_cands{$key} eq 'O T A' or $x_of_cands{$key} eq 'NOTA 5' or $x_of_cands{$key} eq 'NOTA' or $x_of_cands{$key} eq 'Nota' or $x_of_cands{$key} =~ /none\s* of\s* the\s* above/i  or $x_of_cands{$key} eq 'nota' or $x_of_cands{$key} eq 'NOTA') {$x_of_cands{$key}='nota'}
		elsif ($x_of_cands{$key} =~ /^Total$/i or $x_of_cands{$key} =~ /Total\s* vote/i or $x_of_cands{$key} eq 'total' ) {$x_of_cands{$key}='total'}
		elsif ($x_of_cands{$key} =~ /tender votes/i or $x_of_cands{$key} =~ /tendered\s* vo/i or $x_of_cands{$key} =~ /tende red vote/i or $x_of_cands{$key} =~ /tendere d vote/i or $x_of_cands{$key} eq 'No. of tende red votes' or $x_of_cands{$key} eq 'No.of tender votes' or $x_of_cands{$key} eq 'No of Tender- ed Votes' or $x_of_cands{$key} =~ /tenderd vote/i or $x_of_cands{$key} eq 'tende red votes' or $x_of_cands{$key} =~ /tende\s*r ed vote/i or $x_of_cands{$key} =~ /Tendere d vote/i or $x_of_cands{$key} eq 'tendered' or $x_of_cands{$key} =~ /tendred votes/i) {$x_of_cands{$key}='tendered'}
		elsif ($x_of_cands{$key} eq 'Sr. No. of P. S.' or $x_of_cands{$key} eq 'No. of P.S.' or $x_of_cands{$key} =~ /P.S. NO./ or $x_of_cands{$key} =~ /polling st/i or $x_of_cands{$key} eq 'Station' or $x_of_cands{$key} =~ /Polling No/i) {$x_of_ps=$key; undef($x_of_cands{$key}); next key}
		
		# this is the generated manual corrections list for candidates - puh...
		elsif ($ac==152 && $x_of_cands{$key} eq 'Agarwal Uttam Prakash CA') {$x_of_cands{$key}='Agarwal Uttamprakash Ca'}
		elsif ($ac==152 && $x_of_cands{$key} eq 'Jayashree Ashok Dongre') {$x_of_cands{$key}='Jayshree Ashok Dongre'}
		elsif ($ac==152 && $x_of_cands{$key} eq 'Meera Kamath') {$x_of_cands{$key}='Meera Kamat'}
		elsif ($ac==153 && $x_of_cands{$key} eq 'Ashish Bhawnath Fernandes') {$x_of_cands{$key}='Ashish Bhavnath Fernandes'}
		elsif ($ac==153 && $x_of_cands{$key} eq 'Chaudhari Manisha Ashok') {$x_of_cands{$key}='Chaudhary Manisha Ashok'}
		elsif ($ac==153 && $x_of_cands{$key} eq 'Dr. Shubha Raul') {$x_of_cands{$key}='Shubha Umesh Raul'}
		elsif ($ac==153 && $x_of_cands{$key} eq 'Harish Bhujang Sheatty') {$x_of_cands{$key}='Harish Bhujang Shetty'}
		elsif ($ac==153 && $x_of_cands{$key} eq 'Ramprakash Vishwnath Chaturvedi') {$x_of_cands{$key}='Ramprakash Vishwanath Chaturvedi'}
		elsif ($ac==155 && $x_of_cands{$key} eq 'Nandakumar Atmaram Vaity') {$x_of_cands{$key}='Nandkumar Atmaram Vaity'}
		elsif ($ac==155 && $x_of_cands{$key} eq 'Ramdhan Maruti Jadhav') {$x_of_cands{$key}='Ramdhan Maroti Jadhav'}
		elsif ($ac==156 && $x_of_cands{$key} eq 'Akther Sardar Shaikh') {$x_of_cands{$key}='Akhtar Sardar Shaikh'}
		elsif ($ac==156 && $x_of_cands{$key} eq 'Chandrashekhar Maruti Kamble') {$x_of_cands{$key}='Chandrshekhar Maruti Kamble'}
		elsif ($ac==156 && $x_of_cands{$key} eq 'Dr. Sandesh Balasaheb Mhatre') {$x_of_cands{$key}='Dr.Sandesh Balasaheb Mhatre'}
		elsif ($ac==156 && $x_of_cands{$key} eq 'Jishnu Sharama') {$x_of_cands{$key}='Jishnu Sharma'}
		elsif ($ac==156 && $x_of_cands{$key} eq 'Mangesh Eknath Sangle') {$x_of_cands{$key}='Mangesh Eknath Sangale'}
		elsif ($ac==157 && $x_of_cands{$key} eq 'Inderjeet Singh Chadha') {$x_of_cands{$key}='Indrajeet Singh Chadha'}
		elsif ($ac==157 && $x_of_cands{$key} eq 'Koparkar Suresh Harishcha ndra') {$x_of_cands{$key}='Koparkar Suresh Harishchandra'}
		elsif ($ac==157 && $x_of_cands{$key} eq 'Lalbahadur Singh') {$x_of_cands{$key}='Lal Bahadur Singh'}
		elsif ($ac==157 && $x_of_cands{$key} eq 'Nagesh Dharma Lendve') {$x_of_cands{$key}='Nagesh Dharma Lendave'}
		elsif ($ac==157 && $x_of_cands{$key} eq 'Sanaullah B. Sheikh') {$x_of_cands{$key}='Sanaullah B. Shaikh'}
		elsif ($ac==158 && $x_of_cands{$key} eq 'C.A.Rajesh Dalal') {$x_of_cands{$key}='Rajesh R Dalal'}
		elsif ($ac==158 && $x_of_cands{$key} eq 'Inamulla Rahamattulla Khan Alias Babu Khan') {$x_of_cands{$key}='Inamulla Rahimattullah Khan Alias Babu Khan'}
		elsif ($ac==158 && $x_of_cands{$key} eq 'Sr.No.') {undef($x_of_cands{$key})}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Maurya Raghavprasad Shivjiprasad') {$x_of_cands{$key}='Maurya Raghavprasad Shivjiprasad S T'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Mohit Kamboj') {$x_of_cands{$key}='Mohit Kamboj 5 M'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Rajhans Singh Dhananjay Singh') {$x_of_cands{$key}='Rajhans Singh Dhananjay Singh 1 M'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Raorane Ajit Balkrishna') {$x_of_cands{$key}='Raorane Ajit Balkrishna R S P'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'S. K. Jha') {$x_of_cands{$key}='S K Jha'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Shafique Azmi Hitlar') {$x_of_cands{$key}='Shafique Azmi "Hitlar"'}
		elsif ($ac==159 && $x_of_cands{$key} eq 'Thackeray Shalini Jeetendra') {$x_of_cands{$key}='Thackeray Shalini Jeetendra 1 N'}
		elsif ($ac==160 && $x_of_cands{$key} eq 'CU NO.') {undef($x_of_cands{$key})}
		elsif ($ac==160 && $x_of_cands{$key} eq 'Diffrence') {undef($x_of_cands{$key})}
		elsif ($ac==160 && $x_of_cands{$key} eq 'Omprakash') {$x_of_cands{$key}='Omprakash (Uma) Yadav'}
		elsif ($ac==160 && $x_of_cands{$key} eq 'SR No.') {undef($x_of_cands{$key})}
		elsif ($ac==160 && $x_of_cands{$key} eq 'Shashikala Marchande Soni') {$x_of_cands{$key}='Shashikala Marchande - Soni'}
		elsif ($ac==160 && $x_of_cands{$key} eq 'Voter Turnout As per C') {undef($x_of_cands{$key})}
		elsif ($ac==161 && $x_of_cands{$key} eq 'Mansuri Shaikh Fateh Mohammad') {$x_of_cands{$key}='Mansuri Shaikh Fateh Mahammad'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Arunkumar Yadav') {$x_of_cands{$key}='Arun Kumar Yadav Ro Ma'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Aslam Shaikh') {$x_of_cands{$key}='Aslam Shaikh 8, 40'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Cyril Peter D souza') {$x_of_cands{$key}="Cyril Peter D'Souza"}
		elsif ($ac==162 && $x_of_cands{$key} eq 'D souza Tony Salvador') {$x_of_cands{$key}="D'Souza Tony Salvador"}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Deepak Pandurang Pawar') {$x_of_cands{$key}='Deepak Pandurang Pawar (Pappa) 13 Ro'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Dr. Ram Barot') {$x_of_cands{$key}='Dr. Ram Barot 32 Ma'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Dr. Vinay Jain') {$x_of_cands{$key}='Dr. Vinay Jain 30 Ma'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Jyoti Bajirao Patil') {$x_of_cands{$key}='Jyoti Bajirao Patil 3, Ma'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Meetali Milind Lavate') {$x_of_cands{$key}='Meetali Milind Lavate C/ Hi'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Raja') {$x_of_cands{$key}='Raja (S.) Bhalekar Ro Co 09'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Rukhsana Nazim Siddiqui') {$x_of_cands{$key}='Rukhsana Nazim Siddiqui Sa Kh'}
		elsif ($ac==162 && $x_of_cands{$key} eq 'Sunilbhau Shinde') {$x_of_cands{$key}='Sunilbhau Shinde T. Ha Up'}
		elsif ($ac==163 && $x_of_cands{$key} eq 'Akil Ahmed Sallan Ali') {$x_of_cands{$key}='Akil Ahmed Ali Sayed'}
		elsif ($ac==163 && $x_of_cands{$key} eq 'Dipti Ashok Walawalkar') {$x_of_cands{$key}='Dipti Ashok Walavalkar'}
		elsif ($ac==164 && $x_of_cands{$key} eq 'Aakanksha Arindam Banerjee') {$x_of_cands{$key}='Akanksha Arindam Banarjee'}
		elsif ($ac==164 && $x_of_cands{$key} eq 'Dr.Bharati Hemant Lavekar') {$x_of_cands{$key}='Dr. Bharati Hemant Lavekar'}
		elsif ($ac==164 && $x_of_cands{$key} eq 'Girja Shanker Pandey') {$x_of_cands{$key}='Girja Shankar Pandey'}
		elsif ($ac==164 && $x_of_cands{$key} eq 'Reshma Bapurao Dhende') {$x_of_cands{$key}='Reshma Baburao Dhende'}
		elsif ($ac==167 && $x_of_cands{$key} eq 'Apparao Pandura ng Galphade') {$x_of_cands{$key}='Apparao Pandurang Galphade'}
		elsif ($ac==167 && $x_of_cands{$key} eq 'Arora Rakesh Vishwana th') {$x_of_cands{$key}='Arora Rakesh Vishwanath'}
		elsif ($ac==167 && $x_of_cands{$key} eq 'Ashok Mathurda s Panchal') {$x_of_cands{$key}='Ashok Mathurdas Panchal'}
		elsif ($ac==167 && $x_of_cands{$key} eq 'Shashika nt Govind Patkar') {$x_of_cands{$key}='Shashikant Govind Patkar'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Annamal ai S.') {$x_of_cands{$key}='Annamalai S.'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Comrade Jayram Vishwaka rma') {$x_of_cands{$key}='Comrade Jayram Vishwakarma'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Khan Mohd. Arif') {$x_of_cands{$key}='Khan Md. Arif (Naseem)'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Prakash Raghuna th Sawant') {$x_of_cands{$key}='Prakash Raghunath Sawant'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Singh Santosh Ramniwa s') {$x_of_cands{$key}='Singh Santosh Ramniwas'}
		elsif ($ac==168 && $x_of_cands{$key} eq 'Sr. No.') {undef($x_of_cands{$key})}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Firoz Ahemd Ashfaque Siddiqui') {$x_of_cands{$key}='Firoz Ahmed Ashfaque Siddiqui'}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Jagdish Chhagan Chhaudhari') {$x_of_cands{$key}='Jagdish Chagan Chaudhari'}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Prakah Mehta') {$x_of_cands{$key}='Prakash Mehta'}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Prakah Rajdev Sachchan') {$x_of_cands{$key}='Prakash Rajdev Sacchan'}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Prakash Sadashiv Panchras') {$x_of_cands{$key}='Prakash Sadashiv Pancharas'}
		elsif ($ac==170 && $x_of_cands{$key} eq 'Rakhee Harischandra Jadhav') {$x_of_cands{$key}='Rakhi Harishchandra Jadhav'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Abdul Shabir Gulamuddin Shaikh') {$x_of_cands{$key}='Abdul Shabbir Gulamuddin Shaikh R B S'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Abrahani Yusuf') {$x_of_cands{$key}='Abrahani Yasuf'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Abu Asim Azmi') {$x_of_cands{$key}='Abu Asim Azmi S C'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Altaf Kazi') {$x_of_cands{$key}='Altaf Kazi P M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Dastagir Saheblal Shaikh') {$x_of_cands{$key}='Dastgir Saheblal Shaikh P S M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Ganesh Bhimrao Budhe') {$x_of_cands{$key}='Ganesh Bhimrao Budhe B 4'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Gani Abdul') {$x_of_cands{$key}='Gani Abdul 1 M M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Nasir karim shaikh') {$x_of_cands{$key}='Shaikh Nasir Karim'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Pal Jitendrakumar Nanaku') {$x_of_cands{$key}='Pal Jitendrakumar Nanaku L M S'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Parmeshwar Kamble') {$x_of_cands{$key}='Parmeshwar Kamble S M M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Rajendra Bhu Patole') {$x_of_cands{$key}='Rajendra Bhau Patole B-9 Man'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Ranjeet Varma') {$x_of_cands{$key}='Ranjeet Varma R M M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Santosh Shamrao Kate') {$x_of_cands{$key}='Santosh Shyamrao Kate'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Shaikh Alim Ahmed Shamshuddin') {$x_of_cands{$key}='Shaikh Aleem Ahmed Shamsuddin Plo Mum'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Shymlal Medhai Jaiswar') {$x_of_cands{$key}='Shyamlal Medhai Jaiswal'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Suhel Sayyed Ashraf') {$x_of_cands{$key}='Suhail Sayyed Ashraf 1 K'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Sumit Kundalik Vajale') {$x_of_cands{$key}='Sumit Kundlik Vajale'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Suresh Krushanrao Patil') {$x_of_cands{$key}='Suresh Krishnarao Patil A M'}
		elsif ($ac==171 && $x_of_cands{$key} eq 'Uday Bhalekar') {$x_of_cands{$key}='Uday Bhalekar P B M'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'AKBAR HUSSAIN URF RAJU BHAI') {$x_of_cands{$key}='Akbar Hussain Alias Raju Bhai'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'AYYAR GANESH') {$x_of_cands{$key}='Ayyer Ganesh'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'CHANDRAKAN T WAGHU NIRBHAVNE') {$x_of_cands{$key}='Chandrakant Waghu Nirbhavne'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'MAHENDRA TULSHIRAM BHINGARDIV E') {$x_of_cands{$key}='Mahendra Tulshiram Bhingardive'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'MAHULKAR RAJENDRA JAGANNATH') {$x_of_cands{$key}='Mahulkar Rajendra Jagnnath'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'MANOJKUMA R CHANDRESH WAR MHATRE') {$x_of_cands{$key}='Manojkumar Chandreshwar Mhatre'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'R.R. PANDAYAN') {$x_of_cands{$key}='R. R.Pandayan'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'SR. NO.') {undef($x_of_cands{$key})}
		elsif ($ac==172 && $x_of_cands{$key} eq 'TUKARAM RAMKRISHN A KATE') {$x_of_cands{$key}='Tukaram Ramkrushna Kate'}
		elsif ($ac==172 && $x_of_cands{$key} eq 'VINA RAJESH UKRANDE') {$x_of_cands{$key}='Veena Rajesh Ukrande'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'CHAND RAKAN T DAMO DHAR HANDO RE') {$x_of_cands{$key}='Chandrakant Damodhar Handore'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'DINES H SOM A BODH IRAJ') {$x_of_cands{$key}='Dinesh Soma Bodhiraj'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'DIPAK SADAS HIV NIKALJE') {$x_of_cands{$key}='Dipak Sadashiv Nikalje'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'MUK TAJI NARA YAN SONA VANE') {$x_of_cands{$key}='Muktaji Narayan Sonavane'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'PRAKAS H VAIKUN TH PHATER PEKAR') {$x_of_cands{$key}='Prakash Vaikunth Phaterpekar'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'RAJU KACH ARU SONT AKKE') {$x_of_cands{$key}='Raju Kacharu Sontakke'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'RAVI NDRA PAW AR') {$x_of_cands{$key}='Ravindra Pawar'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'SARIK A MAN OJ SAW ANT THAD ANI') {$x_of_cands{$key}='Sarika Manoj Sawant-Thadani'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'SHRIR AM MAT AFER MAN AV') {$x_of_cands{$key}='Shriram Matafer Manav'}
		elsif ($ac==173 && $x_of_cands{$key} eq 'SIRAJ AHM ED KHAN') {$x_of_cands{$key}='Siraj Ahmed Khan'}
		elsif ($ac==174 && $x_of_cands{$key} eq 'Brahmanand G. Shinde') {$x_of_cands{$key}='Bramhanand G.Shinde (B.G.)'}
		elsif ($ac==174 && $x_of_cands{$key} eq 'Milind') {$x_of_cands{$key}='Milind (Anna) Kamble'}
		elsif ($ac==174 && $x_of_cands{$key} eq 'Sr. No.') {undef($x_of_cands{$key})}
		elsif ($ac==175 && $x_of_cands{$key} eq '') {undef($x_of_cands{$key})}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Bagdi Sanjeev Kherlal') {$x_of_cands{$key}='Bagadi Sanjeev Kherlal'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Birmole Tukaram') {$x_of_cands{$key}='Birmole Tukaram (Ganesh)'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Khan Rahebar Siraj') {$x_of_cands{$key}='Khan Rahebar Siraj (Raja)'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Meraz Khan') {$x_of_cands{$key}='Meraj Khan'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Milind Dhanjay Salvi') {$x_of_cands{$key}='Milind Dhananjay Salvi'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Nasim Abdulla Saikh') {$x_of_cands{$key}='Nasim Abdulla Shaikh'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Prakash') {$x_of_cands{$key}='Prakash (Bala) Vasant Sawant'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Shaikh Noor Moham mad') {$x_of_cands{$key}='Shaikh Noor Mohammad'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Shilpa Atul Sarpotd ar') {$x_of_cands{$key}='Shilpa Atul Sarpotdar'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Sunil Sadashi v Rajguru') {$x_of_cands{$key}='Sunil Sadashiv Rajguru'}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Table No') {undef($x_of_cands{$key})}
		elsif ($ac==176 && $x_of_cands{$key} eq 'Vilas Krishna Patkar') {$x_of_cands{$key}='Vilas Krushna Patkar'}
		elsif ($ac==177 && $x_of_cands{$key} eq 'Sr. No.') {undef($x_of_cands{$key})}
		elsif ($ac==179 && $x_of_cands{$key} eq 'Captain R. Tamil Selvan') {$x_of_cands{$key}='Captain R. Tamil Selvan,'}
		elsif ($ac==179 && $x_of_cands{$key} eq 'Mandeep Singh') {$x_of_cands{$key}='Mandeep Singh (Ladi)'}
		elsif ($ac==179 && $x_of_cands{$key} eq 'Moham mad Raza Shaikh') {$x_of_cands{$key}='Mohammad Raza Shaikh'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'DIGAMBAR RAMBHAU SALVE') {$x_of_cands{$key}='Digambar Rambhau Salve 1 M'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'KHALID SIDDIQUI') {$x_of_cands{$key}='Khalid Siddiqui R R'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'MIHIR CHANDRAKAN T KOTECHA') {$x_of_cands{$key}='Mihir Chandrakant Kotecha'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'MOHD. FIROZ KHAN') {$x_of_cands{$key}='Mohd. Firoz Khan R C 0'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'NIHALUDDIN MOHAMMAD SULEMAN SHAIKH') {$x_of_cands{$key}='Nihaluddin Mohammad Suleman 4 Shaikh W'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'ROHAN') {$x_of_cands{$key}='Rohan (Chandrakant) Gauru Tambe 3 M'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'SATISH SHESHRAO NIKALJE') {$x_of_cands{$key}='Satish Sheshrao Nikalje 1 W M'}
		elsif ($ac==180 && $x_of_cands{$key} eq 'TABLE NO') {undef($x_of_cands{$key})}
		elsif ($ac==180 && $x_of_cands{$key} eq 'YESHWANT DABHOLKAR') {$x_of_cands{$key}='Yeshwant Dabholkar S R'}
		elsif ($ac==181 && $x_of_cands{$key} eq 'AnisAhmed Qureshi') {$x_of_cands{$key}='Anis Ahmed Qureshi'}
		elsif ($ac==181 && $x_of_cands{$key} eq 'Com. Eknath Sakhar am Mane') {$x_of_cands{$key}='Com. Eknath Sakharam Mane'}
		elsif ($ac==181 && $x_of_cands{$key} eq 'Sada Sarvank ar') {$x_of_cands{$key}='Sada Sarvankar'}
		elsif ($ac==184 && $x_of_cands{$key} eq 'Madhu') {$x_of_cands{$key}='Madhu (Dada) Chavan'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'ABDUL LATIF SHAIKH') {$x_of_cands{$key}='Abdul Latif Shaikh (Pappu Bhai)'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'AFZAL SHABBI RALI DAWO ODANI') {$x_of_cands{$key}='Afzal Shabbirali Dawoodani'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'AFZAL SHABBIRA LI DAWOOD ANI') {$x_of_cands{$key}='Afzal Shabbirali Dawoodani'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'AL HAJ ADVOCATE ABDUL KADAR KHAN') {$x_of_cands{$key}='Al-Haj Advocate Abdul Kadar Khan C N'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'CUMULATIVE ROUND NUMBER') {undef($x_of_cands{$key})}
		elsif ($ac==186 && $x_of_cands{$key} eq 'HUZEFA ELECTRIC WALA') {$x_of_cands{$key}='Huzefa Electricwala D C'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'HUZEFA ELECTRICW ALA') {$x_of_cands{$key}='Huzefa Electricwala D C'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'MOHAM MED SHAHID RAFI') {$x_of_cands{$key}='Mohammed Shahid Rafi'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'MOHAMM ED HANIF ABBAS MANSURI') {$x_of_cands{$key}='Mohammed Hanif Abbas Mansuri'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'MOHAMM ED NABI SHAIKH') {$x_of_cands{$key}='Mohammed Nabi Shaikh (Nabi Miya)'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'PAGE NO FORM PART I STATE ASSEMBLY ELECTION') {undef($x_of_cands{$key})}
		elsif ($ac==186 && $x_of_cands{$key} eq 'Recorded Votes') {undef($x_of_cands{$key})}
		elsif ($ac==186 && $x_of_cands{$key} eq 'SALEKAR YUGAND HARA YASHWA NT') {$x_of_cands{$key}='Salekar Yugandhara Yashwant'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'SALEKAR YUGANDHA RA YASHWANT') {$x_of_cands{$key}='Salekar Yugandhara Yashwant'}
		elsif ($ac==186 && $x_of_cands{$key} eq 'TABLE NO') {undef($x_of_cands{$key})}
		elsif ($ac==187 && $x_of_cands{$key} eq 'ARVIND DNYANES HWAR GAWDE') {$x_of_cands{$key}='Arvind Dnyaneshwar Gawde'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'ARVIND DNYANESH WAR GAWDE') {$x_of_cands{$key}='Arvind Dnyaneshwar Gawde'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'BERNA RD CHAVES') {$x_of_cands{$key}='Bernard Chaves (Bharat Patil)'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'BERNARD CHAVES') {$x_of_cands{$key}='Bernard Chaves (Bharat Patil)'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'CUMULATIVE ROUND NUMBER') {undef($x_of_cands{$key})}
		elsif ($ac==187 && $x_of_cands{$key} eq 'DESHAPP A SHIVAPP A RATHOD') {$x_of_cands{$key}='Deshappa Shivappa Rathod'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'JAIN SURENDR AKUMAR K.') {$x_of_cands{$key}='Jain Surendrakumar K.'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'KAMBLE RAMESH KASHIRA M') {$x_of_cands{$key}='Kamble Ramesh Kashiram'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'MOHAM MED TAIYAB IBRAHI M TAI') {$x_of_cands{$key}='Mohammed Taiyab Ibrahim Tai'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'MOHAM MED TAIYAB IBRAHIM TAI') {$x_of_cands{$key}='Mohammed Taiyab Ibrahim Tai'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'PANDUR ANG GANPAT SAKPAL') {$x_of_cands{$key}='Pandurang Ganpat Sakpal'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'PANDURAN G GANPAT SAKPAL') {$x_of_cands{$key}='Pandurang Ganpat Sakpal'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'RAJ K.PUROH IT') {$x_of_cands{$key}='Raj K. Purohit'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'RAJ K.PUROHIT') {$x_of_cands{$key}='Raj K. Purohit'}
		elsif ($ac==187 && $x_of_cands{$key} eq 'Recorded Votes') {undef($x_of_cands{$key})}
		elsif ($ac==187 && $x_of_cands{$key} eq 'TABLE NO') {undef($x_of_cands{$key})}
		
		# check if candidate remains unknown
		if (defined($x_of_cands{$key})) {
		    my $re2f = $dbh->selectcol_arrayref("SELECT id FROM candidates WHERE ac = ? AND name LIKE ?",undef,$ac,$x_of_cands{$key});
		    if (scalar(@$re2f) != 1) {$print{'                elsif ($ac=='.$ac.' && $x_of_cands{$key} eq \''.$x_of_cands{$key}.'\') {$x_of_cands{$key}=\''."'}\n"}++;  $troubleac{$ac}=1; undef($x_of_cands{$key}); next key}
		    $x_of_cands{$key}=$$re2f[0];
		}
		
	    }
	    
	}
	
	# iterate through CSV to identify polling stations
	foreach my $line (@csv) {
	    
	    $csv->parse($line);
	    my @fields=$csv->fields();
	    
	    if ($fields[0] == $x_of_ps and $fields[5] =~ /^\d+$/) {$y_of_ps{$fields[3]}=$fields[5]}
	    
	}
	
        # iterate through CSV to count votes
	foreach my $line (@csv) {
	    
	    $csv->parse($line);
	    my @fields=$csv->fields();
	    
	    if (defined($x_of_cands{$fields[0]}) and defined($y_of_ps{$fields[3]}) and $fields[0] != $x_of_ps and $fields[5] =~ /^\d+$/) {
		
		$dbh->do("INSERT INTO results VALUES (?,?,?,?)",undef,$ac,$y_of_ps{$fields[3]},$x_of_cands{$fields[0]},$fields[5]);
		
	    }
	    
	}
	

    }
    
    $dbh->commit;
}

# print diagnostics
foreach my $key (sort(keys(%print))) {print $key}
foreach my $key (sort {$a <=> $b} (keys(%troubleac))) {print "Troubling AC: ".$key."\n"}

# cleanup

stop:

$dbh->disconnect;

system("cat cleanup.sql | sqlite3 results.sqlite");
system("cat extract.sql | sqlite3 results.sqlite");
