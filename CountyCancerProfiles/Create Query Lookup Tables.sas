data LKP_cancer;
infile datalines delimiter=','; 
length cancer $3.;
length cancer_desc $40;
input cancer $ cancer_desc $;

datalines;
001,All Cancer Sites

055,Breast (Female)
057,Cervix
058,Uterus (Corpus & Uterus NOS)
061,Ovary

;
/* 003,Oral Cavity & Pharynx */
/* 017,Esophagus */
/* 018,Stomach */
/* 020,Colon & Rectum */
/* 035,Liver & Bile Duct */
/* 040,Pancreas */
/* 047,Lung & Bronchus */
/* 053,Melanoma of the Skin */
/* 066,Prostate */
/* 071,Bladder */
/* 072,Kidney & Renal Pelvis */
/* 076,Brain & ONS */
/* 080,Thyroid */
/* 086,Non-Hodgkin Lymphoma */
/* 090,Leukemia */
/* 515,Childhood (Ages <20 All Sites) */
/* 516,Childhood (Ages <15 All Sites) */
/* 400,Breast (Female in situ) */
run;

data LKP_race;
infile datalines delimiter=','; 
length race $3.;
length race_desc $50;
input race $ race_desc $;

datalines;
00,All Races (includes Hispanic)
05,Hispanic (any race)
07,White Non-Hispanic
28,Black Non-Hispanic
38,Amer. Indian / AK Native (Non Hispanic)
48,Asian / Pacific Islander (non Hispanic)
;
run;


data LKP_sex;
infile datalines delimiter=','; 
length sex $3.;
length sex_desc $50;
input sex $ sex_desc $;

datalines;

2,Female
;
/* 0,Both Sexes */
/* 1,Male */
run;


data LKP_age;
infile datalines delimiter=','; 
length age $3.;
length age_desc $50;
input age $ age_desc $;

datalines;
001,All Ages

;
/* 006,<65 */
/* 009,<50 */
/* 136,50+ */
/* 157,65+ */
run;


data LKP_stage;
infile datalines delimiter=','; 
length stage $3.;
length stage_desc $50;
input stage $ stage_desc $;

datalines;
211,Late Stage
999,All Stages
;
run;

PROC SQL;
create table Param_combos as select
	a.*
	,b.*
    ,c.*
	,d.*
	,e.*
/* 	,'51' as stateFIPS */
/* 	,'county' as areatype */
from WORK.LKP_AGE as a
,WORK.LKP_RACE as b
,WORK.LKP_SEX as c
,WORK.LKP_STAGE as d
,WORK.LKP_CANCER as e
;
quit;

data Param_combosMACRO ;
set Param_combos;
MACRO = '%call_CancerProfiles(stateFIPS=00, areatype=county, cancer='||cancer||', race='||race||', sex='||sex||', age='||age||', stage='||stage||', year=0,  sortVariableName=rate, sortOrder=desc, output=1);'; 
obsno=_n_;
/*When cancer = all or leukemia, stage can only be All stages  */
if cancer in('001', '090') and stage = '211' then delete;

/*When cancer = breast or cervix or ovary or Uterus (corpus & Uterus, NOS), remove sex = both and male  */
if cancer in ('055', '057', '061', '058') and sex in ('0', '1') then delete;

/*When cancer = breast (female in situ), remove sex = both and male, and stage = late  */
if cancer in ('400') and sex in ('0', '1') then delete;
if cancer in ('400') and stage = '211' then delete;

/*When cancer = childhood <15 or <20, remove age not all  and stage = late  */
/* if cancer in ('516', '515') and age in ('006', '001', '136', '157' ) and stage = '211' then delete; */
/*will need to call childhood cancers separately as age is not an input in the query  */
if cancer in ('516', '515')  then delete;

/*When cancer = prostate, remove sex = both and female  */
if cancer in ('066') and sex in ('0', '2') then  delete;
run;

