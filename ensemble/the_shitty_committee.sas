
*proposal is to make modules for each model type (some of which will be variant calls
 of, say, a neural net module) allowing the various inputs to be plugged in.  An aggregator
 to append each results table (each of which will have the primary key of time along with
 at least one column to describe the results in a normalized data sense (e.g. a col for
 model technology and another for which input).  ;

*all my implementations are time series, so there's a possiblity of just passing in the 
response variables name as a string and having a convention for appellations to that.  E.g.
let voi=price , with the first appellation being lag (contrary to production_glarima in which
the first suffix is the power the var is taken to).
However there are exogenous variables, but in electric load it acts very similar to the response
var so all I would need is the name, could call it x;

*will need to do exploration (Specifically ACF plots and spectral analysis) to determine which
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
*might also want some form of diagnostic on a per-model basis, unless can cover this
 needed info adequately at the ensemble level;
*/



* planning:
shortness effect on flow of ARIMA
?add exo var list to housekeeping in _out or at the top?
each module keep track of time --v
what is shortness 3 for esm?  ---^
MERGE (NOT AppeNd, or rather both in a 2D thing) to central results (per problem run aka buckshot) each time
;









%let fcst_hrz_increments=2000;
%let voi0=lair;
*central housekeeping/flow vars used over all comm members to 
  streamline each buckshot, side benefit these dont have to go into every _out
let basedata=airline
let justone_xvar=gdp;







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

%macro module(_in=,      /*input dataset*/
              _out=,     /*output dataset*/
			  voi=,      /*string, name of response variable*/
              lags=,     /*space delimited numeric lags representing VAR list*/
			  x_flag=0,  /*0 we do NOT use an exovar, 1 we do*/
			  x=,        /*string, name of exogenous variable(s?)*/ 
              date_var=, 
              shortness= );/*1=medium, 2=short 3=very short*/

*each module must paste on to its output the info about each run;
data &_out.;
set &_out.(keep=&date_var. &voi.);
model_spec="MODELTYPE_sh&shortness._modelspecificparms";
in_data="&_in.";
run; 

*diagnostic, timing, postproc e.g. date?;
%mend module;

   /*** EXAMPLES ****/

libname ts 'C:\Users\anhutz\Desktop\msa\TimeSeries\CLASS\class_data';
data orig_3yr;
set ts.airline;
format date 8.;
proxy_dt_trend=_n_;
run; 

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




