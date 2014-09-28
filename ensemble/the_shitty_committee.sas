
* -modules for each model type (some of which will be variant calls of, say, a neural net module (i.e. by shortness, shortness affects model architecture)) 
  -allowing variation over inputs plugged in.  
  -Each module run pushes results table (each of which MIGHT have the primary key of time along with housekeeping (minimum: a col for model technology and another for which input))  ;

*  -all my possible uses are time series
   --can just pass in the response variables name as a string and having a convention for appellations to that.  E.g. let voi=price , with the 
      first appellation being lag (contrary to production_glarima in which the first suffix is the power the var is taken to).
   ---However there are exogenous variables, but in electric load it acts very similar to the response
       var so all I would need is the name, call it x;

*will absolutely have to do exploration (Specifically ACF plots and spectral analysis) to determine which
 lags to put in the var_list;

*common api
input dataset must have a naming convention that expresses "Orig v jitter v subsetted" etc for record keeping;
*macro module(_in=,      /*input dataset*/
              _out=,     /*output dataset*/
			  voi=,      /*string, name of response variable*/
              lags=,     /*space delimited numeric lags representing VAR list*/
			  x_flag=0,  /*0 we do NOT use an exovar, 1 we do*/
			  x=,        /*string, name of exogenous variable(s?)*/ 
              date_var=, 
              shortness= );/*1=medium, 2=short 3=very short*/
;
/*
proc xyz;

*each module must paste on to its output the info about each run;
data &_out.;
set &_out.(keep=&date_var. &voi. forecast where=(&voi=.));
model_spec="A descriptor of this part of the ensemble";
in_data="&_in.";
run; 

*/



* planned:
shortness effect on flow of ARIMA
?add exo var list to housekeeping in _out or at the top?
what is shortness 3 for esm? 
MERGE (NOT AppeNd, or rather both in a 2D thing) to central results (per problem run aka buckshot) each time
 -what does 2D PUSHing mean for time: temp fix was to add it to results tables and append to long but not to wide, plan to have a wide time table
clone this so that this becomes ShitCommCont, spawning ShitCommOrd, ShitCommNom
  consider carefully plugging each model into template
   -one pro is that template (i.e. housekeeping) could be easily changed
   -major con would be model-specific api and architecture needs (e.g. esm noX, arima own lags, ML need more hand holding)
test use of my obs utility (borrowed from GLARIMA)
***voi needs to be consolidated UP to TOP, as does date_var (consider use of a control ds)
;


*known that this wont work the way I want it to YET, inline anywhere;
%macro aj_obs(ds);
%local dstouch bs obs;
     %let dstouch = %sysfunc(open(&ds));
          %let obs= %sysfunc(attrn(&dstouch, nlobs));
     %let bs = %sysfunc(close(&dstouch));
&obs
%mend aj_obs;



*central housekeeping/flow vars used over all comm members to 
  streamline each buckshot, side benefit these dont have to go into every _out

let justone_xvar=gdp;
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
*temporarily defining datevar just like voi.  plan to use an architecture ds, possibly search the basedata input to dynamically find the datevar...?;
%let date_var=proxy_dt_trend;
*restart the run count;
%symdel run;
%let run=1;
*clean & seed long, wide etc;
  *when seeding give character variables great length;
data time_table;
length basedata $ 40 obs fcst_hrz_increments 8 voi0 $ 40 start_time 8 model_spec $ 250 in_data $ 40 elapsed_time 8;
if _n_<1 then output;
run; 
data long_append;
length &date_var. &voi0. 8 model_spec $ 250 in_data $ 40 elapsed_time 8;
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




/***************** DEVELOPMENT SHIPYARD **********************/
   /*** TEMPLATE ****/
%macro module(modtech=means,  /*options are arima, means*/
              _in=,      /*input dataset*/              
              _out=,     /*output dataset*/
			  voi=&voi0.,      /*string, name of response variable*/
              lags=&lags0.,     /*space delimited numeric lags representing VAR list*/
			  x_flag=0,  /*0 we do NOT use an exovar, 1 we do*/
			  x=,        /*string, name of exogenous variable(s?)*/ 
              date_var=, 
              shortness= );/*1=medium, 2=short 3=very short*/
%local this_model t0 t1;
%let this_model=MODELTYPE_sh&shortness._modelspecificparms;
%let t0= %sysfunc(datetime());
*INSERT MODTECH HERE;
	%if %sysevalf(&modtech="means",boolean) %then %do;
		proc means data=&_in;
		output out=&_out.;
		run; 
		data &_out;
		set &_out(keep=&date_var. &voi.);
		&date_var.=19000+_n_;
		run;
	%end;
	%else %if %sysevalf(&modtech="arima",boolean) %then %do;
	   %local dif; %let dif=0; *temporary, needs major cleaning and planning;
		proc arima data=&_in.  plots=(none);
		identify var=&voi.(&dif.) nlag=10 noprint;
		estimate p=1 q=1 noprint;  *option to have short=3 mean 1-1 but others allow other 
		lags (ie meaningful model). Also could have short>1 mean hpf, with 3 being more choking on it; 
		forecast lead=&fcst_hrz_increments out=&_out. id=&date_var. interval=day noprint;
		run;
		*each module must paste on to its output the info about each run;
		data &_out.;
		set &_out.(keep=&date_var. &voi. forecast where=(&voi=.));
		model_spec="ARIMA_p1_q1_d&dif._x0";
		in_data="&_in.";
		run; 
	%end;
%let t1= %sysfunc(datetime()); 
%put TIME: time elapsed = %sysevalf(&t1 - &t0);

*each module must paste on to its output the info about each run;
data &_out.;
set &_out.(keep=&date_var. &voi.);
model_spec="&this_model";
in_data="&_in.";
elapsed_time=%sysevalf(&t1 - &t0);
run; 
proc append base=long_append data=&_out. ; run; 

data _null_;
run_key=&run;
model_spec_&run. ="&this_model";
call symputx("model_spec_&run.",model_spec_&run.,'l');
in_data_&run.="&_in.";
call symputx("in_data_&run.",in_data_&run.,'l');
elapsed_time_&run.=%sysevalf(&t1 - &t0);
call symputx("elapsed_time_&run.",elapsed_time_&run.,'l');
put _all_;
run;
%put Run Number     RUN                = &Run.;
%put Macro Variable MODEL_SPEC_&Run.   = &&MODEL_SPEC_&Run.;
%put Macro Variable IN_DATA_&Run.      = &&IN_DATA_&Run.;
%put Macro Variable ELAPSED_TIME_&Run. = &&ELAPSED_TIME_&Run.;



data &_out._w;
set &_out.(/*keep all?*/ rename=(&voi.=&voi._&run. 
           model_spec=model_spec_&run. 
           in_data=in_data_&run.
           elapsed_time=elapsed_time_&run.)
           );
length model_spec_&run. $ 250 in_data_&run. $ 40;
*might thin this to just voi, if macvars or another alternative to data-based housekeeping works well;
run;

 *time table;
data single_time;
basedata="&basedata.";
obs=%aj_obs(&_in.);
fcst_hrz_increments=&fcst_hrz_increments.;
voi0="&voi0.";
start_time=&t0.;
model_spec="&this_model";
in_data="&_in.";
elapsed_time=%sysevalf(&t1 - &t0);
run;
proc append base=time_table data=single_time force; run; 

*diagnostic, postproc e.g. date?;


*iterate amper run, needs to be at the end of the module in case any housekeeping would like to use it;
%let run=%eval(&run+1);
%mend module;

   /*** ACTIVE DEVELOPMENT ****/

options mprint mprintnest mlogic mlogicnest nosymbolgen source notes;
%module(modtech=arima,_in=orig_3yr,_out=whatevah,date_var=proxy_dt_trend,shortness=1);


%let _in=orig_3yr;  
 %let     _out=esm3;     
%let   voi=&voi0.;
 %let     date_var=proxy_dt_trend; 
 %let    shortness=3;


 proc svm;
 run;



   /*** EXAMPLES ****/



%let ForecastSeries = lz21;
libname g 'C:\Users\anhutz\Desktop\msa\TimeSeries\PROJECTS\GEFCom2012\data';
proc expand data=g.gef out=gexpand; convert &ForecastSeries.; run; quit; 
data gexpand(keep=trend datetime lz21 avgtemp);
set gexpand(where=(&ForecastSeries.^=.));* to have nontriv (bc GEF has miss at end to forecast, Tao held true holdout) ;
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



*TIMEing;  
			  %esm(_in=gexpand,  
              _out=esm_tim,     
			  voi=lz21,
              date_var=trend, 
              shortness=2);

*
             %if &shortness=1 %then model=winters   
             %if &shortness=2 %then model=seasonal   
             %if &shortness=3 %then model=linear   
 on airline, with plots is about .3 sec, without down to about 1/10th of that
	airline esm sh1		.02999997138977
	airline esm sh2		.02999997138977
	airline esm sh3		.02999997138977

*gef (5yr 15-min, fcsting 2000 increments):
esm sh1		.
esm sh2		.06299996376037
esm sh3		.06599998474121
;





