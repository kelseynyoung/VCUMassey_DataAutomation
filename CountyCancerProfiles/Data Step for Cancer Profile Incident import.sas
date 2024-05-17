/* uncomment for testing just the import */
/* %let folder = /mnt/viya-share/myazurevol/data/keyyou/vcumassey/CountyCancerProfiles/data; */
/* %let stateFIPS=00;  */
/* %let areatype=state; */
/* %let cancer=001; */
/* %let race=00; */
/* %let sex=0; */
/* %let age=001; */
/* %let stage=999; */
/* %let year=0; */
/* %let type=incd; */
/* %let sortVariableName=rate; */
/* %let sortOrder=desc; */
/* %let output=1; */


filename incd temp;
proc http method='GET'
	url="https://statecancerprofiles.cancer.gov/incidencerates/index.php"
	query=("stateFIPS"="&stateFIPS" "areatype"="&areatype" "cancer"="&cancer" 
		"race"="&race" "sex"="&sex" "age"="&age" "stage"="&stage" "year"="&year" 
		"type"='incd' "sortVariableName"="&sortVariableName" "sortOrder"="&sortOrder" 
		"sortVariableName"="&sortVariableName" "output"="&output") out=incd;
run;

data NOTES;
	infile INCD delimiter=',' MISSOVER DSD firstobs=3 obs=3;
	informat notes1 $200.;
	format 	notes1 $200.;
	input	notes1 $;
	year_range = compress(strip(scan(notes1, -1, ',')));
	year_range_end = compress(strip(scan(year_range, -1, '-')));
run;
proc sql noprint;
	select year_range, year_range_end into :year_range, :year_range_end from notes;
quit;
proc datasets library=work noprint;
   delete notes;
run;

data &areatype._incd_&stateFIPS._&cancer._&race._&sex._&age._&stage.;
	infile INCD delimiter=',' MISSOVER DSD firstobs=10;
	informat
	x&areatype. $100.
	FIPS $32.
	XInc $32.
	XInc_LCI $32.
	XInc_UCI $32.
	XCIRank_Inc $32.
	XCIRank_Inc_LCI $32.
	XCIRank_Inc_UCI $32.
	XCount $32.
	Trend $32.
	XTrend_5year $32.
	XTrend_5year_LCI $32.
	XTrend_5year_UCI $32.;
	format
	x&areatype. $100.
	FIPS $32.
	XInc $32.
	XInc_LCI $32.
	XInc_UCI $32.
	XCIRank_Inc $32.
	XCIRank_Inc_LCI $32.
	XCIRank_Inc_UCI $32.
	XCount $32.
	Trend $32.
	XTrend_5year $32.
	XTrend_5year_LCI $32.
	XTrend_5year_UCI $32.;
	input
	x&areatype. $
	FIPS $
	XInc $
	XInc_LCI $
	XInc_UCI $
	XCIRank_Inc $
	XCIRank_Inc_LCI $
	XCIRank_Inc_UCI  $
	XCount $
	Trend $
	XTrend_5year $
	XTrend_5year_LCI $
	XTrend_5year_UCI $;

	/* delete header and footer notes */
	if anyalpha(FIPS) > 0 then delete;
	If FIPS = '' then delete;

	/*clean area type 	 */
	&areatype.  = compress(X&areatype. , "1234567890())");
	
	/*Capture data supression records 	 */
	if findw(XCount, 'fewer') > 0 then SupressFlg='Y';
	else SupressFlg='N';

	/* recode missing data  */
	if XInc in ('data not available', 'N/A', "*") then XInc='';
	if XInc_LCI in ('data not available', 'N/A', "*") then XInc_LCI='';
	if XInc_UCI in ('data not available', 'N/A', "*") then XInc_UCI='';
	if XCIRank_Inc in ('data not available', 'N/A', "*") then XCIRank_Inc='';
	if XCIRank_Inc_LCI in ('data not available', 'N/A', "*") then XCIRank_Inc_LCI='';
	if XCIRank_Inc_UCI in ('data not available', 'N/A', "*") then XCIRank_Inc_UCI='';
	if XCount in ('data not available', 'N/A', "*") then XCount='';
	if findw(XCount, 'fewer') > 0 then XCount='';
	if Trend in ('data not available', 'N/A', "*") then Trend='';
	if XTrend_5year in ('data not available', 'N/A', "*") then XTrend_5year='';
	if XTrend_5year_LCI in ('data not available', 'N/A', "*") then XTrend_5year_LCI='';
	if XTrend_5year_UCI in ('data not available', 'N/A', "*") then XTrend_5year_UCI='';

	/*convert nums to numeric  */
	Inc=input(XInc, best18.);
	Inc_LCI=input(XInc_LCI, best18.);
	Inc_UCI=input(XInc_UCI, best18.);
	CIRank_Inc=input(XCIRank_Inc, best18.);
	CIRank_Inc_LCI=input(XCIRank_Inc_LCI, best18.);
	CIRank_Inc_UCI=input(XCIRank_Inc_UCI, best18.);
	Count=input(XCount, best18.);
	Trend_5year=input(XTrend_5year, best18.);
	Trend_5year_LCI=input(XTrend_5year_LCI, best18.);
	Trend_5year_UCI=input(XTrend_5year_UCI, best18.);
	format Inc comma18.1;
	format Inc_LCI comma18.1;
	format Inc_UCI comma18.1;
	format Trend_5year comma6.1;
	format Trend_5year_LCI comma6.1;
	format Trend_5year_UCI comma6.1;
	format Count comma18.;

	/*Set new variables  */
	Cancer="&cancer.";
	Race="&race.";
	Age="&age.";
	Stage="&stage.";
	Sex="&sex.";
	ExtractDT=today();
	format ExtractDT date9.;

	Year_Range= "&year_range.";
	Year_range_end = &year_range_end.;


	/*drop char vars no longer needed  */
	drop XInc XInc_LCI XInc_UCI XCIRank_Inc XCIRank_Inc_LCI XCIRank_Inc_UCI XCount 
		XTrend_5year XTrend_5year_LCI XTrend_5year_UCI x&areatype;

	/*apply labels for reporting  */
	label

	FIPS='FIPS'
	Inc='Incidence Rate'
	Inc_LCI='Incidence Rate (Lower 95% Confidence Interval)'
	Inc_UCI='Incidence Rate (Upper 95% Confidence Interval)'
	CIRank_Inc='CIRank_Inc'
	CIRank_Inc_LCI='CIRank_Inc (Lower 95% Confidence Interval)'
	CIRank_Inc_UCI='CIRank_Inc (Upper 95% Confidence Interval)'
	Count='Average Annual Count'
	Trend='Recent Trend'
	Trend_5year='Recent 5-Year Trend ([trend note]) in Incidence Rates'
	Trend_5year_LCI='Recent 5-Year Trend (Lower 95% Confidence Interval)'
	Trend_5year_UCI='Recent 5-Year Trend (Upper 95% Confidence Interval)'
	ExtractDT='Data Extract Date'
	Year_Range= 'Year Range'
	Year_range_end = 'Year Range End';
	

		if cancer = '001' then cancer_desc = 'All Cancer Sites';
	else if cancer='001' then cancer_desc='All Cancer Sites';
	else if cancer='003' then cancer_desc='Oral Cavity & Pharynx';
	else if cancer='017' then cancer_desc='Esophagus';
	else if cancer='018' then cancer_desc='Stomach';
	else if cancer='020' then cancer_desc='Colon & Rectum';
	else if cancer='035' then cancer_desc='Liver & Bile Duct';
	else if cancer='040' then cancer_desc='Pancreas';
	else if cancer='047' then cancer_desc='Lung & Bronchus';
	else if cancer='053' then cancer_desc='Melanoma of the Skin';
	else if cancer='055' then cancer_desc='Breast (Female)';
	else if cancer='057' then cancer_desc='Cervix';
	else if cancer='058' then cancer_desc='Uterus (Corpus & Uterus NOS)';
	else if cancer='061' then cancer_desc='Ovary';
	else if cancer='066' then cancer_desc='Prostate';
	else if cancer='071' then cancer_desc='Bladder';
	else if cancer='072' then cancer_desc='Kidney & Renal Pelvis';
	else if cancer='076' then cancer_desc='Brain & ONS';
	else if cancer='080' then cancer_desc='Thyroid';
	else if cancer='086' then cancer_desc='Non-Hodgkin Lymphoma';
	else if cancer='090' then cancer_desc='Leukemia';
	else if cancer='515' then cancer_desc='Childhood (Ages <20 All Sites)';
	else if cancer='516' then cancer_desc='Childhood (Ages <15 All Sites)';

	 	if sex='0' then sex_desc='Both Sexes';
	else if sex='1' then sex_desc='Male';
	else if sex='2' then sex_desc='Female';

	 	if age='001' then age_desc='All Ages';
	else if age='006' then age_desc='<65';
	else if age='009' then age_desc='<50';
	else if age='136' then age_desc='50+';
	else if age='157' then age_desc='65+';

	 if stage='211' then stage_desc='Late Stage';
	else if stage='999' then stage_desc='All Stages';

	 if race='00' then race_desc='All Races (includes Hispanic)';
	else if race='05' then race_desc='Hispanic (any race)';
	else if race='07' then race_desc='White Non-Hispanic';
	else if race='28' then race_desc='Black Non-Hispanic';
	else if race='38' then race_desc='Amer. Indian / AK Native (Non Hispanic)';
	else if race='48' then race_desc='Asian / Pacific Islander (non Hispanic)';

	label cancer_desc='Cancer Desc'
			sex_desc='Sex Desc'
			age_desc='Age Desc'
			stage_desc='Stage Desc'
			race_desc='Race Desc';

run;