/* uncomment for testing just the import */

/* %let areatype=State; */
/* %let query=topic=women%nrstr(&)risk=v17%nrstr(&)race=00%nrstr(&)datatype=0%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1; */
/* %let Topic=Women Health; */
/* %let Race=All Races; */
/* %let Sex=Female; */
/* %let Datatype= Direct Estimates; */

libname dt "/cmw/data_automation/_data";
/* cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US"); */
/* caslib _all_ assign; */




%macro cancerscreeningstate(areatype, topic, race, sex, datatype, query, dsn);

filename sr temp;
proc http method='GET'
	url="https://statecancerprofiles.cancer.gov/risk/index.php?&query."
/* 	query=(topic=colorec risk=v302 stateFIPS=99 type=risk sortVariableName=default sortOrder=default)  */
out=sr;
run;

data NOTES;
	infile sr delimiter=',' MISSOVER DSD firstobs=1 obs=9;
	informat notes1 $200.;
	format 	notes1 $200.;
	input	notes1 $;
	row = _n_;
/* 	year_range = compress(strip(scan(notes1, -1, ','))); */
/* 	year_range_end = compress(strip(scan(year_range, -1, '-'))); */
run;

/*Get variable desc and Data Source from Notes, assumes this does not change  */
proc sql noprint;
select notes1 into: Variable from notes where row = 5;
select notes1 into: Source 	 from notes where row = 3;
quit;

/*read in data  */
data dt.screenrisk_&dsn.;
	infile sr delimiter=',' MISSOVER DSD firstobs=11;
	informat
	GEO $100.
	FIPS $32.
	XPercent $32.
	XLCI $32.
	XUCI $32.
	XNoRespond $32.
	;
	format
	GEO $100.
	FIPS $32.
	XPercent $32.
	XLCI $32.
	XUCI $32.
	XNoRespond $32.
	;
	input
	GEO $
	FIPS $
	XPercent $
	XLCI $
	XUCI $
	XNoRespond $
	;


	/* delete header and footer notes */
	if anyalpha(FIPS) > 0 then delete;
	If FIPS = '' then delete;

	if XPercent 	in ('data not available', 'N/A', "*") then XPercent	='';
	if XLCI 		in ('data not available', 'N/A', "*") then XLCI		='';
	if XUCI 		in ('data not available', 'N/A', "*") then XUCI		='';
	if XNoRespond 	in ('data not available', 'N/A', "*") then XUCI		='';

	/*convert nums to numeric  */
	Percent		=input(XPercent, 	best18.);
	LCI			=input(XLCI, 		best18.);
	UCI			=input(XUCI, 		best18.);
	NoRespond	=input(XNoRespond, 	best18.);

	drop XPercent XLCI XUCI XNoRespond;

	/*Set new variables  */
	State_FIPS = substr(FIPS,1,2);
	Area_Type= "&areatype.";
	Topic="&topic.";
	Race="&race.";
	Sex="&sex.";
 	Datatype= "&datatype.";
	Variable= "&Variable.";
	Source= "&Source.";
	ExtractDT=today();
	format ExtractDT date9.;

	label

	LCI='Lower Confidence Interval'
	UCI='Upper Confidence Interval'
	NoRespond = 'Number of Respondents with Screening or Risk Factor'
	ExtractDT='Data Extract Date'
	;


run;

%mend;

%cancerscreeningstate(
areatype	=State,
query		=topic=women%nrstr(&)risk=v17%nrstr(&)race=00%nrstr(&)datatype=0%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
Topic		=Women Health,
Race		=All Races,
Sex			=Female,
Datatype	=Direct Estimates,
dsn			=WHPap);
%cancerscreeningstate(
areatype	=State,
query		=topic=women%nrstr(&)risk=v05%nrstr(&)race=00%nrstr(&)datatype=0%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
Topic		=Women Health,
Race		=All Races,
Sex			=Female,
Datatype	=Direct Estimates,
dsn			=WHMam);


/* Need requirements on combining the data from VCU  */
/* data test; */
/* set WORK.SCREENRISK_WHPAP WORK.SCREENRISK_WHMAM ; */
/* run; */

