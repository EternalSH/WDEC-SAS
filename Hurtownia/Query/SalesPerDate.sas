OPTIONS spool;

LIBNAME REALDATA '/folders/myfolders/WDEC2L/DATA';

DATA TMP1;
	SET REALDATA.FACTS;
RUN;

PROC MEANS maxdec=2 n mean stderr median;
	VAR Sold;
	CLASS FullDate;
	
PROC SORT 
	DATA = TMP1
	OUT = SortByDate;
	BY FullDate;
RUN;

DATA GroupByDate;
   SET SortByDate; BY FullDate;
   
   IF First.FullDate THEN 
   	TotalSold = 0;
   	
   TotalSold + Sold;
   
   IF Last.FullDate;
RUN;

PROC SGPLOT;
	SERIES X = FullDate Y = TotalSold;
	