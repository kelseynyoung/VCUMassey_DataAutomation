/*Importing 500 Cities Place - Social Determinants of Health (SDOH) Data*/
/* For KYF - just county level */
/* one more comment  */

/* Data Source: https://chronicdata.cdc.gov/browse?category=500+Cities+%26+Places&sortBy=newest&utf8 */

%let sdoh_yr = 2021; /*The last year of the range for the 5-year SDOH datasets. The rage for the most recent data is 2017-2021*/
%let places_yr = 2024;  /*The year release, as specified in the Places dataset titles. The current release is 2022*/

libname dt "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;


%macro SDOH_PLACES(fname=, url=, dsn=, idlength= , yr_end=);

/*Pulling down data from web data portal*/
filename &fname. temp;
proc http
 url="&url."
 method="GET"
 out=&fname.;
run;

/*Importing SDOH and PLACES data*/
proc import datafile=&fname. dbms=csv out=&dsn._&yr_end replace;
GUESSINGROWS=10000; /* Specifies the number of rows of the file to scan to determine the appropriate data type and length for the variables*/
run;

/*Adding leading zeros to the LocationID variable and converting it from numeric to character*/
data dt.&dsn._&yr_end.;
set &dsn._&yr_end (rename=(locationID=location_num));
FIPS5=put(location_num,&idlength.); 
data_range_end_year = &yr_end.;
drop location_num;
run;


/*Loading data to Public folder*/
proc casutil incaslib="KAY_YOW" outcaslib = "KAY_YOW";
 droptable casdata="&dsn._&yr_end."  quiet;
 load data =dt.&dsn._&yr_end.  casout = "&dsn._&yr_end." promote ;
 save casdata="&dsn._&yr_end." replace;
quit;

%mend;


/*macro executing the steps above*/

%SDOH_PLACES (fname = SDOHCnty	, url=https://data.cdc.gov/api/views/i6u4-y3g4/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_SDOHCounty		, idlength=z5.  , yr_end = &sdoh_yr.);
%SDOH_PLACES (fname = County	, url=https://data.cdc.gov/api/views/duw2-7jbt/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_County			, idlength=z5.  , yr_end = &places_yr.);




/* old Places */
/* https://data.cdc.gov/api/views/duw2-7jbt/rows.csv?accessType=DOWNLOAD */


/* odata option */

/* Links for new 2024 data, I copied sd8v-uq83 and replaced that in the link structure we had from old PLaces file */
/* http://data.cdc.gov/api/v3/views/sd8v-uq83/export.csv?accessType=DOWNLOAD&app_token=YOURAPPTOKENHERE */
/* https://data.cdc.gov/api/v3/views/sd8v-uq83/query.json?query=SELECT%0A%20%20%60year%60%2C%0A%20%20%60stateabbr%60%2C%0A%20%20%60statedesc%60%2C%0A%20%20%60locationname%60%2C%0A%20%20%60datasource%60%2C%0A%20%20%60category%60%2C%0A%20%20%60measure%60%2C%0A%20%20%60data_value_unit%60%2C%0A%20%20%60data_value_type%60%2C%0A%20%20%60data_value%60%2C%0A%20%20%60data_value_footnote_symbol%60%2C%0A%20%20%60data_value_footnote%60%2C%0A%20%20%60low_confidence_limit%60%2C%0A%20%20%60high_confidence_limit%60%2C%0A%20%20%60totalpop18plus%60%2C%0A%20%20%60totalpopulation%60%2C%0A%20%20%60geolocation%60%2C%0A%20%20%60locationid%60%2C%0A%20%20%60categoryid%60%2C%0A%20%20%60measureid%60%2C%0A%20%20%60datavaluetypeid%60%2C%0A%20%20%60short_question_text%60 */

