/*This program is importing 6 area deprivation index datasets from the following site: 
https://www.neighborhoodatlas.medicine.wisc.edu

Imported data includes the 12-digit FIPS codes for all states for all version years available (i.e., 2015, 2020, 2022), 
and the 9-digit ZIP codes for the state of Virginia for all version years available (e.g., 2015, 2020, 2022)

Login credentials are required to down load the data */
%let folder = /cmw/data_automation;
libname dt "&folder./_data";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

/*Importing 12-digit FIPS codes for all states for version 2015 and renaming to ADI_FIPS_2015*/
data dt.ADI_FIPS_2015    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile "&folder./VCUMassey_DataAutomation/AreaDeprivationIndex/datasets/US_2015_ADI_Census_Block_Group_v4_0_1.csv" delimiter = ',' MISSOVER DSD
lrecl=32767 firstobs=2 ;
       informat VAR1 best32. ;
       informat GISJOIN $15. ;
       informat FIPS best32. ;
       informat ADI_NATRANK $15.;
       informat ADI_STATERNK $15. ;
       format VAR1 best12. ;
       format GISJOIN $15. ;
       format FIPS best12. ;
       format ADI_NATRANK $5. ;
       format ADI_STATERNK $5. ;
    input
                VAR1
                GISJOIN  $
                FIPS
                ADI_NATRANK $
                ADI_STATERNK $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */

	drop VAR1; /*<- removing VAR1, as it only contains observation numbers and is not included in the remaining 12-digit FIPS datasets*/
    run;


/*Importing 12-digit FIPS codes for all states for version 2020 and renaming to ADI_FIPS_2020*/
data dt.ADI_FIPS_2020    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile "&folder./VCUMassey_DataAutomation/AreaDeprivationIndex/datasets/US_2020_ADI_Census_Block_Group_v4_0_1.csv" delimiter = ',' MISSOVER DSD
lrecl=32767 firstobs=2 ;
       informat GISJOIN $15. ;
       informat FIPS best32. ;
       informat ADI_NATRANK $15.;
       informat ADI_STATERNK $15. ;
       format GISJOIN $15. ;
       format FIPS best12. ;
       format ADI_NATRANK $5. ;
       format ADI_STATERNK $5. ;
    input
                GISJOIN  $
                FIPS
                ADI_NATRANK $
                ADI_STATERNK $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */

    run;

/*Importing 12-digit FIPS codes for all states for version 2022 and renaming to ADI_FIPS_2022*/
data dt.ADI_FIPS_2022    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile "&folder./VCUMassey_DataAutomation/AreaDeprivationIndex/datasets/US_2022_ADI_Census_Block_Group_v4_0_1.csv" delimiter = ',' MISSOVER DSD
lrecl=32767 firstobs=2 ;
       informat GISJOIN $15. ;
       informat FIPS best32. ;
       informat ADI_NATRANK $15.;
       informat ADI_STATERNK $15. ;
       format GISJOIN $15. ;
       format FIPS best12. ;
       format ADI_NATRANK $5. ;
       format ADI_STATERNK $5. ;
    input
                GISJOIN  $
                FIPS
                ADI_NATRANK $
                ADI_STATERNK $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */

    run;

/*File too big to load  */
/*Importing 9-digit FIPS codes for Virginia only for version 2015 and renaming to ADI_VAZCTA_2015*/
    data dt.ADI_VAZCTA_2015    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile "&folder./VCUMassey_DataAutomation/AreaDeprivationIndex/datasets//VA_2015_ADI_9 Digit Zip Code_v3.1.txt" delimiter = ',' MISSOVER DSD lrecl=32767
firstobs=2 ;
       informat VAR1 $4. ;
       informat X best32. ;
       informat TYPE $3. ;
       informat ZIPID $12. ;
       informat FIPS_x best32. ;
       informat GISJOIN $17. ;
       informat FIPS_y $14. ;
       informat ADI_NATRANK $4. ;
       informat ADI_STATERNK $4. ;
       format VAR1 $4. ;
       format X best12. ;
       format TYPE $3. ;
       format ZIPID $12. ;
       format FIPS_x best12. ;
       format GISJOIN $17. ;
       format FIPS_y $14. ;
       format ADI_NATRANK $4. ;
       format ADI_STATERNK $4. ;
    input
                VAR1  $
                X
                TYPE  $
                ZIPID  $
                FIPS_x
                GISJOIN  $
                FIPS_y  $
                ADI_NATRANK  $
                ADI_STATERNK  $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */

	drop VAR1 X; /*<- removing VAR1 and X, as they only contains observation numbers and is not included in the remaining 12-digit FIPS datasets*/
    run;

/*Importing 9-digit FIPS codes for Virginia only for version 2020 and renaming to ADI_VAZCTA_2020*/
    data WORK.ADI_VAZCTA_2020    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile '/mnt/viya-share/myazurevol/data/keyyou/vcumassey/AreaDeprivationIndex/Datasets/VA_2020_ADI_9 Digit Zip Code_v4_0_1.csv' delimiter = ',' MISSOVER DSD lrecl=32767
 firstobs=2 ;
       informat ZIP_4 $11. ;
       informat GISJOIN $17. ;
       informat FIPS $14. ;
       informat TYPE $3. ;
       informat ADI_NATRANK $3. ;
       informat ADI_STATERANK $3. ;
       format ZIP_4 $11. ;
       format GISJOIN $17. ;
       format FIPS $14. ;
       format TYPE $3. ;
       format ADI_NATRANK $3. ;
       format ADI_STATERANK $3. ;
    input
                ZIP_4  $
                GISJOIN  $
                FIPS  $
                TYPE  $
                ADI_NATRANK  $
                ADI_STATERANK  $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    run;

/*Importing 9-digit FIPS codes for Virginia only for version 2022 and renaming to ADI_VAZCTA_2022*/
    data WORK.ADI_VAZCTA_2022    ;
    %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
    infile '/mnt/viya-share/myazurevol/data/keyyou/vcumassey/AreaDeprivationIndex/Datasets/VA_2022_ADI_9 Digit Zip Code_v4_0_1.csv' delimiter = ',' MISSOVER DSD lrecl=32767
 firstobs=2 ;
       informat ZIP_4 $11. ;
       informat GISJOIN $17. ;
       informat FIPS $14. ;
       informat TYPE $3. ;
       informat ADI_NATRANK $3. ;
       informat ADI_STATERANK $3. ;
       format ZIP_4 $11. ;
       format GISJOIN $17. ;
       format FIPS $14. ;
       format TYPE $3. ;
       format ADI_NATRANK $3. ;
       format ADI_STATERANK $3. ;
    input
                ZIP_4  $
                GISJOIN  $
                FIPS  $
                TYPE  $
                ADI_NATRANK  $
                ADI_STATERANK  $
    ;
    if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
    run;


%macro ADI(fname=);
/*Loading data to Public folder*/
proc casutil;
 droptable casdata="WORK.&fname." incaslib="Public" quiet;
 load data =WORK.&fname. outcaslib = "Public" casout = "&fname." promote ;
quit;
%mend;

/*macro executing the steps above*/
%ADI (fname = ADI_FIPS_2015);
%ADI (fname = ADI_FIPS_2020);
%ADI (fname = ADI_FIPS_2022);
%ADI (fname = ADI_VAZCTA_2015);
%ADI (fname = ADI_VAZCTA_2020);
%ADI (fname = ADI_VAZCTA_2022);


