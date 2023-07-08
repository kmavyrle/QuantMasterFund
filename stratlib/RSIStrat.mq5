#include <Trade\Trade.mqh>

// Inputs
static input long InpMagicnumber = 202305002;  // magic number static means that you can call the static function without intialising the class for it
static input double InpLotSize = 0.1;
input int InpRSIPeriod = 21;
input int InpRSILevel = 70;
input int InpMAPeriod = 21;
input ENUM_TIMEFRAMES InpMATimeframe = PERIOD_H1; //ENUM_TimeFrames is a built in data type
input int InpStopLoss = 200;
input int InpTakeProfit = 100;
input bool InpCloseSignal = false; // If RSI gives an opposite signal close all trades

// Global Variables
CTrade trade;
MqlTick currenTick;

int handleRSI;
double bufferRSI[]; // initialise an array that stores double type
int handleMA;
double bufferMA[];

datetime openTimeBuy = 0;
datetime openTimeSell = 0;

int OnInit()
{  // set magic number to trade object
   // Gives this EA the magicnumber
   trade.SetExpertMagicNumber(InpMagicnumber);
   
   //Create RSI handle RSI https://www.mql5.com/en/docs/indicators/irsi
   // Creates a rsi handle symbol is the symbol on the chart, period current is of chart, 
   handleRSI = iRSI(_Symbol,PERIOD_CURRENT,InpRSIPeriod,PRICE_OPEN);
   handleMA = iMA(_Symbol,InpMATimeframe,InpMAPeriod,0,MODE_SMA,PRICE_OPEN);
   
   //set buffer as series
   ArraySetAsSeries(bufferRSI,true);
   ArraySetAsSeries(bufferMA, true);
   

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)

{  if(!IsNewBar()){return;} // if new bar == false, wont run the strategy

   if(handleRSI != INVALID_HANDLE){IndicatorRelease(handleRSI);}
   
}

void OnTick()
{
   //get rsi values
   // returns 2 values in an array
   // the buffer is an array, it will pick the latest rsi, and the prev rsi one tick before
   int values = CopyBuffer(handleRSI,0,0,2,bufferRSI);
   
   //get MA values
   // 1 because we only want the latest value
   values = CopyBuffer(handleMA,0,0,1,bufferMA);
   
   // count open positions
   int cntBuy,cntSell;
   if (!CountOpenPositions(cntBuy,cntSell)){return;}
   
   //check for buy positions
   // we only want to take a buy position if thge price is > MA and the price is below the MA
   if (cntBuy==0 && bufferRSI[1]>=(100-InpRSILevel) && bufferRSI[0]<(100-InpRSILevel) && currenTick.ask >bufferMA[0]){
      if(InpCloseSignal){if(!ClosePositions(2)){return;}}
      
      double sl = InpStopLoss==0 ? 0: currenTick.ask +InpStopLoss * _Point; // short form for if else
      double tp = InpTakeProfit ==0 ? 0: currenTick.ask -InpTakeProfit * _Point;
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,currenTick.ask,sl,tp);
   }
   
   //check for sell positions
   // we only want to take a buy position if thge price is > MA and the price is below the MA
   if (cntSell==0 && bufferRSI[1]<=InpRSILevel && bufferRSI[0]>InpRSILevel && currenTick.bid <bufferMA[0]){
      if(InpCloseSignal){if(!ClosePositions(2)){return;}}
      
      double sl = InpStopLoss==0 ? 0: currenTick.bid -InpStopLoss * _Point;
      double tp = InpTakeProfit ==0 ? 0: currenTick.bid +InpTakeProfit * _Point;
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,currenTick.bid,sl,tp);
   }
  
  
// CUSTOM FUNCTIONS 
  
}

bool IsNewBar(){
   static datetime previousTime = 0;
   //Get currenttime with the iTime function
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime){
      previousTime=currentTime;
      return true;
   }
   return false;

}

bool CountOpenPositions(int &cntBuy, int &cntSell){
   // Create a counter to count the number of buys and sells positions
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();// Get open positiosn
   for (int i=total-1; i>=0;i--){
      ulong ticket = PositionGetTicket(i);// get the ticket number of the open position
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){return false;}
      if (magic == InpMagicnumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){return false;}
         if(type==POSITION_TYPE_BUY){cntBuy++;}
         if(type==POSITION_TYPE_SELL){cntSell++;}
      }
      
   }
   return true;

}

bool NormalizePrice(double &price){
   double tickSize = 0;
   if (!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
   return false;}
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   return true;
}

// Close positions functon
bool ClosePositions(int all_buy_sell){
   int total = PositionsTotal();// Returns the total number of open positions
   for (int i=total-1; i >=0;i--){ // Start from the latest 
      ulong ticket = PositionGetTicket(i); // Declare ticket using position => Returns the ticket of an open position given the index of all open positions
      if(!PositionSelectByTicket(ticket)){return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){return false;}
      if (magic == InpMagicnumber){
         long type; // long is just an integer type class
         if(!PositionGetInteger(POSITION_TYPE,type)){return false;}
         if (all_buy_sell ==1 && type == POSITION_TYPE_SELL){continue;}
         if (all_buy_sell ==2 && type == POSITION_TYPE_BUY){continue;}
         trade.PositionClose(ticket);
      }
   }
   return true;
}