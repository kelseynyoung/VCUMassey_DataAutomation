%let year = 2019;

libname dt "/cmw/data_automation/_data";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

filename download temp;
/*make call to ed data express for ZIP files*/
proc http
 method='GET'
 url="https://www.ers.usda.gov/webdocs/DataFiles/80591/FoodAccessResearchAtlasData&year..xlsx"
 out=download;
run;

proc import datafile=download dbms=xlsx out=food replace;
sheet= 'Food Access Research Atlas';
run;
proc import datafile=download dbms=xlsx out=vfood replace;
sheet= 'Variable Lookup';
run;

proc sql noprint;
    select catx('=', trim(field), quote(trim(LongName)))	into: label_list separated by ' ' from VFood   ;
quit;
/* %put label_list  = &label_list.; */

Data dt.Food_Access_&year.;
set food;
label &label_list.;
run;

proc casutil;
droptable casdata="Food_Access_&year." incaslib="public" quiet;
load data =dt.Food_Access_&year. outcaslib = "public" casout = "Food_Access_&year." promote ;
quit;