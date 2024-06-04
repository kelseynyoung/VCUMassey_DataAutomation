libname dt "/cmw/data_automation/_data";
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

/*testing KNY  */
%macro readinACS_applyVar(year);

/*read in the ACS 5 Year  var list - will need to run this per ACS reporting year  */
filename data temp;
proc http url="https://api.census.gov/data/&year./acs/acs5/profile/variables.json"
	out=data;
run;

libname DP_VAR JSON fileref=data;
/*subset on DP05 table and only estimate vars. "PE" indicates Percentange estimate variable, VCU does not want PE. V = 1 non empty rows*/
data var_desc&year.;
	set DP_VAR.ALLDATA;
	where substr(p2, 1, 4)='DP05' and find(p2, 'PE')= 0 and V=1;
run;
proc sort data=WORK.var_desc&year.;
	by P2;
run;
/*reformat  */
proc transpose data=WORK.var_desc&year. out=work.var_desc&year.T;
	var Value;
	id P3;
	by P2;
run;

filename DP temp;

proc http url="https://api.census.gov/data/&year./acs/acs5/profile?get=group(DP05)%nrstr(&)for=county:*%nrstr(&)in=state:51%nrstr(&)key=f79eb0c516892290805ff7bc52a9eaff13bf676f"
out=DP;
run;
libname ACS JSON fileref=DP;

PROC TRANSPOSE data=acs.root(obs=1) out=var_element&year.;
  var _all_;
run;

proc sql noprint;
select catx("=", _Name_, cats(Col1, 'C')) into: rename separated by ' ' from var_element&year. where _Name_ ^= 'ordinal_root' ;
select cats(P2, "=input(", cats(P2, 'C'), ', best32.);') into: convert separated by ' ' from var_desc&year.T  ;
select catx("=", P2, label) into: label separated by ' ' from var_desc&year.T   ;
select P2 into: keeplist separated by ' ' from var_desc&year.T;
quit;
%put rename statement : &rename. ;
%put label statement : &label. ;
%put keeplist statement : &keeplist. ;


data dt.DP05_VACOUNTIES&year. ;
set ACS.root (firstobs=2 rename= (&rename.));
&convert.;
label &label.;

FIPS5 = cats(stateC, countyC);
YearRangeEnd = &year.;
rename GEO_IDC = GEO_ID NameC=Name stateC=state countyC = county;
keep &keeplist. GEO_IDC NameC stateC countyC FIPS5 YearRangeEnd;
run;


%deltable (tables=work.var_desc&year. work.var_desc&year.T work.var_element&year. );

proc casutil;
droptable casdata="DP05_VACOUNTIES&year." incaslib="public" quiet;
load data = dt.DP05_VACOUNTIES&year. outcaslib = "public" casout = "DP05_VACOUNTIES&year." promote ;
quit;

%mend;
%readinACS_applyVar(2022);
%readinACS_applyVar(2021);
%readinACS_applyVar(2020);
%readinACS_applyVar(2019);



