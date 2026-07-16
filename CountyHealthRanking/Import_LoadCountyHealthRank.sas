%let folder=/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData;
libname dt "&folder.";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%macro importcountyhealth(year, CHR_FileName,CHRT_FileName );

/* %deltable (tables=dt.countyhealthranking&year. dt.countyhealthranking_trend&year.); */

/* !!!!!!! filename location and dataset must all be lower case !!!!!!! */
filename CHR "%sysfunc(pathname(work))/countyhealthranking&year..sas7bdat";
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHR_FileName..sas7bdat"
	out=CHR;
run;
data dt.countyhealthranking&year.;
    set countyhealthranking&year.;
    FIPS5 = cat(statecode, countycode);
run;

/* !!!!!!! filename location and dataset must all be lower case !!!!!!! */
filename CHRT "%sysfunc(pathname(work))/countyhealthranking_trend&year..sas7bdat";;
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHRT_FileName..sas7bdat"
	out=CHRT;
run;


data dt.countyhealthranking_trend&year.;
    set countyhealthranking_trend&year.;
    FIPS5 = cat(statecode, countycode);
run;


proc casutil;
droptable casdata="countyhealthranking&year." incaslib="KAY_YOW" quiet;
load data =dt.countyhealthranking&year.  outcaslib = "KAY_YOW" casout = "countyhealthranking&year." promote ;

droptable casdata="countyhealthranking_trend&year." incaslib="KAY_YOW" quiet;
load data =dt.countyhealthranking_trend&year. outcaslib = "KAY_YOW" casout = "countyhealthranking_trend&year." promote ;
quit;


%mend;
%importcountyhealth(2025, analytic_data2025_v3, chr_trends_sas_2025);
%importcountyhealth(2024, analytic_data2024, chr_trends_sas_2024);
%importcountyhealth(2023, analytic_data2023_0, chr_trends_sas_2023);



