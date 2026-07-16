libname dt "/cmw/data_automation/_data";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%let ExtractYR=%sysfunc(year(%sysfunc(date())));
%put &ExtractYR.;

%macro cancerscreening(areatype, query, theme);

filename sr temp;
proc http method='GET'
	url="https://statecancerprofiles.cancer.gov/risk/index.php?&query."
out=sr;
run;

data x&areatype.&theme.NOTES;
	infile sr delimiter=',' MISSOVER DSD firstobs=1 /*obs=9*/;
	informat notes1 $500.;
	informat notes2 $500.;
	format 	notes1 $500.;
	format 	notes2 $500.;
	input	notes1 $
			notes2 $;
	if notes1 ^= '';
	if notes2 = '';
run;
data &areatype.&theme.NOTES;
set X&areatype.&theme.NOTES;
drop notes2;
row=_n_;
run;

/*Get variable desc and Data Source from Notes, assumes this does not change  */
proc sql noprint;
select notes1 into: Source 	 		from &areatype.&theme.NOTES where row = 2;
select notes1 into: Definition 		from &areatype.&theme.NOTES where row = 3;
select notes1 into: Demographics 	from &areatype.&theme.NOTES where row = 4;
select notes1 into: Retrieved 		from &areatype.&theme.NOTES where row = 6;
select notes1 into: Footnote 		from &areatype.&theme.NOTES where row = 7;
quit;

/*read in data  */
data screenrisk_&areatype.&theme.;
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

	/* remove footnotes and invalid FIPS */
	if anyalpha(FIPS) > 0 then delete;
	If FIPS ^= '' ;


	if XPercent 	in ('data not available', 'N/A', "*") then XPercent	='';
	if XLCI 		in ('data not available', 'N/A', "*") then XLCI		='';
	if XUCI 		in ('data not available', 'N/A', "*") then XUCI		='';
	if XNoRespond 	in ('data not available', 'N/A', "*") then XNoRespond	='';

	/*convert nums to numeric  */
	&theme._Percent		=input(XPercent, 	best18.);
	&theme._LCI			=input(XLCI, 		best18.);
	&theme._UCI			=input(XUCI, 		best18.);
	&theme._NoRespond	=input(XNoRespond, 	best18.);

	drop XPercent XLCI XUCI XNoRespond;

	/*Set new variables  */
	State_FIPS = substr(FIPS,1,2);
	Area_Type= "&areatype.";

	&theme._Definition= "&Definition.";
	&theme._Source= "&Source.";
	&theme._Demographics = "&Demographics.";
	&theme._Retrieved = "&Retrieved.";
	&theme._Notes = "&Footnote.";
	
	ExtractDT=today();
	format ExtractDT date9.;

	label
	&theme._LCI	="&theme. Lower Confidence Interval"
	&theme._UCI	="&theme. Upper Confidence Interval"
	&theme._NoRespond = "&theme. Number of Respondents with Screening or Risk Factor";
/* 	ExtractDT='Data Extract Date' */
	;
	if GEO = 'United States' then StateCD = 'US'; 
	else StateCD = FIPSTATE(State_FIPS);

	length StateNM $200.;
	length CountyNM $200.;

	if Area_type = 'County' then do;
		StateNM = strip(scan(GEO, -1, ','));
		CountyNM = strip(scan(GEO, 1, ','));
	end;

	if Area_type = 'State' then do;
		StateNM = GEO;
		CountyNM = '';
	end;


run;


%mend;

/*STATE  */
%cancerscreening(
areatype	=State,
query		=topic=women%nrstr(&)risk=v05%nrstr(&)race=00%nrstr(&)datatype=0%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
theme		=Mammo
);
%cancerscreening(
areatype	=State,
query		=topic=women%nrstr(&)risk=v17%nrstr(&)race=00%nrstr(&)datatype=0%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
theme		=Pap
);



/*COUNTY  */
%cancerscreening(
areatype	=County,
query		=query=topic=women%nrstr(&)risk=v05%nrstr(&)race=00%nrstr(&)datatype=1%nrstr(&)stateFIPS=99%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
theme		=Mammo
);
%cancerscreening(
areatype	=County,
query		=query=topic=women%nrstr(&)risk=v17%nrstr(&)race=00%nrstr(&)datatype=1%nrstr(&)stateFIPS=99%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
theme		=Pap
);
%cancerscreening(
areatype	=County,
query		=query=topic=colorec%nrstr(&)risk=v302%nrstr(&)stateFIPS=99%nrstr(&)type=risk%nrstr(&)sortVariableName=percent%nrstr(&)sortOrder=asc%nrstr(&)output=1,
theme		=Colon
);



PROC SQL;
   CREATE TABLE WORK.SCF_ScreeningST AS
   SELECT 
      t1.GEO,
      t1.FIPS,
      t1.State_FIPS,
      t1.Area_Type,
      t1.ExtractDT FORMAT=DATE9.,
      t1.StateCD,
      t1.StateNM,
      t1.CountyNM,
      t1.Mammo_Percent,
      t1.Mammo_LCI LABEL='Mammo Lower Confidence Interval',
      t1.Mammo_UCI LABEL='Mammo Upper Confidence Interval',
      t1.Mammo_NoRespond LABEL='Mammo Number of Respondents with Screening or Risk Factor',
      t1.Mammo_Definition,
      t1.Mammo_Source,
      t2.Pap_Demographics,
      t1.Mammo_Demographics,
      t1.Mammo_Retrieved,
      t1.Mammo_Notes,
      t2.Pap_Percent,
      t2.Pap_LCI LABEL='Pap Lower Confidence Interval',
      t2.Pap_UCI LABEL='Pap Upper Confidence Interval',
      t2.Pap_NoRespond LABEL='Pap Number of Respondents with Screening or Risk Factor',
      t2.Pap_Definition,
      t2.Pap_Source,
      t2.Pap_Retrieved,
      t2.Pap_Notes
   FROM
      WORK.SCREENRISK_STATEMAMMO t1
         FULL JOIN WORK.SCREENRISK_STATEPAP t2 ON (t1.GEO = t2.GEO)
   ;
QUIT;
RUN;


PROC SQL;
   CREATE TABLE WORK.SCF_ScreeningCO AS
   SELECT 
      t1.GEO,
      t1.FIPS,
      t1.State_FIPS,
      t1.Area_Type,
      t1.ExtractDT FORMAT=DATE9.,
      t1.StateCD,
      t1.StateNM,
      t1.CountyNM,

      t1.Colon_Percent,
      t1.Colon_LCI LABEL='Colon Lower Confidence Interval',
      t1.Colon_UCI LABEL='Colon Upper Confidence Interval',
      t1.Colon_NoRespond LABEL='Colon Number of Respondents with Screening or Risk Factor',
      t1.Colon_Definition,
      t1.Colon_Source,
      t1.Colon_Demographics,
      t1.Colon_Retrieved,
      t1.Colon_Notes,

      t2.Mammo_Percent,
      t2.Mammo_LCI LABEL='Mammo Lower Confidence Interval',
      t2.Mammo_UCI LABEL='Mammo Upper Confidence Interval',
      t2.Mammo_NoRespond LABEL='Mammo Number of Respondents with Screening or Risk Factor',
      t2.Mammo_Definition,
      t2.Mammo_Source,
      t2.Mammo_Demographics,
      t2.Mammo_Retrieved,
      t2.Mammo_Notes,

      t3.Pap_Percent,
      t3.Pap_LCI LABEL='Pap Lower Confidence Interval',
      t3.Pap_UCI LABEL='Pap Upper Confidence Interval',
      t3.Pap_NoRespond LABEL='Pap Number of Respondents with Screening or Risk Factor',
      t3.Pap_Definition,
      t3.Pap_Source,
      t3.Pap_Demographics,
      t3.Pap_Retrieved,
      t3.Pap_Notes
   FROM
      WORK.SCREENRISK_COUNTYCOLON t1
         FULL JOIN WORK.SCREENRISK_COUNTYMAMMO t2 ON (t1.GEO = t2.GEO)
         FULL JOIN WORK.SCREENRISK_COUNTYPAP t3 ON (t1.GEO = t3.GEO)
   ;
QUIT;
RUN;

data Dt.SCF_Screening_&ExtractYR.;
set SCF_SCREENINGCO SCF_SCREENINGST;
run;

proc casutil;
droptable casdata="SCF_Screening_&ExtractYR." incaslib="public" quiet;
load data = Dt.SCF_Screening_&ExtractYR. outcaslib = "public" casout = "SCF_Screening_&ExtractYR." promote ;
quit;


%deltable (tables= WORK.COUNTYCOLONNOTES WORK.COUNTYMAMMONOTES WORK.COUNTYPAPNOTES 
WORK.SCREENRISK_COUNTYCOLON WORK.SCREENRISK_COUNTYMAMMO WORK.SCREENRISK_COUNTYPAP 
WORK.SCREENRISK_STATEMAMMO WORK.SCREENRISK_STATEPAP WORK.STATEMAMMONOTES WORK.STATEPAPNOTES 
WORK.XCOUNTYCOLONNOTES WORK.XCOUNTYMAMMONOTES WORK.XCOUNTYPAPNOTES WORK.XSTATEMAMMONOTES WORK.XSTATEPAPNOTES );





