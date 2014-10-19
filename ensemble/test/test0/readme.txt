Landscape as of 19Oct2014: 
  -Last working version was two pushes back, Sep 16 "Fixed most currently known issues in the template, which had had a lo…" which was BEFORE the consolidation into one
    macro, so there are still seperate arima() and esm() modules there.
  -Most recent version, Oct 10 "Cosmetic changes to ShitComm, no actual code change at all only comme…" is not working as I left it at that time


These files are for baseline comparison because of that operational disjoint, I want to focus today on getting a unit test and this is a way to validate today's run if I get a
successful one, otherwise there may be some doubt as to the veracity of any numbers I get out today.


The isolated code from which they were created is as follows:





%let basedata=airline;
%let fcst_hrz_increments=2000;
%let voi0=lair;  *build out lags list here, would require spectral, before any modules run;
*restart the run count;
%symdel run;
%let run=1;
*clean & seed long, wide etc;
  *when seeding give character variables great length;
data time_table;
length obs fcst_hrz_increments 8 voi0 $ 40 start_time 8 model_spec $ 250 in_data $ 40 elapsed_time 8;
if _n_<1 then output;
run; 





/*********** FINISHED MODULES **************/

*may go with hpfdiag for differencing etc;
%macro arima(_in=,      /*input dataset*/
              _out=,     /*output dataset*/
			  voi=&voi0.,/*string, name of response variable*/
              lags=notusedbyarima,     /*lags_VAR list notusedbyarima*/
			  x_flag=0,  /*0 we do NOT use an exovar, 1 we do*/
			  x=,        /*string, name of exogenous variable(s?)*/  
              shortness=notYETusedbyarima,
              date_var=date, 

			  /*ARIMA-specific*/
              dif=0);     /*the numeric 1st difference BY to pass to the arima call in &voi(&dif)*/
%local t0 t1;
%let t0= %sysfunc(datetime());
proc arima data=&_in.  plots=(none);
identify var=&voi.(&dif.) nlag=10 noprint;
estimate p=1 q=1 noprint;  *option to have short=3 mean 1-1 but others allow other 
lags (ie meaningful model). Also could have short>1 mean hpf, with 3 being more choking on it; 
forecast lead=&fcst_hrz_increments out=&_out. id=&date_var. interval=day noprint;
run;
%let t1= %sysfunc(datetime()); %put TIME: time elapsed = %sysevalf(&t1 - &t0);
*each module must paste on to its output the info about each run;
data &_out.;
set &_out.(keep=&date_var. &voi. forecast where=(&voi=.));
model_spec="ARIMA_p1_q1_d&dif._x0";
in_data="&_in.";
run; 

%mend arima;



%macro esm(_in=,      /*input dataset*/
              _out=,     /*output dataset*/
			  voi=&voi0.,/*string, name of response variable*/
                         /*LAGS Not Applicable for ESM*/
                         /*EXO Not Applicable for ESM*/
                         /*EXO Not Applicable for ESM*/
              date_var=, 
              shortness= );/*1=medium=triple/HW, 2=short 3=very short=plain*/
%local t0 t1;
%let t0= %sysfunc(datetime());
proc esm data=&_in. lead=&fcst_hrz_increments. out=&_out. nooutall;* print=all plot=all;
	id &date_var. interval=day; *as i recall interv does weird stuff with method;
	forecast &voi.     /*yep, cant bs esm on date_var, if you want decent HW results*/
          / 
             %if &shortness=1 %then model=winters   ;
             %if &shortness=2 %then model=seasonal   ;
             %if &shortness=3 %then model=linear   ;
          ; 
run;
%let t1= %sysfunc(datetime()); %put TIME: time elapsed = %sysevalf(&t1 - &t0);
*each module must paste on to its output the info about each run;
data &_out.;
set &_out.(keep=&date_var. &voi.);
model_spec="ESM_sh&shortness.";
in_data="&_in.";
run; 
%mend esm;


   /*** EXAMPLES ****/

libname ts 'C:\Users\anhutz\Desktop\msa\TimeSeries\CLASS\class_data';
data orig_3yr;
set ts.airline;
format date 8.;
proxy_dt_trend=_n_;
run; 

%arima(_in=orig_3yr,      /*input dataset*/
              _out=work.testdev1,     /*output dataset*/
			  voi=&voi0.,/*string, name of response variable*/
              lags=notusedbyarima,     /*lags_VAR list notusedbyarima*/
			  x_flag=0,  /*0 we do NOT use an exovar, 1 we do*/
			  x=,        /*string, name of exogenous variable(s?)*/  
              shortness=notusedbyarima,
              date_var=proxy_dt_trend, 

			  /*ARIMA-specific*/
              dif=0);


%esm(_in=orig_3yr,  
              _out=esm3,     
			  voi=&voi0.,
              date_var=proxy_dt_trend, 
              shortness=3);


			  libname test0 'C:\Users\anhutz\Desktop\msa\nonTS projects\ensemble\test\test0';
proc copy in=work out=test0; select testdev1 esm3; run; 