LIBNAME SRC "D:\PROJECTS\SRC";


/**********************************************************************************************************************************************/
/***************************FEATURE ENGINEERING************************************************************************************************/
/*
AGGREGATE CUSTOMER DATA - SPEND, COUPON, SERVICE TO CUSTOMER LEVEL IN WHICH 5 DIFFERENT PERIODS OF TIME: 1 MONTH, 2 MONTHS, 3 MONTHS, 6 MONTHS 
AND THE WHOLE YEAR ARE APPLIED WITH STATISTICS: MEAN, MAX, MIN, STANDARD DEVIATION, COUNT.
FOR SPEND, 3 DIFFERENT PRODUCT TYPES (G, O, AND S) AND ALL PRODUCTS ARE APPLIED.
FOR COUPON AND SERVICE, IN ADDITION TO 5 DIFFERENT PERIODS OF TIME, THE WHOLE SPAN OF COUPON OR SERVICE IS ALSO APPLIED. 
FOR ALL SPEND, COUPON AND SERVICE FEATURE ENGINEERING, LOG TRANSFORMATION IS APPLIED.  
*/
/**********************************************************************************************************************************************/

/*SUMMARIZE STATISTICS ON DIFFERENT LENGTHS OF TIME FOR ALL PRODUCTS AND APPLY LOG TRANSFORMATION*/
%MACRO FEATURE_ENG_SPEND1(D);
%LET TIME=(30, 60, 90, 180, 365);
	%DO J=1 %TO 5;
		%LET TM=%SCAN(&TIME.,&J.);
			PROC SQL;
				CREATE TABLE DIR.X1 AS
				SELECT ID, &D._DAY, &D._TYPE, &D., MAX(&D._DAY)-&TM. AS DAY_&TM. FROM DIR.SAMPLE_&D.
				GROUP BY ID;

				CREATE TABLE DIR.&D._&TM._ALL AS
				SELECT ID, 
				LOG(MIN(&D.)) AS &D._&TM._ALL_MIN_LOG,
				LOG(MAX(&D.)) AS &D._&TM._ALL_MAX_LOG,
				LOG(STD(&D.)) AS &D._&TM._ALL_STD_LOG,
				LOG(MEAN(&D.)) AS &D._&TM._ALL_AVG_LOG,
				LOG(COUNT(&D.)) AS &D._&TM._ALL_CNT_LOG
				FROM DIR.X1
				WHERE &D._DAY>DAY_&TM.
				GROUP BY ID;
			QUIT;
		
			PROC DATASETS LIB=DIR;
				 DELETE X1;
				 QUIT;
			RUN;	
	%END;
%MEND;

%FEATURE_ENG_SPEND1(SPEND);

/*SUMMARIZE STATISTICS ON DIFFERENT LENGTHS OF TIME FOR 3 DIFFERENT TYPE PRODUCTS AND APPLY LOG TRANSFORMATION*/
%MACRO FEATURE_ENG_SPEND2(D);
%LET TIME=(30, 60, 90, 180, 365);
%LET TP=(G,S,O);
	%DO J=1 %TO 5;
	%LET TM=%SCAN(&TIME.,&J.);
		%DO T=1 %TO 3;
		%LET P=%SCAN(&TP., &T.);
			PROC SQL;
				CREATE TABLE DIR.X1 AS
				SELECT ID, &D._DAY, &D._TYPE, &D., MAX(&D._DAY)-&TM. AS DAY_&TM. FROM DIR.SAMPLE_&D.
				GROUP BY ID;

				CREATE TABLE DIR.&D._&TM._&P. AS
				SELECT ID, 
				LOG(MIN(&D.)) AS &D._&TM._&P._MIN_LOG,
				LOG(MAX(&D.)) AS &D._&TM._&P._MAX_LOG,
				LOG(STD(&D.)) AS &D._&TM._&P._STD_LOG,
				LOG(MEAN(&D.)) AS &D._&TM._&P._AVG_LOG,
				LOG(COUNT(&D.)) AS &D._&TM._&P._CNT_LOG
				FROM DIR.X1
				WHERE &D._TYPE="&P." AND &D._DAY>DAY_&TM.
				GROUP BY ID;
			QUIT;
			PROC DATASETS LIB=DIR;
				 DELETE X1;
				 QUIT;
			RUN;	
		%END;
	%END;
%MEND;

%FEATURE_ENG_SPEND2(SPEND);


