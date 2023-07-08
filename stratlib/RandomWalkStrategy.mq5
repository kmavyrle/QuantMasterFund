#include <Trade/Trade.mqh>

CTrade trade;

input double Lots = 0.01;
input double LotFactor = 2;
input int TpPoints = 20;
input int SlPoints = 10;
input int Magic = 2023001;


int OnInit()
{
   trade.SetExpertMagicNumber(Magic);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

   
}

void OnTick(){
// On every tick, this transaction will run
   if(PositionsTotal()==0){
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double tp = ask + TpPoints * _Point; //0.00001 for EURUSD
      double sl = ask - SlPoints *_Point;
      
      ask = NormalizeDouble(ask,_Digits);
      tp = NormalizeDouble(tp,_Digits);
      sl = NormalizeDouble(sl,_Digits);
      
      
      
      trade.Buy(Lots,_Symbol,ask,sl,tp); // Buy order
   }
}

void  OnTradeTransaction(
// Triggered when a trade transaction is handled by MT5, opening/ closing etc..
   const MqlTradeTransaction&    trans,     // trade transaction structure 
   const MqlTradeRequest&        request,   // request structure 
   const MqlTradeResult&         result     // response structure 
   
   ){
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD){
   // That means there is new deal added to the order history
      CDealInfo deal;
      deal.Ticket(trans.deal);
      //HistorySelexct checks the historical transaction given the previous time
      HistorySelect(TimeCurrent()-PeriodSeconds(PERIOD_D1),TimeCurrent()+10); 
      //Check if the deal symbol is like the current chart sybol
      if (deal.Magic()==Magic && deal.Symbol()==_Symbol){
         
           Print(__FUNCTION__,">Close pos #",trans.position);
         if(deal.Entry()==DEAL_ENTRY_OUT){
            if(deal.DealType()==DEAL_TYPE_BUY){
            //If its a buy type that clsoe an open position this means that there was an open sell position
               double lots = deal.Volume()*LotFactor;
               lots = NormalizeDouble(lots,2);
               
               double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
               double tp = ask + TpPoints * _Point; //0.00001 for EURUSD
               double sl = ask - SlPoints *_Point;
               
               ask = NormalizeDouble(ask,_Digits);
               tp = NormalizeDouble(tp,_Digits);
               sl = NormalizeDouble(sl,_Digits);
               
               trade.Buy(lots,_Symbol,ask,sl,tp);
            }else if(deal.DealType()==DEAL_TYPE_SELL){
               double lots = deal.Volume()*LotFactor;
               lots = NormalizeDouble(lots,2);
               
               double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
               double tp = bid + TpPoints * _Point; //0.00001 for EURUSD
               double sl = bid - SlPoints *_Point;
               
               bid = NormalizeDouble(bid,_Digits);
               tp = NormalizeDouble(tp,_Digits);
               sl = NormalizeDouble(sl,_Digits);
               
               trade.Buy(lots,_Symbol,bid,sl,tp);
            
            }
         }
      }
   };
 };
