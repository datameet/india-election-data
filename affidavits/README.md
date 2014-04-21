2014 affidavits
---------------

The [ECI Affidavit Archive](http://affidavitarchive.nic.in/) has archives of candidate affidavits (i.e. declarations) as PDF files of images.

[This script](http://nbviewer.ipython.org/urls/raw.github.com/datameet/india-election-data/master/affidavits/affidavits.ipynb)
crawls and downloads these for Parliamentary elections, and also creates a CSV file that has the mapping of file name to constituency details.

The CSV file is at
<https://github.com/datameet/india-election-data/blob/master/affidavits/affidavits.csv>.

The source is at
<http://nbviewer.ipython.org/urls/raw.github.com/datameet/india-election-data/master/affidavits/affidavits.ipynb>.

To get the actual PDF files, you'll have to run the scraper yourself. The data is too large to be conveniently stored in a git repository.


2014 ADR data
-------------

ADR publishes the processed affidavits at [myneta.info](http://myneta.info/).

[This script](http://nbviewer.ipython.org/urls/raw.github.com/datameet/india-election-data/master/affidavits/myneta.ipynb)
scrapes these for 2014 (as well as 2009 and 2004) election candidates.

The CSV files for
[2014](https://github.com/datameet/india-election-data/blob/master/affidavits/myneta.2014.csv),
[2009](https://github.com/datameet/india-election-data/blob/master/affidavits/myneta.2009.csv), and
[2004](https://github.com/datameet/india-election-data/blob/master/affidavits/myneta.2004.csv) (partial)
are available. So is the IPC-wise breakup for
[2014](https://github.com/datameet/india-election-data/blob/master/affidavits/myneta.details.2014.csv).

The source is at
<http://nbviewer.ipython.org/urls/raw.github.com/datameet/india-election-data/master/affidavits/myneta.ipynb>.


2009 affidavits
---------------

[ADR's tabulation](http://myneta.info/ls2009/index.php?action=summary&subAction=candidates_analyzed&sort=candidate#summary)
of the 2009 affidavits has been normalised into
<https://github.com/datameet/india-election-data/blob/master/affidavits/adr-2009.csv>.

The ST_CODE, ST_NAME, PC_CODE and PC_NAME fields have been added, and match
the [2008 delimitation codes](https://github.com/datameet/india-election-data/blob/master/constituencies/constituency-names-2008.csv).

The Candidate ID field maps to the myneta.info code. For example, a value of
8772 maps to the URL <http://myneta.info/ls2009/candidate.php?candidate_id=8772>.
