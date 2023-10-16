--exec SpGetDailyTransactionDetails '2023-09-01','2023-09-30',1291197392,'2023-2024'  
alter Procedure SpGetDailyTransactionDetails
@frmdate date null,  
@todate date null,  
@clientid int null,  
@FiscYear varchar(12)     
As                                                         
begin                                                                                                                                          
  Set NoCount On ;   
  if @clientid != 0
  begin
 WITH ProfitData AS (  
    SELECT  
        c.NAME as ClientName,  
        c.TRADECODE as TradeCode,  
        RTRIM(curlocation) + RTRIM(tradecode) as ClientCode,  
        c.CLIENTID,  
        c.PAN_GIR as Pan,  
        t.BuyQty,  
        t.BuyValue,  
        t.TranDateBuy,  
        t.TranDateSale,  
        t.TransID,  
  t.Type,  
       -- CASE WHEN t.Type='Long Term' THEN 'LG' ELSE 'SG' END as Type,  
        T.SaleQty,  
        T.SaleValue,  
        T.ISIN,  
        t.Security,  
        t.DayToSell,  
        t.Profit,  
        t.BuyExpense,  
        t.SellExpense,  
        max(s.SeriesCode) as SecurityType,  
        MAX(s.PRODUCT) as PRODUCT -- Using MAX to pick one PRODUCT name  
    FROM Tax_Profit_Details_Cash_TDS t  
    INNER JOIN Client c ON c.CLIENTID = t.Clientid  
    LEFT JOIN Sauda s ON s.CLIENTID = t.Clientid AND t.TranDateSale = s.TRANDATE AND t.Security = s.SECURITY  
    WHERE TranDateSale between @frmdate and @todate  AND t.clientid = @clientid  
    GROUP BY  
        c.NAME,  
        c.TRADECODE,  
        RTRIM(curlocation) + RTRIM(tradecode),  
        c.CLIENTID,  
        t.BuyQty,  
        t.BuyValue,  
        t.TranDateBuy,  
        t.TranDateSale,  
        t.TransID,  
       -- CASE WHEN t.Type='Long Term' THEN 'LG' ELSE 'SG' END,  
        T.SaleQty,  
        T.SaleValue,  
        T.ISIN,  
        t.Security,  
        t.DayToSell,  
        t.Profit,  
        t.BuyExpense,  
        t.SellExpense,  
        c.PAN_GIR,  
		t.Type  



		union 

			SELECT
			c.NAME,
			c.TRADECODE,
			RTRIM(curlocation) + RTRIM(tradecode),
			c.CLIENTID,
	        c.PAN_GIR as Pan,  

		    0,
            0,
			 tb.Trandate,
			tb.Trandate,
			tb.TransId,
			'Short Term' as Type,
			tb.Qty as SaleQty,
			tb.SellValue as SaleValue,
			tb.ISIN,
			tb.Security,
			1,  
			tb.Profit,  
			0,  
			tb.OtherCharges,  
        max(s.SeriesCode) as SecurityType,  
    MAX(s.PRODUCT) as PRODUCT
FROM tax_Profit_Buynotfound_TDS  tb
INNER JOIN Client c ON c.CLIENTID = tb.Clientid
LEFT JOIN Sauda s ON s.CLIENTID = tb.Clientid AND tb.Trandate= s.TRANDATE AND tb.Security = s.SECURITY
WHERE tb.Trandate  between @frmdate and @todate AND tb.clientid = @clientid AND tb.isactive=1
GROUP BY
    c.NAME,
    c.TRADECODE,
    RTRIM(curlocation) + RTRIM(tradecode),
    c.CLIENTID,
	C.PAN_GIR,
    tb.Trandate,
    tb.TransID,
    tb.Qty,
    tb.SellValue,
    tb.ISIN,
    tb.Security,
	tb.OtherCharges,
	tb.Profit

),  
  
TaxRates AS (  
    -- Select the appropriate tax rates based on the gain type and gain range  
    SELECT  
        Gain_type,  
        YTD_gain_range,  
        finyear,  
        Tax_rate,  
        Surcharge,  
        Cess,  
        Total_tax_rate  
    FROM TaxratesMaster  
    WHERE finyear = @FiscYear  
),  
  
TaxCalculation AS (  
    -- Calculate tax on profit  
    SELECT  
        pd.*,  
      CASE  
            WHEN pd.Type = 'Short Term' THEN  
    CASE  
     WHEN pd.Profit <= 5000000 THEN  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)   
                    ELSE  
       (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
    END  
            WHEN pd.Type = 'Long Term' THEN  
                CASE  
                    WHEN pd.Profit <= 5000000 THEN  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)  
                    ELSE  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
                END  
        END AS TaxPercentage,  
        CASE  
            WHEN pd.Type = 'Short Term' THEN  
    CASE  
     WHEN pd.Profit <= 5000000 THEN  
                        pd.Profit *  (SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear =@FiscYear)   
                    ELSE  
      pd.Profit * (SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
    END  
            WHEN pd.Type = 'Long Term' THEN  
                CASE  
                    WHEN pd.Profit <= 5000000 THEN  
                        pd.Profit *(SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)  
                    ELSE  
                        pd.Profit *(SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear =@FiscYear)  
                END  
        END AS TaxAmount  
    FROM ProfitData pd  
)  
  
-- Finally, you can select the columns you need from the TaxCalculation CTE  
SELECT  
    ClientName,  
    TradeCode,  
    ClientCode,  
    CLIENTID,  
    Pan,  
    BuyQty,  
    BuyValue,  
    TranDateBuy,  
    TranDateSale,  
    TransID,  
    CASE WHEN Type='Long Term' THEN 'LG' ELSE 'SG' END as Type,  
    SaleQty,  
    SaleValue,  
    ISIN,  
    Security,  
    DayToSell,  
    Profit,  
    BuyExpense,  
    SellExpense,  
    SecurityType,  
    PRODUCT,  
 TaxPercentage,  
    TaxAmount  
FROM TaxCalculation order by TranDateSale;  
  end
  else
  begin
  WITH ProfitData AS (  
    SELECT  
        c.NAME as ClientName,  
        c.TRADECODE as TradeCode,  
        RTRIM(curlocation) + RTRIM(tradecode) as ClientCode,  
        c.CLIENTID,  
        c.PAN_GIR as Pan,  
        t.BuyQty,  
        t.BuyValue,  
        t.TranDateBuy,  
        t.TranDateSale,  
        t.TransID,  
  t.Type,  
       -- CASE WHEN t.Type='Long Term' THEN 'LG' ELSE 'SG' END as Type,  
        T.SaleQty,  
        T.SaleValue,  
        T.ISIN,  
        t.Security,  
        t.DayToSell,  
        t.Profit,  
        t.BuyExpense,  
        t.SellExpense,  
        max(s.SeriesCode) as SecurityType,  
        MAX(s.PRODUCT) as PRODUCT -- Using MAX to pick one PRODUCT name  
    FROM Tax_Profit_Details_Cash_TDS t  
    INNER JOIN Client c ON c.CLIENTID = t.Clientid  
    LEFT JOIN Sauda s ON s.CLIENTID = t.Clientid AND t.TranDateSale = s.TRANDATE AND t.Security = s.SECURITY  
    WHERE TranDateSale between @frmdate and @todate  
    GROUP BY  
        c.NAME,  
        c.TRADECODE,  
        RTRIM(curlocation) + RTRIM(tradecode),  
        c.CLIENTID,  
        t.BuyQty,  
        t.BuyValue,  
        t.TranDateBuy,  
        t.TranDateSale,  
        t.TransID,  
       -- CASE WHEN t.Type='Long Term' THEN 'LG' ELSE 'SG' END,  
        T.SaleQty,  
        T.SaleValue,  
        T.ISIN,  
        t.Security,  
        t.DayToSell,  
        t.Profit,  
        t.BuyExpense,  
        t.SellExpense,  
        c.PAN_GIR,  
		t.Type  




		union 

			SELECT
			c.NAME,
			c.TRADECODE,
			RTRIM(curlocation) + RTRIM(tradecode),
			c.CLIENTID,
	        c.PAN_GIR as Pan,  

		    0,
            0,
			 tb.Trandate,
			tb.Trandate,
			tb.TransId,
			'Short Term' as Type,
			tb.Qty as SaleQty,
			tb.SellValue as SaleValue,
			tb.ISIN,
			tb.Security,
			1,  
			tb.Profit,  
			0,  
			tb.OtherCharges,  
        max(s.SeriesCode) as SecurityType,  
    MAX(s.PRODUCT) as PRODUCT
FROM tax_Profit_Buynotfound_TDS  tb
INNER JOIN Client c ON c.CLIENTID = tb.Clientid
LEFT JOIN Sauda s ON s.CLIENTID = tb.Clientid AND tb.Trandate= s.TRANDATE AND tb.Security = s.SECURITY
WHERE tb.Trandate  between @frmdate and @todate and tb.isactive=1
GROUP BY
    c.NAME,
    c.TRADECODE,
    RTRIM(curlocation) + RTRIM(tradecode),
    c.CLIENTID,
	C.PAN_GIR,
    tb.Trandate,
    tb.TransID,
    tb.Qty,
    tb.SellValue,
    tb.ISIN,
    tb.Security,
	tb.OtherCharges,
	tb.Profit
),  
  
TaxRates AS (  
    -- Select the appropriate tax rates based on the gain type and gain range  
    SELECT  
        Gain_type,  
        YTD_gain_range,  
        finyear,  
        Tax_rate,  
        Surcharge,  
        Cess,  
        Total_tax_rate  
    FROM TaxratesMaster  
    WHERE finyear = @FiscYear  
),  
  
TaxCalculation AS (  
    -- Calculate tax on profit  
    SELECT  
        pd.*,  
      CASE  
            WHEN pd.Type = 'Short Term' THEN  
    CASE  
     WHEN pd.Profit <= 5000000 THEN  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)   
                    ELSE  
       (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
    END  
            WHEN pd.Type = 'Long Term' THEN  
                CASE  
                    WHEN pd.Profit <= 5000000 THEN  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)  
                    ELSE  
                        (SELECT Total_tax_rate  FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
                END  
        END AS TaxPercentage,  
        CASE  
            WHEN pd.Type = 'Short Term' THEN  
    CASE  
     WHEN pd.Profit <= 5000000 THEN  
                        pd.Profit *  (SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '<= 50,00,000' AND finyear =@FiscYear)   
                    ELSE  
      pd.Profit * (SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Short Term' AND YTD_gain_range = '> 50,00,000' AND finyear = @FiscYear)  
    END  
            WHEN pd.Type = 'Long Term' THEN  
                CASE  
                    WHEN pd.Profit <= 5000000 THEN  
                        pd.Profit *(SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '<= 50,00,000' AND finyear = @FiscYear)  
                    ELSE  
                        pd.Profit *(SELECT Total_tax_rate / 100 FROM TaxratesMaster    
      WHERE Gain_type = 'Long Term' AND YTD_gain_range = '> 50,00,000' AND finyear =@FiscYear)  
                END  
        END AS TaxAmount  
    FROM ProfitData pd  
)  
  
-- Finally, you can select the columns you need from the TaxCalculation CTE  
SELECT  
    ClientName,  
    TradeCode,  
    ClientCode,  
    CLIENTID,  
    Pan,  
    BuyQty,  
    BuyValue,  
    TranDateBuy,  
    TranDateSale,  
    TransID,  
    CASE WHEN Type='Long Term' THEN 'LG' ELSE 'SG' END as Type,  
    SaleQty,  
    SaleValue,  
    ISIN,  
    Security,  
    DayToSell,  
    Profit,  
    BuyExpense,  
    SellExpense,  
    SecurityType,  
    PRODUCT,  
 TaxPercentage,  
    TaxAmount  
FROM TaxCalculation order by TranDateSale;  
  end
  
End   