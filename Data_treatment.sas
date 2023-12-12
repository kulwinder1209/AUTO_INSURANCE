LIBNAME SRC "D:\PROJECTS\SRC";
LIBNAME DIR "D:\PROJECTS\DATA";

/*******************************************************************************/
/**********************BASIC TREATMENT FOR ONE TABLE****************************/
/*******************************************************************************/

/*GET A STATISTIC SUMMARY FOR NUMERIC VARIABLES*/
PROC MEANS DATA=DIR.SAMPLE_CUSTOMERS;
	VAR _NUMERIC_;
	OUTPUT OUT=DIR.NX1 (DROP = _TYPE_ _FREQ_);
RUN;
/*GET THE NUMBER OF MISSING VALUES*/
PROC MEANS DATA=DIR.SAMPLE_CUSTOMERS;
	VAR _NUMERIC_;
	OUTPUT OUT=DIR.MX1 (DROP = _TYPE_ _FREQ_) NMISS=;
RUN;
/*ADD COLUMN OF _STAT_ WITH VALUE OF 'NMISS'*/
DATA DIR.MX2;
	SET DIR.MX1;
	_STAT_='NMISS';
RUN;
/*TANSPOSE DATA INTO FIELDS FROM _STAT_*/
PROC TRANSPOSE DATA=DIR.NX1 OUT=DIR.NX2;
	ID _STAT_;
	VAR _NUMERIC_;
RUN;
/*TRANSPOSE MISSING VALUE DATA WITH THE SAME WAY*/
PROC TRANSPOSE DATA=DIR.MX2 OUT=DIR.MX3;
	ID _STAT_;
	VAR _NUMERIC_;
RUN;
/*JOIN TWO TRANSPOSED TABLES*/
PROC SQL;
	CREATE TABLE DIR.SUMMARY_CUSTOMERS AS
	SELECT A._NAME_, A.N, A.MIN, A.MAX, A.MEAN, B.NMISS
	FROM DIR.NX2 AS A, DIR.MX3 AS B 
	WHERE A._NAME_=B._NAME_;
QUIT;

/*CLEAN THE WORKING TABLES*/
PROC DATASETS LIB=DIR;
	 DELETE MX1 MX2 MX3 NX1 NX2;
	 QUIT;
RUN;

/*DEFINE THE STRATEGICAL TREATMENT OF MISSING VALUES. THE SOLUTIONS INCLUDE:
CREATING NEW COLUMN - NONMISS, MISS_PCT, MISS, REP, DROP, AND RELATED CODE IN TEXT - MISS_CODE, REP_CODE, DROP_CODE,
WHICH WILL BE APPLIED BY THE LATER DATA STEPS
	--THE TREAMENT DEFINITIONS:
	IF NMISS<5%, THEN FILL WITH MEAN;
	IF NMISS 5~30%, THEN FILL WITH MEAN + MISSING INDICATOR;
	IF NMISS 30~80%, MISSING INDICATOR + DROP FIELD;
	IF NMISS>80%, DROP FIELD; 
*/
DATA DIR.SUMMARY_CUSTOMERS;
	SET DIR.SUMMARY_CUSTOMERS;
	NONMISS=N;
	MISS_PCT=NMISS/(N+NMISS)*100;
    IF (MISS_PCT >5 AND MISS_PCT<80) THEN MISS='Y'; ELSE MISS='N';
	IF (MISS_PCT>0 AND MISS_PCT<30) THEN REP='Y'; ELSE REP='N';
	IF (MISS_PCT >30) THEN DROP='Y'; ELSE DROP='N';
	IF MISS='Y' THEN MISS_CODE='IF '||COMPRESS(_NAME_)||'=. THEN '||COMPRESS(_NAME_)||'_IND=1; ELSE '||COMPRESS(_NAME_)||'_IND=0';
	IF REP='Y' THEN REP_CODE='IF '||COMPRESS(_NAME_)||'=. THEN '||COMPRESS(_NAME_)||'='||MEAN;
	IF DROP='Y' THEN DROP_CODE='DROP '||COMPRESS(_NAME_);
RUN;

/*SELECT TREATMENT CODE INTO MACRO VARIABLES*/
PROC SQL;
SELECT MISS_CODE INTO :M_MISS_CODE SEPARATED BY ';' FROM DIR.SUMMARY_CUSTOMERS WHERE MISS='Y';
SELECT REP_CODE INTO :M_REP_CODE SEPARATED BY ';' FROM DIR.SUMMARY_CUSTOMERS WHERE REP='Y';
SELECT DROP_CODE INTO :M_DROP_CODE SEPARATED BY ';' FROM DIR.SUMMARY_CUSTOMERS WHERE DROP='Y';
QUIT;

/*APPLY MACRO VARIABLES TO DATA STEP FOR SAMPLE CUSTOMERS*/
DATA DIR.SAMPLE_CUSTOMERS;
SET DIR.SAMPLE_CUSTOMERS;
&M_MISS_CODE.;
&M_REP_CODE.;
&M_DROP_CODE.;
RUN;	

