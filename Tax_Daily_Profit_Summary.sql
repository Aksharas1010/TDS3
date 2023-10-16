
--drop table Tax_Daily_Profit_Summary
CREATE TABLE Tax_Daily_Profit_Summary (  
	[TransID] [int] IDENTITY(1,1) NOT NULL,
    Client VARCHAR(50),  
	TransSaleDate [datetime] NULL,     
    Sum_Short_Term_Profit DECIMAL(10, 2),  
    Sum_Long_Term_Profit DECIMAL(10, 2),  
	DailySetOffST DECIMAL(10,2),
	DailySetOffLT Decimal(10,2),
	Profit DECIMAL(10, 2),  
	OpeningBalST Decimal(10,2),  
	OpeningBalLT Decimal(10,2),
	Adjusted_Short_Term DECIMAL(10, 2),  
    Adjusted_Long_Term DECIMAL(10, 2),
		ClosingBalST Decimal(10,2),  
	ClosingBalLT Decimal(10,2),
	TaxableGain DECIMAL(10, 2),  
	ST_Tax DECIMAL(10, 2),  
	LT_Tax DECIMAL(10, 2),   
	ST_TaxPercentage DECIMAL(10, 2),  
	LT_TaxPercentage DECIMAL(10, 2) ,

);  