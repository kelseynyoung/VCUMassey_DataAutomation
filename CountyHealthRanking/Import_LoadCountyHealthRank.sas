%let folder=/cmw/data_automation/_data/;
libname dt "&folder.";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%macro importcountyhealth(year, CHR_FileName,CHRT_FileName );

%deltable (tables=dt.countyhealthranking&year. dt.countyhealthranking_trend&year.);

/* !!!!!!! filename location must all be lower case !!!!!!! */
filename CHR "&folder.countyhealthranking&year..sas7bdat";
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHR_FileName..sas7bdat"
	out=CHR;
run;

/* !!!!!!! filename location must all be lower case !!!!!!! */
filename CHRT "&folder.countyhealthranking_trend&year..sas7bdat";
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHRT_FileName..sas7bdat"
	out=CHRT;
run;

proc casutil;
droptable casdata="countyhealthranking&year." incaslib="public" quiet;
load data =dt.countyhealthranking&year. outcaslib = "public" casout = "countyhealthranking&year." promote ;

droptable casdata="countyhealthranking_trend&year." incaslib="public" quiet;
load data =dt.countyhealthranking_trend&year. outcaslib = "public" casout = "countyhealthranking_trend&year." promote ;
quit;


%mend;

%importcountyhealth(2024, analytic_data2024, chr_trends_sas_2024);
%importcountyhealth(2023, analytic_data2023_0, chr_trends_sas_2023);



