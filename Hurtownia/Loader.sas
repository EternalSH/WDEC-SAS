OPTIONS spool;

LIBNAME METADATA '/folders/myfolders/WDEC2L/META';
LIBNAME REALDATA '/folders/myfolders/WDEC2L/DATA';

%macro AppendIfValidSales(filename=);
	%PUT "AppendIfValidSales called for &filename";

	%LET FileYear = %SYSFUNC(SUBSTR(&filename, 1, 4));	
	%LET FileMonth = %SYSFUNC(SUBSTR(&filename, 5, 2));
	%LET FileDay = %SYSFUNC(SUBSTR(&filename, 7, 2));
	%LET FileShop = %SYSFUNC(SUBSTR(&filename, 10, 1));
	%LET FileId = %SYSFUNC(SUBSTR(&filename, 1, 10));

	PROC IMPORT 
		dbms=xlsx 
		out= RawInput 
		datafile="/folders/myfolders/WDEC2/&filename"
		replace;
	RUN;
				
	DATA NonEmptyInput;
		SET RawInput;
		
		IF produkt_id ~= . THEN
			OUTPUT;	
	RUN;
	
	DATA CleanInput;
		SET NonEmptyInput END=FINAL;
		
		IF produkt_id ~= . THEN DO;
		
			ProductId 	= produkt_id + 0;
			DROP produkt_id;
			
			Sold 		= Ilosc + 0;
			DROP Ilosc;
				
			FullDate 	= INPUT(TRIM(LEFT(Data)), YYMMDD8.);
			DROP Data;
			
			DROP Godzina;
			
			ShopId		= Sklep_id + 0;
			DROP Sklep_id;
		END; 
		
		IF FINAL THEN
			CALL SYMPUT("CleanN&FileId", _N_);
	RUN;

	PROC DELETE 
		data = NonEmptyInput RawInput;

	DATA ValidatedInput;
		SET CleanInput(WHERE=(FullDate = INPUT("&FileDay&FileMonth&FileYear", DDMMYY8.) AND 
			ShopId = &FileShop)) END=FINAL;
		
		IF FINAL THEN
			CALL SYMPUT("ValidN&FileId", _N_);
	RUN;
	
	DATA DataToAppend;
 		IF SYMGETN("ValidN&FileId") = SYMGETN("CleanN&FileId") THEN
 			SET ValidatedInput; 
 		ELSE
 			PUT "Invalid data detected (file: &filename)"; 			
	RUN;
	
	DATA MetadataToAppend;
		LENGTH FileName $32 Status $16;	
		
		FileName = "&filename";
		ReadDate = INPUT(DATETIME(), DDMMYY8.);
		
		IF SYMGETN("ValidN&FileId") = SYMGETN("CleanN&FileId") THEN
			Status = "VALID";			
		ELSE
			Status = "INVALID";
		
		OUTPUT;
	RUN;
			
	PROC APPEND
		BASE = METADATA.READS
		DATA = MetadataToAppend;
	
	PROC DELETE
		DATA = CleanInput ValidatedInput;
		
	PROC APPEND
		BASE = REALDATA.FACTS
		DATA = DataToAppend;
	
	PROC DELETE
		DATA = DataToAppend MetadataToAppend;
	RUN;	
	
	DATA REALDATA.FACTS;
		SET REALDATA.FACTS(WHERE=(ProductId ~= .));
	RUN;		
%MEND;

%MACRO AppendSalesIfNotExists(filename=);	
	DATA TMP1;
		RUN;
		
	DATA TMP2;
		SET TMP1(IN=NDUPLICATE) METADATA.READS(WHERE=(FileName = "&filename" AND Status = "VALID")) END=FIN;
		IF _N_ = 1 AND FIN AND NDUPLICATE THEN
			CALL EXECUTE('%AppendIfValidSales(filename='||"&filename"||')');
	RUN;
	
	DATA TMP3;
		SET METADATA.READS(WHERE=(FileName = "&filename" AND Status = "VALID"));
		IF _N_ = 1 THEN
			PUT "File &filename is already loaded";
	RUN;

	PROC DELETE 
		DATA = TMP1 TMP2 TMP3;
	RUN;
%MEND;

%MACRO AddProducts(filename=);	
	PROC IMPORT 
		dbms=xlsx 
		out= RawInput 
		datafile="/folders/myfolders/WDEC2/&filename"
		replace;
	RUN;
	
	DATA CleanInput;
		SET RawInput;
		
		IF product_id ~= . THEN DO;		
			ProductId 	= product_id + 0;
			DROP product_id;
							
			ProductName	= INPUT(TRIM(LEFT(Nazwa)), $32.);
			DROP nazwa;
		END; 
	RUN;
	
	PROC APPEND
		BASE = REALDATA.PRODUCTS
		DATA = CleanInput;
		
	PROC DELETE
		DATA = RawInput CleanInput;
%MEND;

%MACRO UpdateProducts(filename=);	
	DATA TMP1;
		RUN;
		
	DATA TMP2;
		SET TMP1(IN=NDUPLICATE) REALDATA.Products(WHERE=(ProductId ~= .)) END=FIN;
		IF _N_ = 1 AND FIN AND NDUPLICATE THEN
			CALL EXECUTE('%AddProducts(filename='||"&filename"||')');
	RUN;

	PROC DELETE 
		DATA = TMP1 TMP2;
	RUN;
%MEND;

DATA _NULL_;
	LENGTH fref $8 filename $80;	

	rc = FILENAME(fref, '/folders/myfolders/WDEC2');

	IF rc = 0 THEN DO;
		did = dopen(fref);
		rc = filename(fref);
	END; ELSE DO;
		length msg $200.;
		msg = sysmsg();
		PUT msg=;
		did = .;
	END;

	IF did <= 0 THEN
		PUTLOG 'ERROR Unable to open directory.';

	dnum = dnum(did);

	DO i = 1 TO dnum;
		filename = dread(did, i);
		/* If this entry is a file, then output. */
		fid = mopen(did, filename);
		
		isProductList = index(filename, "ListaProduktow");
  		LastModified=finfo(fid, 'Last Modified');

		IF (fid > 0) THEN DO;
			IF isProductList = 0 THEN DO;
				CALL EXECUTE('		   			
					%AppendSalesIfNotExists(filename='||filename||')
		   		');
		   	END; ELSE DO;
		   		CALL EXECUTE('		   			
					%UpdateProducts(filename='||filename||')
		   		');

		   	END;
		END;
	END;

	rc = dclose(did);	
RUN;
