
libname dt "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData/";

/* cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US"); */
/* caslib _all_ assign; */

%macro load(sastable, castable);
proc casutil incaslib="KAY_YOW" outcaslib="KAY_YOW";

droptable casdata="&castable."  quiet;
load data =dt.&sastable. casout = "&castable." promote ;
save casdata="&castable." replace;

quit;

/* proc casutil */
/*   incaslib="KAY_YOW"  outcaslib="KAY_YOW"; */
  
/*  run; */
%mend load;

%load(_500CITIESPLACES_COUNTY_2024,         _500CITIESPLACES_COUNTY_2024);
%load(_500CITIESPLACES_SDOHCOUNTY_2021,     _500CITIESPLACES_SDOHCOUNTY_2021);
%load(COUNTY_DEATH_00,                      COUNTY_DEATH_00);
%load(COUNTY_INCD_00,                       COUNTY_INCD_00 );
%load(COUNTYHEALTHRANKING_TREND2023,        COUNTYHEALTHRANKING_TREND2023 );
%load(COUNTYHEALTHRANKING_TREND2024,        COUNTYHEALTHRANKING_TREND2024);
%load(COUNTYHEALTHRANKING_TREND2025,        COUNTYHEALTHRANKING_TREND2025 );
%load(COUNTYHEALTHRANKING2023,              COUNTYHEALTHRANKING2023 );
%load(COUNTYHEALTHRANKING2024,              COUNTYHEALTHRANKING2024 );
%load(COUNTYHEALTHRANKING2025,              COUNTYHEALTHRANKING2025 );
%load(DP05_VACOUNTIES2023,                  DP05_VACOUNTIES2023);
%load(DP05_VACOUNTIES2024,                  DP05_VACOUNTIES2024 );
%load(MAMMOSCREENFACILITIES_2026,           MAMMOSCREENFACILITIES_2026);
%load(SVI_CENSUSTRACTS_2022,                SVI_CENSUSTRACTS_2022);
%load(SVI_COUNTIES_2022,                    SVI_COUNTIES_2022);
%load(MAMMO_GEO,                            MAMMO_GEO);
%load(GRANTS_GEO,                           GRANTS_GEO);

