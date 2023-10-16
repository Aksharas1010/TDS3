CREATE PROCEDURE InsertTaxRates
(
    @GainType VARCHAR(50),
    @YTDGainRange VARCHAR(50),
    @FinYear VARCHAR(50),
    @TaxRate DECIMAL(5, 2),
    @Surcharge DECIMAL(5, 2),
    @Cess DECIMAL(5, 2),
    @TotalTaxRate DECIMAL(5, 2)
)
AS
BEGIN
    INSERT INTO TaxratesMaster (Gain_type, YTD_gain_range, finyear, Tax_rate, Surcharge, Cess, Total_tax_rate)
    VALUES (@GainType, @YTDGainRange, @FinYear, @TaxRate, @Surcharge, @Cess, @TotalTaxRate);
END;



