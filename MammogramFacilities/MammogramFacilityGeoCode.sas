/* ============================================================
   Census Geocoder enrichment - Mammography Screening Facilities
   
   Approach: Assign a row_id to each input address, geocode via
   the Census API in a loop, then merge the enrichment columns
   back to the full source by row_id at the end. This preserves
   ALL source columns (facility_name, phone, cert #, etc.) with
   no per-column macro plumbing.
   ============================================================ */

libname DT "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData/";

/* ============================================================
   Step 1: Build the address list with a stable row_id
   ============================================================ */
data addresses;
  set dt.mammoscreenfacilities_2026 (obs=500);
  addr1  = catx("+", address1, city, state, zipcode);
  row_id = _n_;
run;

data _null_;
  set addresses nobs=obs;
  call symputx('naddr', obs);
  stop;
run;

filename Distr "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData/temp.json";

/* ============================================================
   Step 2: Initialize the enrichment results shell.
   Only carries row_id (the join key) + the geocoded fields.
   Everything else comes back via the final merge.
   ============================================================ */
data Enriched_Results;
  length row_id 8 Address $200
         Longitude 8 Latitude 8
         StateFIPS $2 CountyFIPS $3 CountyGEOID $5
         Match_Status $10;
  stop;
run;

/* ============================================================
   Step 3: Loop through addresses. Each iteration writes one row
   to Enriched_Results keyed by row_id, whether it matched or not.
   ============================================================ */
%macro latlong_county_lookup;
  %do j = 1 %to &naddr;

    /* Safety net: clear any residual error state from prior iteration
       so a no-match doesn't cascade OBS=0 into later addresses.       */
    %let syscc = 0;

    data _null_;
      nrec = &j;
      set addresses point=nrec;
      call symputx("a1", (trim(addr1)));
      call symputx("rid", row_id);
      stop;
    run;

    PROC HTTP
      URL="https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress?address=(&a1)%nrstr(&)benchmark=Public_AR_Current%nrstr(&)vintage=Current_Current%nrstr(&)format=json"
      METHOD=GET OUT=Distr;
    RUN;

    libname DIST JSON fileref=Distr;

    /* Did the auto-mapper create the match tables for THIS response? */
    %let has_coords = %sysfunc(exist(DIST.ADDRESSMATCHES_COORDINATES));
    %let has_county = %sysfunc(exist(DIST.GEOGRAPHIES_COUNTIES));

    %if &has_coords = 1 and &has_county = 1 %then %do;
      /* ---- Matched path ---- */
      data _onerow;
        length row_id 8 Address $200
               Longitude 8 Latitude 8
               StateFIPS $2 CountyFIPS $3 CountyGEOID $5
               Match_Status $10;
        row_id       = &rid;
        Address      = symget("a1");
        Match_Status = "MATCHED";
        set DIST.ADDRESSMATCHES_COORDINATES(keep=x y obs=1);
        Longitude = x;
        Latitude  = y;
        set DIST.GEOGRAPHIES_COUNTIES(keep=state county geoid obs=1);
        StateFIPS   = state;
        CountyFIPS  = county;
        CountyGEOID = geoid;
        drop x y state county geoid;
      run;
    %end;
    %else %do;
      /* ---- No-match path: emit a row with missings so it's auditable ---- */
      data _onerow;
        length row_id 8 Address $200
               Longitude 8 Latitude 8
               StateFIPS $2 CountyFIPS $3 CountyGEOID $5
               Match_Status $10;
        row_id       = &rid;
        Address      = symget("a1");
        Longitude    = .;
        Latitude     = .;
        StateFIPS    = "";
        CountyFIPS   = "";
        CountyGEOID  = "";
        Match_Status = "NO_MATCH";
        output;
      run;
      %put NOTE: No Census geocoder match for row_id=&rid (address #&j): %superq(a1);
    %end;

    proc append base=Enriched_Results data=_onerow force;
    run;

    libname DIST clear;
  %end;
%mend;
%latlong_county_lookup;

/* ============================================================
   Step 4: Merge enrichment back to the full source dataset
   by row_id. This preserves ALL original columns automatically.
   ============================================================ */
proc sql;
  create table Enriched_Addresses as
  select a.*,
         e.Address as Geocoded_Input_Address,
         e.Longitude,
         e.Latitude,
         e.StateFIPS,
         e.CountyFIPS,
         e.CountyGEOID,
         e.Match_Status
  from addresses as a
  left join Enriched_Results as e
    on a.row_id = e.row_id
  order by a.row_id;
quit;

/* ============================================================
   Step 5: Quick summary report - how did the run do?
   ============================================================ */
proc sql;
  select Match_Status,
         count(*) as n label="Count"
  from Enriched_Addresses
  group by Match_Status;
quit;

title "Addresses with no Census geocoder match (review candidates)";
proc print data=Enriched_Addresses label noobs;
  where Match_Status = "NO_MATCH";
  var row_id facility_name address1 city state zipcode;
run;
title;
data dt.mammo_geo;
    set enriched_addresses;
run;

proc casutil incaslib="KAY_YOW" outcaslib="KAY_YOW";

droptable casdata="mammo_geo"  quiet;
load data =dt.mammo_geo casout = "mammo_geo" promote ;
save casdata="mammo_geo" replace;

quit;
