//+------------------------------------------------------------------+
//|                                           TradeJournal.mqh       |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Structure for trade record                                        |
//+------------------------------------------------------------------+
struct TradeRecord
{
   ulong ticket;
   datetime openTime;
   datetime closeTime;
   string symbol;
   string orderType;
   double lots;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double closePrice;
   double profit;
   double commission;
   double swap;
   string strategy;
   string htfTrend;
   string entrySignal;
   string exitReason;
   double rsiEntry;
   double macdEntry;
   string emaAlignment;
   double rrPlanned;
   double rrActual;
   int durationMinutes;
   double mfe;  // Maximum Favorable Excursion
   double mae;  // Maximum Adverse Excursion
};

//+------------------------------------------------------------------+
//| Trade Journal Class                                               |
//+------------------------------------------------------------------+
class CTradeJournal
{
private:
   string m_symbol;
   int m_magicNumber;
   string m_fileName;
   int m_fileHandle;
   bool m_isInitialized;

   // Tracking arrays
   TradeRecord m_openTrades[];

   // Helper functions
   string GetTimestampString(datetime dt);
   string GetCSVHeader();
   string TradeRecordToCSV(TradeRecord &record);
   int FindOpenTrade(ulong ticket);

public:
   // Constructor/Destructor
   CTradeJournal();
   ~CTradeJournal();

   // Initialization
   bool Initialize(string symbol, int magic);
   void Close();

   // Trade Logging
   bool LogTradeOpen(ulong ticket, string strategy, string signal, double rsi, double macd, string emaAlign);
   bool LogTradeClose(ulong ticket, string exitReason);
   void OnTradeEvent();

   // Position Tracking
   void UpdateMaxExcursion(ulong ticket, double currentPrice);

   // Reporting
   bool GeneratePerformanceReport(ENUM_TIMEFRAMES period);
   void PrintDailyStats();
   void PrintWeeklyStats();

   // Utility
   bool IsInitialized() { return m_isInitialized; }
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTradeJournal::CTradeJournal()
{
   m_symbol = "";
   m_magicNumber = 0;
   m_fileName = "";
   m_fileHandle = INVALID_HANDLE;
   m_isInitialized = false;

   ArrayResize(m_openTrades, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTradeJournal::~CTradeJournal()
{
   Close();
}

//+------------------------------------------------------------------+
//| Initialize journal                                                |
//+------------------------------------------------------------------+
bool CTradeJournal::Initialize(string symbol, int magic)
{
   m_symbol = symbol;
   m_magicNumber = magic;

   // Create filename with timestamp
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   m_fileName = StringFormat("TradeJournal_%s_%d_%04d%02d%02d.csv",
                             symbol, magic, dt.year, dt.mon, dt.day);

   // Check if file exists
   bool fileExists = false;
   int handle = FileOpen(m_fileName, FILE_READ | FILE_CSV);

   if(handle != INVALID_HANDLE)
   {
      fileExists = true;
      FileClose(handle);
   }

   // Open file for writing (append mode)
   m_fileHandle = FileOpen(m_fileName, FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI);

   if(m_fileHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to open trade journal file: ", m_fileName);
      Print("Error code: ", GetLastError());
      return false;
   }

   // Write header if new file
   if(!fileExists)
   {
      FileSeek(m_fileHandle, 0, SEEK_END);
      FileWrite(m_fileHandle, GetCSVHeader());
   }
   else
   {
      // Position at end of file for appending
      FileSeek(m_fileHandle, 0, SEEK_END);
   }

   m_isInitialized = true;
   Print("Trade journal initialized: ", m_fileName);

   return true;
}

//+------------------------------------------------------------------+
//| Close journal                                                     |
//+------------------------------------------------------------------+
void CTradeJournal::Close()
{
   if(m_fileHandle != INVALID_HANDLE)
   {
      FileClose(m_fileHandle);
      m_fileHandle = INVALID_HANDLE;
   }

   m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Log trade opening                                                 |
//+------------------------------------------------------------------+
bool CTradeJournal::LogTradeOpen(ulong ticket, string strategy, string signal, double rsi, double macd, string emaAlign)
{
   if(!m_isInitialized)
      return false;

   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Cannot select position for logging: ", ticket);
      return false;
   }

   // Create trade record
   TradeRecord record;
   record.ticket = ticket;
   record.openTime = (datetime)PositionGetInteger(POSITION_TIME);
   record.closeTime = 0;
   record.symbol = PositionGetString(POSITION_SYMBOL);
   record.orderType = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   record.lots = PositionGetDouble(POSITION_VOLUME);
   record.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   record.stopLoss = PositionGetDouble(POSITION_SL);
   record.takeProfit = PositionGetDouble(POSITION_TP);
   record.closePrice = 0;
   record.profit = 0;
   record.commission = 0;
   record.swap = 0;
   record.strategy = strategy;
   record.htfTrend = "";  // Will be filled later
   record.entrySignal = signal;
   record.exitReason = "";
   record.rsiEntry = rsi;
   record.macdEntry = macd;
   record.emaAlignment = emaAlign;

   // Calculate planned RR
   double slDistance = MathAbs(record.entryPrice - record.stopLoss);
   double tpDistance = MathAbs(record.takeProfit - record.entryPrice);

   if(slDistance > 0)
   {
      record.rrPlanned = tpDistance / slDistance;
   }
   else
   {
      record.rrPlanned = 0;
   }

   record.rrActual = 0;
   record.durationMinutes = 0;
   record.mfe = 0;
   record.mae = 0;

   // Add to open trades array
   int size = ArraySize(m_openTrades);
   ArrayResize(m_openTrades, size + 1);
   m_openTrades[size] = record;

   Print("Trade opened logged: ", ticket);

   return true;
}

//+------------------------------------------------------------------+
//| Log trade closing                                                 |
//+------------------------------------------------------------------+
bool CTradeJournal::LogTradeClose(ulong ticket, string exitReason)
{
   if(!m_isInitialized)
      return false;

   // Find in open trades
   int index = FindOpenTrade(ticket);

   if(index < 0)
   {
      Print("WARNING: Trade not found in open trades: ", ticket);
      return false;
   }

   // Get close information from history
   if(!HistorySelectByPosition(ticket))
   {
      Print("ERROR: Cannot access trade history for: ", ticket);
      return false;
   }

   // Find the deal
   int deals = HistoryDealsTotal();
   for(int i = deals - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);

      if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == ticket &&
         HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         // Update record with close info
         m_openTrades[index].closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         m_openTrades[index].closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         m_openTrades[index].profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         m_openTrades[index].commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         m_openTrades[index].swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
         m_openTrades[index].exitReason = exitReason;

         // Calculate actual RR
         double slDistance = MathAbs(m_openTrades[index].entryPrice - m_openTrades[index].stopLoss);
         double actualPnL = 0;

         if(m_openTrades[index].orderType == "BUY")
         {
            actualPnL = m_openTrades[index].closePrice - m_openTrades[index].entryPrice;
         }
         else
         {
            actualPnL = m_openTrades[index].entryPrice - m_openTrades[index].closePrice;
         }

         if(slDistance > 0)
         {
            m_openTrades[index].rrActual = actualPnL / slDistance;
         }

         // Calculate duration
         m_openTrades[index].durationMinutes = (int)((m_openTrades[index].closeTime - m_openTrades[index].openTime) / 60);

         // Write to CSV
         FileSeek(m_fileHandle, 0, SEEK_END);
         FileWrite(m_fileHandle, TradeRecordToCSV(m_openTrades[index]));
         FileFlush(m_fileHandle);

         Print("Trade close logged: ", ticket, " Profit: ", m_openTrades[index].profit);

         // Remove from open trades
         for(int j = index; j < ArraySize(m_openTrades) - 1; j++)
         {
            m_openTrades[j] = m_openTrades[j + 1];
         }
         ArrayResize(m_openTrades, ArraySize(m_openTrades) - 1);

         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Handle trade events                                               |
//+------------------------------------------------------------------+
void CTradeJournal::OnTradeEvent()
{
   // Check for closed positions and log them
   // This is called from OnTrade() in main EA
}

//+------------------------------------------------------------------+
//| Update maximum excursion for open trades                         |
//+------------------------------------------------------------------+
void CTradeJournal::UpdateMaxExcursion(ulong ticket, double currentPrice)
{
   int index = FindOpenTrade(ticket);

   if(index < 0)
      return;

   double entryPrice = m_openTrades[index].entryPrice;
   bool isBuy = (m_openTrades[index].orderType == "BUY");

   double excursion = 0;

   if(isBuy)
   {
      excursion = currentPrice - entryPrice;
   }
   else
   {
      excursion = entryPrice - currentPrice;
   }

   // Update MFE (Maximum Favorable Excursion)
   if(excursion > m_openTrades[index].mfe)
   {
      m_openTrades[index].mfe = excursion;
   }

   // Update MAE (Maximum Adverse Excursion)
   if(excursion < 0 && MathAbs(excursion) > m_openTrades[index].mae)
   {
      m_openTrades[index].mae = MathAbs(excursion);
   }
}

//+------------------------------------------------------------------+
//| Generate performance report                                       |
//+------------------------------------------------------------------+
bool CTradeJournal::GeneratePerformanceReport(ENUM_TIMEFRAMES period)
{
   // TODO: Implement performance report generation
   // Read CSV file and calculate statistics

   return true;
}

//+------------------------------------------------------------------+
//| Print daily statistics                                            |
//+------------------------------------------------------------------+
void CTradeJournal::PrintDailyStats()
{
   // TODO: Calculate and print daily stats
   Print("=== Daily Statistics ===");
   Print("Trades today: TBD");
   Print("Win rate: TBD");
   Print("Profit: TBD");
   Print("========================");
}

//+------------------------------------------------------------------+
//| Print weekly statistics                                           |
//+------------------------------------------------------------------+
void CTradeJournal::PrintWeeklyStats()
{
   // TODO: Calculate and print weekly stats
   Print("=== Weekly Statistics ===");
   Print("Trades this week: TBD");
   Print("Win rate: TBD");
   Print("Profit: TBD");
   Print("=========================");
}

//+------------------------------------------------------------------+
//| Get timestamp string                                              |
//+------------------------------------------------------------------+
string CTradeJournal::GetTimestampString(datetime dt)
{
   MqlDateTime mdt;
   TimeToStruct(dt, mdt);

   return StringFormat("%04d.%02d.%02d %02d:%02d:%02d",
                       mdt.year, mdt.mon, mdt.day, mdt.hour, mdt.min, mdt.sec);
}

//+------------------------------------------------------------------+
//| Get CSV header                                                    |
//+------------------------------------------------------------------+
string CTradeJournal::GetCSVHeader()
{
   return "Ticket,OpenTime,CloseTime,Symbol,Type,Lots,EntryPrice,SL,TP,ClosePrice," +
          "Profit,Commission,Swap,Strategy,HTF_Trend,EntrySignal,ExitReason," +
          "RSI_Entry,MACD_Entry,EMA_Alignment,RR_Planned,RR_Actual,DurationMin,MFE,MAE";
}

//+------------------------------------------------------------------+
//| Convert trade record to CSV string                               |
//+------------------------------------------------------------------+
string CTradeJournal::TradeRecordToCSV(TradeRecord &record)
{
   return StringFormat("%lld,%s,%s,%s,%s,%.2f,%.5f,%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%s,%s,%s,%s,%.2f,%.4f,%s,%.2f,%.2f,%d,%.5f,%.5f",
                       record.ticket,
                       GetTimestampString(record.openTime),
                       GetTimestampString(record.closeTime),
                       record.symbol,
                       record.orderType,
                       record.lots,
                       record.entryPrice,
                       record.stopLoss,
                       record.takeProfit,
                       record.closePrice,
                       record.profit,
                       record.commission,
                       record.swap,
                       record.strategy,
                       record.htfTrend,
                       record.entrySignal,
                       record.exitReason,
                       record.rsiEntry,
                       record.macdEntry,
                       record.emaAlignment,
                       record.rrPlanned,
                       record.rrActual,
                       record.durationMinutes,
                       record.mfe,
                       record.mae);
}

//+------------------------------------------------------------------+
//| Find open trade by ticket                                        |
//+------------------------------------------------------------------+
int CTradeJournal::FindOpenTrade(ulong ticket)
{
   for(int i = 0; i < ArraySize(m_openTrades); i++)
   {
      if(m_openTrades[i].ticket == ticket)
         return i;
   }

   return -1;
}
//+------------------------------------------------------------------+
