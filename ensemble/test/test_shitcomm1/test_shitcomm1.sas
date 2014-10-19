
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
*build out lags list here, will require spectral, before any modules run;
%let lags0=&voi0._1_1 &voi0._1_3 &voi0._1_8;
*temporarily defining datevar just like voi.  plan to use an architecture ds;
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


options mprint mprintnest mlogic mlogicnest nosymbolgen source notes;
%module(modtech=arima,_in=orig_3yr,_out=whatevah,date_var=proxy_dt_trend,shortness=1);

*since this is a simple one-model test long_append and wide_merge should match except in varnames;
/*  Temporarily deprecating long_append, it needs schema change (in particular a run_primkey) and
     for some reason wide wasnt getting the lengths intended so i moved the length statement up but then
     the times were different which is much more weird...*/
%let run=1;
%let voi=&voi0;
data long_append_tst_sc1;
set long_append(rename=(&voi.=&voi._&run. 
           model_spec=model_spec_&run. 
           in_data=in_data_&run.
           elapsed_time=elapsed_time_&run.)
           );
run;
proc compare base=long_append_tst_sc1 comp=whatevah_w criteria=1e-12 method=relative(1e-9);
*var proxy_dt_trend forecast;
run;
%let catch_wide_long=&sysinfo;
%put catch_wide_long=&catch_wide_long;


*compare wide_merge to baseline from old code;
data whatevah_w_tst_sc1;
set whatevah_w;
forecast=lair_1;
label forecast="Forecast for LAIR";
run;
libname test0 'C:\Users\anhutz\Desktop\msa\nonTS projects\ensemble\test\test0';
proc compare base=test0.testdev1 comp=whatevah_w_tst_sc1 criteria=1e-12 method=relative(1e-9);
var proxy_dt_trend forecast;
run;
%let catch_baseline0=&sysinfo;
%put catch_baseline0=&catch_baseline0;

proc copy in=work out=benches; select time_table whatevah_w; run; 
*and lastly just compare to bench of same plus timer_table;
libname benches 'C:\Users\anhutz\Desktop\msa\nonTS projects\ensemble\test\test_shitcomm1';
proc compare data=benches.whatevah_w compare=whatevah_w criteria=1e-12 method=relative(1e-9); run;
%let catch_wide=&sysinfo;
%put catch_wide=&catch_wide;

proc compare data=benches.time_table compare=time_table; run;
%let catch_time=&sysinfo;
%put catch_time=&catch_time;

data _null_;
if &catch_wide_long^=16 or &catch_baseline0^=0 or &catch_wide^=0 or &catch_time^=0 then do;
	put "At least one dataset does not match its bench.  FAILURE!";
end;
else put "Test PASSED.";
run;