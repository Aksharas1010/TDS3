
--EXEC SpGetTDSReturnsReportData '2023-07-01','2023-09-30','2023-2024'
create Procedure SpGetTDSReturnsReportData  
 @frm_date VARCHAR(MAX),
 @to_date VARCHAR(MAX) , 
 @FiscYear varchar(12)  
As                                                           
begin


CREATE TABLE #Tax_Monthly_Profit_Summary (  
    Client VARCHAR(50), 
	PAN varchar(max),
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
	ST_SurCharge DECIMAL(10, 2),  
	LT_SurCharge DECIMAL(10, 2),
	ST_Cess DECIMAL(10, 2),  
	LT_Cess DECIMAL(10, 2),
	ST_TaxTotal DECIMAL(10, 2),  
	LT_TaxTotal DECIMAL(10, 2),
	ST_TaxPercentage DECIMAL(10, 2),  
	LT_TaxPercentage DECIMAL(10, 2) ,
	
	);  
insert into #Tax_Monthly_Profit_Summary(Client,PAN,TransSaleDate,
Sum_Short_Term_Profit,Sum_Long_Term_Profit,DailySetOffLT ,DailySetOffST,Profit,OpeningBalLT,OpeningBalST,Adjusted_Short_Term,Adjusted_Long_Term,
TaxableGain,ClosingBalLT,ClosingBalST,ST_Tax,LT_Tax,ST_TaxTotal,LT_TaxTotal,ST_SurCharge,LT_SurCharge,ST_Cess,LT_Cess,ST_TaxPercentage,LT_TaxPercentage)
SELECT  c.NAME AS ClientName,c.PAN_GIR,
    t1.TransSaleDate,t1.Sum_Short_Term_Profit,t1.Sum_Long_Term_Profit,t1.DailySetOffLT,t1.DailySetOffST,t1.Profit,t1.OpeningBalLT,t1.OpeningBalST,
	t1.Adjusted_Short_Term,t1.Adjusted_Long_Term,t1.TaxableGain,t1.ClosingBalLT,t1.ClosingBalST,

   ST_Tax=case when ClosingBalST>0 then   
   CASE  
   WHEN  ClosingBalST > 5000000 THEN ClosingBalST * ( SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear )  
   WHEN  ClosingBalST <= 5000000 THEN ClosingBalST * (SELECT Tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear )  
   end  
   else 
   0
   end,  
   LT_Tax=case when ClosingBalLT>0 then   
   CASE  WHEN  ClosingBalLT > 5000000 THEN  ClosingBalLT * (  SELECT Tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear  )  
   WHEN  ClosingBalLT <= 5000000 THEN ClosingBalLT * (  SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear  )  
   end  
   else 0  
   end,  
   ST_TaxTotal=case when ClosingBalST>0 then   
   CASE  WHEN  ClosingBalST > 5000000 THEN  ClosingBalST * (SELECT Total_tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear )  
   WHEN  ClosingBalST <= 5000000 THEN  ClosingBalST * (SELECT Total_tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear )  
   end  
   else 
   0
   end,  
   LT_TaxTotal=case when ClosingBalLT>0 then   
   CASE  WHEN  ClosingBalLT > 5000000 THEN  ClosingBalLT * (SELECT Total_tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear  )  
   WHEN  ClosingBalLT <= 5000000 THEN  ClosingBalLT * (  SELECT Total_tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear  )  
   end  
   else 0  
   end, 

   ST_Surcharge=case when ClosingBalST>0 then   
   CASE  
   WHEN  ClosingBalST > 5000000 THEN ClosingBalST * (   SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear ) *(SELECT Surcharge / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear )
   WHEN  ClosingBalST <= 5000000 THEN   
   0
   end  
   else 
   0
   end,  
   LT_Surcharge=case when ClosingBalLT>0 then   
   CASE  WHEN  ClosingBalLT > 5000000 THEN   ClosingBalLT * ( SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear  )  *( SELECT Surcharge / 100 FROM TaxratesMaster  WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear) 
   WHEN  ClosingBalLT <= 5000000 THEN   
   0
   end  
   else 0  
   end,



   ST_Cess=case when ClosingBalST>0 then   
   CASE  
   WHEN  ClosingBalST > 5000000 THEN     
     ClosingBalST * (  
     SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear ) 
	 *(SELECT Surcharge / 100 FROM TaxratesMaster WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)
	 *(SELECT Cess / 100 FROM TaxratesMaster WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)
   WHEN  ClosingBalST <= 5000000 THEN   
    ClosingBalST * (  
     SELECT Tax_rate / 100 FROM TaxratesMaster  WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear ) 
	 *(SELECT Cess / 100 FROM TaxratesMaster WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear) 
   end  
   else 
   0
   end,  
   LT_Cess=case when ClosingBalLT>0 then   
   CASE  WHEN  ClosingBalLT > 5000000 THEN  ClosingBalLT * (  
     SELECT Tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear) 
	*(SELECT Surcharge / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear) 
	*(SELECT Cess / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear) 

   WHEN  ClosingBalLT <= 5000000 THEN   ClosingBalLT * (  
     SELECT Tax_rate / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear) 
	*(SELECT Cess / 100 FROM TaxratesMaster WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear) 
   end  
   else 0  
   end,




   ST_TaxPercentage=case when ClosingBalST>0 then   
   CASE  
   WHEN  ClosingBalST > 5000000 THEN   
    (  
     SELECT Total_tax_rate FROM TaxratesMaster  
     WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear  
                )  
   WHEN  ClosingBalST <= 5000000 THEN    
      (  
     SELECT Total_tax_rate FROM TaxratesMaster  
     WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear  
                )  
   end  
   else 0  
   end,  
   LT_TaxPercentage=case when ClosingBalLT>0 then   
   CASE  
   WHEN  ClosingBalLT > 5000000 THEN   
    (  
     SELECT Total_tax_rate FROM TaxratesMaster  
     WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear  
                )  
   WHEN  ClosingBalLT <= 5000000 THEN   
    (  
     SELECT Total_tax_rate FROM TaxratesMaster  
     WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear  
        )  
   end  
   else 0  
   end  
FROM
    Tax_Daily_Profit_Summary t1
INNER JOIN ( SELECT Client,DATEFROMPARTS(YEAR(TransSaleDate), MONTH(TransSaleDate), 1) AS MonthYear, MAX(TransSaleDate) AS last_date_entry FROM Tax_Daily_Profit_Summary
    WHERE TransSaleDate >= @frm_date AND TransSaleDate <= @to_date
    GROUP BY Client, DATEFROMPARTS(YEAR(TransSaleDate), MONTH(TransSaleDate), 1)) t2 ON t1.Client = t2.Client AND t1.TransSaleDate = t2.last_date_entry
INNER JOIN client c ON t1.Client = c.CLIENTID
WHERE t1.Adjusted_Short_Term > 0 OR t1.Adjusted_Long_Term > 0
select * ,Client as ClientName,
case when ClosingBalST>0 then ClosingBalST else 0 end as ShortTermGain,
case when ClosingBalLT>0 then ClosingBalLT else 0 end as LongTermGain
from #Tax_Monthly_Profit_Summary
drop table #Tax_Monthly_Profit_Summary
end



