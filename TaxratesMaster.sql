CREATE TABLE TaxratesMaster (
	TransID INT IDENTITY(1,1) PRIMARY KEY,
	finyear VARCHAR(10),
    Gain_type VARCHAR(20),
    YTD_gain_range VARCHAR(50),
    Tax_rate DECIMAL(5, 2),
    Surcharge DECIMAL(5, 2),
    Cess DECIMAL(5, 2),
    Total_tax_rate DECIMAL(5, 2)
);
--select * from TaxratesMaster
--INSERT INTO TaxratesMaster (Gain_type,YTD_gain_range,finyear, Tax_rate, Surcharge, Cess, Total_tax_rate)
--VALUES
--    ('Short Term', '>= 50,00,000','2023-2024', 15.00, 15.00, 4.00, 17.94),
--    ('Short Term', '< 50,00,000','2023-2024', 15.00, 0.00, 4.00, 15.60);
--INSERT INTO TaxratesMaster (Gain_type,YTD_gain_range,finyear, Tax_rate, Surcharge, Cess, Total_tax_rate)
--VALUES
--    ('Long Term', '> 50,00,000','2023-2024', 10.00, 15.00, 4.00, 11.96),
--    ('Long Term', '<= 50,00,000','2023-2024', 10.00, 0.00, 4.00, 10.40);

INSERT INTO TaxratesMaster (Gain_type,YTD_gain_range,finyear, Tax_rate,Surcharge, Cess,Total_tax_rate)
values
 ('Short Term','<50,00,000','2023-2024', 15.00, 0.00, 4.00,15.60),
    ('Short Term','>= 50,00,000 and < 1 Crore','2023-2024', 15.00, 10.00, 4.00,17.16),
    ('Short Term','>= 1 Crore and < 2 Crore','2023-2024', 15.00, 15.00, 4.00,17.94),
    ('Short Term','>= 2 Crore and < 5 Crore','2023-2024', 15.00, 25.00, 4.00,19.50),
    ('Short Term','>= 5 Crore','2023-2024', 15.00, 37.00, 4.00,21.37);


	INSERT INTO TaxratesMaster (Gain_type,YTD_gain_range,finyear, Tax_rate,Surcharge, Cess,Total_tax_rate)
values
 ('Long Term','<50,00,000','2023-2024', 10.00, 0.00, 4.00,10.40),
    ('Long Term','>= 50,00,000 and < 1 Crore','2023-2024', 10.00, 10.00, 4.00,11.44),
    ('Long Term','>= 1 Crore and < 2 Crore','2023-2024', 10.00, 15.00, 4.00,12.96),
    ('Long Term','>= 2 Crore and < 5 Crore','2023-2024', 10.00, 25.00, 4.00,13.00),
    ('Long Term','>= 5 Crore','2023-2024', 10.00, 37.00, 4.00,14.24);

--drop table TaxratesMaster

