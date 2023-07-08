#include <Trade\Trade.mqh> //includes the MQL5 Trade class that is within the mql5 coding framework

//INPUTS
static input int magicNumber = 202305004; // set magic number
// technical indicator
input int slowMAperiod = 90; //Slow MA Period => This is an input that you can put in in metatrader
input int fastMAperiod = 60; //Fast MA Period

input double takeProfit = 1500; // TP Level
input double stopLoss = 100; // SL Level

// SET GLOBAL VARIABLES
CTrade trade; // Create an instance of CTrade

// Handles are unique identifiers created to use with certain indicators
int handleslowMA;       // Initialise handles for slow and fast MAs
int handlefastMA;
// Buffers are required in tandem with copybuffers https://www.mql5.com/en/docs/series/copybuffer
double bufferslowMA[];  // Initialise buffers for slow and fast MAs
double bufferfastMA[];

// OnInit, OnDeinit, OnTick are functions all called by metatrader, i.e in built. If EA is placed on a chart
// Metatrader will call these functions. Functions are violet in colour

int OnInit()
{  trade.SetExpertMagicNumber(magicNumber);
   //iMA function is a pre-defined function within the MQL5 framework used to create the moving average indicator
   // iMA function will define a specific moving average, it returns a handle, whereby a handle is a concept in m1l5
   // which is a reference to some memory in your PC where a specific description of the indicator is stored
   
   handleslowMA = iMA(_Symbol,PERIOD_CURRENT,slowMAperiod,0,MODE_SMA,PRICE_CLOSE); // Assign moving average indicator to handle
   handlefastMA = iMA(_Symbol,PERIOD_CURRENT,fastMAperiod,0,MODE_SMA,PRICE_CLOSE); // _Symbol is also a predefined variable that will change based on the chart you place your EA on
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
 {

   
}

void OnTick()
{  
   int cntBuy,cntSell;
   if (!CountOpenPositions(cntBuy,cntSell)){return;}
   double slowMA[], fastMA[];
   //copyBuffer function can be used to receive data from a specific indicator that is already explained to the PC
   // and stored in a handle
   // Below, copybuffer function receives data from the handleslowMA handle
   // Main_line can be changed to 0 or MAIN_LINE
   // Need an array at the back to store since we want to store 2 MA values for the latest and latest-1 tick
   CopyBuffer(handleslowMA,MAIN_LINE,0,2,slowMA);
   CopyBuffer(handlefastMA,MAIN_LINE,0,2,fastMA);
   Comment("SlowMA[0]:",slowMA[0], " | slowMA[1]:",slowMA[1],
           "\nFastMA[0]:",fastMA[0], " | FastMA[1]:",fastMA[1]);   //comment will show on the chart the values that you input

   // iClose will get you the close price for a specified bar in a chart after providing an index as a shift value
   // Index 1 will give you the close of the previous bar from the current
   double close1 = iClose(_Symbol,PERIOD_CURRENT,1);
   double close2 = iClose(_Symbol, PERIOD_CURRENT,2);

   
   if(fastMA[1]>slowMA[1] && cntBuy==0 && fastMA[0]<slowMA[0]){
      if (cntSell>0){CloseOrders();}
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sl = stopLoss==0 ? 0: ask - stopLoss* _Point;
      double tp = takeProfit==0 ? 0: ask + takeProfit* _Point;
      ask = NormalizeDouble(ask,_Digits);
      trade.Buy(0.1,_Symbol,ask,sl,tp);
   }
   if(fastMA[1]<slowMA[1] && cntSell==0 && fastMA[0]>slowMA[0]){
      if (cntBuy>0){CloseOrders();}
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double sl = stopLoss==0 ? 0: bid + stopLoss* _Point;
      double tp = takeProfit==0 ? 0: bid - takeProfit* _Point;
      bid = NormalizeDouble(bid,_Digits);
      trade.Sell(0.1,_Symbol,bid,sl,tp);
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
      if(magic==magicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type");return false;}
         if(type ==POSITION_TYPE_BUY){cntBuy++;}
         if(type ==POSITION_TYPE_SELL){cntSell++;}
      }
   }

   return true;
}

// Function to close all open positions
int CloseOrders(){
   int total = PositionsTotal();
   
   
   for (int cnt=total-1;cnt>=0;cnt--){
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      ulong ticket = PositionGetTicket(cnt);
      
      if(magic == magicNumber){
         trade.PositionClose(ticket);
      }
   }
   return(0);
 }

