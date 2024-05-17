%let year 			= 2024;
%let CHR_FileName 	= analytic_data2024;
%let CHRT_FileName 	= chr_trends_sas_2024;


/*Retrieve CHR data */
filename CHR temp ;
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHR_FileName..sas7bdat"
	out=CHR;
run;
/*Retrieve CHR Trends data */
filename CHRT temp ;
proc http method='GET'
	url="https://www.countyhealthrankings.org/sites/default/files/media/document/&CHRT_FileName..sas7bdat"
	out=CHRT;
run;
/*Start CAS Session  */
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;
/*Upload to CAS  */
proc cas;
   upload                                            
      path="%sysfunc(pathname(CHR))"
      casOut={caslib="public", name="CountyHealthRanking&year."}
      importOptions="basesas" ;
   upload                                            
      path="%sysfunc(pathname(CHRT))"
      casOut={caslib="public", name="CountyHealthRanking_Trends&year."}
      importOptions="basesas"; 
run;

Proc cas;
	table.promote / caslib="PUBLIC", drop=TRUE, name="CountyHealthRanking&year", 
		quiet=FALSE, target="CountyHealthRanking&year", targetLib="Public";
	table.promote / caslib="PUBLIC", drop=TRUE, name="CountyHealthRanking_Trends&year", 
		quiet=FALSE, target="CountyHealthRanking_Trends&year", targetLib="Public";
run;





