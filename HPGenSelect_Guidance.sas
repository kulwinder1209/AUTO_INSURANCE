/*

brief project intro

*/

/*

data pre-processing - read, quality check, data integration, data treatment, feature engineering if ncessary

*/

/*

eda - associations/relationships, visualization based on the required metrics/patterns/insights

*/



/*

hpgenselect

The model at below is for tweedie distribution. It's necessary to change the response and distribution when the other model such as poison is
applied
 
*/

/*modeling 

data split 

*/

/*modeling -train model*/
options linesize=120;

proc hpgenselect data=training;
  class driver_age car_age dens gas region brand power / split param=reference;
  model severity = driver_age car_age dens gas region brand power /
        dist=tweedie link=log offset=exposure;
  selection method=stepwise(choose=aicc) details=summary;
  output out=tweedie_hp P R;
  id severity;
  code File='ScoringParameters.txt';
run;

/*modeling -validate residuals for training*/
proc summary data=Tweedie_hp nway missing;
var severity pred residual;
output out=bias_check_hp_train sum=;
run;

/*modeling -score in new dataset (testing)*/
data testScores;
   set Testing;
   %inc 'ScoringParameters.txt';
run;

/*validate residuals for testing*/
proc summary data=testScore nway missing;
var severity pred residual;
output out=bias_check_hp_test sum=;
run;

