/* libname HRSA "/mnt/viya-share/myazurevol/data/keyyou/vcumassey/HRSA/data"; */
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

%macro importHRSA(dsn, filename);
filename HRSA url "https://data.hrsa.gov/DataDownload/DD_Files/&filename..xlsx";
proc import datafile = HRSA out = HRSA.&dsn. dbms=xlsx replace;
run;

proc casutil;
droptable casdata="&dsn." incaslib="public" quiet;
load data =HRSA.&dsn. outcaslib = "public" casout = "&dsn." promote ;
quit;

%mend;

%importHRSA(HPSA_Meta		 ,HPSA_DATAMART_METADATA);
%importHRSA(HPSA_PC			 ,BCD_HPSA_FCT_DET_PC);
%importHRSA(HPSA_Score_Meta	 ,DD_AUTO_HPSA_SITE_METADATA);
%importHRSA(HPSA_Score_PC	 ,SDMS_AUTO_HPSA_SITE_PC);
%importHRSA(HPSA_Mental		 ,BCD_HPSA_FCT_DET_MH);
%importHRSA(HPSA_Score_Mental,SDMS_AUTO_HPSA_SITE_MH);
%importHRSA(HPSA_Dental		 ,BCD_HPSA_FCT_DET_DH);
%importHRSA(HPSA_Score_Dental,SDMS_AUTO_HPSA_SITE_DH);
%importHRSA(HPSA_MUA_Meta	 ,MUA_DATAMART_METADATA);
%importHRSA(HPSA_MUA		 ,MUA_DET);
