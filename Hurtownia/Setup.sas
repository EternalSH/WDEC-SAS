OPTIONS spool;

LIBNAME METADATA '/folders/myfolders/WDEC2L/META';
LIBNAME REALDATA '/folders/myfolders/WDEC2L/DATA';

DATA METADATA.READS;
	ATTRIB
		FileName 	INFORMAT = $32.
		ReadDate 	INFORMAT = DDMMYY8.
		Status		INFORMAT = $16.;


DATA REALDATA.Facts;
	ATTRIB
		Sold 		INFORMAT = 8.
		ProductId 	INFORMAT = 8.
		ShopId		INFORMAT = 8.
		FullDate	INFORMAT = DDMMYY8.;
		
DATA REALDATA.Products;
	ATTRIB
		ProductId 	INFORMAT = 8.
		ProductName	INFORMAT = $32.;
