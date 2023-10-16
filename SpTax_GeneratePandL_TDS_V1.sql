create Procedure [dbo].[SpTax_GeneratePandL_TDS_V1]  
(                           
 @StartDate varchar(20),
 @ToDate varchar(20),
 @clientid int=null

)                                    
As                                     
Begin                                                
 Set Nocount On                      
                          
	declare @Security_Key varchar(20)
	create table  #tempclient(
        clientid int,
        securitykey varchar(50)
    )
	 if @clientid is null
	 begin
   		INSERT INTO #tempclient
   		EXEC SpGetTDSClientDetails @ToDate
     end
     else
     begin
	 INSERT INTO #tempclient
		 EXEC SpGetTDSClientDetails @ToDate,@clientid
	end
	--select * from #tempclient
	DECLARE  @cid int
    DECLARE @securitykey varchar(50)
	DECLARE ClientCursor CURSOR FOR
    SELECT clientid, securitykey FROM #tempclient
    OPEN ClientCursor
    FETCH NEXT FROM ClientCursor INTO @cid, @securitykey
    WHILE @@FETCH_STATUS = 0
    BEGIN
	--FETCH NEXT FROM ClientCursor INTO @cid, @securitykey
            --print @cid                          
	Declare @FromDate VarChar(12)                                          
	Declare @finstart varchar(12)     
	Declare @loc1 Varchar(10)=''
	Declare @FromWeb Char(1) = 'N'
	Declare @StoreForTrading Char(1) = 'N'
	 Declare @PreviousCADate date                        
 declare @mintrandt datetime  
	DECLARE @input_date DATE = @StartDate
	DECLARE @quarter int = (DATEPART(QUARTER, @input_date));
	DECLARE @quarter_start_date DATE = CAST(CAST(YEAR(@input_date) AS VARCHAR(4)) + '-' + CAST((3 * @quarter - 2) AS VARCHAR(2)) + '-01' AS DATE);

	set @FromDate='1900-01-01'                                                            
	set @finstart=@StartDate   
 set @PreviousCADate = @FromDate  
                        
                        
 Declare @EnableLog Char(1)                          
 Declare @Ecess Numeric(15, 2)                                          
 Declare @SPStampduty Numeric(15, 5)                                         
 Declare @DLvStampduty Numeric(15, 4)                                         
 Declare @loc Varchar(10)                                       
 Declare @oldcln integer                                        
 Declare @oldcln1 integer                                        
 Declare @Fyearstart datetime                          
    Declare @trfr char(1)  --MOD:001        
            
 set @trfr='N'          --MOD:001                      
 Set @EnableLog='N'   -- To enable log                          
 Select @Fyearstart=FyearStart from Settings (Nolock)                          
                                  
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step0'  --Log                          
  
create table #sumtemporderfinal                        
 (        
  Slno int,                        
  TranDateBuy datetime,                        
  Security varchar(10),                        
  BuyQty Numeric(15,2),                        
  BuyValue Numeric(15,2),                      
  BuyExpense numeric(15,4),                  
  PurchaseBrokerage Numeric(15,4) not null default 0,                        
  PurchaseServiceTax Numeric(15,4) not null default 0,                        
  PurchaseExchangeLevy Numeric(15,4) not null default 0,                        
  PurchaseStampDuty Numeric(15,4) not null default 0,                                  
  TranDateSale datetime,                        
  SaleQty Numeric(15,2),                        
  SaleValue Numeric(15,2),                        
  SaleBrokerage numeric(15,4),                        
  SaleServiceTax numeric(15,4),                        
  SaleExchangeLevy numeric(15,4),                        
  SaleStampDuty numeric(15,4)                        
 )                  
   
  
 Create table #sumtemporder                 
 (        
  Trandate datetime ,                
  Security varchar(50),               
  SQPurchaseQty  Numeric(15, 2) Not Null  default 0,                
  SQPurchaseValue  Numeric(15, 2) Not Null  default 0,      
  SQPurchaseBrokerage  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseServiceTax  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseExchangeLevy  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseStampDuty  Numeric(15, 4) Not Null  default 0,                
  SQSaleQty  Numeric(15, 2) Not Null  default 0,                
  SQSaleValue  Numeric(15, 2) Not Null  default 0,                
  SQSaleBrokerage Numeric(15, 4) Not Null  default 0,                
  SQSaleServiceTax Numeric(15, 4) Not Null  default 0,                
  SQSaleExchangeLevy Numeric(15, 4) Not Null  default 0,                
  SQSaleStampDuty Numeric(15, 4) Not Null  default 0,                
  TranDateBuy datetime,                
  SlNo int not null identity (1,1)        
 )                   
  
 Create index idxslno on #sumtemporder(SlNo)  
                  
 Create table #sumtemporderdel                 
 (        
  Trandate datetime ,                
  Security varchar(50),                
  SQPurchaseQty  Numeric(15, 2) Not Null  default 0,                
  SQPurchaseValue  Numeric(15, 2) Not Null  default 0,                        
  SQPurchaseBrokerage  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseServiceTax  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseExchangeLevy  Numeric(15, 4) Not Null  default 0,                
  SQPurchaseStampDuty  Numeric(15, 4) Not Null  default 0,                
  SQSaleQty  Numeric(15, 2) Not Null  default 0,                
  SQSaleValue  Numeric(15, 2) Not Null  default 0,                
  SQSaleBrokerage Numeric(15, 4) Not Null  default 0,                
  SQSaleServiceTax Numeric(15, 4) Not Null  default 0,                
  SQSaleExchangeLevy Numeric(15, 4) Not Null  default 0,                
  SQSaleStampDuty Numeric(15, 4) Not Null  default 0,                
  TranDateBuy datetime,                
  SlNo int,              
  sqstampdutyper numeric(10,6)        
 )                  
                          
 Create Table #Caction                                    
 (        
  Security varchar(10) ,                                    
  Multiplier Numeric(15, 3) Not Null Default 1 , --MOD:002    
  SplitDate Datetime,  
  CA_Type varchar(15)  
 )                                   
                          
                          
 Create Table #SumTbl                                    
 (                   
  Security Varchar(10) ,                                    
  SecurityName Varchar(100) ,                                    
  Isin Varchar(12) ,                                    
  SQPurchaseQty Numeric(15, 2) Not Null default 0 ,                                    
  SQPurchaseValue Numeric(15, 2) Not Null default 0 ,                                    
  SQSaleQty Numeric(15, 2) Not Null  default 0 ,                        
  SQSaleValue Numeric(15, 2) Not Null default 0 ,                                    
  BalPurchaseQty Numeric(15, 2) Not Null default 0 ,                     
  BalPurchaseValue Numeric(15, 2) Not Null default 0 ,                                    
  BalSaleQty Numeric(15, 2) Not Null default 0 ,                                    
  BalSaleValue Numeric(15, 2) Not Null default 0 ,                                    
  RealizedPanL Numeric(15, 2) Not Null  Default 0 ,    
  ClosingRate Numeric(15, 2) Not Null  Default 0 ,   
  UnRealizedPanL Numeric(15, 2) Not Null  Default 0 ,                                    
  CurrentHolding Numeric(15, 2) Not Null   default 0 ,                                    
  Avg_price Numeric(15, 2) Not Null   default 0,                              
  Weighted_AverageRate   Numeric(15, 4) Not Null default 0        
 )                    
 Create index idxsec on #SumTbl(Security)                                    
                          
 Create Table #SumTemp                                    
 (                          
  Trandate datetime,                                  
  Security Varchar(10) ,                
  SQPurchaseQty Numeric(15, 2) Not Null default 0 ,                                    
  SQPurchaseValue Numeric(15, 2) Not Null default 0 ,                         
  SQPurchaseBrokerage Numeric(15,4) not null default 0,                        
  SQPurchaseServiceTax Numeric(15,4) not null default 0,                        
  SQPurchaseExchangeLevy Numeric(15,4) not null default 0,                        
  SQPurchaseStampDuty Numeric(15,4) not null default 0,                                   
  SQSaleQty Numeric(15, 2) Not Null  default 0 ,                                    
  SQSaleValue Numeric(15, 2) Not Null  default 0 ,                          
  SQSaleBrokerage Numeric(15,4) not null default 0,                        
  SQSaleServiceTax Numeric(15,4) not null default 0,                        
  SQSaleExchangeLevy Numeric(15,4) not null default 0,                        
  SQSaleStampDuty Numeric(15,4) not null default 0,                                    
  BalPurchaseQty Numeric(15, 2) Not Null default 0 ,                                    
  BalPurchaseValue Numeric(15, 2) Not Null default 0 ,                                    
  BalSaleQty Numeric(15, 2) Not Null default 0 ,                                    
  BalSaleValue Numeric(15, 2) Not Null default 0,                                                
 )                                                
                          
 Create table #charges                         
 (        
  Trandate Datetime,                          
  Security Varchar(10),                          
  Volume Numeric(15,3),                          
  Qty Numeric(15,3),                          
  TurnoverTaxSalesSpec Numeric(15,3),                              
  TurnoverTaxPurchaseDlv Numeric(15,3),                          
  TurnoverTaxSalesDlv Numeric(15,3),                              
  Tolevy Numeric(15,4) not null default 0,                          
  BuyTranno Integer not null default 0,                          
  SellTranno Integer not null default 0,                          
  DelVol Numeric(15,3),                              
  SpecTolevy Numeric(15,2) not null default 0,                              
  DlvTolevy Numeric(15,2) not null default 0           
 )        
                          
 Create Table #Sales                                    
 (                            
  --ClientId int not null,  
  Security Varchar(10) Not Null ,                                
  Trandate datetime Not Null ,                         
  Slno Int Not Null Identity(1, 1) ,                                    
  Qty Numeric(15, 2) Not Null default 0 ,                                    
  Value Numeric(15, 2) Not Null default 0 ,                       
AllocatedPurchaseQty Numeric(15, 2) Not Null  default 0 ,                        
  Brokerage Numeric(15, 4) Not Null default 0,                        
  ServiceTax Numeric(15, 4) Not Null default 0,                        
  ExchangeLevy Numeric(15, 4) Not Null default 0,                        
  StampDuty Numeric(15, 4) Not Null default 0,                                   
  Primary Key (Slno)  
 )                    
   
        
  
 Create index idxslno on  #Sales(Security,Slno)                                               
                            
 Create Table #Temp                                   
 (               
  Security Varchar(10) Not Null ,                                    
  Trandate datetime Not Null ,                                    
  SaudaType Varchar(25) Not Null default 'NORMAL TRADE' ,                                           
  Qty Numeric(15, 2) Not Null default 0 ,                                    
  Value Numeric(15, 2) Not Null default 0,                        
  Brokerage Numeric(15, 4) Not Null default 0,                        
  ServiceTax Numeric(15, 4) Not Null default 0,                        
  ExchangeLevy Numeric(15, 4) Not Null default 0,                        
  StampDuty Numeric(15, 4) Not Null default 0               
 )                                            
                              
 Create Table #TempSpec                              
 (                                    
  Security Varchar(10) Not Null ,                                    
  Trandate datetime Not Null ,                                    
  SaudaType Varchar(25) Not Null      ,                              
  BuyQty Numeric(15, 2) Not Null  default 0 ,                                    
  BuyValue Numeric(15, 2) Not Null  default 0 ,                               
  sellQty Numeric(15, 2) Not Null   default 0 ,                                    
  sellValue Numeric(15, 2) Not Null default 0 ,                              
  Exist char(1) not null default 'N' ,                              
  Profit Numeric(15, 2) Not Null default 0 ,                   
  Brokerage Numeric(15, 4) Not Null default 0, /*-*/                           
  ServiceTax Numeric(15, 4) Not Null default 0,                            
  ExchangeLevy Numeric(15, 5) Not Null default 0,                            
  StampDuty Numeric(15, 5) Not Null default 0 ,                  
  Buysell char(1)    /*-*/                                  
 )                        
 Create index idxSec on #TempSpec(Security)         
 Create Table #oldclnsdet ( clientid integer )        
 Create Index IdxClnId on  #oldclnsdet(clientid)                                        
                                  
 Create Table #TrnDetails                                    
 (                                    
  Exchange Varchar(10) ,                                    
  Security Varchar(10) Not Null ,                       
  SecurityName Varchar(100) ,                                  
  Trandate datetime Not Null ,                                    
  SaudaType Varchar(25) Not Null Default 'NORMAL TRADE' ,                                    
  Bqty Numeric(15, 2) Not Null default 0 ,                                    
  BValue Numeric(15, 2) Not Null default 0 ,                
  BRate Numeric(15, 2) Not Null default 0 ,                                    
  Sqty Numeric(15, 2) Not Null default 0 ,                                    
  SValue Numeric(15, 2) Not Null default 0 ,                                    
  SRate Numeric(15, 2) Not Null default 0,                                                
 )                                          
 Create index idxSec on #TrnDetails(Security)                              
                                        
 Create Table #Purchase                                    
 (        
  --ClientId int not null,  
  Security Varchar(10) Not Null ,               
  Trandate datetime Not Null ,                                    
  Slno Int Not Null  Identity(1, 1) ,                                    
  Qty Numeric(15, 2) Not Null default 0 ,                                    
  Value Numeric(15, 2) Not Null default 0 ,                                    
  AllocatedSellQty Numeric(15, 2) Not Null default 0,  
  CAllocatedSellQty Numeric(15, 2) Not Null default 0,  
  Brokerage Numeric(15, 4) Not Null default 0,                        
  ServiceTax Numeric(15, 4) Not Null default 0,                        
  ExchangeLevy Numeric(15, 4) Not Null default 0,                        
  StampDuty Numeric(15, 4) Not Null default 0,  
  BalanceQuantity Numeric(15, 2) null default null,  
  cactiondoneon datetime null,    
  IsLatest bit default 1   
  Primary Key (Slno)  
 )                                                 
 Create index idxslno on  #Purchase(Security,Slno)                                
                              
 CREATE TABLE [#SAUDA]        
 (  pkslno integer not null identity(1,1)                      ,  
  [TRANSACTIONNO] [int] NOT NULL,                          
  [TRANDATE] [datetime] NOT NULL,                          
  [PRODUCT] [char](10) NOT NULL,                          
  [GROUPCODE] [char](2) NOT NULL,                          
  [STTLYEAR] [int] NOT NULL,                          
  [STTLNO] [int] NOT NULL,                          
  [CLIENTID] [int] NOT NULL,                          
  [SECURITY] [char](10) NOT NULL,                          
  [BUYSELL] [char](1) NOT NULL,                          
  [QTY] [int] NOT NULL,                          
  [RATE] [numeric](15, 4) NULL,                           
  [BROKERAGE] [numeric](15, 2) NULL,                            
  [SERVICETAX] [numeric](15, 2) NULL,                          
  [TOLEVY] [numeric](15, 4) NULL,   
  [StampDuty] [numeric](18, 2) ,                           
  [SAUDATYPE] [varchar](10) NULL,                                 
  [DELSERVICEQTY] [int] NULL,                          
  [DelServiceTax] [numeric](18, 3) NULL,                          
  [DlvServiceChargePerQty] [numeric](15, 2) ,                        
  [TurnoverTaxSalesSpec] [numeric](15, 2) NULL,                             
  [TurnoverTaxPurchaseDlv] [numeric](15, 2) NULL,                         
  [TurnoverTaxSalesDlv] [numeric](15, 2) NULL,  
  [DerivedsDuty] numeric(20,2) not null default 0,  
  [Stampdutyper] numeric(10,10) not null default 0,  
  primary key(pkslno) )  
 Create index IdxTRANSACTIONNO on #SAUDA(TRANSACTIONNO)                                        
 Create index IdxDtls on #SAUDA(Trandate,Security,buysell,Saudatype,Transactionno,Qty,DELSERVICEQTY)                                        
 Create index IdxDtls1 on #SAUDA(Trandate,Security,buysell)  
 CREATE NONCLUSTERED INDEX idxdet1 ON [#SAUDA] ([BUYSELL],[SAUDATYPE],[DELSERVICEQTY]) INCLUDE ([TRANDATE],[SECURITY],[QTY],[RATE],[BROKERAGE],[SERVICETAX],[TOLEVY],[DelServiceTax],[DlvServiceChargePerQty],[derivedsduty])  
 CREATE NONCLUSTERED INDEX idxdet2 ON [#SAUDA] ([SECURITY])  
   
  CREATE TABLE [#psp_SAUDA]  
 (   pkslno integer not null identity(1,1)                     ,  
  [TRANSACTIONNO] [int] NOT NULL,                          
  [TRANDATE] [datetime] NOT NULL,                          
  [PRODUCT] [char](10) NOT NULL,                          
  [GROUPCODE] [char](2) NOT NULL,                          
  [STTLYEAR] [int] NOT NULL,                          
  [STTLNO] [int] NOT NULL,                          
  [CLIENTID] [int] NOT NULL,                          
  [SECURITY] [char](10) NOT NULL,                          
  [BUYSELL] [char](1) NOT NULL,                          
  [QTY] [int] NOT NULL,                          
  [RATE] [numeric](15, 4) NULL,                           
  [BROKERAGE] [numeric](15, 2) NULL,                            
  [SERVICETAX] [numeric](15, 2) NULL,                          
  [TOLEVY] [numeric](15, 4) NULL,                        
  [StampDuty] [numeric](18, 2) ,                           
  [SAUDATYPE] [varchar](10) NULL,                                 
  [DELSERVICEQTY] [int] NULL,                          
  [DelServiceTax] [numeric](18, 3) NULL,                          
  [DlvServiceChargePerQty] [numeric](15, 2) ,                        
  [TurnoverTaxSalesSpec] [numeric](15, 2) NULL,                             
  [TurnoverTaxPurchaseDlv] [numeric](15, 2) NULL,                         
  [TurnoverTaxSalesDlv] [numeric](15, 2) NULL,  
  [DerivedsDuty] numeric(20,2) not null default 0,  
  [Stampdutyper] numeric(10,10) not null default 0,  
  primary key(pkslno)  
 )  
 Create index IdxTRANSACTIONNO on #psp_SAUDA(TRANSACTIONNO)                                        
 Create index IdxDtls on #psp_SAUDA(Trandate,Security,buysell,Saudatype,Transactionno,Qty,DELSERVICEQTY)                                        
 CREATE NONCLUSTERED INDEX idxdet1 ON [#psp_SAUDA] ([BUYSELL],[SAUDATYPE],[DELSERVICEQTY]) INCLUDE ([TRANDATE],[SECURITY],[QTY],[RATE],[BROKERAGE],[SERVICETAX],[TOLEVY],[DelServiceTax],[DlvServiceChargePerQty],[derivedsduty])  
   
                                    
 set @loc=Rtrim(@loc1)                                    
                                  
 if Rtrim(@loc)=''                                       
  Select  @loc = curlocation  from    client (Nolock)                                    
  where clientid = @cid                       
                                                
 --Set @Ecess = 0.03      
 --Set @SPStampduty = 0.00002                                                
--Set @DLvStampduty = 0.0001                            
                                    
 if @StoreForTrading='Y'                                    
  insert into Rpt_average_exec_log(Clientid ) values (@cid)        
 --To Find The Client Transfer History Jiji 17.02.2009                                        
                                         
 set @oldcln = @cid                         
                                        
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step.1'  --Log                          
                                          
 Insert  into #oldclnsdet ( clientid )                                    
 Values  ( @oldcln )                                        
               
 While @oldcln > 0                                     
 Begin                                        
  set @oldcln1 = 0           
                                       
  select  @oldcln1 = isnull(Clientid, 0) from    inacln (Nolock)                                    
  Where (Toclientid = @oldcln)   and (isnull(clientid,'') <> isnull(Toclientid,''))                                       
                                        
  Set @oldcln = @oldcln1                                        
                                  
  if @oldcln > 0         
  Begin                                    
   Insert  into #oldclnsdet ( clientid )                               
   Values  ( @oldcln )          
                                       
   set @trfr='Y'  --MOD:001        
  End        
 End          
         
 if @trfr='Y'      --MOD:001        
 begin        
  Insert  into #oldclnsdet ( clientid )                                           
  Select clientid from inacln (Nolock)        
  where toclientid  = @cid and clientid not in (Select clientid from #oldclnsdet )        
 end                                      
                                             
 if @cid=1290496214       -- AP Kurian Old accounts jiji 04.10.2012 / Satish menon                          
 Begin                          
  Insert  into #oldclnsdet ( clientid )  Values  ( 1290212361 )                                        
  Insert  into #oldclnsdet ( clientid )  Values  ( 1001824 )                                        
  Insert  into #oldclnsdet ( clientid )  Values  ( 2001466 )                  
  Insert  into #oldclnsdet ( clientid )  Values  ( 1290030776 )                                        
  Insert  into #oldclnsdet ( clientid )  Values  ( 171773 )                                        
  /* Select * from #oldclnsdet                          
  ORder by clientid                          
  */                          
 end                          
                                 
 if @cid=1290496225       -- Lizy Kurian Old accounts jiji 04.10.2012 / Satish menon                          
 Begin                          
  Insert  into #oldclnsdet ( clientid )  Values  ( 1290030798 )                                        
  Insert  into #oldclnsdet ( clientid )  Values  ( 1290048961 )          
  Insert  into #oldclnsdet ( clientid )  Values  ( 170951 )             
  Insert  into #oldclnsdet ( clientid )  Values  ( 1290004688 )                                        
                                     
  /*Select * from #oldclnsdet                          
  ORder by clientid                          
  */                          
 end                          
                           
 set @oldcln1 = 0  
  
 Insert  into #Caction ( Security , Multiplier , SplitDate, CA_Type)                                    
 select  BoSecCode , Multiplier , NDFrom, CA_Type                          
 from    Ret_Stock_Split  (Nolock)                          
 Where   Multiplier <> 0                                    
 and Isnull(BoSecCode, '') <> ''                             
 And NDFrom <= @ToDate  
 union all  
 select 'secLast',0,DATEADD(DAY,1, @ToDate),'AfterCA'  
 order by NDFrom asc  
  
 Insert  into #Sauda (  
 [TRANSACTIONNO],  
 [TRANDATE],  
 [PRODUCT],  
 [GROUPCODE],  
 [STTLYEAR],  
 [STTLNO],  
 [CLIENTID],  
 [SECURITY],  
 [BUYSELL],  
 [QTY],  
 [RATE],  
 [BROKERAGE],  
 [SERVICETAX],  
 [TOLEVY],  
 [StampDuty],  
 [SAUDATYPE],  
 [DELSERVICEQTY],  
 [DelServiceTax],  
 [DlvServiceChargePerQty],  
 [TurnoverTaxSalesSpec],  
 [TurnoverTaxPurchaseDlv],  
 [TurnoverTaxSalesDlv],  
 [DerivedsDuty],  
 [Stampdutyper])                            
  Select [TRANSACTIONNO],  
 [TRANDATE],  
 [PRODUCT],  
 [GROUPCODE],  
 [STTLYEAR],  
 [STTLNO],  
 [CLIENTID],  
 [SECURITY],  
 [BUYSELL],  
 [QTY],  
 [RATE],  
 [BROKERAGE],  
 [SERVICETAX],  
 [TOLEVY],  
 [StampDuty],  
 [SAUDATYPE],  
 [DELSERVICEQTY],  
 [DelServiceTax],  
 [DlvServiceChargePerQty],  
 [TurnoverTaxSalesSpec],  
 [TurnoverTaxPurchaseDlv],  
 [TurnoverTaxSalesDlv],  
 0,  
 0   from Sauda with(Nolock)                                    
  Where   ( Clientid in (select distinct Clientid From #oldclnsdet) )                                    
   and ( Trandate >= @FromDate )                                    
   And ( Trandate <= @ToDate )                           
   And (SaudaType='NOR')  -- jiji 07.06.2011 To avoid closing and opening entries                           
                and SECURITY=@securitykey
                                           
  if (@StoreForTrading='N') and (@EnableLog='Y')                          
   Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
   Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step2'  --Log                          
                                   
  If @Fyearstart>@FromDate                          
  Begin                            
   Insert  into #Sauda (  
 [TRANSACTIONNO],  
 [TRANDATE],  
 [PRODUCT],  
 [GROUPCODE],  
 [STTLYEAR],  
 [STTLNO],  
 [CLIENTID],  
 [SECURITY],  
 [BUYSELL],  
 [QTY],  
 [RATE],  
 [BROKERAGE],  
 [SERVICETAX],  
 [TOLEVY],  
 [StampDuty],  
 [SAUDATYPE],  
 [DELSERVICEQTY],  
 [DelServiceTax],  
 [DlvServiceChargePerQty],  
 [TurnoverTaxSalesSpec],  
 [TurnoverTaxPurchaseDlv],  
 [TurnoverTaxSalesDlv],  
 [DerivedsDuty],  
 [Stampdutyper])                                                         
   Select [TRANSACTIONNO],  
 [TRANDATE],  
 [PRODUCT],  
 [GROUPCODE],  
 [STTLYEAR],  
 [STTLNO],  
 [CLIENTID],  
 [SECURITY],  
 [BUYSELL],  
 [QTY],  
 [RATE],  
 [BROKERAGE],  
 [SERVICETAX],  
 [TOLEVY],  
 [StampDuty],  
 [SAUDATYPE],  
 [DELSERVICEQTY],  
 [DelServiceTax],  
 [DlvServiceChargePerQty],  
 [TurnoverTaxSalesSpec],  
 [TurnoverTaxPurchaseDlv],  
 [TurnoverTaxSalesDlv],  
 0,  
 0  from  Saudaback(Nolock)                                    
   Where   ( Clientid in (select distinct Clientid From #oldclnsdet) )                 
    and ( Trandate >= @FromDate )                                    
    And ( Trandate <= @ToDate )                           
    And (SaudaType='NOR')    and SECURITY=@securitykey
 -- jiji 07.06.2011 To avoid closing and opening entries                                       
  End  
  
  INSERT INTO #SAUDA  
   SELECT [TRANSACTIONNO],  
 [TRANDATE],  
 '' [PRODUCT],  
 '' [GROUPCODE],  
 0 [STTLYEAR],  
 0 [STTLNO],  
 [CLIENTID],  
 [SECURITY],  
 [BUYSELL],  
 [QTY],  
 CASE WHEN NetRate = 0 THEN 0.01 ELSE NetRate END,  
 0 [BROKERAGE],  
 0 [SERVICETAX],  
 0 [TOLEVY],  
 0 [StampDuty],  
 'NOR' [SAUDATYPE],  
 Qty AS [DELSERVICEQTY],  
 0 [DelServiceTax],  
 0 [DlvServiceChargePerQty],  
 0 [TurnoverTaxSalesSpec],  
 0 [TurnoverTaxPurchaseDlv],  
 0 [TurnoverTaxSalesDlv],  
 0,  
 0   
 from    ClientAdditionalPortFolio with(Nolock)                                    
 Where   ( Clientid in (select distinct Clientid From #oldclnsdet) )                                        
 and ( Trandate >= @FromDate )             
    And ( Trandate <= @ToDate )   
     and SECURITY=@securitykey

  
 --Jiji 03.03.2023 to optimize  
  
 
  
   Alter table #Caction  
   add todel char(1) not null default 'Y'  
  
   update #Caction set  todel='N' where security='secLast'  
  
   update t set t.todel='N'   
   from #Caction t  
   join (select SECURITY, MIN(TranDate) as TranDate from #Sauda GROUP BY SECURITY) s  
   on t.security=s.SECURITY  
   WHERE t.SplitDate >= s.TranDate  
  
   delete from #Caction where todel='Y'  
  
   Select @mintrandt =min(Trandate) from #Sauda  
  
   delete from #Caction where SplitDate< @mintrandt  
  
  
 --if @RefId=636092  
 --Begin  
 --  select * from #Caction  
 --  return  
 --End  
 --Jiji 03.03.2023 to optimize  
  
  
 declare @curSecurity Varchar(10)                                        
 declare @curMultiplier Numeric(15, 3)  
 declare @curSplitDate datetime  
 declare @caType varchar(15)                                        
 declare @updateFlag int  
 set @updateFlag = 0  
  
                               
 declare StockCaActionCursor cursor for select Security,Multiplier,SplitDate,CA_Type From #Caction  
 order by SplitDate, Security, case when CA_Type='SPLIT' then 1 else 2 end  
 open StockCaActionCursor                                 
 fetch next from StockCaActionCursor into @curSecurity,@curMultiplier,@curSplitDate, @catype                                        
 WHILE @@FETCH_STATUS = 0                                     
 begin  
  
  if(@PreviousCADate <> @FromDate)  
  begin  
  set @FromDate = @PreviousCADate  
  end  
  
 set @ToDate = DATEADD(MILLISECOND,-3,DATEADD(DAY,0, DATEDIFF(DAY,0,@curSplitDate)))  
                                  
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step1'  --Log                          
                                                     
 Insert  into #psp_Sauda(  
  [TRANSACTIONNO],  
  [TRANDATE],  
  [PRODUCT],  
  [GROUPCODE],  
  [STTLYEAR],  
  [STTLNO],  
  [CLIENTID],  
  [SECURITY],  
  [BUYSELL],  
  [QTY],  
  [RATE],  
  [BROKERAGE],  
  [SERVICETAX],  
  [TOLEVY],  
  [StampDuty],  
  [SAUDATYPE],  
  [DELSERVICEQTY],  
  [DelServiceTax],  
  [DlvServiceChargePerQty],  
  [TurnoverTaxSalesSpec],  
  [TurnoverTaxPurchaseDlv],  
  [TurnoverTaxSalesDlv],  
  [DerivedsDuty],  
  [Stampdutyper]  
 )  
 Select [TRANSACTIONNO],  
  [TRANDATE],  
  [PRODUCT],  
  [GROUPCODE],  
  [STTLYEAR],  
  [STTLNO],  
  [CLIENTID],  
  [SECURITY],  
  [BUYSELL],  
  [QTY],  
  [RATE],  
  [BROKERAGE],  
  [SERVICETAX],  
  [TOLEVY],  
  [StampDuty],  
  [SAUDATYPE],  
  [DELSERVICEQTY],  
  [DelServiceTax],  
  [DlvServiceChargePerQty],  
  [TurnoverTaxSalesSpec],  
  [TurnoverTaxPurchaseDlv],  
  [TurnoverTaxSalesDlv],  
  [DerivedsDuty],  
  [Stampdutyper]    
  from #Sauda(Nolock)  
        Where ( Trandate > @FromDate )                                    
     And ( Trandate <= @ToDate )  
     And (SaudaType='NOR')  -- jiji 07.06.2011 To avoid closing and opening entries   
                    
      if (@StoreForTrading='N') and (@EnableLog='Y')                          
      Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
       Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step3'  --Log  
  
 --------------------Added by sudheer for split the stampduty         
 select s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid,        
  Sum(Qty) Qty,Sum(Stampduty) Stampduty,Sum(Stampduty) / Sum(Qty * Rate)  stampdutyper         
 into #saudatestNew  
 from #psp_sauda S               
 group by s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
 having  Sum(Qty * Rate) > 0              
              
 select Security, s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid,        
  Sum(Qty * Rate) vol,Sum(Stampduty) Stampduty         
 into #Findaveragesduty              
 from #psp_sauda s              
 Group by Security, s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
 having  Sum(Qty * Rate) > 0              
                
 alter table #Findaveragesduty add stampdutyper numeric(10,6) not null default 0  
              
 Update A              
 set A.stampdutyper = b.stampdutyper              
 from #Findaveragesduty A inner join #saudatestNew B         
 on a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID                
              
  
 update a              
 set a.stampdutyper = b.stampdutyper , derivedsduty = (a.Qty * a.Rate) *  b.stampdutyper               
 from #psp_sauda a inner join  #saudatestNew b         
 on a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID              
              
 select Sum(stampduty) - Sum(derivedsduty) DiffSDuty,Sum(stampduty) stampduty,        
  Sum(derivedsduty) derivedsduty,Max(TRANSACTIONNO) TRANSACTIONNO,              
  s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid         
 into #FinalSduty              
 from #psp_sauda s              
 group by s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
              
 Update A              
 Set a.derivedsduty = a.derivedsduty + b.DiffSDuty              
 from #psp_sauda a inner join #FinalSduty b         
 on  a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID          
  and a.TRANSACTIONNO = b.TRANSACTIONNO  
  
 ------------------Added by sudheer for split the stampduty              
                     
 --To Find The Client Transfer History Jiji 17.02.2009        
 Insert into #charges(Trandate,Security,Volume,Qty,TurnoverTaxSalesSpec,                          
  TurnoverTaxPurchaseDlv,TurnoverTaxSalesDlv, DelVol)                          
 Select Trandate,Security,Sum(Qty*Rate) Volume,sum(qty) Qty,        
  Sum(TurnoverTaxSalesSpec) TurnoverTaxSalesSpec,                              
  Sum(TurnoverTaxPurchaseDlv) TurnoverTaxPurchaseDlv,        
  Sum(TurnoverTaxSalesDlv) TurnoverTaxSalesDlv,                              
  sum(DelserviceQty*Rate) DelVol    
 From  #psp_sauda (Nolock)                      
 Group by trandate,Security   
   
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step4'  --Log                          
                              
 Select Trandate,Security,buysell,min(Transactionno) Transactionno          
 into #Transactionno         
 From  #psp_sauda (Nolock)                               
 Where DELSERVICEQTY>0                                    
 Group by trandate,Security,Buysell                              
                                 
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step5'  --Log                   
                             
 Select Trandate,Security,buysell,min(Transactionno) Transactionno          
 into #TransactionnoSpec         
 From  #psp_sauda (Nolock)                               
 Where (Qty-DELSERVICEQTY)>0                                    
 Group by trandate,Security,Buysell                              
                          
 if (@StoreForTrading='N') and (@EnableLog='Y')            
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step6'  --Log                          
                              
                              
 Update #charges set #charges.BuyTranno = #Transactionno.Transactionno         
 from #Transactionno,#charges                              
 Where                              
  (#charges.Trandate=#Transactionno.Trandate) and                              
  (#charges.Security=#Transactionno.Security)  and                              
(#Transactionno.buysell='B')                                
                              
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step7'  --Log                 
                              
 Update #charges set #charges.SellTranno = #Transactionno.Transactionno         
 from #Transactionno,#charges                              
 Where                              
  (#charges.Trandate=#Transactionno.Trandate) and                              
  (#charges.Security=#Transactionno.Security) and                              
  (#Transactionno.buysell='S')                                
                                  
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step8'  --Log                          
                              
 Update #charges set #charges.BuyTranno = #TransactionnoSpec.Transactionno         
 from #TransactionnoSpec,#charges                              
 Where                              
  (#charges.Trandate=#TransactionnoSpec.Trandate) and                              
  (#charges.Security=#TransactionnoSpec.Security)  and                   
  (#TransactionnoSpec.buysell='B') and                              
  (#charges.BuyTranno=0)                            
                                 
 if (@StoreForTrading='N') and (@EnableLog='Y')                    
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step9'  --Log                     
     
 Update #charges set #charges.SellTranno = #TransactionnoSpec.Transactionno         
 from #TransactionnoSpec,#charges                 
 Where                              
  (#charges.Trandate=#TransactionnoSpec.Trandate) and                              
  (#charges.Security=#TransactionnoSpec.Security) and                              
  (#TransactionnoSpec.buysell='S')  and                               
  (#charges.SellTranno=0)                              
                              
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step10'  --Log                          
                         
 --Added by sudheer on 03082015 for correct the exact levy                              
 Select Trandate,product,Groupcode,(sum(Tolevy)*100)/Sum(Qty*Rate)  Tolevy,                  
 Sum(Tolevy)/Sum(Qty) LevyForOne into #Tolevy From #psp_SAUDA                              
 Group by Trandate,product,Groupcode                   
 --Added by sudheer on 03082015 for correct the exact levy                           
                                      
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step11'  --Log                          
                    
 Update #charges set #charges.Tolevy = Round(#Tolevy.Tolevy,5,1) from #Tolevy,#charges                              
 Where                              
 (#charges.Trandate=#Tolevy.Trandate)                   
                         
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step12'  --Log                          
                              
 Update #charges set  SpecTolevy = ((Volume-DelVol) *Tolevy *0.01),                          
 DlvTolevy  = (DelVol *Tolevy *0.01)                                
                          
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                  
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step13'  --Log                          
                            
 Update #psp_sauda set TurnoverTaxSalesSpec=0,TurnoverTaxPurchaseDlv=0,TurnoverTaxSalesDlv=0,Tolevy=0                             
 Where (TurnoverTaxSalesSpec+TurnoverTaxPurchaseDlv+TurnoverTaxSalesDlv+Tolevy)>0                     
                          
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step14'  --Log                          
                             
 Update  S set S.TurnoverTaxSalesSpec=C.TurnoverTaxSalesSpec ,                          
  S.TurnoverTaxSalesDlv=C.TurnoverTaxSalesDlv,                          
  S.Tolevy=C.SpecTolevy                          
 From #psp_sauda S,#charges C                              
 Where                              
  (S.Trandate=C.Trandate) and                               
  (S.Security=C.Security) and                               
  (S.Transactionno=C.SellTranno)  
                          
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)        
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step15'  --Log    
                              
 Update  S set S.TurnoverTaxPurchaseDlv=C.TurnoverTaxPurchaseDlv ,                          
 S.Tolevy=C.DlvTolevy         
 From #psp_sauda S,#charges C                              
 Where                              
  (S.Trandate=C.Trandate) and                               
  (S.Security=C.Security) and                               
  (S.Transactionno=C.BuyTranno)  
                         
 --Added by sudheer on 03082015 for correct the exact levy           
 Update S set S.Tolevy = (S.qty * C.LevyForOne)                  
 From #psp_sauda S inner join #tolevy C         
 on S.Product = C.product and S.Groupcode = C.Groupcode         
 and S.Trandate=C.Trandate  
   
 --Added by sudheer on 03082015 for correct the exact levy                           
                               
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step16'  --Log                          
                                       
 --Purchase         
 Insert  into #Temp                         
 Select  Security,Trandate,'NORMAL TRADE' ,              
  Sum(delserviceqty) ,                                  
  Sum((delserviceqty * Rate)),          
  Sum((delserviceqty * Brokerage))+ Sum(delserviceqty * Isnull(DlvServiceChargePerQty, 0)),                               
  Sum(((Servicetax/Qty)*(delserviceqty)) + DelserviceTax) ,              
  --+ Sum(((Servicetax/Qty)*(delserviceqty)) + DelserviceTax) * @Ecess,                                   
  -- + Sum(TurnoverTaxPurchaseDlv + TurnoverTaxSalesDlv)                              
  Sum(TOLEVY),              
  Sum(Isnull(derivedsduty, 0))               
 from    #psp_sauda (Nolock)                                    
 Where (Buysell = 'B') and (Saudatype = 'NOR')         
  and (delserviceqty>0)   
 Group By Security ,Trandate                    
              
                             
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step17'   --Log                          
                                
 Insert  into #Temp  (Security,Trandate,SaudaType,Qty,Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                                       
 Select  Security ,Trandate ,'AUCTION TRADE' ,                                    
  Sum(Qty) ,                
  Sum(Qty * Rate),                        
  Sum(Qty * Brokerage),                                    
  Sum(Servicetax) + Sum(EducationalCessSTax) ,                                   
  -- + Sum(TurnoverTax)                         
  Sum(TOLEVY),                        
  Sum(StampDuty)                                    
 from    AuctionSauda (Nolock)                                    
 Where   Clientid in ( Select    clientid                                    
 from      #oldclnsdet )                                    
  and Buysell = 'B'                                    
  And Trandate > @FromDate                                    
  And Trandate <= @ToDate     and SECURITY=@securitykey
                                  
 Group By Security,Trandate                                                
                                        
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step18'  --Log      
  
    Insert  into #Temp (Security,Trandate,SaudaType,Qty,Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                                        
 Select  Security , Trandate , 'manual' , Qty ,                                          
  Value,0,0,0,0                                         
 from    tax_Profit_Buynotfound_Manual (Nolock)                                          
 Where   ClientId in ( Select    clientid                                          
 from      #oldclnsdet )                                          
  And Trandate >= @FromDate                                          
 -- And Trandate <= @ToDate 
 AND MONTH(Trandate) <= MONTH(@ToDate)             
 --Insert  into #Temp (Security,Trandate,SaudaType,Qty,Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                    
 --Select  Security , Trandate , Saudatype , Qty ,                                    
 -- ( Qty * NetRate ),0,0,0,0                                   
 --from    ClientAdditionalPortFolio with(Nolock)                                    
 --Where   Clientid in ( Select    clientid                                    
 --from      #oldclnsdet )                                    
 -- and Buysell = 'B'                                    
 -- And Trandate > @FromDate                                    
 -- And Trandate <= @ToDate                                                
                                     
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step19'  --Log                   
                                                
 -- To Show Details                                       
 Insert  Into #TrnDetails                      
 ( Security , Trandate , SaudaType ,Bqty ,                               
  BValue , Sqty , SValue)                                    
 Select  Security , Trandate , SaudaType , Qty ,                                    
  Value , 0 , 0                                    
 from    #Temp                                                
                                               
 Insert  into #Purchase ( Security , Trandate , Qty ,               
 Value, Brokerage, ServiceTax, ExchangeLevy, StampDuty)                                    
 Select  Security , Trandate , Sum(Qty) ,                      
  Sum(Value),sum(Brokerage), sum(ServiceTax),                        
  sum(ExchangeLevy), sum(StampDuty)                                    
 From    #Temp                                    
 Group By Security ,Trandate                   
                         
 Insert into #Purchase (Trandate,Security,Qty,Value,Brokerage,        
  ServiceTax,ExchangeLevy,StampDuty)                        
 select t.doa,s.security,t.quantity,t.coa,t.brokerages,        
  t.servicetax,t.exchangelevy,t.stampduty           
 from TaxClientwiseNonMarketEntry t(nolock),security s(nolock)                        
 where t.isin=s.isinno --and s.sectype='EQ'               
  and t.trantype in ('OffMktIn','Buy')
    and t.Clientid=@cid    and s.SECURITY=@securitykey

  --and t.refid=@RefId                        
                           
 --Sales                                               
 Truncate Table #Temp          
                                               
 Insert  into #Temp                                    
 Select  Security , Trandate , 'NORMAL TRADE' , Sum(delserviceqty) ,                                    
  Sum(delserviceqty * Rate), Sum(delserviceqty * Brokerage)+ Sum(delserviceqty *DlvServiceChargePerQty) ,                             
  Sum((Servicetax/qty)*delserviceqty + DelserviceTax) ,               
  --+ Sum((Servicetax/qty)*delserviceqty + DelserviceTax) * @Ecess  ,                                  
  --  + Sum( TurnoverTaxPurchaseDlv+ TurnoverTaxSalesDlv)                                    
  Sum(TOLEVY), Sum(isnull(derivedsduty,0))                                    
 from #psp_sauda (Nolock)                                    
 Where (Buysell = 'S') and (Saudatype = 'NOR')         
  and (delserviceqty>0)                           
 Group By Security,Trandate                   
                
 Insert  into #Temp (Security,Trandate,SaudaType,Qty,        
  Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                   
 Select  Security , Trandate , 'AUCTION TRADE' , Sum(Qty) ,                       
  Sum(Qty * Rate), Sum(Qty * Brokerage), Sum(Servicetax) + Sum(EducationalCessSTax)  ,                                  
  -- + Sum(TurnoverTax)                         
  Sum(TOLEVY), Sum(StampDuty)                
 from    AuctionSauda (Nolock)                                    
Where   Clientid in ( Select    clientid from   #oldclnsdet )                  
  and Buysell = 'S'              
  And Trandate > @FromDate                                    
  And Trandate <= @ToDate    and SECURITY=@securitykey
                                   
 Group By Security , Trandate                                            
                                                
 --Insert  into #Temp (Security,Trandate,SaudaType,Qty,Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                                    
 --Select  Security , Trandate , Saudatype , Qty , ( Qty * NetRate ) ,0,0,0,0                                   
 --from    ClientAdditionalPortFolio (Nolock)                                    
 --Where   Clientid in ( Select    clientid from      #oldclnsdet )                                    
 -- and Buysell = 'S'                                    
 -- And Trandate > @FromDate                                    
 -- And Trandate <= @ToDate                                                
                                                
 -- To Show Details                                                
 Insert  Into #TrnDetails ( Security , Trandate , SaudaType , Bqty , BValue , Sqty , SValue)                                    
 Select  Security , Trandate , SaudaType , 0 , 0 , Qty , Value        
 from    #Temp                                                
                                               
 Insert  into #Sales ( Security , Trandate , Qty ,        
  Value , Brokerage, ServiceTax, ExchangeLevy, StampDuty)                                    
 Select  Security , Trandate , Sum(Qty) ,             
  Sum(Value), sum(Brokerage), sum(ServiceTax), sum(ExchangeLevy), sum(StampDuty)                                     
 From    #Temp                                    
 Group By Security , Trandate                    
                                                
 Insert into #Sales (Trandate,Security,Qty,Value,Brokerage,ServiceTax,ExchangeLevy,StampDuty)                        
 select t.doa,s.security,t.quantity,t.coa,t.brokerages,t.servicetax,t.exchangelevy,t.stampduty                        
 from TaxClientwiseNonMarketEntry t(nolock),security s(nolock)                        
 where t.isin=s.isinno --and s.sectype = 'EQ'               
  and t.trantype in ('Sell')    and s.SECURITY=@securitykey

    and t.Clientid=@cid --by akshara  

  --and t.refid=@RefId                                               
  
                                                  
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step20'  --Log                     
                       
                         
                          
 -- Allocation                                                
 Declare @Pqty Numeric(15, 2)                                              
 Declare @Pslno Numeric(15, 2)                     
 Declare @Sqty Numeric(15, 2)                                          
 Declare @Sslno Numeric(15, 2)                                                
 Declare @sec Varchar(10)                                                
                                                   
 --CAllocatedSellQty added  
Declare Pur Cursor for                                                
 Select Security,Slno,Qty-CAllocatedSellQty from #Purchase Where (Qty-CAllocatedSellQty)>0 and IsLatest = 1   
 Open Pur  
 Fetch Next From Pur into @sec,@Pslno,@Pqty                                                
 WHILE @@FETCH_STATUS = 0                         
 Begin                                                
  Declare Sl Cursor for                        
  Select Slno,Qty-AllocatedPurchaseQty from #Sales Where Security=@sec  and (Qty-AllocatedPurchaseQty)>0  
  Open Sl                                                
  Fetch Next From Sl into @Sslno,@Sqty                            
  WHILE @@FETCH_STATUS = 0                                     
  Begin                                            
If @Pqty > 0                         
   Begin                 
    If @Sqty >= @Pqty           
    Begin                                                
     Update  #Sales Set     AllocatedPurchaseQty = AllocatedPurchaseQty + @Pqty  
     Where   Security = @sec And Slno = @Sslno                        
        
     Update  #Purchase Set     AllocatedSellQty = AllocatedSellQty + @Pqty, CAllocatedSellQty = AllocatedSellQty + @Pqty  
     Where   Security = @sec  And Slno = @Pslno          
                                                 
     Set @Pqty = 0                             
    End                                                
    Else                                     
    Begin                                          
     Update  #Sales Set     AllocatedPurchaseQty = AllocatedPurchaseQty+@Sqty                                    
     Where   Security = @sec And Slno = @Sslno                           
        
     Update  #Purchase Set     AllocatedSellQty = AllocatedSellQty+@Sqty, CAllocatedSellQty = AllocatedSellQty+@Sqty  
     Where   Security = @sec And Slno = @Pslno          
                                            
     Set @Pqty = @Pqty - @Sqty                                   
    End                                                
   End                                         
   Fetch Next From Sl into @Sslno,@Sqty                                                
  End                                                
  Close Sl                                                
  Deallocate Sl                                                
  Fetch Next From Pur into @sec,@Pslno,@Pqty                         
 End                                                 
 Close Pur                                              
 Deallocate Pur                                               
  
update #Purchase set BalanceQuantity = Qty-CAllocatedSellQty  
  
if(@caType<>'Bonus' and @caType<>'AfterCA')  
 begin  
 if(exists(select 1  
 from #Purchase (nolock)  
 where BalanceQuantity>0 and [Security]=@curSecurity and Trandate<=@ToDate))  
 begin  
  Insert into #Purchase (Trandate,[Security],Qty,Value,Brokerage,        
  ServiceTax,ExchangeLevy,StampDuty,cactiondoneon)  
  
  select Trandate,[security],BalanceQuantity*@curMultiplier,(Value/Qty)*BalanceQuantity,(Brokerage/Qty)*BalanceQuantity,        
  (servicetax/Qty)*BalanceQuantity,(exchangelevy/Qty)*BalanceQuantity,(stampduty/Qty)*BalanceQuantity, getdate()  
  from #Purchase (nolock)                        
  where BalanceQuantity>0 and [Security]=@curSecurity and Trandate<=@ToDate  
  
  update #purchase set BalanceQuantity = 0, CAllocatedSellQty=qty  
  where BalanceQuantity>0 and [Security]=@curSecurity and Trandate<=@ToDate and cactiondoneon is null  
   
  set @updateFlag = 1  
 end  
  end  
 else if(@caType='Bonus')  
 begin  
  Insert into #Purchase (Trandate,Security,Qty,Value,Brokerage,        
 ServiceTax,ExchangeLevy,StampDuty)       
 select @curSplitDate,t.security,sum(t.BalanceQuantity)*(@curMultiplier-1),0,0,0,0,0  
 from #Purchase t(nolock)                        
 where t.BalanceQuantity<>0 and t.Security=@curSecurity and t.Trandate<=@ToDate  
 group by t.security  
  
  set @updateFlag = 1  
  
  end  
 else if(@caType='AfterCA')  
 begin  
 set @updateFlag = 1  
 end  
  
 if(@updateFlag=1)  
begin  
set @updateFlag = 0  
  
;with cte_purchase  
 as  
 (  
 select ROW_NUMBER() OVER(PARTITION BY TranDate ORDER by Slno desc) as RowNo,*  
 from #Purchase  
 where Security = @curSecurity  
 )  
update cte_purchase set IsLatest = 0 where RowNo > 1 and cactiondoneon is not null  
  
Declare Purchase Cursor for                                                
 Select Security,Slno,Qty-CAllocatedSellQty from #Purchase Where (Qty-CAllocatedSellQty)>0  and Trandate<=@ToDate    and IsLatest = 1                                           
 Open Purchase                                                
 Fetch Next From Purchase into @sec,@Pslno,@Pqty                                                
 WHILE @@FETCH_STATUS = 0                         
 Begin         
 Declare Sales Cursor for                        
 Select Slno,Qty-AllocatedPurchaseQty from #Sales Where Security=@sec  and (Qty-AllocatedPurchaseQty)>0 and Trandate<=@ToDate                                              
 Open Sales                                                
 Fetch Next From Sales into @Sslno,@Sqty                                                
 WHILE @@FETCH_STATUS = 0                                     
 Begin                                                
 If @Pqty > 0                                     
 Begin                   
 If @Sqty >= @Pqty                                     
 Begin                                                
  Update  #Sales Set     AllocatedPurchaseQty = AllocatedPurchaseQty + @Pqty                                    
  Where   Security = @sec And Slno = @Sslno                        
        
  Update  #Purchase Set     AllocatedSellQty = AllocatedSellQty + @Pqty, CAllocatedSellQty = CAllocatedSellQty + @Pqty  
  Where   Security = @sec  And Slno = @Pslno          
                                      
  Set @Pqty = 0                             
 End                                                
 Else                                     
 Begin                                          
  Update  #Sales Set     AllocatedPurchaseQty = AllocatedPurchaseQty+@Sqty                                    
  Where   Security = @sec And Slno = @Sslno                           
        
  Update  #Purchase Set     AllocatedSellQty = AllocatedSellQty+@Sqty, CAllocatedSellQty = CAllocatedSellQty+@Sqty  
  Where   Security = @sec And Slno = @Pslno              
                                            
  Set @Pqty = @Pqty - @Sqty                                   
 End                                                
 End                                         
 Fetch Next From Sales into @Sslno,@Sqty                                                
 End                                                
 Close Sales                                                
 Deallocate Sales                                                
 Fetch Next From Purchase into @sec,@Pslno,@Pqty                         
 End          
 Close Purchase                                                
 Deallocate Purchase  
 end  
--End  
  set @PreviousCADate = @ToDate  
  update #Purchase set BalanceQuantity = Qty-CAllocatedSellQty  
  
  truncate table #charges  
  truncate table #Temp  
  truncate table #TrnDetails  
  truncate table #psp_SAUDA  
  drop table #Findaveragesduty  
  drop table #FinalSduty  
  drop table #Transactionno  
  drop table #TransactionnoSpec  
  drop table #Tolevy  
  drop table #saudatestNew   
    
 if (@StoreForTrading='N') and (@EnableLog='Y')                          
  Insert into Log_SpGenerateTradingPandL(cid,FromDate,ToDate,loc1,FromWeb,StoreForTrading,Remarks)                          
  Select @cid , @FromDate,@ToDate,@loc1,@FromWeb ,@StoreForTrading,'Step21'  --Log        
  
  fetch next from StockCaActionCursor into  @curSecurity,@curMultiplier,@curSplitDate, @catype                                        
 end  
  
 close StockCaActionCursor                                        
 deallocate StockCaActionCursor  
  
 drop table #Caction  
  
 /* Calculating duty and levy */  
 select s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid,        
  Sum(Qty) Qty,Sum(Stampduty) Stampduty,Sum(Stampduty) / Sum(Qty * Rate)  stampdutyper         
 into #saudatestNew_copy  
 from #sauda S               
 group by s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
 having  Sum(Qty * Rate) > 0              
              
 select Security, s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid,        
  Sum(Qty * Rate) vol,Sum(Stampduty) Stampduty         
 into #Findaveragesduty_copy              
 from #sauda s              
 Group by Security, s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
 having  Sum(Qty * Rate) > 0              
                
 alter table #Findaveragesduty_copy add stampdutyper numeric(10,6) not null default 0  
              
 Update A              
 set A.stampdutyper = b.stampdutyper              
 from #Findaveragesduty_copy A inner join #saudatestNew_copy B         
 on a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID  
  
 update a              
 set a.stampdutyper = b.stampdutyper , derivedsduty = (a.Qty * a.Rate) *  b.stampdutyper               
 from #sauda a inner join  #saudatestNew_copy b         
 on a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID  
              
              
 select Sum(stampduty) - Sum(derivedsduty) DiffSDuty,Sum(stampduty) stampduty,        
  Sum(derivedsduty) derivedsduty,Max(TRANSACTIONNO) TRANSACTIONNO,              
  s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid         
 into #FinalSduty_copy              
 from #sauda s              
 group by s.Trandate,s.Product,s.GroupCode,s.Sttlyear,s.Sttlno,s.Clientid              
              
 Update A              
 Set a.derivedsduty = a.derivedsduty + b.DiffSDuty              
 from #sauda a inner join #FinalSduty_copy b         
 on  a.TRANDATE = b.TRANDATE and a.PRODUCT = b.PRODUCT         
  and a.GROUPCODE = b.GROUPCODE and a.STTLNO = b.STTLNO         
  and a.STTLYEAR = b.STTLYEAR and a.CLIENTID = b.CLIENTID          
  and a.TRANSACTIONNO = b.TRANSACTIONNO  
  
 ------------------Added by sudheer for split the stampduty              
                     
 --To Find The Client Transfer History Jiji 17.02.2009        
 Insert into #charges(Trandate,Security,Volume,Qty,TurnoverTaxSalesSpec,                          
  TurnoverTaxPurchaseDlv,TurnoverTaxSalesDlv, DelVol)                          
 Select Trandate,Security,Sum(Qty*Rate) Volume,sum(qty) Qty,        
  Sum(TurnoverTaxSalesSpec) TurnoverTaxSalesSpec,                              
  Sum(TurnoverTaxPurchaseDlv) TurnoverTaxPurchaseDlv,        
  Sum(TurnoverTaxSalesDlv) TurnoverTaxSalesDlv,                              
  sum(DelserviceQty*Rate) DelVol         
 From  #sauda (Nolock)                                    
 Group by trandate,Security                         
                              
 Select Trandate,Security,buysell,min(Transactionno) Transactionno          
 into #Transactionno_copy         
 From  #sauda (Nolock)                               
 Where DELSERVICEQTY>0                                    
 Group by trandate,Security,Buysell                      
                             
 Select Trandate,Security,buysell,min(Transactionno) Transactionno          
 into #TransactionnoSpec_copy         
 From  #sauda (Nolock)                               
 Where (Qty-DELSERVICEQTY)>0                                    
 Group by trandate,Security,Buysell                                                   
                              
                              
 Update #charges set #charges.BuyTranno = #Transactionno_copy.Transactionno         
 from #Transactionno_copy,#charges                              
 Where                              
  (#charges.Trandate=#Transactionno_copy.Trandate) and                              
  (#charges.Security=#Transactionno_copy.Security)  and                              
  (#Transactionno_copy.buysell='B')                                
                              
 Update #charges set #charges.SellTranno = #Transactionno_copy.Transactionno         
 from #Transactionno_copy,#charges                              
 Where                              
  (#charges.Trandate=#Transactionno_copy.Trandate) and                              
  (#charges.Security=#Transactionno_copy.Security) and                              
  (#Transactionno_copy.buysell='S')                      
                              
 Update #charges set #charges.BuyTranno = #TransactionnoSpec_copy.Transactionno         
 from #TransactionnoSpec_copy,#charges                
 Where                              
  (#charges.Trandate=#TransactionnoSpec_copy.Trandate) and                        
  (#charges.Security=#TransactionnoSpec_copy.Security)  and                   
  (#TransactionnoSpec_copy.buysell='B') and                              
  (#charges.BuyTranno=0)       
                              
 Update #charges set #charges.SellTranno = #TransactionnoSpec_copy.Transactionno         
 from #TransactionnoSpec_copy,#charges                 
 Where                              
  (#charges.Trandate=#TransactionnoSpec_copy.Trandate) and                              
  (#charges.Security=#TransactionnoSpec_copy.Security) and                              
  (#TransactionnoSpec_copy.buysell='S')  and                               
  (#charges.SellTranno=0)                         
                         
 --Added by sudheer on 03082015 for correct the exact levy    
 Select Trandate,product,Groupcode,(sum(Tolevy)*100)/Sum(Qty*Rate)  Tolevy,                  
 Sum(Tolevy)/Sum(Qty) LevyForOne into #Tolevy_copy From #SAUDA                              
 Group by Trandate,product,Groupcode                   
 --Added by sudheer on 03082015 for correct the exact levy                       
                           
 Update #charges set #charges.Tolevy = Round(#Tolevy_copy.Tolevy,5,1) from #Tolevy_copy,#charges                              
 Where                              
 (#charges.Trandate=#Tolevy_copy.Trandate)  
                               
 Update #charges set  SpecTolevy = ((Volume-DelVol) *Tolevy *0.01),                          
 DlvTolevy  = (DelVol *Tolevy *0.01)                        
                            
 Update #sauda set TurnoverTaxSalesSpec=0,TurnoverTaxPurchaseDlv=0,TurnoverTaxSalesDlv=0,Tolevy=0                             
 Where (TurnoverTaxSalesSpec+TurnoverTaxPurchaseDlv+TurnoverTaxSalesDlv+Tolevy)>0                       
                             
 Update  S set S.TurnoverTaxSalesSpec=C.TurnoverTaxSalesSpec ,                          
  S.TurnoverTaxSalesDlv=C.TurnoverTaxSalesDlv,                          
  S.Tolevy=C.SpecTolevy                          
 From #sauda S,#charges C                              
 Where                              
  (S.Trandate=C.Trandate) and                               
  (S.Security=C.Security) and                               
  (S.Transactionno=C.SellTranno)  
  
 Update  S set S.TurnoverTaxPurchaseDlv=C.TurnoverTaxPurchaseDlv ,                          
 S.Tolevy=C.DlvTolevy         
 From #sauda S,#charges C                              
 Where                              
  (S.Trandate=C.Trandate) and                               
  (S.Security=C.Security) and                               
  (S.Transactionno=C.BuyTranno)  
                         
 --Added by sudheer on 03082015 for correct the exact levy           
 Update S set S.Tolevy = (S.qty * C.LevyForOne)                  
 From #sauda S inner join #Tolevy_copy C         
 on S.Product = C.product and S.Groupcode = C.Groupcode         
 and S.Trandate=C.Trandate  
 /* End of Calculating duty and levy */  
  
 --set @ToDate=+right(@FiscYear,4)+'-03-31'  
  
 Insert  Into #SumTemp                                    
 (         
  Trandate,             
  Security ,                                    
  SQPurchaseQty ,                       
  SQPurchaseValue ,                        
  SQPurchaseBrokerage,                        
  SQPurchaseServiceTax,                    
  SQPurchaseExchangeLevy,                        
  SQPurchaseStampDuty,                                    
  BalPurchaseQty ,                                    
  BalPurchaseValue                                    
 )                                    
 Select  TranDate,Security ,                              
  AllocatedSellQty ,                                    
  case when Qty = 0 then 0 else ( AllocatedSellQty * ( Value / Qty ) ) end ,                           
  case when Qty = 0 then 0 else ( AllocatedSellQty * ( Brokerage / Qty ) ) end ,                          
  case when Qty = 0 then 0 else ( AllocatedSellQty * ( ServiceTax / Qty ) ) end ,                        
  case when Qty = 0 then 0 else ( AllocatedSellQty * ( ExchangeLevy / Qty ) ) end ,                         
  case when Qty = 0 then 0 else ( StampDuty ) end ,                                 
  ( Qty - AllocatedSellQty ) ,                    
  case when Qty = 0 then 0 else ( Qty - AllocatedSellQty ) * ( Value / Qty ) end                          
 From    #Purchase                       
                                           
 Insert  Into #SumTemp                                    
 (         
  TranDate,                        
  Security ,                             
  SQSaleQty ,                                    
  SQSaleValue ,                        
  SQSaleBrokerage,                        
  SQSaleServiceTax,                        
  SQSaleExchangeLevy,                        
  SQSaleStampDuty,                                     
  BalSaleQty ,                                    
  BalSaleValue                               
 )                                    
 Select  TranDate,Security ,                                    
  AllocatedPurchaseQty ,                                    
  case when Qty = 0 then 0 else ( AllocatedPurchaseQty * ( Value / Qty ) ) end ,                              
  --case when Qty = 0 then 0 else ( AllocatedPurchaseQty * ( Brokerage / Qty ) ) end ,                          
  --case when Qty = 0 then 0 else ( AllocatedPurchaseQty * ( ServiceTax / Qty ) ) end ,                         
  --case when Qty = 0 then 0 else ( AllocatedPurchaseQty * ( ExchangeLevy / Qty ) ) end , 
   case when Qty = 0 then 0 else case when  AllocatedPurchaseQty=0 then  (( Brokerage / Qty ) )  else  ( AllocatedPurchaseQty * ( Brokerage / Qty ) ) end end,         
  case when Qty = 0 then 0 else case when  AllocatedPurchaseQty=0 then  (( ServiceTax / Qty ) )  else  (AllocatedPurchaseQty * ( ServiceTax / Qty ) ) end end,                               
  case when Qty = 0 then 0 else case when  AllocatedPurchaseQty=0 then  (( ExchangeLevy / Qty ) )  else ( AllocatedPurchaseQty * ( ExchangeLevy / Qty ) ) end  end,       
  case when Qty = 0 then 0 else (StampDuty ) end ,                             
  ( Qty - AllocatedPurchaseQty ) ,                                    
  case when Qty = 0 then 0 else ( Qty - AllocatedPurchaseQty ) * ( Value / Qty ) end                                   
 From    #Sales               
 ----end of modificTION ----------------------------------------------                        
  
 -----Speculative Trades 16.02.2011           
 Insert  into #TempSpec (Security,Trandate,SaudaType,BuyQty,BuyValue,Brokerage,ServiceTax,ExchangeLevy,StampDuty,Buysell)  /*-*/                                  
 Select Security , Trandate , 'NORMAL TRADE SPEC' ,                                    
  Sum(Qty-delserviceqty) , Sum((Qty-delserviceqty) * Rate),              
  Sum((Qty-delserviceqty) * Brokerage), Sum((Qty-delserviceqty) * (Servicetax/qty) ) ,              
  --+ Sum((Servicetax/qty)*(Qty-delserviceqty) ) * @Ecess ,                                              
  Sum(TOLEVY), Sum(derivedsduty), Buysell                
 from    #Sauda (Nolock)                                    
 Where (Buysell = 'B')  and (Saudatype = 'NOR' )         
  and ((Qty-delserviceqty)>0)  --and   Security = 'UTIBAN'                          
 Group By Trandate,Security ,Buysell                     
               
 -- To Show Details                                                
 --Insert  Into #TrnDetails                                    
 --        ( Security ,                                    
 --        Trandate ,                                    
 --          SaudaType ,                                    
 --          Bqty ,                                    
 --          BValue ,                                    
 --          Sqty ,                                    
 --          SValue                                    
 --  )                                    
 --        Select  Security ,                                    
 --                Trandate ,                                    
 --                SaudaType ,                                   
 --                BuyQty ,                                    
 --                BuyValue ,                                    
 --                0 ,                                    
 --                0                                    
 --        from    #TempSpec             
                                         
 --Sales                       
 Insert  into #TempSpec (Security,Trandate,SaudaType,SellQty,SellValue,Brokerage,ServiceTax,ExchangeLevy,StampDuty,Buysell) /*-*/               
 Select  Security ,Trandate ,'NORMAL TRADE SPEC' ,                                    
  Sum(Qty-delserviceqty) ,Sum((Qty-delserviceqty) * Rate) ,                               
  Sum((Qty-delserviceqty) * Brokerage),Sum((Servicetax/qty)*(Qty-delserviceqty) )  ,              
  -- + Sum((Servicetax/qty)*(Qty-delserviceqty) ) * @Ecess,                                    
  Sum(TOLEVY) ,Sum(derivedsduty), Buysell                      
 from    #Sauda (Nolock)                                   
 Where (Buysell = 'S')  and (Saudatype = 'NOR' ) and         
  ((Qty-delserviceqty)>0)   -- and   Security = 'UTIBAN'                           
 Group By Trandate,Security ,Buysell  
                            
 Delete from #TempSpec where Trandate<@finstart             
 Delete from #TempSpec where Trandate>@todate  
                               
 --Insert  Into #TrnDetails                                    
 --        ( Security ,                                    
 --          Trandate ,                                    
 --          SaudaType ,                                    
 --          Bqty ,                                    
 --          BValue ,                                    
 --          Sqty ,                                    
 --          SValue                                    
 --        )                                    
 --        Select  Security ,                                    
 --       Trandate ,                                    
 --                SaudaType ,                                    
 --                0 ,                                    
 --                0 ,                                    
 --                SellQty ,                                 
 --                SellValue                                    
 --        from    #TempSpec                  
                                        
 Select Trandate,Security,Buysell,Sum(BuyQty) BuyQty, Sum(BuyValue) BuyValue,Sum(SellQty) SellQty,                               
  Sum(SellValue) SellValue, Sum(SellValue)-Sum(BuyValue) Profit,'N' Exist ,                  
  Sum(Brokerage) Brokerage,Sum(ServiceTax) ServiceTax ,Sum(ExchangeLevy) ExchangeLevy,        
  Sum(StampDuty) StampDuty,Sum(StampDuty) derivedsduty              
 into #TempProfit                   
 from  #TempSpec                                 
 Group by Trandate,Security,Buysell  
                    
 Alter table #TempProfit add Expense Numeric(15,4)                  
                    
 Update #TempProfit set profit  = profit- (Brokerage+ServiceTax+ExchangeLevy+StampDuty),                  
 Expense =  (Brokerage+ServiceTax+ExchangeLevy+StampDuty)                
                
 -- To Show Details                              
                       
 /*-*/                    
 select A.Trandate,A.Security,A.BuyQty,A.BuyValue,B.SellQty,B.SellValue,                   
  A.Brokerage BuyBrokerage,A.ServiceTax BuyServiceTax,A.ExchangeLevy BuyExchangeLevy,        
  A.StampDuty BuyStampDuty,B.Brokerage SaleBrokerage,B.ServiceTax SaleServiceTax,        
  B.ExchangeLevy SaleExchangeLevy,B.StampDuty SaleStampDuty,                  
  A.Expense BuyExpense,B.Expense SaleExpense, (A.Profit+B.Profit) Profit                
 Into #TempProfitSpec                  
 from #TempProfit A,#TempProfit B                  
 where A.Security=B.Security And                  
  A.trandate=B.Trandate And A.BuyQty=B.SellQty And                  
  A.Buysell='B' And B.Buysell='S'                  
 Order by A.Security  
  
 Create table #profit                        
 (        
  Type varchar(16),                        
  Profit Numeric(15,2) not null default 0        
 )        
                         
 Insert into #profit                        
 select 'Speculation',isnull(sum(profit),0) from #TempProfitSpec                        
                         
 select * into #sumtempbal from #sumtemp where balsaleqty <> 0       
                   
 Delete from #sumtempbal where Trandate<@finstart         
 Delete from #sumtempbal where Trandate>@todate                        
               declare @OtherCharges decimal(10,2)=0;
	  declare @balqty decimal(10,2)=0;            
 --Insert into tax_Profit_Buynotfound (RefId,Clientid,Trandate,Security,ISIN,Qty,Euser)                        
 --select @RefId,@cid,trandate,t.security,s.isinno,balsaleqty,'system'         
 --from #sumtempbal t,security s(nolock)                        
 --where t.security=s.security          
 
 INSERT INTO tax_Profit_Buynotfound_TDS (Clientid, Trandate, Security, ISIN, Qty, Euser, SellValue, OtherCharges, Profit,isActive)
	SELECT @cid, trandate, t.security, s.isinno, balsaleqty, 'system', BalSaleValue,
    CASE
        WHEN SQSaleQty > 0 THEN SUM(SQSaleBrokerage / SQSaleQty + SQSaleServiceTax / SQSaleQty + SQSaleExchangeLevy / SQSaleQty + SQSaleStampDuty) * @balqty
        ELSE SUM(SQSaleBrokerage + SQSaleServiceTax + SQSaleExchangeLevy + SQSaleStampDuty) * BalSaleQty
    END,
    CASE
        WHEN SQSaleQty > 0 THEN BalSaleValue - SUM(SQSaleBrokerage / SQSaleQty + SQSaleServiceTax / SQSaleQty + SQSaleExchangeLevy / SQSaleQty + SQSaleStampDuty) * @balqty
        ELSE BalSaleValue - SUM(SQSaleBrokerage + SQSaleServiceTax + SQSaleExchangeLevy + SQSaleStampDuty) * BalSaleQty
    END,1
	FROM #sumtempbal t
	JOIN security s (NOLOCK) ON t.security = s.security
	GROUP BY trandate, t.security, s.isinno, balsaleqty, BalSaleValue, t.SQSaleQty
	HAVING (SQSaleQty) <> 0; -- Added condition to avoid division by zero

                    
 Alter table #sumtemp add TranDateBuy datetime                        
                  
                         
 ----Select Trandate,Security,SQPurchaseQty,SQPurchaseValue,                        
 ----SQPurchaseBrokerage+SQPurchaseServiceTax+SQPurchaseExchangeLevy+SQPurchaseStampDuty as SQPurchaseExpense,                        
 ----SQSaleQty,SQSaleValue,SQSaleBrokerage,SQSaleServiceTax,SQSaleExchangeLevy,SQSaleStampDuty,TranDateBuy into #sumtemporder from #sumtemp                        
 ----order by TranDate,Security                      
                   
 Insert into #sumtemporder                
 Select Trandate,Security,SQPurchaseQty,SQPurchaseValue,                        
  SQPurchaseBrokerage,SQPurchaseServiceTax,SQPurchaseExchangeLevy,SQPurchaseStampDuty, /*as SQPurchaseExpense,*/                  
  SQSaleQty,SQSaleValue,SQSaleBrokerage,SQSaleServiceTax,        
  SQSaleExchangeLevy,SQSaleStampDuty,TranDateBuy          
 from #sumtemp                        
 order by TranDate,Security                      
                
alter table #sumtemporder add SQstampdutyper numeric(10,6) not null default 0              
              
 Update A Set A.SQstampdutyper = B.stampdutyper              
 from #sumtemporder A inner join #Findaveragesduty_copy b         
 on a.TranDate = b.TRANDATE and a.Security = b.SECURITY              
         
 --Select top 0 * into #sumtemporderdel from #sumtemporder  
              
                          
 --Alter table #sumtemporder Add SlNo int identity (1,1)                        
 --Alter table #sumtemporderdel Add SlNo int                                          
 if exists (select top 1 * from #sumtemporder)                       
 begin              
  Declare @SlNo int            
  Declare @Trandate datetime                        
Declare @Security varchar(20)                        
  Declare @SQPurchaseQty numeric(15,2)                        
  Declare @SQPurchaseValue numeric(15,2)                        
  Declare @SQPurchaseExpense numeric(15,4)                   
  Declare @SQPurchaseBrokerage numeric(15,4)                        
  Declare @SQPurchaseServiceTax numeric(15,4)                        
  Declare @SQPurchaseExchangeLevy numeric(15,4)                        
  Declare @SQPurchaseStampDuty numeric(15,4)                  
  Declare @SQSaleQty numeric(15,2)                         
  Declare @SQSaleValue numeric(15,2)                        
  Declare @SaleBrokerage numeric(15,4)                        
  Declare @SaleServiceTax numeric(15,4)                        
  Declare @SaleExchangeLevy numeric(15,4)                        
  Declare @SaleStampDuty numeric(15,4)                        
  Declare @StampDutyPer numeric(15,6)          
  Declare @SlNoIn int                        
  Declare @TrandateIn datetime                        
  Declare @SecurityIn varchar(20)                        
  Declare @SQPurchaseQtyIn numeric(15,2)                        
  Declare @SQPurchaseValueIn numeric(15,2)                        
  Declare @SQPurchaseExpenseIn numeric(15,4)                  
  Declare @SQPurchaseBrokerageIn numeric(15,4)                        
  Declare @SQPurchaseServiceTaxIn numeric(15,4)                        
  Declare @SQPurchaseExchangeLevyIn numeric(15,4)                        
  Declare @SQPurchaseStampDutyIn numeric(15,4)                  
  Declare @SQSaleQtyIn numeric(15,2)                         
  Declare @SQSaleValueIn numeric(15,2)                        
  Declare @SaleBrokerageIn numeric(15,4)                        
  Declare @SaleServiceTaxIn numeric(15,4)                        
  Declare @SaleExchangeLevyIn numeric(15,4)                        
  Declare @SaleStampDutyIn numeric(15,4)                 
  Declare @sqstampdutyperin numeric(15,6)                 
                           
  --Declare @SQPurchaseQtyforRate int                     
  Declare @SQPurchaseQtyforRate numeric(15,2) --Added By Samson on 06.06.2019                     
                     
  IF CURSOR_STATUS('global','SaleTranDateCur')>=-1                    
  BEGIN                        
   DEALLOCATE SaleTranDateCur             
  END                      
            
  Declare SaleTranDateCur cursor for   
  Select SlNo,Trandate,Security,SQPurchaseQty,SQPurchaseValue,        
   SQPurchaseBrokerage,SQPurchaseServiceTax,SQPurchaseExchangeLevy,SQPurchaseStampDuty,                  
   /*SQPurchaseExpense*/                        
   SQSaleQty,SQSaleValue,SQSaleBrokerage,SQSaleServiceTax,SQSaleExchangeLevy,SQSaleStampDuty,SQstampdutyper         
  from #sumtemporder           
  order by Slno         
                         
  open SaleTranDateCur                                
  fetch next from SaleTranDateCur into @SlNo,@Trandate,@Security,@SQPurchaseQty,@SQPurchaseValue,                  
   @SQPurchaseBrokerage,@SQPurchaseServiceTax,@SQPurchaseExchangeLevy,@SQPurchaseStampDuty,                  
   /*@SQPurchaseExpense,*/                  
   @SQSaleQty,@SQSaleValue,@SaleBrokerage,@SaleServiceTax,@SaleExchangeLevy,@SaleStampDuty,@StampDutyPer                      
                                      
  WHILE @@FETCH_STATUS = 0                                     
  begin                           
   if @SQSaleQty=0 and @SQPurchaseQty <> 0                        
   begin                        
    set @SQPurchaseQtyforRate=@SQPurchaseQty                        
    truncate table #sumtemporderdel                  
                      
    insert into #sumtemporderdel                        
    Select  * from #sumtemporder         
    where security=@Security and slno>@slno         
    and SQSaleQty<>0 and TranDateBuy is null                     
                                          
    Declare SaleTranDateInsideCur Cursor for Select SlNo,Trandate,Security,SQPurchaseQty,SQPurchaseValue,             
     SQPurchaseBrokerage,SQPurchaseServiceTax,SQPurchaseExchangeLevy,SQPurchaseStampDuty,                  
     /*SQPurchaseExpense,*/                        
     SQSaleQty,SQSaleValue,SQSaleBrokerage,SQSaleServiceTax,SQSaleExchangeLevy,SQSaleStampDuty,sqstampdutyper from                        
     #sumtemporderdel order by Slno                        
                                 
    Open SaleTranDateInsideCur                        
                                          
    fetch next from SaleTranDateInsideCur into @SlNoIn,@TrandateIn,@SecurityIn,@SQPurchaseQtyIn,@SQPurchaseValueIn,                        
     @SQPurchaseBrokerageIn,@SQPurchaseServiceTaxIn,@SQPurchaseExchangeLevyIn,@SQPurchaseStampDutyIn,                  
     /*@SQPurchaseExpenseIn*/                  
     @SQSaleQtyIn,@SQSaleValueIn,@SaleBrokerageIn,@SaleServiceTaxIn,@SaleExchangeLevyIn,                        
     @SaleStampDutyIn,@sqstampdutyperin                   
                                        
    Set @SQPurchaseExpense = @SQPurchaseBrokerage+@SQPurchaseServiceTax+@SQPurchaseExchangeLevy+@SQPurchaseStampDuty                       
                                          
    WHILE @@FETCH_STATUS = 0                                     
    begin                          
     If @SQPurchaseQty=@SQSaleQtyIn or @SQSaleQtyIn < @SQPurchaseQty                        
     begin                                     
      Insert into #sumtemporderfinal         
      values (@SlNo,@Trandate,@Security,@SQSaleQtyIn,@SQSaleQtyIn*(@SQPurchaseValue/@SQPurchaseQtyforRate),                        
       @SQSaleQtyIn*(@SQPurchaseExpense/@SQPurchaseQtyforRate),                          
       /*--*/ @SQSaleQtyIn*(@SQPurchaseBrokerage/@SQPurchaseQtyforRate)  ,                  
       @SQSaleQtyIn*(@SQPurchaseServiceTax/@SQPurchaseQtyforRate)  ,                  
       @SQSaleQtyIn*(@SQPurchaseExchangeLevy/@SQPurchaseQtyforRate)  ,                  
       /*--*/ --@SQSaleQtyIn*(@SQPurchaseStampDuty/@SQPurchaseQtyforRate)  ,                    
       --@SQPurchaseStampDuty,              
       (@SQSaleQtyIn*(@SQPurchaseValue/@SQPurchaseQtyforRate)) * @sqstampdutyperin,              
            
       @TrandateIn,@SQSaleQtyIn,@SQSaleValueIn,@SQSaleQtyIn*(@SaleBrokerageIn/@SQSaleQtyIn),                        
       @SQSaleQtyIn*(@SaleServiceTaxIn/@SQSaleQtyIn),     
       @SQSaleQtyIn*(@SaleExchangeLevyIn/@SQSaleQtyIn),                        
  --@SQSaleQtyIn*(@SaleStampDutyIn/@SQSaleQtyIn))               
       -- @SaleStampDutyIn)              
       (@SQSaleValueIn) * @sqstampdutyperin)              
                                              
      Update #sumtemporder         
      set TranDateBuy=@Trandate,SQPurchaseQty=@SQSaleQtyIn,                        
       SQPurchaseValue=@SQSaleQtyIn*(@SQPurchaseValue/@SQPurchaseQtyforRate)                        
      where Slno=@SlNoIn                        
                               
      set @SQPurchaseQty=@SQPurchaseQty-@SQSaleQtyIn                        
                                                 
      if @SQPurchaseQty=0                        
       truncate table #sumtemporderdel                        
     end                  
     else                        
     If @SQSaleQtyIn > @SQPurchaseQty and @SQPurchaseQty<>0                        
     begin                                  
      Insert into #sumtemporderfinal         
      values                        
       (@SlNo,@Trandate,@Security,@SQPurchaseQty,@SQPurchaseQty*(@SQPurchaseValue/@SQPurchaseQtyforRate),                  
       @SQPurchaseQty*(@SQPurchaseExpense/@SQPurchaseQtyforRate),                         
       @SQPurchaseQty*(@SQPurchaseBrokerage/@SQPurchaseQtyforRate)  ,                  
       @SQPurchaseQty*(@SQPurchaseServiceTax/@SQPurchaseQtyforRate) ,                  
       @SQPurchaseQty*(@SQPurchaseExchangeLevy/@SQPurchaseQtyforRate) ,                  
       -- @SQPurchaseQty*(@SQPurchaseStampDuty/@SQPurchaseQtyforRate) ,              
       -- @SQPurchaseStampDuty,                         
       (@SQPurchaseQty*(@SQPurchaseValue/@SQPurchaseQtyforRate)) * @sqstampdutyperin ,              
                       
       @TrandateIn,@SQPurchaseQty,@SQPurchaseQty*(@SQSaleValueIn/@SQSaleQtyIn),                        
       @SQPurchaseQty*(@SaleBrokerageIn/@SQSaleQtyIn),@SQPurchaseQty*(@SaleServiceTaxIn/@SQSaleQtyIn),                        
       @SQPurchaseQty*(@SaleExchangeLevyIn/@SQSaleQtyIn),              
       --@SaleStampDutyIn              
       (@SQPurchaseQty*(@SQSaleValueIn/@SQSaleQtyIn)) * @sqstampdutyperin               
      )              
      --@SQPurchaseQty*(@SaleStampDutyIn/@SQSaleQtyIn))                        
                                  
      Update #sumtemporder         
      set SQSaleQty=SQSaleQty-@SQPurchaseQty,                        
       SQSaleValue=(SQSaleQty-@SQPurchaseQty)*(@SQSaleValueIn/@SQSaleQtyIn),                        
       SQSaleBrokerage= (SQSaleQty-@SQPurchaseQty)*(@SaleBrokerageIn/@SQSaleQtyIn),                        
       SQSaleServiceTax= (SQSaleQty-@SQPurchaseQty)*(@SaleServiceTaxIn/@SQSaleQtyIn),                        
       SQSaleExchangeLevy= (SQSaleQty-@SQPurchaseQty)*(@SaleExchangeLevyIn/@SQSaleQtyIn),                        
       --SQSaleStampDuty= (SQSaleQty-@SQPurchaseQty)*(@SaleStampDutyIn/@SQSaleQtyIn)                        
       --SQSaleStampDuty= @SaleStampDutyIn              
       SQSaleStampDuty = ((SQSaleQty-@SQPurchaseQty)*(@SQSaleValueIn/@SQSaleQtyIn))*(@sqstampdutyperin)                 
      where Slno=@SlNoIn                        
                               
      set @SQSaleQtyIn=@SQSaleQtyIn-@SQPurchaseQty          
      set @SQPurchaseQty=0                        
                                                  
      truncate table #sumtemporderdel                        
     end                         
                                             
     fetch next from SaleTranDateInsideCur into @SlNoIn,@TrandateIn,@SecurityIn,@SQPurchaseQtyIn,@SQPurchaseValueIn,                        
     @SQPurchaseBrokerageIn,@SQPurchaseServiceTaxIn,@SQPurchaseExchangeLevyIn,@SQPurchaseStampDutyIn,                  
     /*@SQPurchaseExpenseIn,*/                  
     @SQSaleQtyIn,@SQSaleValueIn,@SaleBrokerageIn,@SaleServiceTaxIn,@SaleExchangeLevyIn,@SaleStampDutyIn, @sqstampdutyperin          
    end         
    
    Close SaleTranDateInsideCur                  
  Deallocate SaleTranDateInsideCur                        
   end         
                        
   fetch next from SaleTranDateCur into @SlNo,@Trandate,@Security,@SQPurchaseQty,@SQPurchaseValue,                  
   @SQPurchaseBrokerage,@SQPurchaseServiceTax,@SQPurchaseExchangeLevy,@SQPurchaseStampDuty,                  
   /*@SQPurchaseExpense,*/                  
   @SQSaleQty,@SQSaleValue,@SaleBrokerage,@SaleServiceTax,@SaleExchangeLevy,@SaleStampDuty ,@StampDutyPer                                        
  end         
                                    
  close SaleTranDateCur                         
  deallocate SaleTranDateCur                  
  -- Cursor to get date wise buy sell  --- By Sunil on 21.12.2012  --- End         
 end                     
                       
 Delete from #sumtemporderfinal where Trandatesale<@finstart                        
 Delete from #sumtemporderfinal where Trandatesale>@todate                   
                        
 Alter table #sumtemporderfinal add DayToSell int                         
 Alter table #sumtemporderfinal add Profit Numeric(15,2)                        
                           
 Update #sumtemporderfinal set DayToSell=datediff(day,trandateBuy,TranDateSale)                        
                           
 Update #sumtemporderfinal set Profit=(SaleValue-(SaleBrokerage+SaleServiceTax+SaleExchangeLevy+saleStampDuty)) -   
                                      (BuyValue+(PurchaseBrokerage+PurchaseServiceTax+PurchaseExchangeLevy+PurchaseStampDuty)) --MOD:003                  
                                                                 
 Insert into #profit                        
 Select 'Short Term',isnull(sum(profit),0) from #sumtemporderfinal where DayToSell<=365                        
                           
 Insert into #profit                        
 Select 'Long Term',isnull(sum(profit),0) from #sumtemporderfinal where DayToSell>365                           
                      
 Alter table #TempProfitSpec add ISIN varchar(32)  , Description varchar(126)     -- Added by Abdul Samad On 19.07.2017 for GBNPP_SUP-1542                                       
           
 update #TempProfitSpec set ISIN=s.isinno,Description = S.Description         
 from #TempProfitSpec t,security s (nolock)               -- Added by Abdul Samad On 19.07.2017 for GBNPP_SUP-1542          
 where t.security=s.security                        
                     
 Alter table #sumtemporderfinal add ISIN varchar(32) , Description varchar(126)   -- Added by Abdul Samad On 19.07.2017 for GBNPP_SUP-1542                       
                          
 update #sumtemporderfinal set ISIN=s.isinno,Description = S.Description         
 from #sumtemporderfinal t,security s (nolock) -- Added by Abdul Samad On 19.07.2017 for GBNPP_SUP-1542                       
 where t.security=s.security       
                          
 Declare @foclientid int                        
 Declare @FOProfit Numeric(15,2)                        
 Declare @CDSProfit Numeric(15,2)                        
                          
 Select @foclientid=foclientid from foclient (nolock) where clientid=@cid                        
                          
                 
 Insert into #profit         
 values ('F&O',isnull(@FOProfit,0))                        
                          
 Insert into #profit         
 values ('CDS',isnull(@CDSProfit,0))                        
   
              
 Insert into Tax_Profit_Details_Cash_TDS                        
  (clientid,type,TranDateBuy,Security,ISIN,BuyQty,BuyValue,TranDateSale,        
  SaleQty,SaleValue,Profit,Euser,LastUpdatedOn,PurchaseBrokerage,PurchaseServiceTax,        
  PurchaseExchangeLevy,PurchaseStampDuty,BuyExpense,SaleBrokerage,SaleServiceTax,        
  SaleExchangeLevy,SaleStampDuty,SellExpense,Description)                        
 select @cid,'Speculation',Trandate,Security,ISIN,CEILING(BuyQty),BuyValue,Trandate,        
  CEILING(SellQty),SellValue,Profit,'System',getdate(),        -- Added by Abdul Samad On 05.05.2017 CEILING added for Buy and sell qty          
  BuyBrokerage,BuyServiceTax,BuyExchangeLevy,BuyStampDuty,BuyExpense,SaleBrokerage,        
  SaleServiceTax,SaleExchangeLevy,SaleStampDuty,saleExpense ,Description                 
 from #TempProfitSpec order by security  
                      
 Insert into Tax_Profit_Details_Cash_TDS                        
  (clientid,type,TranDateBuy,Security,ISIN,BuyQty,BuyValue,TranDateSale,        
  SaleQty,SaleValue,DayToSell,Profit,Euser,LastUpdatedOn,PurchaseBrokerage,        
  PurchaseServiceTax,PurchaseExchangeLevy,PurchaseStampDuty,BuyExpense,        
  SaleBrokerage,SaleServiceTax,SaleExchangeLevy,SaleStampDuty,SellExpense,Description)                        
 Select @cid,'Short Term',TranDateBuy,Security,ISIN,CEILING(BuyQty),BuyValue,TranDateSale,        
  CEILING(SaleQty),SaleValue,DayToSell,Profit,-- Added by Abdul Samad On 05.05.2017 CEILING added for Buy and sell qty          
  'System',getdate(),PurchaseBrokerage,PurchaseServiceTax,PurchaseExchangeLevy,PurchaseStampDuty,          
  (PurchaseBrokerage+PurchaseServiceTax+PurchaseExchangeLevy+PurchaseStampDuty),SaleBrokerage,SaleServiceTax,SaleExchangeLevy,          
  SaleStampDuty,(SaleBrokerage+SaleServiceTax+SaleExchangeLevy+SaleStampDuty),Description                    
 from #sumtemporderfinal where DayToSell<=365          
                          
 Insert into Tax_Profit_Details_Cash_TDS                        
  (clientid,type,TranDateBuy,Security,ISIN,BuyQty,BuyValue,TranDateSale,        
  SaleQty,SaleValue,DayToSell,Profit,Euser,LastUpdatedOn,PurchaseBrokerage,        
  PurchaseServiceTax,PurchaseExchangeLevy,PurchaseStampDuty,BuyExpense,        
  SaleBrokerage,SaleServiceTax,SaleExchangeLevy,SaleStampDuty,SellExpense,Description)          
 Select @cid,'Long Term',TranDateBuy,Security,ISIN,CEILING(BuyQty),BuyValue,TranDateSale,        
  CEILING(SaleQty),SaleValue,DayToSell,Profit,-- Added by Abdul Samad On 05.05.2017 CEILING added for Buy and sell qty          
  'System',getdate(),PurchaseBrokerage,PurchaseServiceTax,PurchaseExchangeLevy,PurchaseStampDuty,          
  (PurchaseBrokerage+PurchaseServiceTax+PurchaseExchangeLevy+ PurchaseStampDuty),        
  SaleBrokerage,SaleServiceTax,SaleExchangeLevy,          
  SaleStampDuty,(SaleBrokerage+SaleServiceTax+SaleExchangeLevy+SaleStampDuty),Description          
 from #sumtemporderfinal where DayToSell>365          
 

 drop table #SumTbl
 drop table #SumTemp
 drop table #charges
 drop table #Sales
 drop table #Purchase
 drop table #Temp
drop table #Profit
 drop table #TempSpec
 drop table #tempprofit
 drop table #TempProfitSpec
 drop table #Sumtempbal
 drop table #sumtemporder
 drop table #sumtemporderdel
 drop table #sumtemporderfinal
 drop table #oldclnsdet
 drop table #TrnDetails
 drop table #SAUDA
 drop table #psp_sauda
 drop table #saudatestNew_copy
 drop table #Findaveragesduty_copy
 drop table #FinalSduty_copy
 drop table #Transactionno_copy
 drop table #TransactionnoSpec_copy
 drop table #Tolevy_copy
          FETCH NEXT FROM ClientCursor INTO @cid, @securitykey      
End   
  CLOSE ClientCursor
    DEALLOCATE ClientCursor
    --DROP TABLE #tempclient
  end
  