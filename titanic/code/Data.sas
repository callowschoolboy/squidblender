
/* Legend/Sections:
    1. Data Dictionary
    2. Training data from titanic_core.csv ONLY (i.e. not even seeing the kaggle-actual-holdout)
    3. Snippets and comments about building FAMILIES 
    4. "partioning" i.e. creating own (first) role variable within MASTER which like #2 is on true-train-only titanic_core.csv
    5. orphaned addition of VARIABLES
*/


*1;

/*    *** Data Dictionary ***      
VARIABLE DESCRIPTIONS:
survival        Survival
                (0 = No; 1 = Yes)
pclass          Passenger Class
                (1 = 1st; 2 = 2nd; 3 = 3rd)
name            Name
sex             Sex
age             Age
sibsp           Number of Siblings/Spouses Aboard
parch           Number of Parents/Children Aboard
ticket          Ticket Number
fare            Passenger Fare
cabin           Cabin
embarked        Port of Embarkation
                (C = Cherbourg; Q = Queenstown; S = Southampton)

SPECIAL NOTES:
Pclass is a proxy for socio-economic status (SES)
 1st ~ Upper; 2nd ~ Middle; 3rd ~ Lower

Age is in Years; Fractional if Age less than One (1)
 If the Age is Estimated, it is in the form xx.5

With respect to the family relation variables (i.e. sibsp and parch)
some relations were ignored.  The following are the definitions used
for sibsp and parch.

Sibling:  Brother, Sister, Stepbrother, or Stepsister of Passenger Aboard Titanic
Spouse:   Husband or Wife of Passenger Aboard Titanic (Mistresses and Fiances Ignored)
Parent:   Mother or Father of Passenger Aboard Titanic
Child:    Son, Daughter, Stepson, or Stepdaughter of Passenger Aboard Titanic

Other family relatives excluded from this study include cousins,
nephews/nieces, aunts/uncles, and in-laws.  Some children travelled
only with a nanny, therefore parch=0 for them.  As well, some
travelled with very close friends or neighbors in a village, however,
the definitions do not support such relations.
*/



*2;

libname titanic 'C:\Users\anhutz\Desktop\msa\nonTS projects\titanic';


data /*titanic.*/train;
infile 'C:\Users\anhutz\Desktop\msa\nonTS projects\titanic\titanic_core.csv' dsd firstobs=2;
length survived 8	pclass 8	name $ 100	sex	$ 6 age 8	sibsp 8	parch 8	ticket $ 20	fare 8	cabin $ 20	embarked $ 1;
input  survived		pclass		name $		sex	$ 	age		sibsp	parch	ticket $	fare	cabin $ 	embarked $;

*it will be very fruitful across tasks (starting with families) to parse names;
/*drop name; *commit to parsing all info, flags NAME for DROPping;*/
/*surname=*/

run;

proc print; where age=. or int(age)^=age; run;
proc print; where find(name,'master','i'); run;


*3;

proc sql;
create table fams as /*first attempt at building families.  If poss shooting for no misclassification, no false pos (think a nonfam is a fam) no false negs (fam rel not caught)*/
select * from train
where (age>10 or age=.) and ((sex='male' and sibsp^=0) or find(name,'mrs','i') )
order by name;
quit;

*match from these 'safe' with two new vars: 
  family - of the form <surname> <position> where latter can be patriarch, matriarch, child, etc
  accounted - an incremental count of number of relatives I believe I have matched for a person
;

proc sql;
create table odd as /*first attempt at building families.  If poss shooting for no misclassification, no false pos (think a nonfam is a fam) no false negs (fam rel not caught)*/
select * from train
where find(name,'"','i')  or find(name,'(','i')
order by sex;
quit;  *so for these odd male names, look for a blank space between any paren or quotes greedy, i.e. is it one word for a nickanme or multiple for an alias;



*4;

/*********  PARTITIONING  *********/
/*********  PARTITIONING  *********/
/*********  PARTITIONING  *********/

/*    shortcut directly to permanent version of ds master *     
data master;
set titanic.master;
run;
*/;
data /*titanic.*/master;
infile 'C:\Users\anhutz\Desktop\msa\nonTS projects\titanic\titanic_core.csv' dsd firstobs=2;
length survived 8	pclass 8	name $ 100	sex	$ 6 age 8	sibsp 8	parch 8	ticket $ 20	fare 8	cabin $ 20	embarked $ 1;
input  survived		pclass		name $		sex	$ 	age		sibsp	parch	ticket $	fare	cabin $ 	embarked $;

call streaminit(3893751);
if rand("UNIFORM")<.9 then role1="train"; 
else role1="test";

/*if rand("UNIFORM")<.7 then role2="train"; */
/*else role2="test";*/

/*if rand("UNIFORM")<.85 AND then role3="train"; */
/*else role3="test";*/

*a quick and dirty way of getting numeric categoricals;
if sex=" " then sexnum=.; else if sex="male" then sexnum=1; else if sex="female" then sexnum=2; else sexnum=9;
if embarked=" " then embnum=.; else if embarked="S" then embnum=1; else if embarked="C" then embnum=2; else if embarked="Q" then embnum=3; else embnum=9;

run;

data test1;
set /*titanic.*/master;
WHERE role1="test";
run;


*5;

/*********  VARIABLES  *********/
/*********  VARIABLES  *********/
/*********  VARIABLES  *********/


*Families and numpplticket are ACROSS records so partitioning technically trumps;

*So for now only adding a few INTRA record vars;

/*if cabin^=' ' then cabnotmiss=1; else cabnotmiss=0;*/
/*sibpar=sibsp+parch;*/


*changed naming and definition a bit from QCS to Greater than or Equal to 2;
/*if sibsp<=1 then sibge2=0; else if sibsp>=2 then sibge2=1;*/
/*if parch<=1 then parge2=0; else if parch>=2 then parge2=1;*/

*a quick and dirty way of getting numeric categoricals;
/*if sex=" " then sexnum=.; else if sex="male" then sexnum=1; else if sex="female" then sexnum=2; else sexnum=9;*/
/*if embarked=" " then embnum=.; else if embarked="S" then embnum=1; else if embarked="C" then embnum=2; else if embarked="Q" then embnum=3; else embnum=9;*/
