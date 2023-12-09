#include <Trade/Trade.mqh>


// 1. INPUTS
static input long MagicNumber = 20230502; //magic number
static input double InpLotSize = 0.1; //Lot size
input int InpRSIPeriodd= 10; // Rolling RSI Period
input int InpRSILevel = 70; // RSI Top End
input int InpStopLoss = 700; // stop loss level
input int InpTakeProfit = 1500; //take profit in points
input bool InpCloseSignal = true; //Close trades but opposite signal
input int days = 60; //days
input int r = 2; //waititme

// 2. GLOBAL VARIABLES
// Handle for RSI Indicator
int handle;
double buffer[]; // Dynamic array for rsi buffer
MqlTick currentTick;
CTrade trade; //Create CTrade class object as trade
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

int OnInit()
{  

   if(MagicNumber<=0){
      Alert("Magic number <=0");
      return INIT_PARAMETERS_INCORRECT;
   }
   // set magic number to trade object
   trade.SetExpertMagicNumber(MagicNumber);
   // create rsi handle
   handle = iRSI(_Symbol,PERIOD_CURRENT,InpRSIPeriodd,PRICE_CLOSE);
   
   // set buffer as series
   ArraySetAsSeries(buffer,true);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // Release indicator handle
   if (handle!=INVALID_HANDLE){
      IndicatorRelease(handle);
   }
   
}
void OnTick()
{  
   double reg = regime_proxy();
   Print(reg);
   if (reg>=r){return;}
   //get rsi values
   // function will store the 2 values, 0,2 in the buffer array
   int values = CopyBuffer(handle,0,0,2,buffer);
   
   if(values!=2){
      Print("Failed to get indicator values");
      return;
   }
   
   // Open and close positions
   // count open positions
   int cntBuy,cntSell;
   if(!CountOpenPositions(cntBuy,cntSell)){return;}
   
   //check for buy positions
   if(cntBuy ==0 && buffer[1]>=(100-InpRSILevel) && buffer[0]<(100-InpRSILevel) && openTimeBuy!=iTime(_Symbol,PERIOD_CURRENT,0)){
      openTimeBuy=iTime(_Symbol,PERIOD_CURRENT,0);
      if(InpCloseSignal){if(!ClosePositions(2)){return;}}
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      bid = NormalizeDouble(bid,_Digits);

      double sl = InpStopLoss==0 ? 0: bid - InpStopLoss* _Point;
      double tp = InpStopLoss==0 ? 0: bid+ InpTakeProfit* _Point;
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,currentTick.ask,sl,tp);
   
   }
      if(cntSell ==0 && buffer[1]<=InpRSILevel && buffer[0]>InpRSILevel && openTimeSell!=iTime(_Symbol,PERIOD_CURRENT,0)){
      openTimeBuy=iTime(_Symbol,PERIOD_CURRENT,0);
      if(InpCloseSignal){if(!ClosePositions(1)){return;}}
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      ask = NormalizeDouble(ask,_Digits);
      double sl = InpStopLoss==0 ? 0: ask + InpStopLoss* _Point;
      double tp = InpStopLoss==0 ? 0: ask - InpTakeProfit* _Point;
      
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,currentTick.bid,sl,tp);
   
   }
   

}

// Count Open Positions
bool CountOpenPositions(int & cntBuy, int & cntSell){
   cntBuy=0;
   cntSell = 0;
   int total = PositionsTotal();
   
   for (int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      long magic;
      

      
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
      if(magic==MagicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type");return false;}
         if(type ==POSITION_TYPE_BUY){cntBuy++;}
         if(type ==POSITION_TYPE_SELL){cntSell++;}
      }
   }

   return true;
}

//Normalise price
bool NormalizeDouble(double &price){

   double tickSize = 0;
   if (!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
      Print("Failed to get tick size");
      return false;
   }
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   return true;
}

//close positions
bool ClosePositions(int all_buy_sell){

   int total = PositionsTotal();
   
   for (int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
      if(magic==MagicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type");return false;}
         if(all_buy_sell==1 && type ==POSITION_TYPE_BUY){continue;}
         if(all_buy_sell ==2 && type ==POSITION_TYPE_SELL){continue;}
         trade.PositionClose(ticket);
      }
   }

   return true;
}
//Normalize Price Function
double NormalizePrice(double p)
{
    double ts=SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    return(MathRound(p/ts)*ts);
}

// EA pause
double regime_proxy()
{  
   datetime CurentTime = TimeCurrent(); 
   datetime PrevTime   = iTime(Symbol(),PERIOD_D1,days); 

   HistorySelect(PrevTime,CurentTime);
   
   int    trades_of_day = 0;
   double winning_trade  = 0;
   double losing_trade  = 0;
   uint   total         = HistoryDealsTotal();
   ulong  ticket        = 0;
   
   for(uint i=0; i<total; i++)
     {
      if((ticket=HistoryDealGetTicket(i))>0)
         trades_of_day++;
         string symbol          = HistoryDealGetString(ticket,DEAL_SYMBOL);
         double deal_commission = HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         double deal_swap       = HistoryDealGetDouble(ticket,DEAL_SWAP);
         double deal_profit     = HistoryDealGetDouble(ticket,DEAL_PROFIT);
         double profit          = deal_commission + deal_swap + deal_profit;
         long PosMagic          = HistoryDealGetInteger(ticket,DEAL_MAGIC);
         if(Symbol() == symbol)
         {
          if(profit>0 && PosMagic == MagicNumber) winning_trade+=1;
          if(profit<0 && PosMagic == MagicNumber) losing_trade+=1;
         }
     }

return(losing_trade);
}