
/*

genmod

The following model is for tweedie. It's necessary to change response and distribution when you predict claims - do not forget normalization as 
discussed in previous project sessions.

*/
proc genmod data = training plots = ALL;
	class Power Car_Age Driver_age Brand Gas Region Dens;
	model severity = Power Car_Age Driver_age Brand Gas Region Dens /
	dist = tweedie
	link = log
	offset = exposure;
ODS OUTPUT PARAMETERESTIMATES= parameters2 MODELFIT = MODELFIT2 ;
output out = train_out resdev = dev_res pred = prediction;
store model_freq;
RUN;


* prediction v.s. actual - checking bias;
proc summary data = train_out nway missing;
	var severity prediction;
	output out = bias_check_tweedie sum=; 
quit;


proc plm restore= model_freq;
   score data= testing out= testout predicted / ilink;
run;


* prediction v.s. actual - checking bias on test data;
proc summary data = testout nway missing;
	var severity predicted;
	output out = bias_check_testout sum=; 
quit;

