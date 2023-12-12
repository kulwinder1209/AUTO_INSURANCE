PROC IMPORT OUT= KATE.Ins_freq
            DATAFILE= "C:\Users\user\Desktop\DSWEP\Insurance Project\CAS
_freq.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 guessingrows=10000;
RUN;

PROC IMPORT OUT= KATE.Ins_sev  
            DATAFILE= "C:\Users\user\Desktop\DSWEP\Insurance Project\CAS
_sev.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 guessingrows=10000;
RUN;
/*Data element	Description
PolicyID	The policy ID (used to link with the contract dataset).
ClaimNb	    Number of claims during the exposure period.
Exposure	The period of exposure for a policy, in years.
Power	    The power of the car (ordered categorical).
CarAge	    The vehicle age, in years.
DriverAge	The driver age, in years (in France, people can drive a car at 18).
Brand	    The car brand divided in the following groups: A- Renaut Nissan and Citroen, B- Volkswa-gen, Audi, Skoda and Seat, C- Opel, General Motors and Ford, D- Fiat, E- Mercedes Chrysler and BMW, F- Japanese (except Nissan) and Korean, G- other.
Gas	        The car gas, Diesel or regular.
Region	    The policy region in France (based on the 1970-2015 classification)
Density	    The density of inhabitants (number of inhabitants per km2) in the city the driver of the car lives in.
Severity	The cost of the claim.
*/
* for using merge statement  First,  if the data are not already sorted, you must use the SORT procedure to sort 
	all data sets by the common variables. 
;
proc sort data=KATE.Ins_freq ;
   by PolicyID;
run;
proc sort data=KATE.Ins_sev;
   by PolicyID;
run;

*merging to datasets together;
data KATE.merged;
merge KATE.Ins_freq KATE.Ins_sev;
by PolicyID;
run;


*Geting copy of data;
DATA KATE.INS ;
 SET KATE.merged ;
RUN;

* BROWSING THE DESCRIPTION PORTION ;
PROC CONTENTS DATA=KATE.INS;
RUN; 

* BROWSING THE Data PORTION ;
*Head;
proc print data=KATE.Ins (obs=10);run;

*getting the names of all columns;
PROC CONTENTS DATA = KATE.INS VARNUM SHORT;
RUN;


*DROP DUPLICATE OBSERVATION IF EXIST;
PROC SORT DATA=KATE.INS OUT=KATE.INS1 NODUPKEY;
 BY _ALL_;
RUN;
 *--> we have   0 observations with duplicate key values,



**************************FINDING THE MISSING VALUES ********************************;

*Numerical Columns;


 PROC MEANS DATA = KATE.Ins N NMISS RANGE MIN MEAN STD MAX MAXDEC=2;RUN;
/*there is 397779 in severity column, since those MV mean there was no clame made
 I am going to replace it with 0*/

/*create new dataset with missing values in "severity" column replaced by zero*/
data KATE.Ins_new;
   set KATE.Ins;
   array variablesOfInterest severity;
   do over variablesOfInterest;
      if variablesOfInterest=. then variablesOfInterest=0;
   end;
run;
/*to make sure we got rid og MV run proc means again */
 PROC MEANS DATA = KATE.Ins_new N NMISS RANGE MIN MEAN STD MAX MAXDEC=2;RUN;


 *Character Column;

proc sql; 
    select nmiss(Brand) as Brand_miss, nmiss(Gas) as Gas_miss, nmiss(PolicyID) as PolicyID_miss, nmiss(Power) as Power_miss,
	nmiss(Region) as Region_miss, nmiss(VAR1) as VAR1_miss
    from KATE.Ins_new;
quit;

/*I am going to drop column Var1 since its duplicated of policyId*/
data KATE.Insurance(drop=VAR1); 
set KATE.Ins_new; 
run;


*Univarite, Bivariate, Multi Variate Analysis based on data type of variables:;
*************************************UNIVARIATE ANALYSIS****************************************;
************************************************************************************************;
*** UNIVARIATE - DESCRIPTIVE ANALYSIS ***;
  
/*Univariate Analysis:
  For categorical columns:
 		                    for summarization:   frequency, percentage, Mode, levels (unique values) in SAS by using proc freq    
                            for visualization :  Bar chart or Pie chart
  For numerical columns  :
                            for summarization:   Central tendency(mean, median, mode,...) and
                                                 measue of position:the five-number summary(min,Q1,median(Q2),Q3,Max), 
												 and measur eof dispresion such as standard deviation ,CV ( COEFFICIENT OF VARIATION)...
												in SAS by using proc means,summary, or univariate
                            for visualization:   Histogram , Box plot,density,...*/




 *FOR ALL CONTINUOUS VARIABLES: summarization;
TITLE "THIS IS DESCRIPTIVE ANALYSIS OF ALL CONTINUOUS VARIABLES";

PROC MEANS DATA=KATE.Insurance N NMISS MIN Q1 MEDIAN  Q3 MAX qrange mean std cv clm maxdec=2  ;
RUN;
title;

*After finding the whole picture  for continuous variable We should better to do univariate analysis one by one by using proc univarialte;
*CONTINOUSE DATA : VISUALIZE METHODS;
********************************************************************************************************************;
%MACRO UNI_ANALYSIS_NUM(DATA,VAR);
 TITLE "THIS IS HISTOGRAM FOR &VAR";
 PROC SGPLOT DATA=&DATA;
  HISTOGRAM &VAR;
  DENSITY &VAR;
  DENSITY &VAR/type=kernel ;
    STYLEATTRS 
    BACKCOLOR=DARKGREY 
    WALLCOLOR=LIGHTGREY
     ;
  keylegend / location=inside position=topright;
 RUN;
 QUIT;
 TITLE "THIS IS HORIZONTAL BOXPLOT FOR &VAR";
 PROC SGPLOT DATA=&DATA;
  HBOX &VAR;
    STYLEATTRS 
    BACKCOLOR=DARKGREY 
    WALLCOLOR=LIGHTPINK
     ;
 RUN;
TITLE "THIS IS UNIVARIATE ANALYSIS FOR &VAR IN &DATA";
proc means data=&DATA  N NMISS MIN Q1 MEDIAN MEAN Q3 MAX qrange cv clm maxdec=2 ;
var &var;
run;
%MEND;

%UNI_ANALYSIS_NUM(KATE.Insurance,ClaimNb)
%UNI_ANALYSIS_NUM(KATE.Insurance,Exposure)
%UNI_ANALYSIS_NUM(KATE.Insurance,CarAge)
%UNI_ANALYSIS_NUM(KATE.Insurance,DriverAge)
%UNI_ANALYSIS_NUM(KATE.Insurance,Density)
%UNI_ANALYSIS_NUM(KATE.Insurance,severity)



/* by looking at the box plot we are able to identify the ouliers, 
some of them are extreeme for Severity, Density and Carage*/


*CATEGORICAL VARIABLES : 
************************************************************************************************************************;
%MACRO UNI_ANALYSIS_CAT(DATA,VAR);
 TITLE "THIS IS FREQUENCY OF &VAR FOR &DATA";
  PROC FREQ DATA=&DATA;
  TABLE &VAR;
 RUN;

TITLE "THIS IS VERTICAL BARCHART OF &VAR FOR &DATA";
PROC SGPLOT DATA = &DATA;
 VBAR &VAR;
    STYLEATTRS 
    BACKCOLOR=DARKGREY 
    WALLCOLOR=TAN
     ;
 RUN;

TITLE "THIS IS PIECHART OF &VAR FOR &DATA";
PROC GCHART DATA=&DATA;
  PIE3D &VAR/discrete 
             value=inside
             percent=outside
             EXPLODE=ALL
			 SLICE=OUTSIDE
			 RADIUS=20
		
;

RUN;
%MEND;


%UNI_ANALYSIS_CAT(KATE.Insurance,Brand)
%UNI_ANALYSIS_CAT(KATE.Insurance,Gas)
%UNI_ANALYSIS_CAT(KATE.Insurance,Power)
%UNI_ANALYSIS_CAT(KATE.Insurance,Region)



title "Total Number of Accounts";
PROC SQL;
 SELECT COUNT(DISTINCT PolicyID) AS UNI_ACC_COUNT format=comma10.
 FROM KATE.Insurance
 ;
 QUIT;
title;

title'Total Number of Accounts with previouse claims';
 PROC SQL;
 SELECT COUNT(*) AS total_activ format=comma10.
     FROM KATE.Insurance
      WHERE ClaimNb not = 0
 ;
 QUIT;
 title;

 TITLE " TOTAL Number of Accounts without claims";
 PROC SQL;
 SELECT COUNT(*)AS TOTAL_DEACC format=comma10. 
 FROM KATE.Insurance
 WHERE ClaimNb = 0
 ;
 QUIT;
TITLE;
/*
Thus, we found total number of accounts, which is 413,169.
Total number of Accounts with previouse claims= 15,390
Total number of Accounts without claims= 397,779
*/

data Kate.Ins_Total;
set KATE.Insurance;
 format Age_group $15.
     CarAge_group $15.;
 if DriverAge <=20 then Age_group="< 20";
 else if 21<= DriverAge< =30 then Age_group="21-30";
 else if 31<= DriverAge< =40 then Age_group="31-40";
 else if 41<= DriverAge< =50 then Age_group="41-50";
 else if 51<= DriverAge< =60 then Age_group="51-60";
 else if 61<= DriverAge< =70 then Age_group="61-70";
 else if DriverAge =>71  then Age_group="70 > ";


 if 0<= CarAge <=5  then CarAge_group= "0-5";
 else if 6<= CarAge< =10 then CarAge_group= "6-10";
 else if 11<= CarAge< =15 then CarAge_group= "11-15";
 else if 16<= CarAge< =20 then CarAge_group= "16-20";
 else if 21<= CarAge< =25 then CarAge_group= "21-25";
 else if CarAge =>26  then CarAge_group= "25 > ";
 run;

/*always check proc freq after segmentation to make sure there are no MV and you were able to pick up all observations*/
proc freq data=Kate.Ins_Total;
table age_group;
run;

proc freq data=Kate.Ins_Total;
table CarAge_group;
run;

/*Lets assign a status to our accounts*/

data Kate.Ins;
set  Kate.Ins_Total;
if ClaimNb = 0 then Status= 'NoClaims';
else Status= 'Claim';
run;

 TITLE "PIECHART OF  Accounts";
 PROC GCHART DATA=Kate.Ins;
 PIE3D Status/DISCRETE
 VALUE=INSIDE
 PERCENT=OUTSIDE
 EXPLODE=ALL
 SLICE=OUTSIDE
 RADIUS=20;
 RUN;
 TITLE;

 /* we can see only 4% of total accounts had claimed their insurance*/
/*lets take a closer look at those accounts */

%UNI_ANALYSIS_CAT(Kate.Ins,Age_group)
%UNI_ANALYSIS_CAT(Kate.Ins,CarAge_group)

data kate.Claims kate.NoClaims;
set Kate.Ins;
if Status= 'Claim' then output kate.Claims;
else output kate.NoClaims;
run;

title "Distribution of Drivers Age category for Accounts with previouse claims ";
PROC SGPLOT DATA=kate.Claims;
VBAR  age_group/stat=percent seglabel;
STYLEATTRS
BACKCOLOR=GREY
WALLCOLOR=TAN;
RUN; 
 TITLE;

 /*By looking at this chart we can clearly see that most of the customers who claimed 
 their insurance were between 40-50 years old followed by 30-40 age cathegory*/


title "Distribution of Brand for Accounts with previouse claims ";
PROC SGPLOT DATA=kate.Claims;
VBAR  Brand/stat=percent seglabel;
STYLEATTRS
BACKCOLOR=GREY
WALLCOLOR=TAN;
RUN; 
 TITLE;

  /*From this chart we can clearly see that 55.6% of the customers who claimed 
 their insurance were driving Renault, Nissan or Citroen*/ 

  TITLE "Distribution of Drivers' Age for Renault, Nissan or Citroen make for insurance claims";
 PROC SGPLOT DATA =kate.Claims; 
VBAR  Age_group/group = Brand stat=percent datalabel   groupdisplay=cluster;  
yaxis grid display=(nolabel);  xaxis display=(nolabel)  discreteorder=data; 
where Brand='Renault, Nissan or Citroen';

STYLEATTRS     BACKCOLOR=DARKGREY    WALLCOLOR=TAN; 
RUN;
TITLE;
/*by looking at this bar chart we can see that alost 25% of all of the insurance claims were done by the insured
Renault, Nissan or Citroen drivers who were 40-50 years old followed by 30-40 years old cathergory */

/*Let's see if age of the car affect posiibilityto make the insurance claims*/

title "Distribution of CarAge of Renault, Nissan or Citroen Make for Accounts with Previouse Claims ";
 PROC SGPLOT DATA =kate.Claims; 
VBAR  CarAge_group/group = Brand stat=percent datalabel   groupdisplay=cluster;  
yaxis grid display=(nolabel);  xaxis display=(nolabel)  discreteorder=data; 
where Brand='Renault, Nissan or Citroen';

STYLEATTRS     BACKCOLOR=DARKGREY    WALLCOLOR=TAN; 
RUN;
TITLE;
/*by looking at this chart we can see that newer cars show the highest destribution of claims 
compared to older car for Renault, Nissan or Citroen make */
/* Lets see where are the most customers who drive Renault, Nissan or Citroen are located */

title "Distribution of Region of Renault, Nissan or Citroen Make for Accounts with Previouse Claims ";
 PROC SGPLOT DATA =kate.Claims; 
VBAR  Region/group = Brand stat=percent datalabel   groupdisplay=cluster;  
yaxis grid display=(nolabel);  xaxis display=(nolabel)  discreteorder=data; 
where Brand='Renault, Nissan or Citroen';

STYLEATTRS     BACKCOLOR=DARKGREY    WALLCOLOR=TAN; 
RUN;
TITLE;
/*Majority 48% of all the customers who claimed their insurance and drived renault etc were from central region */




 TITLE "PIECHART of CarAge_group for Accounts with previouse claims ";
 PROC GCHART DATA=kate.Claims;
 PIE3D CarAge_group/DISCRETE
 VALUE=INSIDE
 PERCENT=OUTSIDE
 EXPLODE=ALL
 SLICE=OUTSIDE
 RADIUS=20;
 RUN;
 TITLE;

 /* from this pie chart we can see that 39% of all insurance claims were made by vehicles o-5 years old 
 followed by 6-10 years old cathegoty (31%) and 11-20 (29%). Frankly, by looking at the pie chart it looks like 
 the possibility of claims are not associated with the car age, to prove that we need to run a hypothesis testing
 */*
_________________________________________________________________________________________________

 Bivariate Analysis 
_________________________________________________________________________________________________

Continuous Vs. Continuous For visualization : Scatter plot, line graph(if one column is time),...
                          For test of independency and summarization : correlation (pearson, spearman, Kendal tue,...)and  linear regression( SLR for bivariate analysis)

Categorical Vs. Categorical For visualization : Grouped bar chart, stacked bar chart
                            For Summarization : Contingency table(Two-way table)
                            For test of independency : chi-square test

Continuous Vs. Categorical For visualization : Grouped box plot,Grouped histogram, grouped density, ....
                           For Summarization : Grouped by categorical column and aggregate of continuous column( proc means or summary or univarite with class statement)
                           For test of indecency : t-test(if you have two levels for categorical column and assumption of t-test are satisfied)
                                                   ANOVA(Analysis Of Variance)(if you have more than two levels for categorical column and assumption of ANOVA are satisfied)

*/
********************************;
*CarAge_group and Status
 __________________________________________________________________________________________________________________________________________________
*Qusstion: is there any assicoation between CarAge_group and Status?
Null hypothese:there is no associtation between CarAge_group and Status
Alternative hypotheses: there is associtation beteen CarAge_group and Status
 
********Categorical VS Categorical*****
/******CHI SQURE*****/
*We use Chi squre test for finding if two categorical varaible are independent from each other or not.
**************************************************;*
Assumption of chi-square test:
The Chi-square test statistic can be used if the following conditions are satisfied:
1.N, the total frequency, should be reasonably large, say greater than 50.
2. The sample observations should be independent. This implies that no individual item should be included twice or more 
in the sample.
3. No expected frequencies should be small. Small is a relative term. Preferably each expected frequencies 
should be larger than 10 but in any case not less than 5.;

PROC FREQ DATA=Kate.Ins;
 TABLE  CarAge_group * Status/chisq norow nocol nopercent;
 
RUN;

title 'Correlation between CarAge_group and Status';
proc sgplot data=Kate.Ins;
vbar CarAge_group/ group=Status nostatlabel
       groupdisplay=cluster dataskin=gloss;

yaxis grid;
run;
title; 

*since p-value is less than 5% we reject null hypothese and conclude that
there is statistically assicoation between CarAge_group and Status at 5% significant level;

/*Drivers age by brand
__________________________________________________________________________________________________*/

title 'Correlation between Drivers age by brand';
proc sgplot data=Kate.Ins;
vbar brand / group=Age_group nostatlabel
       groupdisplay=cluster dataskin=gloss;

yaxis grid;
run;
title; 

PROC FREQ DATA=Kate.Ins;
 TABLE  Age_group * brand/chisq norow nocol nopercent;
RUN;
*since p-value is less than 5% we reject null hypothese and conclude that
there is statistically assicoation between Drivers' age and brand at 5% significant level;

/*Brand by Region 
__________________________________________________________________________________________________*/

title 'Correlation between Brand and Region';
proc sgplot data=Kate.Ins;
vbar brand / group=Region nostatlabel
       groupdisplay=cluster dataskin=gloss;

yaxis grid;
run;
title; 

PROC FREQ DATA=Kate.Ins;
 TABLE  Region * brand/chisq norow nocol nopercent;
RUN;
*since p-value is less than 5% we reject null hypothese and conclude that
there is statistically assicoation between Brand and Region at 5% significant level;


/*Claims Number and region  (continues vs cathegorical)*/

title 'Correlation between Claims Number and Region';
proc sgplot data=Kate.claims;
vbar ClaimNb / group=Region nostatlabel
       groupdisplay=cluster dataskin=gloss;

yaxis grid;
run;
title; 

PROC FREQ DATA=Kate.claims;
    TABLE ClaimNb * Region / CHISQ EXPECTED DEVIATION NOROW NOCOL NOPERCENT;
RUN;

/*Density and Status (continues vs cathegorical)*/
*Categorical vs Continious;


proc means data=Kate.Ins n nmiss min Q1 median Q3 max range qrange mean clm std cv maxdec=2;
class Status;
var Density;
run;
/* *As you can see the mean of Density for people without any imsurance claims is 2061.83 and the mean of 
Density for people having  imsurance claims is 1982.19, 
so there is less than a 100 units difference between mean of these two groups, but the question is wheather 
those 79.64 units is significan or not?;

  *since Density is continuous variable and  Status is categorical varible with only two levels we
  should run t-test if all assumption are met;
*/
proc univariate data=Kate.Ins normal plot;
var Density;
class Status;
run;
* we have some Extreme outliers!! need to treat them before running ttest 

title '5 Number Summary';
proc means data=Kate.Ins min max median q1 q3;
var Density ;
run;

PROC SQL;
CREATE TABLE kate.outl AS
SELECT * 
FROM Kate.Ins
where Density > 1400
;
QUIT;

*we have a lot of outliers that going to affect our test, i can not delete them since those outliers are not wrong data
they represent the whole region in france so i cannot run any parametric tests;

*there are several available options:

Performing a nonparametric The Mann-Whitney U test is the most popular alternative.  This test is considered robust 
to violations of normality and outliers.  The Wilcoxon signed-rank performs a similar comparison to that of a paired 
samples t-test only on ranks.  This is the most well-known alternative.;

proc glm data =Kate.Ins PLOTS(MAXPOINTS= NONE);
class Status;
model Density = Status ; *in proc glm in model statement continuous varible is
located on the left sideof equation and categorical variable is located on the right side of equal sign;
means Status / hovtest= levene (type =abs) welch;
run;

/*perform Mann Whitney U test*/
proc npar1way data=Kate.Ins wilcoxon;
    class Status;
    var Density;
run;

*since p-value of Mann Whitney U test is less than 5% I can reject null hypothese and get coclusion that
thoes two groups don't have equal variance so
Satterthwaite (also known as Welch’s) t-test is appropriate;



*since p-value of Welch's ANOVA for Density is less than 5% we can reject null hypothese and conclude that
there is statistically difference between mean of Density for people who have had insurance claimes  and people
who didn't at 5% significant level;

* you can run proc t-test as well to get same conclusion;

proc ttest data=Kate.Ins;
var Density;
class Status;
run;
*since P-value of Satterthwaite (also known as Welch’s) is less than 5% we can reject null hypotheses and get conclusion that:
There is association between Density and Status;


/*ClaimNB and Density

cont vs cont*/

title "correlation between ClaimNB and Density";
proc corr data = Kate.Ins;
var ClaimNB  Density;
run;
title; 
*there is weak positive correlation between Density and ClaimNb;

PROC SGPLOT data=Kate.Ins;
scatter x = Density y = ClaimNB;
    reg x = Density  y = ClaimNB;
run;

/*culculating new variables*/

DATA Kate.Ins1;
 SET Kate.Ins;
 Frequency = ClaimNb/ exposure;
 PureClaim = Severity/Exposure;
RUN;
PROC PRINT DATA = Kate.Ins1 (OBS=10);
 VAR PureClaim Frequency ClaimNb exposure;
 FORMAT Frequency 12.;
RUN;

%UNI_ANALYSIS_NUM(Kate.Ins1,Frequency)


/*MODELING*/

data KATE.Ins(drop=PolicyID); *droping policy id since it has no use for our data;
set Kate.Ins1; 
run;

proc export data=KATE.Ins
    outfile="C:/Users/user/Desktop/DSWEP/Insurance Project/ins.csv"
    dbms=csv;
run;

*split the data into test and train;

proc surveyselect data=Kate.Ins
    out= MODEL_DATA /*exports to work library*/
    method=SRS    /*simple random sampling*/
    samprate=0.8     /* Wanted Training Dataset 80% */
    seed=1357924
    outall; /*includes all observations from the input data set
	         and also each observation’s selection status*/
run;

PROC FREQ DATA = MODEL_DATA;
 TABLE Selected;
RUN;
proc print data=model_data (obs=5);run;

DATA TRAINING TESTING;
 SET MODEL_DATA;
 IF Selected EQ 1 THEN OUTPUT TRAINING;
 ELSE OUTPUT TESTING;
RUN;

proc contents data=TRAINING;run;
proc contents data=testing;run;


*Generalized Linear Model – proc genmod;

proc genmod data = TRAINING;
	weight Exposure;
	class Power CarAge Driverage Brand Gas Region Density;
	model Frequency = Power CarAge Driverage Brand Gas Region Density /
	dist = poisson
	link = log;
ODS OUTPUT PARAMETERESTIMATES= parameters MODELFIT = MODELFIT ;
output out = p_train_out resdev = dev_res pred = prediction;
store model_freq_p;
RUN; 

proc sgplot data = p_train_out;
	histogram dev_res;
quit;

data p_train_out;
	set p_train_out;
	claim_count_pred = prediction * Exposure;
run;

/* prediction v.s. actual - checking bias;*/
proc summary data = p_train_out nway missing;
	var claim_count_pred claimnb;
	output out = p_bias_check sum=; 
quit;


proc plm restore= model_freq_p;
   score data= testing out= p_test predicted = res / ilink;
run;

data p_test;
	set p_test;
	claim_count_pred = predicted * Exposure;
	r2 = claim_count_pred - claimnb;
run;



* prediction v.s. actual - checking bias on test data;
proc summary data = p_test nway missing;
	var claim_count_pred claimnb r2;
	output out = p_bias_check_test sum=; 
quit;


/*solution 2: apply offset option*/ 
proc genmod data = training;
	class Power CarAge Driverage Brand Gas Region Density;
	model claimnb = Power CarAge Driverage Brand Gas Region Density /
	dist = poisson
	link = log
	offset = exposure;
ODS OUTPUT PARAMETERESTIMATES= parameters MODELFIT = MODELFIT ;
output out = p_train_out2 resdev = dev_res pred = prediction;
store model_freq_p2;
RUN;

proc sgplot data = p_train_out2;
	histogram dev_res;
quit;

/* prediction v.s. actual - checking bias;*/
proc summary data = p_train_out2 nway missing;
	var prediction claimnb;
	output out = p_bias_check_train2 sum=; 
quit;


proc plm restore= model_freq_p2;
   score data= testing out= p_test2 predicted residual/ ilink;
run;

data p_test2;
	set p_test2;
	r2 = predicted - claimnb;
run;

* prediction v.s. actual - checking bias on test data;
proc summary data = p_test2 nway missing;
	var predicted claimnb r2;
	output out = p_bias_check_test2 sum=; 
quit;











/* Creating Logistic regression model */
proc logistic data=MODEL_DATA descending;
where selected = 1;
class Exposure Power carage driverage brand gas region density severity;
model status(event= 'claim') = Exposure Power carage driverage brand gas region density severity /
selection=stepwise expb stb lackfit;
output out = temp p=new;
store insurance_logistic;
run;















