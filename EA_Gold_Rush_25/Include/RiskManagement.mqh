//+------------------------------------------------------------------+
//|                                            RiskManagement.mqh    |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Risk Management Class                                             |
//+------------------------------------------------------------------+
class CRiskManagement
{
private:
   // Configuration
   string m_symbol;
   int m_magicNumber;

   // Risk parameters
   double m_riskPercent;
   double m_maxDailyLossPercent;
   double m_maxWeeklyLossPercent;
   int m_maxPositions;

   // Helper functions
   double GetSymbolPoint();
   double GetSymbolTickValue();
   double NormalizeLots(double lots);
   int GetDigits();

public:
   // Constructor/Destructor
   CRiskManagement();
   ~CRiskManagement();

   // Initialization
   void SetParameters(string symbol, int magic, double risk, double maxDaily, double maxWeekly, int maxPos);

   // Position sizing
   double CalculatePositionSize(double stopLossPips, double riskPercent);
   double CalculatePositionSizeByDistance(double entryPrice, double stopLossPrice, double riskPercent);

   // Stop Loss and Take Profit calculation
   double CalculateStopLoss(ENUM_ORDER_TYPE orderType, double atrValue, double atrMultiplier);
   double CalculateStopLossBySwing(ENUM_ORDER_TYPE orderType, int lookbackBars);
   double CalculateStopLossByLevel(ENUM_ORDER_TYPE orderType, double levelPrice, double bufferPips);

   double CalculateTakeProfit(double entryPrice, double stopLossPrice, double rrRatio);
   double CalculateTakeProfitByLevel(ENUM_ORDER_TYPE orderType, double targetLevel);

   // Risk checks
   bool CheckDailyLossLimit(double startBalance, double maxLossPercent);
   bool CheckWeeklyLossLimit(double startBalance, double maxLossPercent);
   bool CheckMaxPositions(int maxAllowed);
   bool CheckAccountMargin(double lotSize);

   // Utility functions
   double GetAccountRisk(double riskPercent);
   double PipsToPrice(double pips);
   double PriceToPips(double price);
   int CalculatePipsDistance(double price1, double price2);

   // Money management
   double GetCurrentDrawdown();
   double GetDailyPnL(double startBalance);
   double GetWeeklyPnL(double startBalance);
   int CountOpenPositions();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CRiskManagement::CRiskManagement()
{
   m_symbol = _Symbol;
   m_magicNumber = 0;
   m_riskPercent = 1.0;
   m_maxDailyLossPercent = 3.0;
   m_maxWeeklyLossPercent = 5.0;
   m_maxPositions = 3;
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CRiskManagement::~CRiskManagement()
{
}

//+------------------------------------------------------------------+
//| Set risk parameters                                               |
//+------------------------------------------------------------------+
void CRiskManagement::SetParameters(string symbol, int magic, double risk, double maxDaily, double maxWeekly, int maxPos)
{
   m_symbol = symbol;
   m_magicNumber = magic;
   m_riskPercent = risk;
   m_maxDailyLossPercent = maxDaily;
   m_maxWeeklyLossPercent = maxWeekly;
   m_maxPositions = maxPos;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk and SL in pips             |
//+------------------------------------------------------------------+
double CRiskManagement::CalculatePositionSize(double stopLossPips, double riskPercent)
{
   if(stopLossPips <= 0)
   {
      Print("ERROR: Invalid stop loss pips: ", stopLossPips);
      return 0;
   }

   // Get account balance
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Calculate risk amount in account currency
   double riskAmount = accountBalance * (riskPercent / 100.0);

   // Get symbol point and tick value
   double point = GetSymbolPoint();
   double tickValue = GetSymbolTickValue();

   // Calculate stop loss in price
   double stopLossPrice = stopLossPips * point;

   // Calculate lot size
   // Formula: Lots = RiskAmount / (StopLossPips * TickValue * LotSize)
   double lotSize = riskAmount / (stopLossPrice * tickValue / point);

   // Normalize to broker requirements
   lotSize = NormalizeLots(lotSize);

   // Validate lot size
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);

   if(lotSize < minLot)
   {
      Print("WARNING: Calculated lot size ", lotSize, " is below minimum ", minLot);
      return minLot;
   }

   if(lotSize > maxLot)
   {
      Print("WARNING: Calculated lot size ", lotSize, " exceeds maximum ", maxLot);
      return maxLot;
   }

   // Check if we have enough margin
   if(!CheckAccountMargin(lotSize))
   {
      Print("WARNING: Insufficient margin for lot size ", lotSize);

      // Try to reduce lot size
      while(lotSize > minLot && !CheckAccountMargin(lotSize))
      {
         lotSize -= SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
         lotSize = NormalizeLots(lotSize);
      }

      if(!CheckAccountMargin(lotSize))
      {
         Print("ERROR: Cannot find acceptable lot size with available margin");
         return 0;
      }
   }

   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate position size by entry and SL price                    |
//+------------------------------------------------------------------+
double CRiskManagement::CalculatePositionSizeByDistance(double entryPrice, double stopLossPrice, double riskPercent)
{
   if(entryPrice <= 0 || stopLossPrice <= 0)
   {
      Print("ERROR: Invalid entry or stop loss price");
      return 0;
   }

   double stopLossPips = MathAbs(entryPrice - stopLossPrice) / GetSymbolPoint();
   return CalculatePositionSize(stopLossPips, riskPercent);
}

//+------------------------------------------------------------------+
//| Calculate stop loss based on ATR                                 |
//+------------------------------------------------------------------+
double CRiskManagement::CalculateStopLoss(ENUM_ORDER_TYPE orderType, double atrValue, double atrMultiplier)
{
   if(atrValue <= 0)
   {
      Print("ERROR: Invalid ATR value");
      return 0;
   }

   double currentPrice = (orderType == ORDER_TYPE_BUY) ?
                         SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                         SymbolInfoDouble(m_symbol, SYMBOL_BID);

   double stopLoss = 0;
   double atrDistance = atrValue * atrMultiplier;

   if(orderType == ORDER_TYPE_BUY)
   {
      stopLoss = currentPrice - atrDistance;
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      stopLoss = currentPrice + atrDistance;
   }

   return NormalizeDouble(stopLoss, GetDigits());
}

//+------------------------------------------------------------------+
//| Calculate stop loss based on swing high/low                      |
//+------------------------------------------------------------------+
double CRiskManagement::CalculateStopLossBySwing(ENUM_ORDER_TYPE orderType, int lookbackBars)
{
   double swingLevel = 0;

   if(orderType == ORDER_TYPE_BUY)
   {
      // Find recent swing low
      swingLevel = iLow(m_symbol, PERIOD_CURRENT, iLowest(m_symbol, PERIOD_CURRENT, MODE_LOW, lookbackBars, 1));
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      // Find recent swing high
      swingLevel = iHigh(m_symbol, PERIOD_CURRENT, iHighest(m_symbol, PERIOD_CURRENT, MODE_HIGH, lookbackBars, 1));
   }

   return NormalizeDouble(swingLevel, GetDigits());
}

//+------------------------------------------------------------------+
//| Calculate stop loss based on key level with buffer               |
//+------------------------------------------------------------------+
double CRiskManagement::CalculateStopLossByLevel(ENUM_ORDER_TYPE orderType, double levelPrice, double bufferPips)
{
   double buffer = bufferPips * GetSymbolPoint();
   double stopLoss = 0;

   if(orderType == ORDER_TYPE_BUY)
   {
      stopLoss = levelPrice - buffer;
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      stopLoss = levelPrice + buffer;
   }

   return NormalizeDouble(stopLoss, GetDigits());
}

//+------------------------------------------------------------------+
//| Calculate take profit based on risk:reward ratio                 |
//+------------------------------------------------------------------+
double CRiskManagement::CalculateTakeProfit(double entryPrice, double stopLossPrice, double rrRatio)
{
   if(entryPrice <= 0 || stopLossPrice <= 0 || rrRatio <= 0)
   {
      Print("ERROR: Invalid parameters for TP calculation");
      return 0;
   }

   double stopLossDistance = MathAbs(entryPrice - stopLossPrice);
   double takeProfitDistance = stopLossDistance * rrRatio;
   double takeProfit = 0;

   if(entryPrice > stopLossPrice) // Buy trade
   {
      takeProfit = entryPrice + takeProfitDistance;
   }
   else // Sell trade
   {
      takeProfit = entryPrice - takeProfitDistance;
   }

   return NormalizeDouble(takeProfit, GetDigits());
}

//+------------------------------------------------------------------+
//| Calculate take profit at specific level                          |
//+------------------------------------------------------------------+
double CRiskManagement::CalculateTakeProfitByLevel(ENUM_ORDER_TYPE orderType, double targetLevel)
{
   return NormalizeDouble(targetLevel, GetDigits());
}

//+------------------------------------------------------------------+
//| Check if daily loss limit reached                                |
//+------------------------------------------------------------------+
bool CRiskManagement::CheckDailyLossLimit(double startBalance, double maxLossPercent)
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyPnL = currentBalance - startBalance;
   double maxLossAmount = startBalance * (maxLossPercent / 100.0);

   if(dailyPnL <= -maxLossAmount)
   {
      Print("Daily loss limit reached. PnL: ", dailyPnL, " Max Loss: ", -maxLossAmount);
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if weekly loss limit reached                               |
//+------------------------------------------------------------------+
bool CRiskManagement::CheckWeeklyLossLimit(double startBalance, double maxLossPercent)
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double weeklyPnL = currentBalance - startBalance;
   double maxLossAmount = startBalance * (maxLossPercent / 100.0);

   if(weeklyPnL <= -maxLossAmount)
   {
      Print("Weekly loss limit reached. PnL: ", weeklyPnL, " Max Loss: ", -maxLossAmount);
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if max positions reached                                   |
//+------------------------------------------------------------------+
bool CRiskManagement::CheckMaxPositions(int maxAllowed)
{
   int openPositions = CountOpenPositions();
   return (openPositions >= maxAllowed);
}

//+------------------------------------------------------------------+
//| Check if sufficient margin available                             |
//+------------------------------------------------------------------+
bool CRiskManagement::CheckAccountMargin(double lotSize)
{
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   // Calculate required margin for the trade
   double requiredMargin = 0;

   if(!OrderCalcMargin(ORDER_TYPE_BUY, m_symbol, lotSize,
                       SymbolInfoDouble(m_symbol, SYMBOL_ASK), requiredMargin))
   {
      Print("ERROR: Failed to calculate required margin");
      return false;
   }

   // Add 10% buffer for safety
   requiredMargin *= 1.1;

   if(freeMargin < requiredMargin)
   {
      Print("Insufficient margin. Free: ", freeMargin, " Required: ", requiredMargin);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Get account risk amount                                          |
//+------------------------------------------------------------------+
double CRiskManagement::GetAccountRisk(double riskPercent)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   return accountBalance * (riskPercent / 100.0);
}

//+------------------------------------------------------------------+
//| Convert pips to price                                            |
//+------------------------------------------------------------------+
double CRiskManagement::PipsToPrice(double pips)
{
   return pips * GetSymbolPoint();
}

//+------------------------------------------------------------------+
//| Convert price to pips                                            |
//+------------------------------------------------------------------+
double CRiskManagement::PriceToPips(double price)
{
   return price / GetSymbolPoint();
}

//+------------------------------------------------------------------+
//| Calculate distance between two prices in pips                    |
//+------------------------------------------------------------------+
int CRiskManagement::CalculatePipsDistance(double price1, double price2)
{
   return (int)MathRound(MathAbs(price1 - price2) / GetSymbolPoint());
}

//+------------------------------------------------------------------+
//| Get current account drawdown                                     |
//+------------------------------------------------------------------+
double CRiskManagement::GetCurrentDrawdown()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   if(balance <= 0) return 0;

   double drawdown = ((balance - equity) / balance) * 100.0;
   return drawdown;
}

//+------------------------------------------------------------------+
//| Get daily PnL                                                     |
//+------------------------------------------------------------------+
double CRiskManagement::GetDailyPnL(double startBalance)
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   return currentBalance - startBalance;
}

//+------------------------------------------------------------------+
//| Get weekly PnL                                                    |
//+------------------------------------------------------------------+
double CRiskManagement::GetWeeklyPnL(double startBalance)
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   return currentBalance - startBalance;
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                 |
//+------------------------------------------------------------------+
int CRiskManagement::CountOpenPositions()
{
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
            PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
         {
            count++;
         }
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Get symbol point value                                           |
//+------------------------------------------------------------------+
double CRiskManagement::GetSymbolPoint()
{
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

   // Adjust for 3/5 digit brokers
   if(digits == 3 || digits == 5)
      point *= 10;

   return point;
}

//+------------------------------------------------------------------+
//| Get symbol tick value                                            |
//+------------------------------------------------------------------+
double CRiskManagement::GetSymbolTickValue()
{
   return SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker requirements                        |
//+------------------------------------------------------------------+
double CRiskManagement::NormalizeLots(double lots)
{
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

   // Round to lot step
   lots = MathRound(lots / lotStep) * lotStep;

   // Ensure within bounds
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;

   // Get lot digits for proper normalization
   double lotDigits = 2;
   if(lotStep >= 1.0) lotDigits = 0;
   else if(lotStep >= 0.1) lotDigits = 1;
   else if(lotStep >= 0.01) lotDigits = 2;

   return NormalizeDouble(lots, (int)lotDigits);
}

//+------------------------------------------------------------------+
//| Get symbol digits                                                 |
//+------------------------------------------------------------------+
int CRiskManagement::GetDigits()
{
   return (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
}
//+------------------------------------------------------------------+
