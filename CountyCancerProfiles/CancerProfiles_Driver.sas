/*  
-Cancer = 400 Breast (Female in situ) does not exist in mortality data, excluded for now

*/
/* folder is for %include */
%let folder = /create-export/create/homes/Kelsey.Young@sas.com/PublicHealthScripts/VCUMassey_DataAutomation/CountyCancerProfiles;
libname dt "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData/";
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%macro call_CancerProfiles(stateFIPS, areatype, cancer, race, sex, age, stage, year=0, sortVariableName=rate, sortOrder=desc, output=1);

/* Perform data import and cleansing */
%include "&folder./Data Step for Cancer Profile Incident import.sas";

/* Perform data import and cleansing */
%include "&folder./Data Step for Cancer Profile Mortality import.sas";
%mend;

%macro setdatasets(final_table);
/*reset dsn list  */
%let dsn_list = '';
/*create list of all dataset names revelant  */
proc sql noprint;
    select catx(".", libname, memname) into: dsn_list separated by ' '	from dictionary.tables
   	where libname='WORK' and memtype='DATA' and index(memname, "%nrbquote(&final_table.)") >0
   ;
quit;
/* %put dsn_list  = &dsn_list.; */

/*create final dataset of all permuations  */
data dt.&final_table.; set &dsn_list.; run;
/*delete individual temp tables  */
%deltable (tables=&dsn_list.);
%mend;
/**************************************************************/



/*State - permutations requested by VCU   */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=001, race=00, sex=0, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=055, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=057, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=020, race=00, sex=0, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=047, race=00, sex=0, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */
/* %call_CancerProfiles(stateFIPS=00, areatype=state, cancer=066, race=00, sex=1, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1); */

/* %setdatasets(STATE_INCD_00); */
/* %setdatasets(STATE_DEATH_00); */



/* proc casutil; */
/* droptable casdata="STATE_INCD_00" incaslib="public" quiet; */
/* load data =dt.STATE_INCD_00 outcaslib = "public" casout = "STATE_INCD_00" promote ; */
/* droptable casdata="STATE_DEATH_00" incaslib="public" quiet; */
/* load data =dt.STATE_DEATH_00 outcaslib = "public" casout = "STATE_DEATH_00" promote ; */
/* quit; */



/*County - level for all female cancers     */
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=001, race=00, sex=0, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=001, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=055, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=057, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=058, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=061, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);

%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=003, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=017, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=018, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=020, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=035, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=040, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=047, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=053, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=071, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=072, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=076, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=080, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=086, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);
%call_CancerProfiles(stateFIPS=00, areatype=county, cancer=090, race=00, sex=2, age=001, stage=999, year=0,  sortVariableName=rate, sortOrder=desc, output=1);

%setdatasets(COUNTY_INCD_00);
%setdatasets(COUNTY_DEATH_00);

proc casutil incaslib="KAY_YOW" outcaslib="KAY_YOW";
droptable casdata="COUNTY_INCD_00"  quiet;
load data =dt.COUNTY_INCD_00  casout = "COUNTY_INCD_00" promote ;
save casdata="COUNTY_INCD_00" replace;
droptable casdata="COUNTY_DEATH_00"  quiet;
load data =dt.COUNTY_DEATH_00 casout = "COUNTY_DEATH_00" promote ;
save casdata="COUNTY_DEATH_00" replace;
quit;




/*all County Level */
/* Create Master Dataset of all Combinations for Female cancers (minus non existing ex: prostate & female)  */
/* %include "&folder./Create Query Lookup Tables.sas"; */
/*Open the Program and Run piece meal  */
/* %include "&folder./Execute for VA County.sas"; */

/* proc casutil; */
/* droptable casdata="COUNTY_INCD_51" incaslib="public" quiet; */
/* load data =dt.COUNTY_INCD_51 outcaslib = "public" casout = "COUNTY_INCD_51" promote ; */
/* droptable casdata="COUNTY_DEATH_51" incaslib="public" quiet; */
/* load data =dt.COUNTY_DEATH_51 outcaslib = "public" casout = "COUNTY_DEATH_51" promote ; */
/* quit; */

