/*Importing Lung Cancer Screening Data*/

/* Data Source: https://www.acr.org/Clinical-Resources/Lung-Cancer-Screening-Resources/LCS-Locator-Tool */

%let LCSyear = %sysfunc(year("&sysdate"d));

libname VCU "/mnt/viya-share/myazurevol/data/keyyou/vcumassey/_data";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;


/*Pulling down data from Lung Cancer Screening Locator Tool*/
filename LCS temp;
proc http
 url="https://report.acr.org/t/PUBLIC/views/NRDRLCSLocator/ACRLCSDownload.csv?4%20state="
 method="GET"
 out=LCS;
run;

/*Importing Lung Cancer Screening data*/
proc import datafile=VCU dbms=csv out=VCU.LungScreenFacilities_&LCSyear. replace;
guessingrows=2000;
run;


/*Loading data to Public folder*/
proc casutil;
 droptable casdata="LungScreenFacilities_&LCSyear." incaslib="Public" quiet;
 load data =VCU.LungScreenFacilities_&LCSyear. outcaslib = "Public" casout = "LungScreenFacilities_&LCSyear." promote ;
quit;





