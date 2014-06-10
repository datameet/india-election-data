#!/usr/bin/perl

use WWW::Mechanize;
use DBD::SQLite;
use Text::CSV;

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
    next if $state ne 'S06';
    next if $fields[1] =~ /none of the above/i;
    $dbh->do ("INSERT INTO candidates (pc,rank,name,party) VALUES (?,?,?,?)",undef,$pc,$rank,$fields[1],$party{$fields[2]});
}

# then read actual form20 results

undef(my %print); undef(my %troubleac);

$dbh->begin_work;

# iterate through PCs
for ($pc=1;$pc<=26;$pc++) {

    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'valid');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'rejected');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'nota');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'total');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'tendered');
    
    my $ref = $dbh->selectcol_arrayref("SELECT ac FROM actopc WHERE state_name = 'Gujarat' AND pc = ?",undef,$pc);

    # iterate through relevant ACs
    foreach my $ac (@$ref) {
		
	my $code=$ac;
	if ($code<10) {$code="00$code"}
	elsif ($code<100) {$code="0$code"}
	
	# generate CSV file if not yet there
	if (!-e "AC$code.csv") {
	    
	    my $pagecount=`gs -q -dNODISPLAY -c "(AC$code.PDF) (r) file runpdfbegin pdfpagecount = quit" `;
	    chomp($pagecount);
	    
	    undef(my @csv);
	    for ($page=1;$page<=$pagecount;$page++) {
		if (!-e "AC$code.$page.csv") {system("pdf-table-extract -r 300 -p $page -i AC$code.PDF -o AC$code.$page.csv -t table_csv");}
		
		open (CSV,"AC$code.$page.csv");
		my @temp = <CSV>;
		push (@csv,@temp);
		close (CSV);
		
		system("rm -f AC$code.$page.csv");
	    }
	    
	    $toggle=0; my $checkit=0;
	    open (CSV,">AC$code.csv");
	    undef(my %line);
	    foreach my $line (@csv) {
		next if $line =~ /^\,+\n$/;
		next if $line =~ /annexure/i;
		next if $line =~ /^[, ]*page/i;
		next if $line =~ /^[, ]*form.20/i;
		next if defined($line{$line});
		$line{$line}=1;
		print CSV $line;
	    }
	    close (CSV);
	
	}

	my $csv = Text::CSV->new({binary=>1});
	
	# read in CSV file, prepare stuff
	open (CSV,"AC$code.csv");
	my @csv = <CSV>;
	close (CSV);

	undef(my %cand);
	undef(my $pscol);
	my $toggle=0;
	
	# iterate through CSV file
	foreach my $line (@csv) {
	    
	    if ($toggle == 0) { # filter garbage and register general names
		if ($line =~ /Polling St/gsi) {
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
		
		if ($ac==10) {
		    $cand{1}='Chaudhary Haribhai Parthibhai';
		    $cand{2}='Patel Joitabhai Kasnabhai';
		    $cand{3}='Mahant Parsotamgiri Turantgiri';
		    $cand{4}='Choudhary Adambhai Nasirbhai';
		    $cand{5}='Sanjaykumar Somnathbhai Raval';
		    $cand{6}='Gamar Vadhabhai Radhabhai';
		    $cand{7}='Thakor Bhupataji Ravaji';
		    $cand{8}='Dabhi Navajibhai Madhabhai';
		    $cand{9}='Babaji Thakor';
		    $cand{10}='Mahendrabhai Kesarabhai Bumbadia';
		    $cand{11}='Madhu Nirupaben Natvarlal';
		    $cand{12}='Shrimali Ashokbhai Balchndbhai';
		    $cand{13}='Solanki Dineshkumar Aljibhai';
		    $cand{14}='Solanki Saybabhai Nanabhai';
		} elsif ($ac==58) {
		    $cand{1}='CHAUHAN DEVUSINH JESINGBHAI';
		    $cand{2}='DINSHA PATEL';
		    $cand{3}='PANDAV BHAILALBHAI KALUBHAI';
		    $cand{4}='ABDUL RAZAKKHAN PATHAN';
		    $cand{5}='BADHIWALA LABHUBHAI JIVRAJBHAI';
		    $cand{6}='RANVEER PRANAYRAJ GOVINDBHAI';
		    $cand{7}='KHRISTI ADWARD KHUSHALBHAI';
		    $cand{8}='CHAUHAN DEVUSING MOTISHING';
		    $cand{9}='PATHAN AMANULLAKHA SITABKHA';
		    $cand{10}='PARIKH VIRAL HASMUKHBHAI';
		    $cand{11}='MALEK YAKUBMIYA NABIMIYA';
		    $cand{12}='MALEK SADIK HUSHEN MAHAMMD HUSHEN';
		    $cand{13}='MALEK SABIRHUSEN ISMAELBHAI';
		    $cand{14}='RATANSINH UDESINH CHAUHAN';
		    $cand{15}='ROSHAN PRIYAVADAN SHAH';
		} elsif ($ac==81) {
		    $cand{1}='AHIR VIKRAMBHAI ARJANBHAI MADAM';
		    $cand{2}='POONAMBEN HEMATBHAI MAADAM';
		    $cand{3}='SAMA YUSUF';
		    $cand{4}='KASAMBHAI';
		    $cand{5}='JHALA RAJENDRASINH';
		    $cand{6}='SAIYAD ABUBAKAR IBRAHIM';
		    $cand{7}='CHANDRAVIJAYSINH TAKHUBHA RANA';
		    $cand{8}='DALIT ASHOK NATHABHAI CHAVDA';
		    $cand{9}='DALIT JITESH BABUBHAI RATHORE';
		    $cand{10}='DHANJIBHAI LALJIBHAI RANEVADIA';
		    $cand{11}='DHARAVIYA VALLABHBHAI';
		    $cand{12}='NARIYA PRAVINBHAI VALLABHBHAI';
		    $cand{13}='PADHIYAR LALJIBHAI KARABHAI';
		    $cand{14}='PANDYA CHIRAGBHAI HARIOMBHAI';
		    $cand{15}='BATHWAR NANJIBHAI';
		    $cand{16}='MAMAD HAJI BOLIM';
		    $cand{17}='MEMAN RAFIK ABUBAKAR POPATPUTRA';
		    $cand{18}='VAGHER ALI ISHAK PALANI';
		    $cand{19}='VAGHER JAVIDBHAI OSMANBHAI NOLE';
		    $cand{20}='VANIYA GANGAJIBHAI';
		    $cand{21}='SACHADA HABIB ISHABHAI';
		    $cand{22}='SUTHAR HANSABEN HARSUKHBHAI GORECHA';
		    $cand{23}='SUMARA AMANDBHAI NOORMAMADBHAI SUMARA';
		    $cand{24}='SODHA SALIMBHAI NURMAMADBHAI';
		    $cand{25}='SANDHI MAMADBHAI HAJIBHAI SAFIA';
		} elsif ($ac==106) {
		    $cand{1}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)';
		    $cand{2}='DR. BHARATIBEN DHIRUBHAI SHIYAL';
		    $cand{3}='RATHOD PRAVINBHAI JINABHAI';
		    $cand{4}='DR. KANUBHAI V. KALSARIA';
		    $cand{5}='KAGADA RAMESHBHAI PUNABHAI';
		    $cand{6}='KHADRANI ASIMBHAI PIRBHAI';
		    $cand{7}='GOHIL PRAVINSINH DHIRUBHA';
		    $cand{8}='GOHEL BHARATBHAI BHIMABHAI';
		    $cand{9}='JAGADISHBHAI AMARABHAI VEGAD';
		    $cand{10}='BHAVES GHANSHYAMBHAI RAJYAGURU';
		    $cand{11}='MEHTA YASHVANTRAY ODHAVJIBHAI';
		    $cand{12}='MARU MANHAR VALAJIBHAI';
		    $cand{13}='RASIDKHAN HASANKHAN PATHAN';
		    $cand{14}='RATHOD PRAVINSINH CHANDRASINH';
		    $cand{15}='VAGHELA NARENDRABHAI SHAVJIBHAI';
		    $cand{16}='VEGAD NATHABHAI';
		} elsif ($ac==144) {
		    $cand{1}='NARENDRA MODI';
		    $cand{2}='MISTRI MADHUSUDAN DEVRAM';
		    $cand{3}='ROHIT MADHUSUDAN MOHANBHAI';
		    $cand{4}='JADAV AMBALAL KANABHAI';
		    $cand{5}='TAPAN DASGUPTA';
		    $cand{6}='PATHAN MAHEMUDKHAN RAZAKKHAN';
		    $cand{7}='PATHAN SAHEBKHAN ASIFKHAN';
		    $cand{8}='SUNIL DIGAMBAR KULKARNI';
		}
		
		key: foreach my $key (sort(keys(%cand))) {
		    $cand{$key} =~ s/\s*\(.*//gs;
		    $cand{$key} =~ s/[^A-Za-z\.\(\) ]/ /gs;
		    $cand{$key} =~ s/\s+/ /gs;
		    $cand{$key} =~ s/\s+$//gs;
		    $cand{$key} =~ s/^\s+//gs;
		    
		    if ($cand{$key} eq 'Valid' or $cand{$key} =~ /valied votes/i or $cand{$key} =~ /valid\s* votes/i or $cand{$key} eq 'valid' or $cand{$key} =~ /total\s* of\s* valid/i) {$cand{$key}='valid'}
		    elsif ($cand{$key} =~ /rejected/i or $cand{$key} =~ /rejecte d vote/i or $cand{$key} eq 'No. of Reject votes' or $cand{$key} eq 'No. of reje cted votes' or $cand{$key} eq 'reje cted votes' or $cand{$key} eq 'Total of Reject - ed Votes' or $cand{$key} =~ /rejec\s*t\s*e\s*d vote/i or $cand{$key} =~ /rejected\/ missing/ or $cand{$key} eq 'rejected' ) {$cand{$key}='rejected'}
		    elsif ($cand{$key} =~ /[\'\" ]N\s*O\s*T\s*A[\'\" ]/i or $cand{$key} eq 'N O T A' or $cand{$key} eq 'O T A' or $cand{$key} eq 'NOTA 5' or $cand{$key} eq 'NOTA' or $cand{$key} eq 'Nota' or $cand{$key} =~ /none\s* of\s* the\s* above/i  or $cand{$key} eq 'nota') {$cand{$key}='nota'}
		    elsif ($cand{$key} =~ /^Total$/i or $cand{$key} =~ /Total\s* vote/i or $cand{$key} eq 'total' ) {$cand{$key}='total'}
		    elsif ($cand{$key} =~ /tender votes/i or $cand{$key} =~ /tendered\s* vo/i or $cand{$key} =~ /tende red vote/i or $cand{$key} =~ /tendere d vote/i or $cand{$key} eq 'No. of tende red votes' or $cand{$key} eq 'No.of tender votes' or $cand{$key} eq 'No of Tender- ed Votes' or $cand{$key} =~ /tenderd vote/i or $cand{$key} eq 'tende red votes' or $cand{$key} =~ /tende\s*r ed vote/i or $cand{$key} =~ /Tendere d vote/i or $cand{$key} eq 'tendered' or $cand{$key} =~ /tendred votes/i) {$cand{$key}='tendered'}
		    elsif (!defined($pscol) and ($cand{$key} eq 'No. of P.S.' or $cand{$key} =~ /polling st/i or $cand{$key} eq 'Station')) {$pscol=$key;undef($cand{$key})}
		    elsif ($cand{$key} eq '' or $cand{$key} !~ /\D/ or $cand{$key} eq 'Name' or $cand{$key} eq 'NAME' or $cand{$key} eq 'o.' or $cand{$key} eq '03-BHUJ' or ($ac==40 and $key==27) or $cand{$key} =~ /Sr\s*No\./i or $cand{$key} =~ /Sr\.\s*No/i or $cand{$key} eq 'Table No.' or $cand{$key} =~ /1E\+\d+/ or $cand{$key} =~ /returning officer/i or $cand{$key} !~ /\D/ or $cand{$key} =~ /test votes/i) {undef($cand{$key})}
		    else {
			if ($pc==4 && $cand{$key} eq 'Thakor Samaratji Balavantsinh') {$cand{$key}='THAKOR SAMARATJI BALVANTSINH'}
			elsif ($pc==4 && $cand{$key} eq 'Smt. Vandanaben Dineshkumar Patel') {$cand{$key}='SMT VANDANABEN DINESHKUMAR PATEL'}
			elsif ($pc==6 && $cand{$key} eq 'M. K.Shah') {$cand{$key}='M. K. SHAH'}
			elsif ($pc==7 && $cand{$key} eq 'Khalifa Samsuddin Nasirudding') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==7 && $cand{$key} eq 'Dutt Aakash - Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'}
			elsif ($pc==9 && $cand{$key} eq 'PARMARVASHARAMBHAI BAVALBHAI') {$cand{$key}='PARMAR VASHARAMBHAI BAVALBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'MAKWANA UKABHAI AMRATBHAI') {$cand{$key}='MAKWANA UKABHAI AMRABHAI'}
			elsif ($pc==9 && $cand{$key} eq 'ZALA MANSINH SHIVUBHA') {$cand{$key}='MANSINH SHIVUBHA ZALA'}
			elsif ($pc==9 && $cand{$key} eq 'VAGEHLA PRAKASHBHAI BACHUBHAI') {$cand{$key}='VAGHELA PRAKASHBHAI BACHUBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'VORA BHAVABHAI DEVABHAI') {$cand{$key}='VORA BHAVANBHAI DEVAJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'FATEPARA DEVJIBHAI GOVINDBHAI') {$cand{$key}='FATEPARA DEVAJIBHAI GOVINDBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'PATEL JETHABHAI MANJIBHAI') {$cand{$key}='JETHABHAI MANJIBHAI PATEL'}
			elsif ($pc==9 && $cand{$key} eq 'CHAVADA PALABHAI NANJIBHAI') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'PARMAR PARBHUBHAI GOKABHAI') {$cand{$key}='PARMAR PRABHUBHAI GOKALBHAI'}
			elsif ($pc==7 && $cand{$key} eq 'Naranbhai T. Sengal') {$cand{$key}='NARANBHAI T. SENGAL (DR. N. T. SENGAL)'}
			elsif ($pc==14 && $cand{$key} eq 'THUMMAR VIRJIBHAI KESHAVBHAI') {$cand{$key}='THUMMAR VIRJIBHAI KESHAVBHAI (VIRJIBHAI THUMMAR)'}
			elsif ($pc==16 && $cand{$key} eq 'Patel Naineshkuma r Umedbhai') {$cand{$key}='PATEL NAINESHKUMAR UMEDBHAI'}
			elsif ($pc==16 && $cand{$key} eq 'Vahora Firojbhai Walimahamad bhai') {$cand{$key}='VAHORA FIROJBHAI WALIMAHAMADBHAI (KASORWALA)'}
			elsif ($pc==16 && $cand{$key} eq 'Vaghela Bharat P') {$cand{$key}='VAGHELA BHARAT P.'}
			elsif ($pc==16 && $cand{$key} eq 'Purshottambhai Alias Kanubhai Mathurbhai Chauhan') {$cand{$key}='PURSOTTAMBHAI ALIAS KANUBHAI MATHURBHAI CHAUHAN'}
			elsif ($pc==16 && $cand{$key} eq 'Girishbhai Das') {$cand{$key}='GIRISHBHAI DAS (ADVOCATE)'}
			elsif ($pc==16 && $cand{$key} eq 'Padhiyar Vikramsinh') {$cand{$key}='PADHIYAR VIKRAMSINH (VAKIL)'}
			elsif ($pc==16 && $cand{$key} eq 'Ravjibhai S Parmar') {$cand{$key}='RAVJIBHAI S. PARMAR'}
			elsif ($pc==17 && $cand{$key} eq 'Parikh Viral Hasmukhbh ai') {$cand{$key}='PARIKH VIRAL HASMUKHBHAI'}
			elsif ($pc==17 && $cand{$key} eq 'Roshan Priyavada n Shah') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'}
			elsif ($pc==17 && $cand{$key} eq 'Abdul Razakkha n Pathan') {$cand{$key}='ABDUL RAZAKKHAN PATHAN'}
			elsif ($pc==17 && $cand{$key} eq 'Khristi Adward Khushalbh ai') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'}
			elsif ($pc==3 && $cand{$key} eq 'Rathod Bhavsinhbhai Dahyabha') {$cand{$key}='RATHOD BHAVSINHBHAI DAHYABHAI'}
			elsif ($pc==4 && $cand{$key} eq 'Patel Vandanaben Dineshbhai') {$cand{$key}='SMT VANDANABEN DINESHKUMAR PATEL'}
			elsif ($pc==4 && $cand{$key} eq 'Pathan Mahmad Azam Haidarkhan') {$cand{$key}='MAHMAD AZAM HAIDERKHAN PATHAN'}
			elsif ($pc==4 && $cand{$key} eq 'Dabhi Girishji Jenaji') {$cand{$key}='GIRISHJI JENAJI DABHI'}
			elsif ($pc==7 && $cand{$key} eq 'VIJAYKUMAR M VADHER') {$cand{$key}='VIJAYKUMAR M. VADHEL'}
			elsif ($pc==7 && $cand{$key} eq 'Khalifa Samsuddin Nasiruddin') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==8 && $cand{$key} eq 'Solanki Vithalbhai Maganbhai') {$cand{$key}='SOLANKI VITTHALBHAI MAGANBHAI'}
			elsif ($pc==7 && $cand{$key} eq 'ANIL KUMAR SHARMA') {$cand{$key}='ANILKUMAR SHARMA'}
			elsif ($pc==8 && $cand{$key} eq 'Dr. J G Parmar') {$cand{$key}='DR J. G. PARMAR'}
			elsif ($pc==9 && $cand{$key} eq 'Parmar Vashrambhai Bavalbhai') {$cand{$key}='PARMAR VASHARAMBHAI BAVALBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Ukabhai Amrabhai') {$cand{$key}='MAKWANA UKABHAI AMRABHAI'}
			elsif ($pc==7 && $cand{$key} eq 'DASHRATHBHAI M DEVDA') {$cand{$key}='DASHRATHBHAI M. DEVDA'}
			elsif ($pc==8 && $cand{$key} eq 'J J Mevada') {$cand{$key}='J. J. MEVADA'}
			elsif ($pc==9 && $cand{$key} eq 'Vora Bhavanbhai Devjibhai') {$cand{$key}='VORA BHAVANBHAI DEVAJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Vashrambhai Karshanbhai') {$cand{$key}='MAKWANA VASHARAMBHAI KARSHANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'CHAVDA PALABHAI NANAJIBHAI') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Tukadiya G.R.') {$cand{$key}='TUKADIA G. R.'}
			elsif ($pc==11 && $cand{$key} eq 'Rathod Chandulal Mohanbhai') {$cand{$key}='RATHOD CHANDULAL MOHANLAL'}
			elsif ($pc==7 && $cand{$key} eq 'ROSHAN PRIYVADAN SHAH') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'}
			elsif ($pc==7 && $cand{$key} eq 'NARANBHAI T SENGAL') {$cand{$key}='NARANBHAI T. SENGAL (DR. N. T. SENGAL)'}
			elsif ($pc==7 && $cand{$key} eq 'BUDDHPRIYA JASHVANT SOMABHAI') {$cand{$key}='BUDDHPRIYA JASVANT SOMABHAI'}
			elsif ($pc==7 && $cand{$key} eq 'PARESH RAVAL') {$cand{$key}='PARESH RAWAL'}
			elsif ($pc==7 && $cand{$key} eq 'KHALIFA SAMSUDDIN NASIRUDDIN') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==7 && $cand{$key} eq 'ROHIT RAJUBHAI VIRJIBHAI URF MANOJ SONTARIYA') {$cand{$key}='ROHIT RAJUBHAI VIRJIBHAI ALIAS MANOJBHAI SONTARIYA'}
			elsif ($pc==7 && $cand{$key} eq 'DATT AKASH ADVOCATE') {$cand{$key}='DUTT AAKASH -. ADVOCATE'}
			elsif ($pc==9 && $cand{$key} eq 'Bar Ajmalbhai Karmanbhai') {$cand{$key}='BAR AJAMALBHAI KARMANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Vadliya Kalubhai Malubhai') {$cand{$key}='VADALIYA KALUBHAI MALUBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Majethiya Samratbhai Jerambhai') {$cand{$key}='MAJETHIYA SAMARATBHAI JERAMBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Chavda Palabhai Nanajibhai') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Fatepara Devjibhai Govindbhai') {$cand{$key}='FATEPARA DEVAJIBHAI GOVINDBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Vasharambhai Karshanbhai') {$cand{$key}='MAKWANA VASHARAMBHAI KARSHANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Sapra Vipulbhai Rameshbhai') {$cand{$key}='SAPARA VIPULBHAI RAMESHBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Parmar Prabhubhai Gokalbha') {$cand{$key}='PARMAR PRABHUBHAI GOKALBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Sadiya Vrajlal Pababhai') {$cand{$key}='SADIYA VRAJALAL PABABHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Naranbh ai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Irfanshah Habibshah Suhravardi') {$cand{$key}='IRFANSHAH HABIBSHAH SUHARAVARDI'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Naranbhai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Mansukh Sundarji Dhokai') {$cand{$key}='MANSUKH SUNDARAJI DHOKAI'}
			elsif ($pc==11 && $cand{$key} eq 'Irafanshah Habibshah Suhravardi') {$cand{$key}='IRFANSHAH HABIBSHAH SUHARAVARDI'}
			elsif ($pc==11 && $cand{$key} eq 'Unadakat Prakash Vallabhada s') {$cand{$key}='UNADAKAT PRAKASH VALLABHADAS'}
			elsif ($pc==11 && $cand{$key} eq 'Tukadia G.R.') {$cand{$key}='TUKADIA G. R.'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Narambhai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Radadiya Vitthalbhai Hansarajbhai') {$cand{$key}='RADADIYA VITHALBHAI HANSRAJBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Atul Govindbhai Shekhda') {$cand{$key}='ATUL GOVINDBHAI SHEKHADA'}
			elsif ($pc==13 && $cand{$key} eq 'Harilal Ranchhodb hai Chauhan') {$cand{$key}='HARILAL RANCHHODBHAI CHAUHAN'}
			elsif ($pc==13 && $cand{$key} eq 'Saiyad Altafhusen Abdulahmiya') {$cand{$key}='SAIYED ALTAF HUSAIN ABDULLAH MIYAN'}
			elsif ($pc==13 && $cand{$key} eq 'Kadri Ibrahim saiyad Husen') {$cand{$key}='KADRI IBRAHIM SAIYED HUSEN'}
			elsif ($pc==13 && $cand{$key} eq 'Gadhiya Soyeb Hushenbha i') {$cand{$key}='GADHIYA SOYEB HUSHENBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Gadhiya Soyeb Husenbhai') {$cand{$key}='GADHIYA SOYEB HUSHENBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Punjabhai Bhimabhai Vainsh') {$cand{$key}='PUNJABHAI BHIMABHAI VANSH'}
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVA NT RAY ODHAVJI BHAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Vegad Nathabhai') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'}
			elsif ($pc==15 && $cand{$key} eq 'Rathod Pravin sinh Chandra sinh') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN BHAI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR VALJI BHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'JAGDISH BHAI AMARA BHAI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'}
			elsif ($pc==15 && $cand{$key} eq 'DR. BHARATI BEN DHIRU BAHI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHA BHAI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'}
			elsif ($pc==15 && $cand{$key} eq 'Maru Manhar Valjibhai') {$cand{$key}='MARU MANHAR VALAJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHANSHYAM BHAI RAJYAGURU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVANT RAY ODHAVJI BHAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'DR. KANU BHAI V. KALSARIA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Dr.Bharatiben Dhirubhai Shiyal') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==15 && $cand{$key} eq 'RASID KHAN HASAN KHAN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'}
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARAT BHAI BHIMA BHAI') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHAN SHYAM BHAI RAJYA GURU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDRA BHAI SHAVJI BHAI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARE NDRA BHAI SHAVJI BHAI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'KHAD RANI ASIM BHAI PIRBHAI') {$cand{$key}='KHADRANI ASIMBHAI PIRBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN BHAI JINA BHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Vaghela Narendra bhai Shavji bhai') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN SINH CHANDRA SINH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'}
			elsif ($pc==15 && $cand{$key} eq 'DR. KANUBHAI V. KALSARIYA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Mehta Yashvan tray Odhavji bhai') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVI NSINH DHIRU BHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'}
			elsif ($pc==15 && $cand{$key} eq 'Dr.Kanubhai V. Kalsaria') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Jagdishbhai Amarabhai Vegad') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'}
			elsif ($pc==15 && $cand{$key} eq 'GITA CHETAN PAUNDA') {$cand{$key}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)'}
			elsif ($pc==15 && $cand{$key} eq 'Rathod Pravinhai Jinabhai') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Kagada Ramesh bhai Punabhai') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVIN SINH DHIRU BHAI') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'}
			elsif ($pc==15 && $cand{$key} eq 'KAGADA RAMESH BHAI PUNA BHAI') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Bhaves Ghanshyam bhai Rajyaguru') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'DR. BHARATI BEN DHIRU BHAI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==17 && $cand{$key} eq 'ADWARD KHUSHALBHA I') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'}
			elsif ($pc==17 && $cand{$key} eq 'MALEK SADIK HUSHEN MAH. HUSHEN') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'}
			elsif ($pc==20 && $cand{$key} eq 'MISTRI MADHUSUD AN DEVRAM') {$cand{$key}='MISTRI MADHUSUDAN DEVRAM'}
			elsif ($pc==20 && $cand{$key} eq 'PATHAN MAHEMUDK HAN RAZAKKHAN') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'}
			elsif ($pc==20 && $cand{$key} eq 'Pathan Mahemudk han Razakkhan') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'}
			elsif ($pc==20 && $cand{$key} eq 'ROHIT MADHUSUD AN MOHANBHAI') {$cand{$key}='ROHIT MADHUSUDAN MOHANBHAI'}
			elsif ($pc==20 && $cand{$key} eq 'Sunil Digamba r Kulkarn i') {$cand{$key}='SUNIL DIGAMBAR KULKARNI'}
			elsif ($pc==21 && $cand{$key} eq 'NARANBHAI JEMALABHAI RATHAVA') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Naranbhai Jemlabhai Rathva') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'PRO. ARJUNBHAI VERSINGBHA I RATHAVA') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Prof. Arjunbhai Versingbhai Rathva 3') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Prof. Arjunbhai Versingbhai Rathva Aam Aadmi Party') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'RAMSINH RATHAVA') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Ramsinh Rathva') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Ramsinh Rathwa 2') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Vasava Prafulbhai Devajibhai Jantadal') {$cand{$key}='VASAVA PRAFULBHAI DEVJIBHAI'}
			elsif ($pc==21 && $cand{$key} eq 'Vasava Prafulbhai Devjibhai 4') {$cand{$key}='VASAVA PRAFULBHAI DEVJIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Anandkumar Sarvarsinh Vasava - IND') {$cand{$key}='ANANDKUMAR SARVARSINH VASAVA'}
			elsif ($pc==22 && $cand{$key} eq 'Anilkumar Chhitubhai Bhagat - JD') {$cand{$key}='ANILKUMAR CHHITUBHAI BHAGAT'}
			elsif ($pc==22 && $cand{$key} eq 'Bhura Shabbirbhai Valibhai - IND') {$cand{$key}='BHURA SHABBIRBHAI VALIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Jayendrasinh Rana - AAP') {$cand{$key}='JAYENDRASINH RANA'}
			elsif ($pc==22 && $cand{$key} eq 'Nitin Ishwarlal Vakil') {$cand{$key}='NITIN ISHWARLAL VAKIL (ADVOCATE)'}
			elsif ($pc==22 && $cand{$key} eq 'Patel Jayeshbhai Ambalalbhai') {$cand{$key}='PATEL JAYESHBHAI AMBALALBHAI (JAYESH KAKA)'}
			elsif ($pc==22 && $cand{$key} eq 'Rafikbhai Suleman Sapa - IND') {$cand{$key}='RAFIKBHAI SULEMAN SAPA'}
			elsif ($pc==22 && $cand{$key} eq 'Saiyad Mohsin Bapu Nanumiyawala - BMP') {$cand{$key}='SAIYAD MOHSIN BAPU NANUMIYAWALA'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Al - ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Ali - ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Ali ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Shaileshkumar Maganbhai Parmar - IND') {$cand{$key}='SHAILESHKUMAR MAGANBHAI PARMAR'}
			elsif ($pc==22 && $cand{$key} eq 'Sindhi Mayyudeen Umarbhai - IND') {$cand{$key}='SINDHI MAYYUDEEN UMARBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Sukhramsingh - BSP') {$cand{$key}='SUKHRAMSINGH'}
			elsif ($pc==22 && $cand{$key} eq 'Vasava Mansukhbhai Dhanjibhai - BJP') {$cand{$key}='VASAVA MANSUKHBHAI DHANJIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Virsangbhai Parbatbhai Gohil - IND') {$cand{$key}='VIRSANGBHAI PARBATBHAI GOHIL'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Chandubhai Machalabhai.') {$cand{$key}='CHAUDHARI CHANDUBHAI MACHALABHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Reniyabhai Shankarbhai.') {$cand{$key}='CHAUDHARI RENIYABHAI SHANKARBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Revaben Shankarbhai.') {$cand{$key}='CHAUDHARI REVABEN SHANKARBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Tusharbhai Amarsinhbha i.') {$cand{$key}='CHAUDHARI TUSHARBHAI AMARSINHBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Tusharbhai Amarsinhbhai.') {$cand{$key}='CHAUDHARI TUSHARBHAI AMARSINHBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Gamit Surendrabhai Simabhai.') {$cand{$key}='GAMIT surendrabhai simabhai'}
			elsif ($pc==23 && $cand{$key} eq 'Rathod Rameshbhai Bhikhabhai.') {$cand{$key}='RATHOD RAMESHBHAI BHIKHABHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Vasava Parbhubhai Nagarbhai.') {$cand{$key}='VASAVA PARBHUBHAI NAGARBHAI'}
			elsif ($pc==24 && $cand{$key} eq '-16') {undef($cand{$key});next}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM JARDOSH') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI BHUPATB') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH AI') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN BHAI') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B. PATEL') {$cand{$key}='MOHANBHAI B. PATEL'}
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B.') {$cand{$key}='MOHANBHAI B. PATEL'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH AI') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI CHHOTU') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==25 && $cand{$key} eq '#N/A') {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} =~ /^\d.\d+$/) {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} eq 'Arun S. Pathak') {$cand{$key}='ARUN S. PATHAK(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Asla m Mistr y') {$cand{$key}='ASLAM MISTRY'}
			elsif ($pc==25 && $cand{$key} eq 'C.R.Patil') {$cand{$key}='C. R. PATIL'}
			elsif ($pc==25 && $cand{$key} eq 'Chauhan Keshavbhai Malabhai') {$cand{$key}='CHAUHAN KESAVBHAI MALABHAI (MASTER)'}
			elsif ($pc==25 && $cand{$key} eq 'D:\\') {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} eq 'Hasan Sheikh') {$cand{$key}='HASAN SHAIKH'}
			elsif ($pc==25 && $cand{$key} eq 'Kesha vji L. Sarad va') {$cand{$key}='KESHAVJI L. SARADVA'}
			elsif ($pc==25 && $cand{$key} eq 'Keshavji L. Sardva') {$cand{$key}='KESHAVJI L. SARADVA'}
			elsif ($pc==25 && $cand{$key} eq 'Lataben Ashokku mar Dwivedi') {$cand{$key}='LATABEN ASHOKKUMAR DWIVEDI'}
			elsif ($pc==25 && $cand{$key} eq 'Lataben Ashokkumar Dwiv') {$cand{$key}='LATABEN ASHOKKUMAR DWIVEDI'}
			elsif ($pc==25 && $cand{$key} eq 'Maksu d Mirza') {$cand{$key}='MAKSUD MIRZA'}
			elsif ($pc==25 && $cand{$key} eq 'Parsi Munsi') {$cand{$key}='PERCY MUNSHI'}
			elsif ($pc==25 && $cand{$key} eq 'Patel Bhupen drakum ar Dhirubh ai') {$cand{$key}='PATEL BHUPENDRAKUMAR DHIRUBHAI'}
			elsif ($pc==25 && $cand{$key} eq 'Patel Bhupendrakuma r Dhirubhai') {$cand{$key}='PATEL BHUPENDRAKUMAR DHIRUBHAI'}
			elsif ($pc==25 && $cand{$key} eq 'Pyarel al Bharti') {$cand{$key}='PYARELAL BHARTI'}
			elsif ($pc==25 && $cand{$key} eq 'Ramjan Mansuri') {$cand{$key}='RAMJAN MANSURI(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Ramzan Mansuri') {$cand{$key}='RAMJAN MANSURI(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravsaheb Bhimrav Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravsha heb Bhimra v Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravshaheb Bhimrav Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Saiyad Mehmud Aehmad') {$cand{$key}='SAIYED MEHMUD AHMED'}
			elsif ($pc==25 && $cand{$key} eq 'Saiyed Mehmu d Ahmed') {$cand{$key}='SAIYED MEHMUD AHMED'}
			elsif ($pc==25 && $cand{$key} eq 'Sonal Kellog g') {$cand{$key}='SONAL KELLOGG'}
			elsif ($pc==25 && $cand{$key} eq 'Sonal Kelog') {$cand{$key}='SONAL KELLOGG'}
			elsif ($pc==25 && $cand{$key} eq 'Varde Rajubhai Bhimrav') {$cand{$key}='WARDE RAJUBHAI BHIMRAO'}
			elsif ($pc==25 && $cand{$key} eq 'Vimal Patel') {$cand{$key}='VIMAL PATEL (ENDHAL)'}
			elsif ($pc==25 && $cand{$key} eq 'Warde Rajub hai Bhimr ao') {$cand{$key}='WARDE RAJUBHAI BHIMRAO'}
			elsif ($pc==26 && $cand{$key} eq 'DR. K.C.PATEL') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. K.C. Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. K.C.Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajbhai Parbhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajkumar P. Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajkumar Parbhubhai') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.K.C. Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.K.C.Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.Pankaj kumar Parabhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.Pankajku mar Parabhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Gaurangbhai R. Patel') {$cand{$key}='GAURANGBHAI RAMESHBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Budhabhai R.') {$cand{$key}='PATEL BUDHABHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Budhabhai Ranchhodb hai') {$cand{$key}='PATEL BUDHABHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Govindbhai R.') {$cand{$key}='PATEL GOVINDBHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Govindbhai Ranchhod bhai') {$cand{$key}='PATEL GOVINDBHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Shaileshbhai G.') {$cand{$key}='PATEL SHAILESHBHAI GANDABHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Serial No.') {undef($cand{$key}); next}
			elsif ($pc==26 && $cand{$key} eq 'Talaviya Babubhai C.') {$cand{$key}='TALAVIYA BABUBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Thakarya Ratilal Vajirbhai') {$cand{$key}='THAKRIYA RATILAL VAJIRBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Thakriya Ratilal V.') {$cand{$key}='THAKRIYA RATILAL VAJIRBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Vadiya Laxmanbhai C.') {$cand{$key}='VADIA LAXMANBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Vadiya Laxmanbhai Chhaganbhai') {$cand{$key}='VADIA LAXMANBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 's. no') {undef($cand{$key}); next}
			elsif ($pc==15 && $cand{$key} eq '* *') {undef($cand{$key}); next}
			elsif ($pc==15 && $cand{$key} eq '*') {undef($cand{$key}); next}
			elsif ($pc==12 && $cand{$key} eq 'PADHIYAR LALJIBHAI KARABHA') {$cand{$key}='PADHIYAR LALJIBHAI KARABHAI'} # AC 78
			elsif ($pc==12 && $cand{$key} eq 'SUMARA AMANDBHAI NOORMAMADBHA SUMARA') {$cand{$key}='SUMARA AMANDBHAI NOORMAMADBHAI SUMARA'} # AC 79
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHABHAI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'} # AC 106
			elsif ($pc==3 && $cand{$key} eq 'RATHOD BHAVSINH DAHYABHAI') {$cand{$key}='RATHOD BHAVSINHBHAI DAHYABHAI'} # AC 19
			elsif ($pc==11 && $cand{$key} eq 'Jadeja Kandhalbhai Saramanbhai') {$cand{$key}='JADEJA KANDHALBHAI SARMANBHAI'} # AC 88, column 1
			elsif ($pc==11 && $cand{$key} eq 'Unadakat Prakash Vallabhdas') {$cand{$key}='UNADAKAT PRAKASH VALLABHADAS'} # AC 73, column 7
			elsif ($pc==18 && $cand{$key} eq 'AAAP') {$cand{$key}='PIYUSHKUMAR DILIPBHAI PARMAR'} # AC 127, column 4
			elsif ($pc==18 && $cand{$key} eq 'BJP') {$cand{$key}='CHAUHAN PRABHATSINH PRATAPSINH'} # AC 127, column 2
			elsif ($pc==18 && $cand{$key} eq 'BSP') {$cand{$key}='GIRI RAMCHANDRA VAIJNATH'} # AC 127, column 1
			elsif ($pc==18 && $cand{$key} eq 'INC') {$cand{$key}='RAMSINH PARMAR'} # AC 127, column 3
			elsif ($pc==18 && $key==10) {$cand{$key}='PATEL PANKAJBHAI RAVJIBHAI'} # AC 127, column 10
			elsif ($pc==18 && $key==11) {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 127, column 11
			elsif ($pc==18 && $key==12) {$cand{$key}='VANKAR MANILAL BHANABHAI'} # AC 127, column 12
			elsif ($pc==18 && $key==7) {$cand{$key}='GORA SHOEB MOHMADHANIF'} # AC 127, column 7
			elsif ($pc==18 && $key==8) {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 127, column 8
			elsif ($pc==18 && $key==9) {$cand{$key}='CHAVADA HARISHCHANDRASINH PRABHATSINH'} # AC 127, column 9
			elsif ($pc==18 && $cand{$key} eq 'JD') {$cand{$key}='SHAIKH MAJITMIYA JIVAMIYA'} # AC 127, column 6
			elsif ($pc==18 && $cand{$key} eq 'SP') {$cand{$key}='SHAIKH KALIM ABDULLATIF'} # AC 127, column 5
			elsif ($pc==20 && $cand{$key} eq 'Pathan Sahebkhan Aasifkhan') {$cand{$key}='PATHAN SAHEBKHAN ASIFKHAN'} # AC 143, column 7
			elsif ($pc==20 && $cand{$key} eq 'Rohit Madhusu dan Mohanb hai') {$cand{$key}='ROHIT MADHUSUDAN MOHANBHAI'} # AC 143, column 3
			elsif ($pc==20 && $cand{$key} eq 'Tapan Dasgup ta') {$cand{$key}='TAPAN DASGUPTA'} # AC 143, column 5
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM 3') {$cand{$key}='DARSHANA VIKRAM JARDOSH'} # AC 155, column 2
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI 4') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'} # AC 159, column 3
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH 5') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'} # AC 155, column 4
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN 8') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'} # AC 159, column 7
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B. PATEL 6') {$cand{$key}='MOHANBHAI B. PATEL'} # AC 155, column 5
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH 9') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'} # AC 159, column 8
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI 7') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'} # AC 159, column 6
			elsif ($pc==25 && $cand{$key} eq 'Chuhan Kesavbhai Malabhai') {$cand{$key}='CHAUHAN KESAVBHAI MALABHAI (MASTER)'} # AC 165, column 1
			elsif ($pc==6 && $cand{$key} eq 'of 11') {undef($cand{$key}); next} # AC 40, column 25
			elsif ($pc==8 && $cand{$key} eq 'Chavda Mansukhbh ai Nagarbhai') {$cand{$key}='CHAVDA MANSUKHBHAI NAGARBHAI'} # AC 54, column 3
			elsif ($pc==8 && $cand{$key} eq 'Dr. J.G. Parmar') {$cand{$key}='DR J. G. PARMAR'} # AC 56, column 6
			elsif ($pc==8 && $cand{$key} eq 'Ishvarbhai Dhanabhai Makwana') {$cand{$key}='ISHWARBAHI DHANABHAI MAKWANA'} # AC 54, column 1
			elsif ($pc==8 && $cand{$key} eq 'Solanki Rameshbha i Danabhai') {$cand{$key}='SOLANKI RAMESHBHAI DANABHAI'} # AC 56, column 10
			elsif ($pc==11 && $cand{$key} eq 'Jadeja Kandhalbh ai Saramanb hai') {$cand{$key}='JADEJA KANDHALBHAI SARMANBHAI'} # AC 85, column 1
			elsif ($pc==13 && $cand{$key} eq 'ChudasamaRaje shbhai Naranbhai') {$cand{$key}='CHUDASAMA RAJESHBHAI NARANBHAI'} # AC 92, column 1
			elsif ($pc==15 && $cand{$key} eq 'Gita Chetan Paunda') {$cand{$key}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)'} # AC 104, column 1
			elsif ($pc==17 && $cand{$key} eq 'CHAUHAN 1 DEVUSINH JESINGBHAI') {$cand{$key}='CHAUHAN DEVUSING MOTISHING'} # AC 115, column 1
			elsif ($pc==21 && $cand{$key} eq 'Naranbhai Jemalabhai Rathva 1') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'} # AC 139, column 1
			elsif ($pc==23 && $cand{$key} eq 'Gamit Movaliyabhai Nopariyabhai .') {$cand{$key}='GAMIT MOVALIYABHAI NOPARIYABHAI'} # AC 157, column 1
			elsif ($pc==23 && $cand{$key} eq 'Gamit Movaliyabhai Nopariyabhai.') {$cand{$key}='GAMIT MOVALIYABHAI NOPARIYABHAI'} # AC 172, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS 2') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 155, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS TAV') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 166, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 167, column 1
			elsif ($pc==26 && $cand{$key} eq 'Kishanbhai V. Patel') {$cand{$key}='KISHANBHAI VESTABHAI PATEL'} # AC 177, column 1
			elsif ($pc==3 && $cand{$key} eq 'Parmar Maganbhai Amrabhai') {$cand{$key}='PARMAR MAGANBHAI AMARABHAI'} # AC 18, column 1
			elsif ($pc==9 && $cand{$key} eq 'KOLIPATEL SOMABHAI GANDABHAI') {$cand{$key}='KOLI PATEL SOMABHAI GANDALAL'} # AC 39, column 1
			elsif ($pc==1 && $cand{$key} eq 'BHUJ') {undef($cand{$key}); next} # AC 3, column 11
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHANSHY AMBHAI RAJYAGU RU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'} # AC 100, column 10
			elsif ($pc==15 && $cand{$key} eq 'DR.BHARA TIBEN DHIRUBH AI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'} # AC 100, column 2
			elsif ($pc==15 && $cand{$key} eq 'DR.BHARTI BEN DHIRUBHA I SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'} # AC 102, column 2
			elsif ($pc==15 && $cand{$key} eq 'DR.KANU BHAI.V.KA LSARIYA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'} # AC 100, column 4
			elsif ($pc==15 && $cand{$key} eq 'DR.KANUB HAI V. KALSARIA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'} # AC 102, column 4
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARATB HAI BHIMABH AI') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'} # AC 100, column 8
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARATBH AI BHIMABHA I') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'} # AC 102, column 8
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVIN SINH DHIRU BHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 107, column 7
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVINSI NH DHIRUBH A') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 100, column 7
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVINSIN H DHIRUBHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 102, column 7
			elsif ($pc==15 && $cand{$key} eq 'JAGADISHB HAI AMARABH AI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'} # AC 102, column 9
			elsif ($pc==15 && $cand{$key} eq 'JAGDISHB HAI AMARAB HAI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'} # AC 100, column 9
			elsif ($pc==15 && $cand{$key} eq 'KAGADA RAMESHB HAI PUNABHA I') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'} # AC 100, column 5
			elsif ($pc==15 && $cand{$key} eq 'KAGDA RAMESHB HAI PUNABHAI') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'} # AC 102, column 5
			elsif ($pc==15 && $cand{$key} eq 'KHADRAN I ASIMBHAI PIRBHAI') {$cand{$key}='KHADRANI ASIMBHAI PIRBHAI'} # AC 100, column 6
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR BHAI VALJIBHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 100, column 12
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR VALAJI BHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 107, column 12
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHARB HAI VALJIBHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 102, column 12
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVAN TRAY ODHAVJIB HAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'} # AC 100, column 11
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVANT RAI ODHAVJIB HAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'} # AC 102, column 11
			elsif ($pc==15 && $cand{$key} eq 'RASIDKHA N HASANKH AN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'} # AC 100, column 13
			elsif ($pc==15 && $cand{$key} eq 'RASIDKHA N HASANKH AN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'} # AC 102, column 13
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINBH AI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'} # AC 100, column 3
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINBH AI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'} # AC 102, column 3
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINSI NH CHANDRA SINH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'} # AC 100, column 14
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINSIN H CHANDRAS INH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'} # AC 102, column 14
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDR ABHAI SAVAJIBH AI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'} # AC 100, column 15
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDR ABHAI SHAVJIBHA I') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'} # AC 102, column 15
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHABH AI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'} # AC 100, column 16
			elsif ($pc==17 && $cand{$key} eq 'Abdul Rajjakkhan Pathan') {$cand{$key}='ABDUL RAZAKKHAN PATHAN'} # AC 117, column 4
			elsif ($pc==17 && $cand{$key} eq 'Badhivala Labhubhai Jivrajbhai') {$cand{$key}='BADHIWALA LABHUBHAI JIVRAJBHAI'} # AC 117, column 5
			elsif ($pc==17 && $cand{$key} eq 'Chauhan Devusinh Motisinh') {$cand{$key}='CHAUHAN DEVUSING MOTISHING'} # AC 117, column 8
			elsif ($pc==17 && $cand{$key} eq 'Khristi Advord Khushalbha i') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'} # AC 117, column 7
			elsif ($pc==17 && $cand{$key} eq 'Malek Sabirhusen Ismailbhai') {$cand{$key}='MALEK SABIRHUSEN ISMAELBHAI'} # AC 117, column 13
			elsif ($pc==17 && $cand{$key} eq 'Malek Sadik Husen Mahammd Hushen') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'} # AC 120, column 12
			elsif ($pc==17 && $cand{$key} eq 'Malek Shadikhusen Mahmadhuse n') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'} # AC 117, column 12
			elsif ($pc==17 && $cand{$key} eq 'Malek Yakubmiya Nabhimiya') {$cand{$key}='MALEK YAKUBMIYA NABIMIYA'} # AC 118, column 11
			elsif ($pc==17 && $cand{$key} eq 'Malek Yakubmiya Nabi miya') {$cand{$key}='MALEK YAKUBMIYA NABIMIYA'} # AC 117, column 11
			elsif ($pc==17 && $cand{$key} eq 'Pathan Amanullakha Sitabka') {$cand{$key}='PATHAN AMANULLAKHA SITABKHA'} # AC 117, column 9
			elsif ($pc==17 && $cand{$key} eq 'Ranvir Pranavraj Govindbhai') {$cand{$key}='RANVEER PRANAYRAJ GOVINDBHAI'} # AC 117, column 6
			elsif ($pc==17 && $cand{$key} eq 'Roshan Priyvadan Shan') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'} # AC 117, column 15
			elsif ($pc==18 && $cand{$key} eq 'Chavada Harishchandr asinh Prabhatsinh') {$cand{$key}='CHAVADA HARISHCHANDRASINH PRABHATSINH'} # AC 126, column 9
			elsif ($pc==18 && $cand{$key} eq 'Gora Shoeb Mohmadh anif') {$cand{$key}='GORA SHOEB MOHMADHANIF'} # AC 126, column 7
			elsif ($pc==18 && $cand{$key} eq 'Mansuri Mukhatyar Mohammad') {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 126, column 11
			elsif ($pc==18 && $cand{$key} eq 'S.N. Chavada') {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 126, column 8
			elsif ($pc==18 && $cand{$key} eq 'Shaikh Kalim Abdul Latif') {$cand{$key}='SHAIKH KALIM ABDULLATIF'} # AC 126, column 5
			elsif ($pc==19 && $cand{$key} eq 'Bhura Navalbhai Manabhai') {$cand{$key}='BHURA NAVALABHAI MANABHAI'} # AC 134, column 10
			elsif ($pc==19 && $cand{$key} eq 'K. C. Muniya Advocate') {$cand{$key}='K. C. MUNIA ADVOCATE'} # AC 130, column 6
			elsif ($pc==19 && $cand{$key} eq 'Katara Singjibhai Jaljibhai') {$cand{$key}='KATARA SINGAJIBHAI JALJIBHAI'} # AC 134, column 1
			elsif ($pc==19 && $cand{$key} eq 'Meda Jagdishbha i Manilal') {$cand{$key}='MEDA JAGDISHBHAI MANILAL'} # AC 130, column 7
			elsif ($pc==19 && $cand{$key} eq 'Taviyad Dr.Prabhaben Kishorsinh') {$cand{$key}='TAVIYAD DR. PRABHABEN KISHORSINH'} # AC 134, column 3
			elsif ($pc==20 && $cand{$key} eq 'Pathan Mahemudkhan Rajakkhan') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'} # AC 145, column 6
			elsif ($pc==21 && $cand{$key} eq 'Prof.Arjunbhai Versingbhai Rathva') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'} # AC 138, column 3
			elsif ($pc==22 && $cand{$key} eq 'Anandkumar Sarvarsinh Vasava IND') {$cand{$key}='ANANDKUMAR SARVARSINH VASAVA'} # AC 154, column 8
			elsif ($pc==22 && $cand{$key} eq 'Anilkumar Chhitubhai Bhagat JD') {$cand{$key}='ANILKUMAR CHHITUBHAI BHAGAT'} # AC 154, column 4
			elsif ($pc==22 && $cand{$key} eq 'Bhura Shabbirbhai Valibhai IND') {$cand{$key}='BHURA SHABBIRBHAI VALIBHAI'} # AC 154, column 10
			elsif ($pc==22 && $cand{$key} eq 'Jayendrasinh Rana AAP') {$cand{$key}='JAYENDRASINH RANA'} # AC 154, column 5
			elsif ($pc==22 && $cand{$key} eq 'Rafikbhai Suleman Sapa IND') {$cand{$key}='RAFIKBHAI SULEMAN SAPA'} # AC 154, column 11
			elsif ($pc==22 && $cand{$key} eq 'Saiyad Mohsin Bapu Nanumiyawala BMP') {$cand{$key}='SAIYAD MOHSIN BAPU NANUMIYAWALA'} # AC 147, column 7
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Al ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'} # AC 147, column 6
			elsif ($pc==22 && $cand{$key} eq 'Shaileshkumar Maganbhai Parmar IND') {$cand{$key}='SHAILESHKUMAR MAGANBHAI PARMAR'} # AC 154, column 13
			elsif ($pc==22 && $cand{$key} eq 'Sindhi Mayyudeen Umarbhai IND') {$cand{$key}='SINDHI MAYYUDEEN UMARBHAI'} # AC 154, column 14
			elsif ($pc==22 && $cand{$key} eq 'Sukhramsingh BSP') {$cand{$key}='SUKHRAMSINGH'} # AC 154, column 3
			elsif ($pc==22 && $cand{$key} eq 'Vasava Mansukhbhai Dhanjibhai BJP') {$cand{$key}='VASAVA MANSUKHBHAI DHANJIBHAI'} # AC 147, column 2
			elsif ($pc==22 && $cand{$key} eq 'Virsangbhai Parbatbhai Gohil IND') {$cand{$key}='VIRSANGBHAI PARBATBHAI GOHIL'} # AC 154, column 12
			elsif ($pc==25 && $cand{$key} eq 'N A') {undef($cand{$key});next} # AC 168, column 20
			elsif ($pc==6 && $cand{$key} eq 'Amarkumar Raj Prajapati') {$cand{$key}='RAJ PRAJAPATI'} # AC 55, column 15
			elsif ($pc==6 && $cand{$key} eq 'Brahmbhatt Sanjaybhai') {$cand{$key}='BRAHMBHATT SANJAYBHAI AMARKUMAR'} # AC 55, column 14
			elsif ($pc==6 && $cand{$key} eq 'L K Advani') {$cand{$key}='L. K. ADVANI'} # AC 55, column 1
			elsif ($pc==6 && $cand{$key} eq 'of') {undef($cand{$key});next} # AC 40, column 25
			elsif ($pc==7 && $cand{$key} eq 'Dutt Aakash Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'} # AC 49, column 6
			elsif ($pc==7 && $cand{$key} eq 'PATEL HIMMATSINGH PRAHLADSIGH') {$cand{$key}='PATEL HIMMATSINGH PRAHLADSINGH'} # AC 48, column 1
			elsif ($pc==3 && $cand{$key} eq 'PARMAR MAGANBHAI AMRABHAI') {$cand{$key}='PARMAR MAGANBHAI AMARABHAI'} # AC 19, column 1
			elsif ($pc==7 && $cand{$key} eq 'Aditya Rawal') {$cand{$key}='ADITYA RAVAL'} # AC 46, column 4
			elsif ($pc==7 && $cand{$key} eq 'Buddhipriya Jaswant Somabhai') {$cand{$key}='BUDDHPRIYA JASVANT SOMABHAI'} # AC 46, column 9
			elsif ($pc==7 && $cand{$key} eq 'Dashrathbhai M. Devada') {$cand{$key}='DASHRATHBHAI M. DEVDA'} # AC 46, column 13
			elsif ($pc==7 && $cand{$key} eq 'Datt Akash Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'} # AC 46, column 6
			elsif ($pc==7 && $cand{$key} eq 'Patel Himmatsinh Prahladsinh') {$cand{$key}='PATEL HIMMATSINGH PRAHLADSINGH'} # AC 46, column 1
			elsif ($pc==7 && $cand{$key} eq 'Rohit Rajubhai Virjibhai') {$cand{$key}='ROHIT RAJUBHAI VIRJIBHAI ALIAS MANOJBHAI SONTARIYA'} # AC 46, column 3
			elsif ($pc==18 && $cand{$key} eq 'MANSURI MUKHATYAR MOHAMMAD') {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 127, column 11
			elsif ($pc==18 && $cand{$key} eq 'S. N. CHAVADA') {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 127, column 8
			
			
			# check if candidate remains unknown
			my $re2f = $dbh->selectcol_arrayref("SELECT id FROM candidates WHERE pc = ? AND name LIKE ?",undef,$pc,$cand{$key});
			if (scalar(@$re2f) != 1) {$print{'elsif ($pc=='.$pc.' && $cand{$key} eq \''.$cand{$key}.'\') {$cand{$key}=\''."'} # AC $ac, column $key\n"}++;  $troubleac{$ac}=1; undef($cand{$key}); next key;}
			$cand{$key}=$$re2f[0];
		    }
		}
	    } else { # read in results
		if ($line =~ /VIPUL\\FORM-20 LS/) {$toggle=0; next}
		$csv->parse($line);
		my @fields=$csv->fields();
		
		next unless $fields[$pscol] =~ /\d/;
		next if ($fields[$pscol+1] == $fields[$pscol]+1 && $fields[$pscol+2] == $fields[$pscol]+2 && $fields[$pscol+3] == $fields[$pscol]+3 && $fields[$pscol+4] == $fields[$pscol]+4 && $fields[$pscol+5] == $fields[$pscol]+5);
		
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
		if ($total != $control) {$print{"Vote count mismatch in AC $ac, booth ".$fields[$pscol].": votes add up to $control, but total column says $total!\n"}++;  $troubleac{$ac}=1; }
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
