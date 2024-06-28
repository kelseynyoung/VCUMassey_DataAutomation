%macro setdatasetsVA(final_table, chunk);
/*reset dsn list  */
%let dsn_list = '';
/*create list of all dataset names revelant  */
proc sql noprint;
    select catx(".", libname, memname)	into: dsn_list separated by ' ' from dictionary.tables
   	where libname='WORK' and memtype='DATA' and index(memname, "%nrbquote(&final_table.)") >0
   ;
quit;
%put dsn_list  = &dsn_list.;

/*create final dataset of all permuations  */
data dt.&final_table._&chunk.; set &dsn_list.; run;
/*delete individual temp tables  */
%deltable (tables=&dsn_list.);
%mend;

/***************A********************/
proc printto log = "&folder./logs/log_A.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_A separated by ' ' from work.Param_combosMACRO	where obsno<=500   	   ;
quit;
&VA_macrocall_A. ;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, a);
%setdatasetsVA(COUNTY_DEATH_51, a);
data _null_;
    call sleep(20,1);
run;

/***************B********************/
proc printto log = "&folder./logs/log_B.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_B separated by ' '	from work.Param_combosMACRO	where obsno between 501 and 1000   	   ;
quit;
&VA_macrocall_B.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, b);
%setdatasetsVA(COUNTY_DEATH_51, b);
data _null_;
    call sleep(20,1);
run;

/**************C*********************/
proc printto log = "&folder./logs/log_C.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_C separated by ' ' from work.Param_combosMACRO	where obsno between 1001 and 1500 	   ;
quit;
&VA_macrocall_C.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, c);
%setdatasetsVA(COUNTY_DEATH_51, c);
data _null_;
    call sleep(20,1);
run;

/***************D********************/
proc printto log = "&folder./logs/log_D.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_D separated by ' ' 	from work.Param_combosMACRO	where obsno between 1501 and 2000  	   ;
quit;
&VA_macrocall_D.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, d);
%setdatasetsVA(COUNTY_DEATH_51, d);
data _null_;
    call sleep(20,1);
run;

/****************E*******************/
proc printto log = "&folder./logs/log_E.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_E separated by ' ' 	from work.Param_combosMACRO	where obsno between 2001 and 2500  	   ;
quit;
&VA_macrocall_E.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, e);
%setdatasetsVA(COUNTY_DEATH_51, e);
data _null_;
    call sleep(20,1);
run;

/****************F*******************/
proc printto log = "&folder./logs/log_F.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_F separated by ' ' 	from work.Param_combosMACRO	where obsno between 2501 and 3000  	   ;
quit;
&VA_macrocall_F.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, f);
%setdatasetsVA(COUNTY_DEATH_51, f);
data _null_;
    call sleep(20,1);
run;

/***************G********************/
proc printto log = "&folder./logs/log_G.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_G separated by ' ' 	from work.Param_combosMACRO	where obsno between 3001 and 3500  	   ;
quit;
&VA_macrocall_G.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, g);
%setdatasetsVA(COUNTY_DEATH_51, g);
data _null_;
    call sleep(20,1);
run;

/****************H*******************/
proc printto log = "&folder./logs/log_H.txt";
run;
proc sql noprint;
    select macro into: VA_macrocall_H separated by ' ' 	from work.Param_combosMACRO	where obsno between 3501 and 4000  	   ;
quit;
&VA_macrocall_H.;
proc printto;
run;
%setdatasetsVA(COUNTY_INCD_51, h);
%setdatasetsVA(COUNTY_DEATH_51, h);
data _null_;
    call sleep(20,1);
run;
/************************************/

/*Set all together  */
Data dt.COUNTY_INCD_51;
set dt.COUNTY_INCD_51_A dt.COUNTY_INCD_51_B dt.COUNTY_INCD_51_C dt.COUNTY_INCD_51_D dt.COUNTY_INCD_51_E dt.COUNTY_INCD_51_F dt.COUNTY_INCD_51_G  dt.COUNTY_INCD_51_H;
run;

Data dt.COUNTY_DEATH_51;
set dt.COUNTY_DEATH_51_A dt.COUNTY_DEATH_51_B dt.COUNTY_DEATH_51_C dt.COUNTY_DEATH_51_D dt.COUNTY_DEATH_51_E dt.COUNTY_DEATH_51_F dt.COUNTY_DEATH_51_G  dt.COUNTY_DEATH_51_H;
run;



/*need separate call for cancer 515 and 516 for childhood cancer, stage and age not in the HTTP  */
/* https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=51&areatype=county&cancer=516&race=00&sex=0&type=incd&sortVariableName=rate&sortOrder=desc&output=1 */
