
*planned data integrity checks: it's easier (maybe) to check in an automated way than by hand (rmpo)
1. noncontiguous days should usually be because of weekends so look at dow
2. Investigate any outlier in terms of # entries, tot time, start or end time, dow in (1,7)
3. dupe dates.  Once create plan ds side by side then merge look for date mismatch
4. consolidate silly entries such as a day that has wake up AND wake ready, also plan=0duration


glob "eat" with "lunch"  !!! ;
;


*highly limited scope: basically only concerned with 2 vars for ACTUAL, activity and 
 duration in minutes.  Start time for same is parsed as character for visual only. Also
 because of need for manual data cleaning only a small range of days parsed;
data x;
*infile 'C:\Users\anhutz\Desktop\new_again\self_data\ap_timelog\Planning is often but not always futile.csv' dsd;
infile 'C:\Users\anhutz\Desktop\msa\nonTS projects\self_data\ap_timelog\Planning is often but not always futile - Sheet1.csv' dsd; *or plan0.csv;
  INPUT @1 rectype $4. @ ;
   length theworddate $ 4 activity $ 32;
   drop theworddate rectype;
   retain date;
   format date date9. ;*start_time hhmm.;
    IF (rectype = "Date") THEN INPUT theworddate $ Date : date9.  ;
    ELSE DO;
	input @1 activity $ dur_min start_time $;
	output;
	end;
; run;
data ap;
set x;
  *sometimes the PLAN side is longer, delete those with empty ACTUAL;
  if activity=' '  and dur_min=. then delete;
run;
proc sql;
 select count(distinct date) from ap;
quit;
/*proc freq data=ap; table activity; run;*/
  *Based on above consolidating the data;
data ap;
set ap; 
 length short $ 18;
  if find(activity,'leave') OR 
    (find(activity,'kelly','i') and not find(activity,'kelly','i')) then short='leave';
  else if find(activity,'lunch','i') then short='lunch';
  else if find(activity,'chat','i') or find(activity,'talk','i') then short='talk';
  else if find(activity,'research','i') then short='research';
  *COMMUTE (including bike drive walk (TO work)) BEFORE work;
  else if find(activity,'to work','i') then short='commute';
  else if find(activity,'walk','i') then short='walk';
  else if find(activity,'bike','i') then short='bike'; 
  else if find(activity,'drive','i') then short='drive'; 
  else if find(activity,'work','i') then short='work';
  else if find(activity,'churn','i') then short='churn';
  else if find(activity,'program','i') or
           find(activity,'prayer','i') or 
      find(activity,'meditat','i')   then short='program';
  else if find(activity,'wake','i') then short='wake';
  else if find(activity,'breakfast','i') or
           find(activity,'eat','i') or 
      find(activity,'dinner','i')    then short='eat'; *breakfast BEFORE break;
  else if find(activity,'break','i') then short='break';
  else if find(activity,'meeting','i') then short='meeting';
  else if find(activity,'video','i') then short='video';
  else if find(activity,'plan','i') then short='plan';
  else if find(activity,'subanalytics','i') then short='subanalytics';
  else if find(activity,'tea','i') then short='tea';
  else if find(activity,'juggle','i') then short='juggle';
  else if find(activity,'brush','i') then short='brush';
  else short='other';
run;
/*proc print data=ap; where short=' ' or short=''; run; */


data subset;
set ap;
if short='leave' then delete;
*leave is trivial, dur_min=.  but wake and commute are not admissible so delete them too;
if short='wake' or short='commute' or find(activity,'shower') then delete;

length catgy $ 12;
if short='work' or short='meeting' then catgy='work';
else if short='program' or short='plan' then catgy='program';
else if short='churn' then catgy='churn';
else if short='subanalytics' or short='research' then catgy='subanalytics';
else if short='lunch' then catgy='lunch';
else if short='talk' or short='tea' 
     or short='break' or short='video' or short='juggle' then catgy='break';
else if short='eat' or short='brush' then catgy='necessary';
else if short='walk' or short='bike' or short='other' or short='drive' then catgy='OTHER';
else catgy="Data Problem!";

*temporarily? roll up necessary into OTHER;
if catgy='necessary' then catgy='OTHER';
run;
proc freq data=subset; table catgy; run; 


proc sort data=subset out=jumble; by date catgy;*the real key is date/time; run;
proc means data=jumble noprint; 
output out=alttosql sum=dailysum; 
var dur_min; by date catgy; 
run; 
data sumavg;
set alttosql;
*REVISIT: anything that has missing at this point give it zero;
if dailysum=. then dailysum=0;
avg=dailysum/_freq_;
drop _type_ _freq_;
run;
/*

TRYING to superstack, get one row per date with variables for sum_work, avg_work, sum_program ...
 This is classic transaction-data-to-analytical-data ninja stuff

who cares what the smart way is, this works
*/ 
data cat1;
set sumavg;
where catgy='work';
work_sum=dailysum;
work_avg=avg;
run;
data cat2;
set sumavg;
where catgy='program';
program_sum=dailysum;
program_avg=avg;run;
data cat3;
set sumavg;
where catgy='churn';
churn_sum=dailysum;
churn_avg=avg;run;
data cat4;
set sumavg;
where catgy='subanalytics';
sanly_sum=dailysum;
sanly_avg=avg;run;
data cat5;
set sumavg;
where catgy='lunch';
lunch_sum=dailysum;
lunch_avg=avg;run;
data cat6;
set sumavg;
where catgy='break';
break_sum=dailysum;
break_avg=avg;run;
data cat7;
set sumavg;
where catgy='OTHER';
other_sum=dailysum;
other_avg=avg;run;
data series;
merge cat1 cat2 cat3 cat4 cat5 cat6 cat7;
by date; drop dailysum avg;
*get work as a percentage;
work_pct=work_sum/sum(program_sum,churn_sum,sanly_sum,break_sum,other_sum,work_sum);
tot_known_time=sum(program_sum,churn_sum,sanly_sum,break_sum,other_sum,work_sum,lunch_sum);
*if any VAR_typ is missing it should be 0;
run;

   *reset all goptions and the window, then plot;
      goptions reset=all dev=sasprtc;
      options sysprintfont="Courier";	      
      goptions display;
      ods select all;
      ods listing close;
      ods html3 file="event_fcst_example.html" path="C:\temp"; 
      ods graphics on / reset imagename="event_" imagefmt=png width=1250px height=780px border=off ANTIALIASMAX=50100;
      options orientation=landscape;
      ods PATH work.templat(update) sasuser.templat(read)
                 sashelp.tmplmst(read);

proc sgplot data=series;
series x=date y=work_sum;
series x=date y=tot_known_time;
series x=date y=work_pct / y2axis;
run;

proc sgplot data=series;
series x=date y=break_sum;
run;

*going back closer to source, data isnt as dirty as I assumed it would be but there are some minor discrepancies;
*such as an avg of 4 hours categorized per work day, cross referencing with granular data;
proc sql;
create table daily as 
 select date, sum(dur_min)/60-2/*morning commute*/-1/*lunch*/ as approx_work_hrs_tot
  from x
   group by date;
quit;
proc univariate data=daily; run; *yes theres discrepancy;

*getting daily wake up time from source;
data wakeup;
set x;
where find(activity,'wake');
*convert start_time to numeric datetime;
st_time=input(start_time,time.); format st_time time.;
run;
proc sgplot data=wakeup;
series x=date y=st_time ;
yaxis grid;
run;