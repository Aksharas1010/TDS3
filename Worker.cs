using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.Entity;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using ClosedXML.Excel;
using DocumentFormat.OpenXml.Office.Word;
using DocumentFormat.OpenXml.Wordprocessing;
using GenerateTDSService.DTO;
using GenerateTDSService.Model;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using GenerateTDSService.Utils;
using System.Runtime.InteropServices.ComTypes;

namespace GenerateTDSService
{
    internal class Worker : BackgroundService
    {
        private static readonly object _object = new object();

        private readonly ILogger<Worker> _logger;
        public Worker(ILogger<Worker> logger) => (_logger) = (logger);
        PnLInputModel pnLInputModel_for_log = null;
        static int queryTimeout = !string.IsNullOrEmpty(ConfigurationManager.AppSettings["queryTimeout"]) ?
        Convert.ToInt32(ConfigurationManager.AppSettings["queryTimeout"]) : 4800;
        //void Run()
        //{
        //    List<string> files = new List<string>();
        //    using (GCCEntities gcc = new GCCEntities())
        //    {
        //        gcc.Database.CommandTimeout = queryTimeout;
        //        DateTime currentDate = DateTime.Now;
        //        int financialYearStartMonth = 4;
        //        var finyear = "";
        //        if (currentDate.Month < financialYearStartMonth)
        //        {
        //            int financialYearStart = currentDate.Year - 1;
        //            int financialYearEnd = currentDate.Year;
        //            finyear = financialYearStart + "-" + financialYearEnd;
        //        }
        //        else
        //        {
        //            int financialYearStart = currentDate.Year;
        //            int financialYearEnd = currentDate.Year + 1;
        //            finyear = financialYearStart + "-" + financialYearEnd;
        //        }
        //        //string formattedDate = currentDate.ToString("yyyy-MM-dd");
        //        string formattedDate = "2023-09-25";
        //        var todDateParam = new SqlParameter("@todate", SqlDbType.VarChar, 20) { Value = formattedDate };
        //        var clientIdParam = new SqlParameter("@clientid", SqlDbType.Int) { Value = DBNull.Value };

        //        var customerModels = gcc.Database.SqlQuery<TDSNROCMCustomerModel>(
        //            "exec SpGetTDSClientDetails @todate, @clientid",
        //            todDateParam, clientIdParam
        //        ).ToList();
        //        if (customerModels.Count < 0)
        //        {
        //            _logger.LogInformation($"No NRO CM customer have sell transaction on : {formattedDate}");
        //            return;
        //        }
        //        var customercount = 0;
        //        foreach (var item in customerModels)
        //        {
        //            customercount++;
        //            var query = $"EXEC SpTax_GeneratePandL_TDS '{formattedDate}','{formattedDate}','{item.ClientId}'";
        //            _logger.LogInformation($"Starts for client: {item.ClientId} on: {DateTime.Now}\n Query: {query}");
        //            _logger.LogInformation($"{query} started at {DateTime.Now}.");
        //            var equityResult = gcc.Database.SqlQuery<PnLOutputModel>(query).ToList();
        //            _logger.LogInformation($"{query} ended at {DateTime.Now}.");



        //            var TaxComputationQuery = $"exec SpGetTDSCalculated '{formattedDate}','{item.ClientId}','{finyear}'";
        //            //var TaxComputationQuery = $"exec SpGetTDSCalculated '{formattedDate}',1291197392,'{finyear}'";
        //            var TaxComputedlist = gcc.Database.SqlQuery<TDSReturn>(TaxComputationQuery).ToList();
        //            if (TaxComputedlist.Count > 0)
        //            {
        //                var fileName = GenerateTDSReport(TaxComputedlist, formattedDate, item.ClientId);
        //                //var fileName = GenerateTDSReport(TaxComputedlist, formattedDate, 1291197392);
        //                files.Add(fileName);
        //                var clientsforTDSQuery = $"exec SpGetTDSEmailClientDetails '{item.ClientId}'";
        //                var computationRefernceModel = gcc.Database.SqlQuery<ClientModel>(clientsforTDSQuery).ToList();
        //                if (computationRefernceModel != null)
        //                {
        //                    var emailSubject = $"Trade Details " + DateTime.Now.Date;
        //                    var isSuccess = SendEmailEmailToClientWithAttachment(fileName + ".pdf", computationRefernceModel[0].ClientEmail, "", "", emailSubject, "Client", computationRefernceModel[0].TradeCode);
        //                    if (isSuccess)
        //                    {
        //                        int cid = item.ClientId;
        //                        string queryout = "EXEC SpUpdateProcessedRequest @todate, @clientid, @result OUTPUT";
        //                        SqlParameter paramTodate = new SqlParameter("@todate", formattedDate);
        //                        SqlParameter paramClientId = new SqlParameter("@clientid", cid);
        //                        SqlParameter paramResult = new SqlParameter("@result", SqlDbType.Int);
        //                        paramResult.Direction = ParameterDirection.Output;
        //                        var updateresult = gcc.Database.SqlQuery<returnmodel>(queryout, paramTodate, paramClientId, paramResult).ToList();
        //                        int resultValue = Convert.ToInt32(paramResult.Value);
        //                        if (resultValue != 1 && resultValue != 0)
        //                        {
        //                            _logger.LogInformation($"failed   to lock the client process" + computationRefernceModel[0].Clientid);

        //                        }
        //                        _logger.LogInformation($"Lock the client process" + computationRefernceModel[0].Clientid);


        //                    }
        //                    else
        //                    {
        //                        _logger.LogInformation($"failed sending mail to client" + computationRefernceModel[0].Clientid);
        //                    }
        //                    // _logger.LogInformation($"Ends for Client: {computationRefernceModel[0].Clientid} on: {DateTime.Now}\n Query: {query}");

        //                }
        //            }

        //        }

        //        if (customercount == customerModels.Count)
        //        {
        //            var query = $"EXEC SpGetBuyNotFoundList '{formattedDate}'";
        //            _logger.LogInformation($"Starts BuyNot Found Mails to Branch on: {DateTime.Now}\n Query: {query}");
        //            _logger.LogInformation($"{query} started at {DateTime.Now}.");
        //            var buynotfoundlist = gcc.Database.SqlQuery<BuyNotFound>(query).ToList();
        //            _logger.LogInformation($"{query} ended at {DateTime.Now}.");
        //            if (buynotfoundlist.Count > 0)
        //            {
        //                var groupedlist = buynotfoundlist.GroupBy(x => x.LocationEmail);
        //                foreach (var items in groupedlist)
        //                {
        //                    string fileName = $"BuyNotFound_Missingdata" + "_" + finyear + DateTime.Now.ToString("yyyyMMddhhmmssfff");
        //                    string folderPath = ConfigurationManager.AppSettings["FileSavePath"];
        //                    if (!PdfGenerator.GenerateBuyNotFoundExcel(items, fileName, folderPath))
        //                    {
        //                        return;
        //                    }
        //                    var emailSubject = $"BuyNotFound data on " + DateTime.Now.Date;
        //                    var isSuccess = SendEmailEmailToClientWithAttachment(fileName + ".pdf", items.Key, "", "", emailSubject, "Branch", "");
        //                    if (!isSuccess)
        //                    {
        //                        _logger.LogInformation($"failed sending mail to Branch" + items.Key);
        //                    }
        //                    _logger.LogInformation($"Ends for Branch: {items.Key} on: {DateTime.Now}\n Query: {query}");

        //                }
        //            }

        //        }
        //    }
        //}

        private bool SendEmailEmailToClientWithAttachment(string fileName, string toEmail, string ccEmail, string name, string emailSubject, string typo, string TradeCode)
        {
            toEmail = "akshara.shylajan@simelabs.com";
            ccEmail = "akshara.shylajan@simelabs.com";
            try
            {
                using (SmtpClient SmtpServer = new SmtpClient(ConfigurationManager.AppSettings["Host"]))
                {
                    SmtpServer.UseDefaultCredentials = true;

                    SmtpServer.Port = Convert.ToInt32(ConfigurationManager.AppSettings["SMTPPort"]);
                    SmtpServer.Credentials = new System.Net.NetworkCredential(ConfigurationManager.AppSettings["SMTPUserName"], ConfigurationManager.AppSettings["SMTPPassword"]);
                    var emailTemplate = File.ReadAllText(Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location) + "\\" + ConfigurationManager.AppSettings["ClientEmailTemplatePath"]);
                    if (typo == "Branch")
                    {
                        emailTemplate = File.ReadAllText(Path.GetDirectoryName(System.Reflection.Assembly.GetEntryAssembly().Location) + "\\" + ConfigurationManager.AppSettings["EmailTemplatePath"]);

                    }
                    else
                    {
                        emailTemplate = emailTemplate.Replace("{tradecode}", TradeCode);
                        emailTemplate = emailTemplate.Replace("{date}", DateTime.Now.Date.ToString("yyyy-MM-dd"));
                    }
                    using (MailMessage mail = new MailMessage())
                    {
                        mail.From = new MailAddress(ConfigurationManager.AppSettings["FromEmail"]);
                        mail.To.Add(toEmail);
                        mail.CC.Add(ccEmail);
                        mail.Subject = emailSubject;
                        mail.Body = emailTemplate;
                        mail.BodyEncoding = Encoding.UTF8;
                        mail.IsBodyHtml = true;

                        Attachment attachment;
                        attachment = new Attachment(ConfigurationManager.AppSettings["FileSavePath"] + fileName);
                        mail.Attachments.Add(attachment);

                        SmtpServer.Send(mail);
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error occured on {DateTime.Now}, while sending TDS file for the client:{toEmail}, Error:\n {ex}");
                throw ex;
            }
        }
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                while (!stoppingToken.IsCancellationRequested)
                {
                    _logger.LogInformation("Process started");
                    //lock (_object)
                    //{
                    //    Run();
                    //}
                    var tasks = new List<Task>();
                    List<int> clientIds = new List<int>();
                    clientIds= GetClientIdsToProcess();
                    foreach (var clientId in clientIds)
                    {
                        var task = ProcessClientAsync(clientId);
                        tasks.Add(task);
                    }
                    await Task.WhenAll(tasks);                  
                    _logger.LogInformation("Process completed");
                }
            }
            catch (Exception ex)
            {
                var subject = "Error in TDS Service";
                _logger.LogError(ex.Message);
                Environment.Exit(1);
            }
        }

        public string GenerateTDSReport(List<TDSReturn> TaxComputedlist, string formatteddate, int clientid)
        {
            try
            {
                var querytransaction = $"EXEC SpGetDailyTransactions '{formatteddate}','{clientid}'";
                string fileName = $"{clientid}_{DateTime.Now.ToString("yyyyMMddhhmmssfff")}_TDSReport";
                using (GCCEntities gcc = new GCCEntities())
                {
                    var dailytransactions = gcc.Database.SqlQuery<DailyTransactions>(querytransaction).ToList();
                    var quarterlytransaction = $"EXEC SpGetQuarterlyGainForEachMonth '{formatteddate}','{clientid}'";
                    var Quartertransactions = gcc.Database.SqlQuery<QuarterSummary>(quarterlytransaction).ToList();

                    _logger.LogInformation($"{querytransaction} ended at {DateTime.Now}.");
                    string folderPath = ConfigurationManager.AppSettings["FileSavePath"];
                    string path = folderPath + fileName + ".pdf";
                    if (!Directory.Exists(folderPath))
                    {
                        Directory.CreateDirectory(folderPath);
                    }
                    if (dailytransactions.Any())
                    {
                        var pdfGenerationStatus = PdfGenerator.GenerateTDSPdf(TaxComputedlist, dailytransactions, Quartertransactions, path);
                    }
                }
                return fileName;
            }
            catch(Exception ex)
            {
                _logger.LogError(ex.Message);
                throw ex;
            }
           
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            var subject = "TDS Service is stopping";
            var message = "Stop request fired, service is stopping execution";
            var fromEmail = ConfigurationManager.AppSettings["ErrorDetailFromEmail"];
            var toEmail = ConfigurationManager.AppSettings["ErrorDetailToEmail"];

            SendErrorOrStopRequestEmail(subject, message, fromEmail, toEmail);
            await base.StopAsync(cancellationToken);
        }

        public void SendErrorOrStopRequestEmail(string emailSubject, string message, string fromEmail, string toEmail)
        {
            toEmail = "akshara.shylajan@simelabs.com";

            try
            {
                using (SmtpClient SmtpServer = new SmtpClient(ConfigurationManager.AppSettings["Host"]))
                {
                    SmtpServer.UseDefaultCredentials = true;

                    SmtpServer.Port = Convert.ToInt32(ConfigurationManager.AppSettings["SMTPPort"]);
                    SmtpServer.Credentials = new System.Net.NetworkCredential(ConfigurationManager.AppSettings["SMTPUserName"], ConfigurationManager.AppSettings["SMTPPassword"]);

                    using (MailMessage mail = new MailMessage())
                    {
                        mail.From = new MailAddress(fromEmail);
                        mail.To.Add(toEmail);
                        mail.Subject = emailSubject;
                        mail.Body = message;

                        SmtpServer.Send(mail);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error occured on {DateTime.Now}: {ex}");
            }
        }

        private List<int> GetClientIdsToProcess()
        {
            List<int> clientIds = new List<int>();
            using (GCCEntities gcc = new GCCEntities())
            {
                string formattedDate = "2023-09-25";
                var todDateParam = new SqlParameter("@todate", SqlDbType.VarChar, 20) { Value = formattedDate };
                var clientIdParam = new SqlParameter("@clientid", SqlDbType.Int) { Value = DBNull.Value };

                var customerModels = gcc.Database.SqlQuery<TDSNROCMCustomerModel>(
                    "exec SpGetTDSClientDetails @todate, @clientid",
                    todDateParam, clientIdParam
                ).ToList();
                foreach (var customerModel in customerModels)
                {
                    clientIds.Add(customerModel.ClientId);
                }
                if (clientIds.Count == 0)
                {
                    _logger.LogInformation($"No NRO CM customers have sell transactions on: {formattedDate}");
                }
                return clientIds;
            }
        }

        void Run(int ClientId)
        {
            List<string> files = new List<string>();
            using (GCCEntities gcc = new GCCEntities())
            {
                gcc.Database.CommandTimeout = queryTimeout;
                DateTime currentDate = DateTime.Now;
                int financialYearStartMonth = 4;
                var finyear = "";
                if (currentDate.Month < financialYearStartMonth)
                {
                    int financialYearStart = currentDate.Year - 1;
                    int financialYearEnd = currentDate.Year;
                    finyear = financialYearStart + "-" + financialYearEnd;
                }
                else
                {
                    int financialYearStart = currentDate.Year;
                    int financialYearEnd = currentDate.Year + 1;
                    finyear = financialYearStart + "-" + financialYearEnd;
                }
                //string formattedDate = currentDate.ToString("yyyy-MM-dd");
                string formattedDate = "2023-09-25";               
                var customercount = 0;
                customercount++;
                var query = $"EXEC SpTax_GeneratePandL_TDS '{formattedDate}','{formattedDate}','{ClientId}'";
                _logger.LogInformation($"Starts for client: {ClientId} on: {DateTime.Now}\n Query: {query}");
                _logger.LogInformation($"{query} started at {DateTime.Now} for client {ClientId}.");
                var equityResult = gcc.Database.SqlQuery<PnLOutputModel>(query).ToListAsync();
                _logger.LogInformation($"{query} ended at {DateTime.Now} for client {ClientId}.");
                 
                var TaxComputationQuery = $"exec SpGetTDSCalculated '{formattedDate}','{ClientId}','{finyear}'";
                var TaxComputedlist = gcc.Database.SqlQuery<TDSReturn>(TaxComputationQuery).ToList();
                if (TaxComputedlist.Count > 0)
                {
                    var fileName = GenerateTDSReport(TaxComputedlist, formattedDate, ClientId);
                    files.Add(fileName);
                    var clientsforTDSQuery = $"exec SpGetTDSEmailClientDetails '{ClientId}'";
                    var computationRefernceModel = gcc.Database.SqlQuery<ClientModel>(clientsforTDSQuery).ToList();
                    if (computationRefernceModel != null)
                    {
                        var emailSubject = $"Trade Details " + DateTime.Now.Date;
                        //var isSuccess = SendEmailEmailToClientWithAttachment(fileName + ".pdf", computationRefernceModel[0].ClientEmail, "", "", emailSubject, "Client", computationRefernceModel[0].TradeCode);
                        //if (isSuccess)
                        //{
                        //    int cid = ClientId;
                        //    string queryout = "EXEC SpUpdateProcessedRequest @todate, @clientid, @result OUTPUT";
                        //    SqlParameter paramTodate = new SqlParameter("@todate", formattedDate);
                        //    SqlParameter paramClientId = new SqlParameter("@clientid", cid);
                        //    SqlParameter paramResult = new SqlParameter("@result", SqlDbType.Int);
                        //    paramResult.Direction = ParameterDirection.Output;
                        //    var updateresult = gcc.Database.SqlQuery<returnmodel>(queryout, paramTodate, paramClientId, paramResult).ToList();
                        //    int resultValue = Convert.ToInt32(paramResult.Value);
                        //    if (resultValue != 1 && resultValue != 0)
                        //    {
                        //        _logger.LogInformation($"failed   to lock the client process" + computationRefernceModel[0].Clientid);

                        //    }
                        //    _logger.LogInformation($"Lock the client process" + computationRefernceModel[0].Clientid);


                        //}
                        //else
                        //{
                        //    _logger.LogInformation($"failed sending mail to client" + computationRefernceModel[0].Clientid);
                        //}
                        // _logger.LogInformation($"Ends for Client: {computationRefernceModel[0].Clientid} on: {DateTime.Now}\n Query: {query}");

                    }
                }



            }
        }
        private async Task ProcessClientAsync(int ClientId)
        {
            List<string> files = new List<string>();
            var finyear = "";
            try
            {
                using (GCCEntities gcc = new GCCEntities())
                {
                    gcc.Database.CommandTimeout = queryTimeout;
                    DateTime currentDate = DateTime.Now;
                    int financialYearStartMonth = 4;
                    
                    if (currentDate.Month < financialYearStartMonth)
                    {
                        int financialYearStart = currentDate.Year - 1;
                        int financialYearEnd = currentDate.Year;
                        finyear = financialYearStart + "-" + financialYearEnd;
                    }
                    else
                    {
                        int financialYearStart = currentDate.Year;
                        int financialYearEnd = currentDate.Year + 1;
                        finyear = financialYearStart + "-" + financialYearEnd;
                    }
                    //string formattedDate = currentDate.ToString("yyyy-MM-dd");
                    string formattedDate = "2023-09-25";
                    var customercount = 0;
                    customercount++;
                    var query = $"EXEC SpTax_GeneratePandL_TDS '{formattedDate}','{formattedDate}','{ClientId}'";
                    _logger.LogInformation($"Starts for client: {ClientId} on: {DateTime.Now}\n Query: {query}");
                    _logger.LogInformation($"{query} started at {DateTime.Now} for client {ClientId}.");
                    var equityResult = await gcc.Database.SqlQuery<PnLOutputModel>(query).ToListAsync();
                    _logger.LogInformation($"{query} ended at {DateTime.Now} for client {ClientId}.");



                    var TaxComputationQuery = $"exec SpGetTDSCalculated '{formattedDate}','{ClientId}','{finyear}'";
                    var TaxComputedlist = await gcc.Database.SqlQuery<TDSReturn>(TaxComputationQuery).ToListAsync();
                    if (TaxComputedlist.Count > 0)
                    {
                        var fileName = GenerateTDSReport(TaxComputedlist, formattedDate, ClientId);
                        files.Add(fileName);
                        var clientsforTDSQuery = $"exec SpGetTDSEmailClientDetails '{ClientId}'";
                        var computationRefernceModel = await gcc.Database.SqlQuery<ClientModel>(clientsforTDSQuery).ToListAsync();
                        if (computationRefernceModel != null)
                        {
                            var emailSubject = $"Trade Details " + DateTime.Now.Date;
                            var isSuccess = SendEmailEmailToClientWithAttachment(fileName + ".pdf", computationRefernceModel[0].ClientEmail, "", "", emailSubject, "Client", computationRefernceModel[0].TradeCode);
                            if (isSuccess)
                            {
                                int cid = ClientId;
                                string queryout = "EXEC SpUpdateProcessedRequest @todate, @clientid, @result OUTPUT";
                                SqlParameter paramTodate = new SqlParameter("@todate", formattedDate);
                                SqlParameter paramClientId = new SqlParameter("@clientid", cid);
                                SqlParameter paramResult = new SqlParameter("@result", SqlDbType.Int);
                                paramResult.Direction = ParameterDirection.Output;
                                var updateresult = gcc.Database.SqlQuery<returnmodel>(queryout, paramTodate, paramClientId, paramResult).ToList();
                                int resultValue = Convert.ToInt32(paramResult.Value);
                                if (resultValue != 1 && resultValue != 0)
                                {
                                    _logger.LogInformation($"failed   to lock the client process" + computationRefernceModel[0].Clientid);

                                }
                                _logger.LogInformation($"Lock the client process" + computationRefernceModel[0].Clientid);


                            }
                            else
                            {
                                _logger.LogInformation($"failed sending mail to client" + computationRefernceModel[0].Clientid);
                            }
                            _logger.LogInformation($"Ends for Client: {computationRefernceModel[0].Clientid} on: {DateTime.Now}\n Query: {query}");

                        }
                    }
                }
            }
            catch(Exception ex)
            {
                if (ClientId != null)
                {
                    var subject = $"Error while generating TDS for the client: {ClientId}, Year: {finyear}";
                    var message = $"Error: {ex}";
                    var fromEmail = ConfigurationManager.AppSettings["ErrorDetailFromEmail"];
                    var toEmail = ConfigurationManager.AppSettings["ErrorDetailToEmail"];
                    SendErrorOrStopRequestEmail(subject, message, fromEmail, toEmail);
                    _logger.LogError($"{subject} \nError occured on {DateTime.Now}: {ex}");                  
                }
               

            }
        }
    }
}
