OPTIONS spool;

LIBNAME REALDATA '/folders/myfolders/WDEC2L/DATA';


DATA TMP1;
	SET REALDATA.FACTS;
DATA TMP2;
	SET REALDATA.PRODUCTS;
RUN;	

PROC SORT
	DATA = TMP1;
	BY ProductId;
	
PROC SORT
	DATA = TMP2;
	BY ProductId;	
	
DATA SALES;
   MERGE TMP1 TMP2;
   BY ProductId;
   
RUN;

PROC SORT 
	DATA = SALES;
	BY ProductId;
RUN;

DATA GroupByProduct;
   SET SALES; BY ProductId;
   
   IF First.ProductId THEN 
   	TotalSold = 0;
   	
   TotalSold + Sold;
   
   IF Last.ProductId;
RUN;

PROC SGPLOT;
	VBAR ProductName / RESPONSE = TotalSold;
	