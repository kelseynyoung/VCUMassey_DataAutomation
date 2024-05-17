libname mam "/mnt/viya-share/myazurevol/data/keyyou/vcumassey/MammogramFacilities/data";

cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
caslib _all_ assign;

/* detect proper delim for UNIX vs. Windows */
%let delim=%sysfunc(ifc(%eval(&sysscp. = WIN),\,/));
 /* create a name for our downloaded ZIP */
%let ziploc = %sysfunc(getoption(work))&delim.datafile.zip;
filename download "&ziploc";

/*make call to ed data express for ZIP files*/
proc http
 method='GET'
 url="http://www.accessdata.fda.gov/premarket/ftparea/public.zip"
 out=download;
run;

/* Assign a fileref wth the ZIP method */
filename inzip zip "&ziploc";
 
/* Read the "members" (files) from the ZIP file - only needed if unsure ZIP contents/filenames */
/* data contents(keep=memname); */
/*  length memname $200; */
/*  fid=dopen("inzip"); */
/*  if fid=0 then */
/*   stop; */
/*  memcount=dnum(fid); */
/*  do i=1 to memcount; */
/*   memname=dread(fid,i); */
/*   output; */
/*  end; */
/*  rc=dclose(fid); */
/* run; */

/*https://www.fda.gov/radiation-emitting-products/mammography-information-patients/search-certified-facility  */
  data mam.MammoScreenFacilities    ;
          infile inzip(public.txt) delimiter = '|' MISSOVER DSD lrecl=32767 ;
          informat Facility_Name $75. ;
          informat Address1 $50. ;
          informat Address2 $50. ;
          informat Address3 $50. ;
          informat City $50. ;
          informat State $2. ;
          informat ZipCode $15. ;
          informat Phone $50. ;
          informat Fax $50. ;
          format Facility_Name $75. ;
          format Address1 $50. ;
          format Address2 $50. ;
          format Address3 $50. ;
          format City $50. ;
          format State $2. ;
          format ZipCode $15. ;
          format Phone $50. ;
          format Fax $50. ;
       	  input
               Facility_Name  $
               Address1  $
               Address2  $
               Address3  $
               City  $
			   State  $
               ZipCode  $
               Phone  $
               Fax  $  ;
		   label Facility_Name = 'Facility Name';
       run;
proc casutil;
droptable casdata="MammoScreenFacilities" incaslib="public" quiet;
load data =mam.MammoScreenFacilities outcaslib = "public" casout = "MammoScreenFacilities" promote ;
quit;