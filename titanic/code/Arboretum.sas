
libname titanic 'C:\Users\anhutz\Desktop\msa\nonTS projects\titanic';

%let input_var_list=ImpAgeStrat                        sibpar fare; *ImpEmbMode ImpAgeStrat cabnotmiss sibpar fare;
%let _temp_lib=work;
%let input_dsn=master;
%let test_dsn_in=test1;
%let test_dsn_out=ScoredByArboretum;
*let date_var=occupancy_dt;
*let process_group_id_var=process_group_id;
%let response_var=survived;
*let process_group_iter=1 ;
%let split_criterion=probf;
%let max_dow_groups=6;
   
       proc arboretum data=&_temp_lib..&input_dsn
       	              criterion=&split_criterion;

                  where role1="train"; 

          input &input_var_list / level=nominal;
          target &response_var. / level=interval;
          interact;
          train maxbranches=&max_dow_groups maxdepth=3;
          save path=&_temp_lib..dow_path1
               nodestats=&_temp_lib..dow_node_stats1
               sequence=&_temp_lib..dow_sequence1
               rules=&_temp_lib..dow_rules1;


        score 
            data= &_temp_lib..&test_dsn_in
            out= &_temp_lib..&test_dsn_out
            role= score;

       run;
       quit;

*how did we do?;
proc sql;
select count(*) from &_temp_lib..&test_dsn_out where ( (p_survived<=.5 and survived=0) OR (p_survived>.5 and survived=1) );
quit;

* split_criterion=probf max_dow_groups=2 roletest 1  maxdepth=1    input_var_list=ImpEmbMode ImpAgeStrat cabnotmiss sibpar fare     accuracy = 56/87 ~~ 64%;
* split_criterion=probf max_dow_groups=6 roletest 1  maxdepth=1    input_var_list=ImpEmbMode ImpAgeStrat cabnotmiss sibpar fare     accuracy = 56/87 ~~ 64%;
* split_criterion=probf max_dow_groups=6 roletest 1  maxdepth=1    input_var_list=ImpEmbMode                        sibpar fare     accuracy = 59/87 ~~ 67%;
* split_criterion=probf max_dow_groups=6 roletest 1  maxdepth=1    input_var_list=           ImpAgeStrat            sibpar fare     accuracy = 59/87 ~~ 67%;
* split_criterion=probf max_dow_groups=6 roletest 1  maxdepth=3    input_var_list=           ImpAgeStrat            sibpar fare     accuracy = 59/87 ~~ 67%;





libname x (&_temp_lib.); 

%let catalog=catalog;

*CURRENTLY LIMITED TO ONLY INTERVAL VARIABLES IN THIS AUTOMATED FLOW;

proc dmdb data=x.&input_dsn. dmdbcat=&catalog.;
var  &input_var_list.;
class &response_var.;
target &response_var.;
run;


%let maxtime=129600;
%let maxiter= 450;

filename out "C:\temp\another_DL_log.log";*"C:\Users\anhutz\Desktop\msa\TimeSeries\METHODS\Neural\DeepLearn_base\DeepLearn___out.txt"; 
proc printto print= out new; run; 
proc neural

      data= x.&input_dsn.
      dmdbcat= work.&catalog.;
 nloptions  noprint;

      performance compile details cpucount=12 threads=yes;
      nloptions fconv= 0.00005;
      netoptions decay= 1.0; 

      archi MLP hidden= 3; /* default act= tanh combine= linear */
      hidden 25 / id= h1;
      hidden 10 / id= h2;
      hidden 2 / id= h3 ;
      input &input_var_list. / id= i level= int std= std;
      target &response_var. / level= ordinal;

      initial random= 4805353; 
      prelim 10 preiter= 10; 

      freeze h1->h2; 
      freeze h2->h3; 
      train technique= congra maxtime= &maxtime maxiter= &maxiter;

      freeze i->h1; 
      thaw h1->h2; 
      train technique= congra maxtime= &maxtime maxiter= &maxiter;

      freeze h1->h2; 
      thaw h2->h3; 
      train technique= congra maxtime= &maxtime maxiter= &maxiter;

      thaw i->h1;
      thaw h1->h2; 
      train technique= congra maxtime= &maxtime maxiter= &maxiter;

      *code file= "C:\Users\anhutz\Desktop\msa\TimeSeries\METHODS\Neural\DeepLearn_base\DeepLearn___model.sas";  

      *  score  
            data= x.DeepLearn___train
            out= x.DeepLearn___train_score
            outfit= x.DeepLearn___train_fit
            role= train; 

        score 
            data= &_temp_lib..&test_dsn_in
            out= &_temp_lib..&test_dsn_out
            role= score;
run; 
proc printto; run;

*not sure AT ALL if this is correct way to count accuracy from deep neural;
proc sql;
select count(*) from &_temp_lib..&test_dsn_out where ( (p_survived1<=.5 and survived=0) OR (p_survived1>.5 and survived=1) );
quit;
