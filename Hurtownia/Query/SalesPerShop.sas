OPTIONS spool;

LIBNAME REALDATA '/folders/myfolders/WDEC2L/DATA';

DATA TMP1;
	SET REALDATA.FACTS;
RUN;

PROC MEANS maxdec=2 n mean stderr median;
	VAR Sold;
	CLASS ShopId;
	
PROC SORT 
	DATA = TMP1
	OUT = SortByShop;
	BY ShopId;
RUN;

DATA GroupByShop;
   SET SortByShop; BY ShopId;
   
   IF First.ShopId THEN 
   	TotalSold = 0;
   	
   TotalSold + Sold;
   
   IF Last.ShopId;
RUN;

PROC SGPLOT;
	SERIES X = ShopId Y = TotalSold;
	
	