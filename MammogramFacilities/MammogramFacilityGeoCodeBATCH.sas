/* ============================================================
Census Geocoder BATCH enrichment - Mammography Screening Facilities

Approach: Assign a stable row_id, write the addresses out as a
CSV in the exact layout the Census /addressbatch endpoint wants,
POST the file (in chunks of <=10,000), parse the returned CSV,
then merge enrichment back to the full source by row_id.

Why batch: for many rows this replacesmany HTTP round-trips
with a handful of calls - officially supported up to 10,000
addresses per submission, and far faster/kinder to Census.
============================================================ */
libname DT "/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData/";

%let WORKDIR=/create-export/create/homes/Kelsey.Young@sas.com/PublicHealthData;
%let CHUNKSIZE=2000; /* rows per POST; <=10,000. Smaller = more resilient */

/* ============================================================
Step 1: Build the address list with a stable row_id.
Strip embedded commas from each component so they don't break
the 5-field CSV layout the batch parser expects.
============================================================ */
data addresses;
    set dt.mammoscreenfacilities_2026 ;
        /* add (obs=500) here to test on a subset */
    row_id=_n_;
    /* Cleaned components for the batch CSV (no internal commas) */
    b_street=compress(address1, ',');
    b_city=compress(city, ',');
    b_state=compress(state, ',');
    b_zip=compress(zipcode, ',');
run;

data _null_;
    set addresses nobs=obs;
    call symputx('naddr', obs);
    stop;
run;

%let NCHUNKS=%sysfunc(ceil(&naddr / &CHUNKSIZE));

/* ============================================================
Step 2: Initialize the enrichment results shell.
Carries row_id (join key) + everything the batch endpoint
returns. All other source columns come back via the merge.
============================================================ */
data Enriched_Results;
    length row_id 8 Input_Address $250 Match_Ind $10 Match_Type $15
        Matched_Address $250 Coordinates $50 TigerLine_ID $20 Side $1 StateFIPS
        $2 CountyFIPS $3 Tract $6 Block $4 Longitude 8 Latitude 8 CountyGEOID $5
        Match_Status $10;
    stop;
run;

/* ============================================================
Step 3: Loop over chunks. For each chunk:
3a. Write the input CSV (no header): id,street,city,state,zip
3b. Hand-build a multipart/form-data body, then POST it
3c. Read the returned CSV and normalize the fields
3d. Append to Enriched_Results
============================================================ */
%macro batch_geocode;
    %local boundary;
    %let boundary=----------SASGeocoderBoundary&SYSJOBID;

    %do c=1 %to &NCHUNKS;

        %let lo=%eval((&c - 1) * &CHUNKSIZE + 1);
        %let hi=%sysfunc(min(%eval(&c * &CHUNKSIZE), &naddr));
        %put NOTE:=====Chunk &c of &NCHUNKS : row_id &lo to &hi=====;

        /* Safety net: clear residual error state between chunks */
        %let syscc=0;

        filename batchin "&WORKDIR/geocode_in_&c..csv";
        filename batchout "&WORKDIR/geocode_out_&c..csv";
        filename reqbody temp lrecl=32767;

        /* --- 3a. Input CSV in required order, no header row --- */
        data _null_;
            set addresses;
            where row_id ge &lo and row_id le &hi;
            file batchin dsd dlm=',' lrecl=32767;
            put row_id b_street b_city b_state b_zip; /* no explicit commas! */
        run;

        /* --- 3b1. Assemble the multipart/form-data request body ---
        CRLF line endings are what strict multipart parsers expect.
        We write the three form fields (benchmark, vintage, and the
        file part), inline the CSV, then close with the boundary.   */
        data _null_;
            infile batchin end=eof lrecl=32767 truncover;
            file reqbody termstr=crlf lrecl=32767;
            if _n_=1 then do;
                put "--&boundary";
                put 'Content-Disposition: form-data; name="benchmark"';
                put ;
                put "Public_AR_Current";
                put "--&boundary";
                put 'Content-Disposition: form-data; name="vintage"';
                put ;
                put "Current_Current";
                put "--&boundary";
                put
                    'Content-Disposition: form-data; name="addressFile"; filename="addr.csv"';
                put 'Content-Type: text/csv';
                put ;
            end;
            input;
            put _infile_; /* inline each CSV line */
            if eof then put "--&boundary--";
        run;

        /* --- 3b2. One POST for the whole chunk --- */
        proc http
            url="https://geocoding.geo.census.gov/geocoder/geographies/addressbatch"
            method="POST" in=reqbody
            ct="multipart/form-data; boundary=&boundary" timeout=1800
            out=batchout;
        run;

  %put NOTE: Chunk &c POST status=&SYS_PROCHTTP_STATUS_CODE (&SYS_PROCHTTP_STATUS_PHRASE);

        /* --- 3c. Parse the returned CSV ---
        Output columns (geographies batch), comma-delimited, quoted
        where needed:
        id, input_address, match_indicator, match_type,
        matched_address, coordinates(lon,lat), tigerline_id, side,
        state_fips, county_fips, tract, block
        No-match / tie rows leave the trailing fields blank.        */
        data _chunkrows;
            infile batchout dsd truncover lrecl=32767;
            length row_id 8 Input_Address $250 Match_Ind $10 Match_Type $15
                Matched_Address $250 Coordinates $50 TigerLine_ID $20 Side $1
                StateFIPS $2 CountyFIPS $3 Tract $6 Block $4 Longitude 8
                Latitude 8 CountyGEOID $5 Match_Status $10;
            input row_id Input_Address Match_Ind Match_Type Matched_Address
                Coordinates TigerLine_ID Side StateFIPS CountyFIPS Tract Block;

            /* Coordinates come back as "longitude,latitude" */
            Longitude=input(scan(Coordinates, 1, ','), ?? best32.);
            Latitude=input(scan(Coordinates, 2, ','), ?? best32.);

            /* 5-digit combined county FIPS */
            if not missing(StateFIPS) and not missing(CountyFIPS) then
                CountyGEOID=cats(StateFIPS, CountyFIPS);
            else CountyGEOID="";

            /* Normalize match indicator to our MATCHED / NO_MATCH / TIE */
            if upcase(Match_Ind)="MATCH" then Match_Status="MATCHED";
            else if index(upcase(Match_Ind), "NO_MATCH") then Match_Status=
                "NO_MATCH";
            else if upcase(Match_Ind)="TIE" then Match_Status="TIE";
            else Match_Status=upcase(Match_Ind);
        run;

        /* --- 3d. Accumulate --- */
        proc append base=Enriched_Results data=_chunkrows force;
        run;

        filename batchin clear;
        filename batchout clear;
        filename reqbody clear;
    %end;
%mend;
%batch_geocode;

/* ============================================================
   Step 3.5: Retry NO_MATCH / TIE rows.
   The /addressbatch endpoint is already "structured", so the lever
   here is CLEANING the components (drop suite/unit, strip punctuation,
   trim ZIP to 5 digits) and re-POSTing. Successful re-matches are
   written back in place; unresolved rows keep their original values
   and are tagged for audit.
   ============================================================ */

/* 3.5.0 - Tag existing results with the pass that produced them */
data Enriched_Results;
  set Enriched_Results;
  length Geocode_Pass $16;
  if missing(Geocode_Pass) then Geocode_Pass = "BATCH";
run;

/* 3.5a - Pull failed row_ids back to their source components */
proc sql noprint;
  create table _retry_src as
  select a.row_id, a.b_street, a.b_city, a.b_state, a.b_zip
  from addresses as a
  inner join Enriched_Results as e
    on a.row_id = e.row_id
  where e.Match_Status in ("NO_MATCH","TIE");
quit;
%let n_retry = &sqlobs;
%put NOTE: ===== Step 3.5: &n_retry row(s) flagged NO_MATCH/TIE for retry =====;

%macro retry_pass;
%if &n_retry = 0 %then %do;
  %put NOTE: Nothing to retry - skipping Step 3.5.;
%end;
%else %do;

  /* 3.5b - Clean the components */
  data _retry_clean;
    set _retry_src;
    length c_street $100 c_zip $10;
    c_street = upcase(strip(b_street));
    /* drop trailing "#unit" then any secondary-unit designator to end */
    c_street = prxchange('s/\s+#.*$//', 1, c_street);
    c_street = prxchange('s/\s+(STE|SUITE|UNIT|APT|APARTMENT|RM|ROOM|FL|FLR|FLOOR|BLDG|BUILDING|DEPT|SPC|SPACE|LOT|TRLR)\b.*$//', 1, c_street);
    c_street = prxchange('s/[.,#]/ /', -1, c_street);   /* residual punctuation */
    c_street = prxchange('s/\s+/ /',  -1, c_street);    /* collapse spaces */
    c_street = strip(c_street);
    c_zip    = substr(compress(b_zip, , 'kd'), 1, 5);   /* first 5 digits only */
  run;

  filename rtryin   "&WORKDIR/geocode_retry_in.csv";
  filename rtryout  "&WORKDIR/geocode_retry_out.csv";
  filename rtrybody temp lrecl=32767;

  /* 3.5c - Input CSV (DSD handles the commas; no literals) */
  data _null_;
    set _retry_clean;
    file rtryin dsd dlm=',' lrecl=32767;
    put row_id c_street b_city b_state c_zip;
  run;

  /* 3.5d - Hand-built multipart body (same proven pattern as Step 3) */
  %local bnd;
  %let bnd = ----------SASRetryBoundary&SYSJOBID;
  data _null_;
    infile rtryin end=eof lrecl=32767 truncover;
    file rtrybody termstr=crlf lrecl=32767;
    if _n_ = 1 then do;
      put "--&bnd";
      put 'Content-Disposition: form-data; name="benchmark"';
      put ;
      put "Public_AR_Current";
      put "--&bnd";
      put 'Content-Disposition: form-data; name="vintage"';
      put ;
      put "Current_Current";
      put "--&bnd";
      put 'Content-Disposition: form-data; name="addressFile"; filename="retry.csv"';
      put 'Content-Type: text/csv';
      put ;
    end;
    input;
    put _infile_;
    if eof then put "--&bnd--";
  run;

  proc http
    url="https://geocoding.geo.census.gov/geocoder/geographies/addressbatch"
    method="POST"
    in=rtrybody
    ct="multipart/form-data; boundary=&bnd"
    timeout=1800
    out=rtryout;
  run;
  %put NOTE: Step 3.5 POST status=&SYS_PROCHTTP_STATUS_CODE (&SYS_PROCHTTP_STATUS_PHRASE);

  /* 3.5e - Parse the retry response (identical layout to Step 3c) */
  data _retryrows;
    infile rtryout dsd truncover lrecl=32767;
    length row_id 8 Input_Address $250 Match_Ind $10 Match_Type $15
           Matched_Address $250 Coordinates $50
           TigerLine_ID $20 Side $1
           StateFIPS $2 CountyFIPS $3 Tract $6 Block $4
           Longitude 8 Latitude 8 CountyGEOID $5 Match_Status $10 Geocode_Pass $16;
    input row_id Input_Address Match_Ind Match_Type Matched_Address
          Coordinates TigerLine_ID Side StateFIPS CountyFIPS Tract Block;
    Longitude = input(scan(Coordinates, 1, ','), ?? best32.);
    Latitude  = input(scan(Coordinates, 2, ','), ?? best32.);
    if not missing(StateFIPS) and not missing(CountyFIPS)
      then CountyGEOID = cats(StateFIPS, CountyFIPS);
      else CountyGEOID = "";
    if upcase(Match_Ind) = "MATCH"    then Match_Status = "MATCHED";
    else if index(upcase(Match_Ind), "NO_MATCH") then Match_Status = "NO_MATCH";
    else if upcase(Match_Ind) = "TIE" then Match_Status = "TIE";
    else Match_Status = upcase(Match_Ind);
    Geocode_Pass = "RETRY_MATCHED";
  run;

  /* 3.5f - Update in place: only successful re-matches overwrite.
     UPDATE overwrites master with NONMISSING transaction values only,
     so a still-failed retry (blank coords) can't wipe anything.      */
  data _retry_fixed;
    set _retryrows;
    where Match_Status = "MATCHED";
  run;

  proc sort data=Enriched_Results; by row_id; run;
  proc sort data=_retry_fixed;      by row_id; run;

  data Enriched_Results;
    update Enriched_Results _retry_fixed;
    by row_id;
  run;

  /* Tag rows that were retried but still unresolved (audit trail) */
  proc sql;
    update Enriched_Results
      set Geocode_Pass = "RETRY_NOFIX"
      where row_id in (select row_id from _retry_src)
        and Match_Status in ("NO_MATCH","TIE");
  quit;

  filename rtryin   clear;
  filename rtryout  clear;
  filename rtrybody clear;
%end;
%mend;
%retry_pass;

/* ============================================================
Step 4: Merge enrichment back to the full source by row_id.
Selects the curated set of source columns + enrichment fields.
============================================================ */
proc sql;
    create table Enriched_Addresses as select 
    a.Facility_Name
    ,a.Address1 
    ,a.Address2 
    ,a.Address3 
    ,a.City 
    ,a.State 
    ,a.ZipCode 
    ,a.Phone 
    ,a.Fax 
    ,e.Longitude
    ,e.Latitude
    ,e.StateFIPS
    ,e.CountyFIPS
    ,e.CountyGEOID
    ,e.Match_Status
    ,e.Geocode_Pass
    ,e.Match_Type
    ,e.Matched_Address as Geocoded_Match_Address
    ,e.Tract
    ,e.Block 
    ,a.row_id
    from addresses as a left join Enriched_Results as e on a.row_id=e.row_id
        order by a.row_id;
quit;

/* ============================================================
Step 5: Summary report - how did the run do?
============================================================ */
proc sql;
  title "Geocode outcome by pass";
  select coalesce(Match_Status,'(no result)') as Match_Status label="Status",
         coalesce(Geocode_Pass,'BATCH')       as Geocode_Pass label="Obtained via",
         count(*) as n label="Count"
  from Enriched_Addresses
  group by calculated Match_Status, calculated Geocode_Pass;
quit;

title "Still unresolved after retry (review candidates)";
proc print data=Enriched_Addresses label noobs;
  where Match_Status in ("NO_MATCH","TIE") or missing(Match_Status);
  var row_id facility_name address1 city state zipcode Match_Status Geocode_Pass;
run;
title;

/* ============================================================
Step 6: Persist to library + promote/save in CAS (unchanged)
============================================================ */
data dt.mammo_geo;
    set enriched_addresses;
run;

proc casutil incaslib="KAY_YOW" outcaslib="KAY_YOW";
    droptable casdata="mammo_geo" quiet;
    load data=dt.mammo_geo casout="mammo_geo" promote;
    save casdata="mammo_geo" replace;
quit;
