/*Importing 500 Cities Place - Social Determinants of Health (SDOH) Data*/

/* Data Source: https://chronicdata.cdc.gov/browse?category=500+Cities+%26+Places&sortBy=newest&utf8 */

%let sdoh_yr = 2021; /*The last year of the range for the 5-year SDOH datasets. The rage for the most recent data is 2017-2021*/
%let places_yr = 2022;  /*The year release, as specified in the Places dataset titles. The current release is 2022*/

libname VCU "/cmw/data_automation/_data";

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
GUESSINGROWS=3000; /* Specifies the number of rows of the file to scan to determine the appropriate data type and length for the variables*/
run;

/*Adding leading zeros to the LocationID variable and converting it from numeric to character*/
data VCU.&dsn._&yr_end.;
set &dsn._&yr_end (rename=(locationID=location_num));
LocationID=put(location_num,&idlength.); 
data_range_end_year = &yr_end.;
drop location_num;
run;


/*Loading data to Public folder*/
proc casutil;
 droptable casdata="&dsn._&yr_end." incaslib="Public" quiet;
 load data =VCU.&dsn._&yr_end. outcaslib = "Public" casout = "&dsn._&yr_end." promote ;
quit;

%mend;


/*macro executing the steps above*/
%SDOH_PLACES (fname = SDOHZCTA	, url=https://data.cdc.gov/api/views/bumh-rgsq/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_SDOHZCTA 		, idlength=z5.  , yr_end = &sdoh_yr.);
%SDOH_PLACES (fname = SDOHPLCE	, url=https://data.cdc.gov/api/views/edkk-ze78/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_SDOHPlace		, idlength=z7.  , yr_end = &sdoh_yr.);
%SDOH_PLACES (fname = SDOH_CT	, url=https://data.cdc.gov/api/views/e539-uadk/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_SDOHCTract	    , idlength=z11. , yr_end = &sdoh_yr.);
%SDOH_PLACES (fname = SDOHCnty	, url=https://data.cdc.gov/api/views/i6u4-y3g4/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_SDOHCounty		, idlength=z5.  , yr_end = &sdoh_yr.);
%SDOH_PLACES (fname = ZCTA	    , url=https://data.cdc.gov/api/views/gd4x-jyhw/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_ZCTA 			, idlength=z5.  , yr_end = &places_yr.);
%SDOH_PLACES (fname = Place	    , url=https://data.cdc.gov/api/views/epbn-9bv3/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_Place			, idlength=z7.  , yr_end = &places_yr.);
%SDOH_PLACES (fname = CT		, url=https://data.cdc.gov/api/views/nw2y-v4gm/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_CTract		    , idlength=z11. , yr_end = &places_yr.);
%SDOH_PLACES (fname = County	, url=https://data.cdc.gov/api/views/duw2-7jbt/rows.csv?accessType=DOWNLOAD	, dsn=_500CitiesPlaces_County			, idlength=z5.  , yr_end = &places_yr.);




