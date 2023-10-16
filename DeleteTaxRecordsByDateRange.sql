alter PROCEDURE DeleteTaxRecordsByDateRange
    @fromDate DATE,
    @toDate DATE,
    @clientId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Success INT = 1; -- Default to success

    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Tax_Daily_Profit_Summary
        WHERE Client = @clientId
          AND TransSaleDate BETWEEN @fromDate AND @toDate;
        DELETE FROM TDS_JournalEntry
        WHERE Client = @clientId
          AND TransSaleDate = @toDate;
		  
        --DELETE FROM tax_Profit_Buynotfound_TDS
        --WHERE Trandate BETWEEN @fromDate AND @toDate and SECURITY in  (select distinct security from tax_Profit_Buynotfound_Manual where CAST(Trandate AS DATE)=@toDate) 
		update tax_Profit_Buynotfound_TDS set isActive=0 
		WHERE Trandate BETWEEN @fromDate AND @toDate and SECURITY in  (select distinct security from tax_Profit_Buynotfound_Manual where CAST(Trandate AS DATE)=@toDate) 


		delete from Tax_Profit_Details_Cash_TDS WHERE ClientId = @clientId
          AND TranDateSale between @fromDate and @todate and Security in (select distinct security from tax_Profit_Buynotfound_Manual where CAST(Trandate AS DATE)=@toDate) 
        COMMIT;
    END TRY
    BEGIN CATCH
        -- If an error occurs, set @Success to 0 and roll back the transaction
        SET @Success = 0;
        ROLLBACK;
    END CATCH;

    SELECT @Success AS Success;
END;
