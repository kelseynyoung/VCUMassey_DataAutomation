libname SDI "/mnt/viya-share/data/VCUMassey_DataAutomation/_data";
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%macro execute(SY, EY);
%macro importSDI(type, filename);
filename SDI temp;
proc http
 url="https://www.graham-center.org/content/dam/rgc/documents/maps-data-tools/sdi/&filename..csv"
 method="GET"
 out=SDI;
run;

/* proc import datafile=SDI dbms=csv out=SDI_&EY._&type. replace; */
/* guessingrows=2000; */
/* run; */
data SDI.SDI_&EY._&type.;

	infile SDI delimiter=',' MISSOVER DSD firstobs=2;
	informat &type._FIPS $32.;
	informat &type._population best32.;
	informat SDI_score best32.;
	informat PovertyLT100_FPL_score best32.;
	informat Single_Parent_Fam_score best32.;
	informat Education_LT12years_score best32.;
	informat HHNo_Vehicle_score best32.;
	informat HHRenter_Occupied_score best32.;
	informat HHCrowding_score best32.;
	informat Nonemployed_score best32.;
	informat sdi best32.;
	informat pct_Poverty_LT100 best32.;
	informat pct_Single_Parent_Fam best32.;
	informat pct_Education_LT12years best32.;
	informat pct_NonEmployed best32.;
	informat pctHH_No_Vehicle best32.;
	informat pctHH_Renter_Occupied best32.;
	informat pctHH_Crowding best32.;
	format &type._FIPS $32.;
	format &type._population best12.;
	format SDI_score best12.;
	format PovertyLT100_FPL_score best12.;
	format Single_Parent_Fam_score best12.;
	format Education_LT12years_score best12.;
	format HHNo_Vehicle_score best12.;
	format HHRenter_Occupied_score best12.;
	format HHCrowding_score best12.;
	format Nonemployed_score best12.;
	format sdi best12.;
	format pct_Poverty_LT100 best12.;
	format pct_Single_Parent_Fam best12.;
	format pct_Education_LT12years best12.;
	format pct_NonEmployed best12.;
	format pctHH_No_Vehicle best12.;
	format pctHH_Renter_Occupied best12.;
	format pctHH_Crowding best12.;
	input
	&type._FIPS $
	&type._population
	SDI_score
	PovertyLT100_FPL_score
	Single_Parent_Fam_score
	Education_LT12years_score
	HHNo_Vehicle_score
	HHRenter_Occupied_score
	HHCrowding_score
	Nonemployed_score
	sdi
	pct_Poverty_LT100
	pct_Single_Parent_Fam
	pct_Education_LT12years
	pct_NonEmployed
	pctHH_No_Vehicle
	pctHH_Renter_Occupied
	pctHH_Crowding;
run;


proc casutil;
droptable casdata="SDI_&EY._&type." incaslib="public" quiet;
load data =SDI.SDI_&EY._&type. outcaslib = "public" casout = "SDI_&EY._&type." promote ;
quit;

%mend;

%if &SY. = 2008 %then    %importSDI(Census		 ,&SY.-&EY.-sdi/rgcsdi-&SY.-&EY._censustract);
%else 					 %importSDI(Census		 ,&SY.-&EY.-sdi/rgcsdi-&SY.-&EY.-censustract);

%importSDI(County	 ,&SY.-&EY.-sdi/rgcsdi-&SY.-&EY.-county		);
%importSDI(PCSA		 ,&SY.-&EY.-sdi/rgcsdi-&SY.-&EY.-pcsa		);
%importSDI(ZCTA		 ,&SY.-&EY.-sdi/rgcsdi-&SY.-&EY.-zcta		);
%mend;

%execute(2008,2012);
%execute(2011,2015);
%execute(2012,2016);
%execute(2013,2017);
%execute(2014,2018);
%execute(2015,2019);