//+------------------------------------------------------------------+
//|                                         TradeExecution.mqh       |
//|                                    Professional Day Trader EA    |
//+------------------------------------------------------------------+
#property copyright "Gold Rush 25 Development Team"
#property link      "https://www.yoursite.com"
#property version   "1.00"

#include "Enums.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Structure to track position state                                |
//+------------------------------------------------------------------+
struct PositionState
{
   ulong ticket;
   bool breakevenMoved;
   bool partialClosed;
   datetime openTime;
   double openPrice;
   double stopLoss;
   double takeProfit;
};

//+------------------------------------------------------------------+
//| Trade Execution Class                                             |
//+------------------------------------------------------------------+
class CTradeExecution
{
private:
   CTrade m_trade;
   string m_symbol;
   int m_magicNumber;
   int m_slippage;

   // Position tracking
   PositionState m_positionStates[];

   // Helper functions
   int FindPositionState(ulong ticket);
   void AddPositionState(ulong ticket, double openPrice, double sl, double tp);
   void RemovePositionState(ulong ticket);
   double NormalizePrice(double price);

public:
   // Constructor/Destructor
   CTradeExecution();
   ~CTradeExecution();

   // Initialization
   void Initialize(string symbol, int magic, int slippage);
   void SetExpertParameters(int magic, int deviation);

   // Order Execution
   ulong OpenMarketOrder(ENUM_ORDER_TYPE orderType, double lotSize, double sl, double tp, string comment);
   bool CloseOrder(ulong ticket);
   bool ClosePartialOrder(ulong ticket, double closePercent);

   // Order Modification
   bool ModifyOrder(ulong ticket, double newSL, double newTP);
   bool ModifyStopLoss(ulong ticket, double newSL);
   bool ModifyTakeProfit(ulong ticket, double newTP);

   // Trade Management
   bool CheckAndMoveToBreakeven(ulong ticket, double rrTrigger);
   bool ApplyTrailingStop(ulong ticket, ENUM_TRAIL_TYPE trailType, double trailDistance);
   bool CheckPartialTakeProfit(ulong ticket, double partialRR, double closePercent);

   // Position Info
   bool GetPositionInfo(ulong ticket, double &openPrice, double &currentSL, double &currentTP, double &currentProfit);
   double GetPositionProfitInRR(ulong ticket);
   double GetPositionLots(ulong ticket);

   // Validation
   bool ValidateStopLoss(ENUM_ORDER_TYPE orderType, double price, double sl);
   bool ValidateTakeProfit(ENUM_ORDER_TYPE orderType, double price, double tp);
   double AdjustStopLoss(ENUM_ORDER_TYPE orderType, double sl);
   double AdjustTakeProfit(ENUM_ORDER_TYPE orderType, double tp);

   // Error handling
   string GetLastErrorDescription();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTradeExecution::CTradeExecution()
{
   m_symbol = _Symbol;
   m_magicNumber = 0;
   m_slippage = 30;

   ArrayResize(m_positionStates, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTradeExecution::~CTradeExecution()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                         |
//+------------------------------------------------------------------+
void CTradeExecution::Initialize(string symbol, int magic, int slippage)
{
   m_symbol = symbol;
   m_magicNumber = magic;
   m_slippage = slippage;

   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetDeviationInPoints(slippage);
   m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   m_trade.SetAsyncMode(false);
}

//+------------------------------------------------------------------+
//| Set expert parameters                                             |
//+------------------------------------------------------------------+
void CTradeExecution::SetExpertParameters(int magic, int deviation)
{
   m_magicNumber = magic;
   m_slippage = deviation;

   m_trade.SetExpertMagicNumber(magic);
   m_trade.SetDeviationInPoints(deviation);
}

//+------------------------------------------------------------------+
//| Open market order                                                 |
//+------------------------------------------------------------------+
ulong CTradeExecution::OpenMarketOrder(ENUM_ORDER_TYPE orderType, double lotSize, double sl, double tp, string comment)
{
   // Validate lot size
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);

   if(lotSize < minLot || lotSize > maxLot)
   {
      Print("ERROR: Invalid lot size: ", lotSize, " (Min: ", minLot, " Max: ", maxLot, ")");
      return 0;
   }

   // Normalize prices
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);

   // Validate SL and TP
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(m_symbol, SYMBOL_BID);

   if(!ValidateStopLoss(orderType, price, sl))
   {
      sl = AdjustStopLoss(orderType, sl);
   }

   if(!ValidateTakeProfit(orderType, price, tp))
   {
      tp = AdjustTakeProfit(orderType, tp);
   }

   // Execute order
   bool result = false;

   if(orderType == ORDER_TYPE_BUY)
   {
      result = m_trade.Buy(lotSize, m_symbol, 0, sl, tp, comment);
   }
   else if(orderType == ORDER_TYPE_SELL)
   {
      result = m_trade.Sell(lotSize, m_symbol, 0, sl, tp, comment);
   }

   if(result)
   {
      ulong ticket = m_trade.ResultOrder();
      Print("Order opened successfully. Ticket: ", ticket);

      // Add to position tracking
      AddPositionState(ticket, price, sl, tp);

      return ticket;
   }
   else
   {
      Print("ERROR: Failed to open order. ", GetLastErrorDescription());
      return 0;
   }
}

//+------------------------------------------------------------------+
//| Close order                                                        |
//+------------------------------------------------------------------+
bool CTradeExecution::CloseOrder(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Position not found: ", ticket);
      return false;
   }

   bool result = m_trade.PositionClose(ticket, m_slippage);

   if(result)
   {
      Print("Position closed successfully. Ticket: ", ticket);
      RemovePositionState(ticket);
      return true;
   }
   else
   {
      Print("ERROR: Failed to close position. ", GetLastErrorDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close partial order                                               |
//+------------------------------------------------------------------+
bool CTradeExecution::ClosePartialOrder(ulong ticket, double closePercent)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Position not found: ", ticket);
      return false;
   }

   double currentLots = PositionGetDouble(POSITION_VOLUME);
   double closeVolume = NormalizeDouble(currentLots * (closePercent / 100.0), 2);

   // Ensure we don't close less than minimum
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   if(closeVolume < minLot)
   {
      closeVolume = minLot;
   }

   bool result = m_trade.PositionClosePartial(ticket, closeVolume, m_slippage);

   if(result)
   {
      Print("Partial close successful. Ticket: ", ticket, " Closed: ", closeVolume, " lots");

      // Update position state
      int index = FindPositionState(ticket);
      if(index >= 0)
      {
         m_positionStates[index].partialClosed = true;
      }

      return true;
   }
   else
   {
      Print("ERROR: Failed to close partial position. ", GetLastErrorDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Modify order                                                       |
//+------------------------------------------------------------------+
bool CTradeExecution::ModifyOrder(ulong ticket, double newSL, double newTP)
{
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Position not found: ", ticket);
      return false;
   }

   newSL = NormalizePrice(newSL);
   newTP = NormalizePrice(newTP);

   bool result = m_trade.PositionModify(ticket, newSL, newTP);

   if(result)
   {
      Print("Position modified. Ticket: ", ticket, " New SL: ", newSL, " New TP: ", newTP);

      // Update position state
      int index = FindPositionState(ticket);
      if(index >= 0)
      {
         m_positionStates[index].stopLoss = newSL;
         m_positionStates[index].takeProfit = newTP;
      }

      return true;
   }
   else
   {
      Print("ERROR: Failed to modify position. ", GetLastErrorDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Modify stop loss only                                            |
//+------------------------------------------------------------------+
bool CTradeExecution::ModifyStopLoss(ulong ticket, double newSL)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   double currentTP = PositionGetDouble(POSITION_TP);
   return ModifyOrder(ticket, newSL, currentTP);
}

//+------------------------------------------------------------------+
//| Modify take profit only                                          |
//+------------------------------------------------------------------+
bool CTradeExecution::ModifyTakeProfit(ulong ticket, double newTP)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   double currentSL = PositionGetDouble(POSITION_SL);
   return ModifyOrder(ticket, currentSL, newTP);
}

//+------------------------------------------------------------------+
//| Move to breakeven                                                 |
//+------------------------------------------------------------------+
bool CTradeExecution::CheckAndMoveToBreakeven(ulong ticket, double rrTrigger)
{
   int index = FindPositionState(ticket);

   // Already moved to breakeven
   if(index >= 0 && m_positionStates[index].breakevenMoved)
      return false;

   if(!PositionSelectByTicket(ticket))
      return false;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   // Calculate profit in RR terms
   double slDistance = MathAbs(openPrice - currentSL);
   double currentProfit = 0;

   if(posType == POSITION_TYPE_BUY)
   {
      currentProfit = currentPrice - openPrice;
   }
   else
   {
      currentProfit = openPrice - currentPrice;
   }

   double currentRR = slDistance > 0 ? currentProfit / slDistance : 0;

   // Check if profit reached trigger RR
   if(currentRR >= rrTrigger)
   {
      // Calculate breakeven price (entry + spread + small buffer)
      double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double buffer = 5 * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double breakevenPrice = 0;

      if(posType == POSITION_TYPE_BUY)
      {
         breakevenPrice = openPrice + spread + buffer;
      }
      else
      {
         breakevenPrice = openPrice - spread - buffer;
      }

      // Only move if new SL is better
      bool shouldMove = false;
      if(posType == POSITION_TYPE_BUY && breakevenPrice > currentSL)
      {
         shouldMove = true;
      }
      else if(posType == POSITION_TYPE_SELL && breakevenPrice < currentSL)
      {
         shouldMove = true;
      }

      if(shouldMove)
      {
         bool result = ModifyStopLoss(ticket, breakevenPrice);

         if(result && index >= 0)
         {
            m_positionStates[index].breakevenMoved = true;
            Print("Moved to breakeven. Ticket: ", ticket);
         }

         return result;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Apply trailing stop                                               |
//+------------------------------------------------------------------+
bool CTradeExecution::ApplyTrailingStop(ulong ticket, ENUM_TRAIL_TYPE trailType, double trailDistance)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double newSL = currentSL;

   if(trailType == TRAIL_FIXED)
   {
      // Fixed pip trailing
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      if(digits == 3 || digits == 5)
         point *= 10;

      double trailPrice = trailDistance * point;

      if(posType == POSITION_TYPE_BUY)
      {
         newSL = currentPrice - trailPrice;

         // Only move if improving
         if(newSL > currentSL)
         {
            return ModifyStopLoss(ticket, newSL);
         }
      }
      else
      {
         newSL = currentPrice + trailPrice;

         if(newSL < currentSL || currentSL == 0)
         {
            return ModifyStopLoss(ticket, newSL);
         }
      }
   }
   // TODO: Implement EMA and ATR trailing

   return false;
}

//+------------------------------------------------------------------+
//| Check and execute partial take profit                            |
//+------------------------------------------------------------------+
bool CTradeExecution::CheckPartialTakeProfit(ulong ticket, double partialRR, double closePercent)
{
   int index = FindPositionState(ticket);

   // Already taken partial profit
   if(index >= 0 && m_positionStates[index].partialClosed)
      return false;

   // Check if reached partial TP level
   double currentRR = GetPositionProfitInRR(ticket);

   if(currentRR >= partialRR)
   {
      bool result = ClosePartialOrder(ticket, closePercent);

      if(result && index >= 0)
      {
         m_positionStates[index].partialClosed = true;
         Print("Partial take profit executed. Ticket: ", ticket);
      }

      return result;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get position information                                          |
//+------------------------------------------------------------------+
bool CTradeExecution::GetPositionInfo(ulong ticket, double &openPrice, double &currentSL, double &currentTP, double &currentProfit)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   currentSL = PositionGetDouble(POSITION_SL);
   currentTP = PositionGetDouble(POSITION_TP);
   currentProfit = PositionGetDouble(POSITION_PROFIT);

   return true;
}

//+------------------------------------------------------------------+
//| Get position profit in R:R terms                                 |
//+------------------------------------------------------------------+
double CTradeExecution::GetPositionProfitInRR(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return 0;

   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
   double currentSL = PositionGetDouble(POSITION_SL);
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   double slDistance = MathAbs(openPrice - currentSL);

   if(slDistance == 0)
      return 0;

   double currentProfit = 0;

   if(posType == POSITION_TYPE_BUY)
   {
      currentProfit = currentPrice - openPrice;
   }
   else
   {
      currentProfit = openPrice - currentPrice;
   }

   return currentProfit / slDistance;
}

//+------------------------------------------------------------------+
//| Get position lots                                                 |
//+------------------------------------------------------------------+
double CTradeExecution::GetPositionLots(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return 0;

   return PositionGetDouble(POSITION_VOLUME);
}

//+------------------------------------------------------------------+
//| Validate stop loss                                                |
//+------------------------------------------------------------------+
bool CTradeExecution::ValidateStopLoss(ENUM_ORDER_TYPE orderType, double price, double sl)
{
   if(sl == 0)
      return true; // No SL

   int stopLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   double minDistance = stopLevel * point;
   double actualDistance = MathAbs(price - sl);

   return (actualDistance >= minDistance);
}

//+------------------------------------------------------------------+
//| Validate take profit                                              |
//+------------------------------------------------------------------+
bool CTradeExecution::ValidateTakeProfit(ENUM_ORDER_TYPE orderType, double price, double tp)
{
   if(tp == 0)
      return true; // No TP

   int stopLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

   double minDistance = stopLevel * point;
   double actualDistance = MathAbs(price - tp);

   return (actualDistance >= minDistance);
}

//+------------------------------------------------------------------+
//| Adjust stop loss to valid level                                  |
//+------------------------------------------------------------------+
double CTradeExecution::AdjustStopLoss(ENUM_ORDER_TYPE orderType, double sl)
{
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(m_symbol, SYMBOL_BID);

   int stopLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double minDistance = stopLevel * point;

   if(orderType == ORDER_TYPE_BUY)
   {
      return NormalizePrice(price - minDistance);
   }
   else
   {
      return NormalizePrice(price + minDistance);
   }
}

//+------------------------------------------------------------------+
//| Adjust take profit to valid level                                |
//+------------------------------------------------------------------+
double CTradeExecution::AdjustTakeProfit(ENUM_ORDER_TYPE orderType, double tp)
{
   double price = (orderType == ORDER_TYPE_BUY) ?
                  SymbolInfoDouble(m_symbol, SYMBOL_ASK) :
                  SymbolInfoDouble(m_symbol, SYMBOL_BID);

   int stopLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double minDistance = stopLevel * point;

   if(orderType == ORDER_TYPE_BUY)
   {
      return NormalizePrice(price + minDistance);
   }
   else
   {
      return NormalizePrice(price - minDistance);
   }
}

//+------------------------------------------------------------------+
//| Find position state index                                        |
//+------------------------------------------------------------------+
int CTradeExecution::FindPositionState(ulong ticket)
{
   for(int i = 0; i < ArraySize(m_positionStates); i++)
   {
      if(m_positionStates[i].ticket == ticket)
         return i;
   }

   return -1;
}

//+------------------------------------------------------------------+
//| Add position state                                                |
//+------------------------------------------------------------------+
void CTradeExecution::AddPositionState(ulong ticket, double openPrice, double sl, double tp)
{
   PositionState state;
   state.ticket = ticket;
   state.breakevenMoved = false;
   state.partialClosed = false;
   state.openTime = TimeCurrent();
   state.openPrice = openPrice;
   state.stopLoss = sl;
   state.takeProfit = tp;

   int size = ArraySize(m_positionStates);
   ArrayResize(m_positionStates, size + 1);
   m_positionStates[size] = state;
}

//+------------------------------------------------------------------+
//| Remove position state                                             |
//+------------------------------------------------------------------+
void CTradeExecution::RemovePositionState(ulong ticket)
{
   int index = FindPositionState(ticket);

   if(index >= 0)
   {
      // Shift array
      for(int i = index; i < ArraySize(m_positionStates) - 1; i++)
      {
         m_positionStates[i] = m_positionStates[i + 1];
      }

      ArrayResize(m_positionStates, ArraySize(m_positionStates) - 1);
   }
}

//+------------------------------------------------------------------+
//| Normalize price                                                   |
//+------------------------------------------------------------------+
double CTradeExecution::NormalizePrice(double price)
{
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

//+------------------------------------------------------------------+
//| Get last error description                                        |
//+------------------------------------------------------------------+
string CTradeExecution::GetLastErrorDescription()
{
   return "Code: " + IntegerToString(m_trade.ResultRetcode()) +
          " - " + m_trade.ResultRetcodeDescription();
}
//+------------------------------------------------------------------+
