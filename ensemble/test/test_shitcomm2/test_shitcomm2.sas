/*
copy test 1
with esm 

TEST DELTAS:
but still trivial append and time tables etc

CODE DELTAS:
added wide merging functionality
moved esm into main module

*/


proc datasets lib=work kill noprint nolist; run; quit;

libname ts 'C:\Users\anhutz\Desktop\msa\TimeSeries\CLASS\class_data';
data orig_3yr;
set ts.airline;
format date 8.;
proxy_dt_trend=_n_;
run; 

%let basedata=airline;
%let fcst_hrz_increments=2000;
%let voi0=lair;  

%let lags0=&voi0._1_1 &voi0._1_3 &voi0._1_8;

%let date_var=proxy_dt_trend;

*restart the run count;
%symdel run;
%let run=1;

*clean & seed long, wide etc;
data time_table;
length basedata $ 40 obs fcst_hrz_increments 8 voi0 $ 40 start_time 8 model_spec $ 250 in_data $ 40 elapsed_time 8;
if _n_<1 then output;
run; 
data long_append;
length &date_var. &voi0. 8 model_spec $ 250 in_data $ 40 elapsed_time 8;
if _n_<1 then output;
run;
data wide_merge;
if _n_<1 then output;
run;

options mprint mprintnest mlogic mlogicnest nosymbolgen source notes;
%module(modtech=esm,_in=orig_3yr,_out=whatevah,date_var=proxy_dt_trend,shortness=1);
%module(modtech=esm,_in=orig_3yr,_out=whatevah,date_var=proxy_dt_trend,shortness=2);
%module(modtech=esm,_in=orig_3yr,_out=whatevah,date_var=proxy_dt_trend,shortness=3);

libname benches 'C:\Users\anhutz\Desktop\msa\nonTS projects\ensemble\test\test_shitcomm2';
/*  long_append  needs schema change (in particular a run_primkey) 
    investigate the minor issues with test 1 (not holdups, formatting (sysinfo=16) and 
    time blips  */
proc compare base=benches.long_append comp=long_append criteria=1e-12 method=relative(1e-9);
var  &date_var. &voi0. model_spec in_data;
run;
%let catch_long=&sysinfo;
%put catch_long=&catch_long;


*compare to bench of WIDE_MERGE;
proc compare data=benches.wide_merge compare=wide_merge criteria=1e-12 method=relative(1e-9); 
var in_data_1 lair_1 model_spec_1 proxy_dt_trend;  *excluded elapsed_time_1, should not differ by more than .05 seconds, e.g. should not be higher than .12 seconds; 
run;
%let catch_wide=&sysinfo;
%put catch_wide=&catch_wide;


*compare to bench of timer_table;
proc compare data=benches.time_table compare=time_table; 
var basedata fcst_hrz_increments in_data model_spec obs voi0; *same, exclude from comparison elapsed_time and start_time, latter cannot possibly match;
run;
%let catch_time=&sysinfo;
%put catch_time=&catch_time;

data _null_;
if &catch_long^=0 or &catch_wide^=0 or &catch_time^=0 then do;
	put "At least one dataset does not match its bench.  FAILURE!";
end;
else put "Test PASSED.";
run;

/*to rebench:

proc copy in=work out=benches; select _____; run; quit;