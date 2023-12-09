//+------------------------------------------------------------------+
//|                                                     Sortable.mqh |
//|                                      Contact: kmavyrle@gmail.com |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
#include <Arrays/ArrayObj.mqh>
template <typename T> // can create with any base typename

class CSortable: public CObject {
public:
   // Use the templated type as the key
   T  key;
   // Next part is for comparison
   int   Compare(const CObject *node,const int mode = 0) const;
   
   
};
template <typename T>
int CSortable::Compare(const CObject *node,const int mode = 0) const{
   
   if (mode <=0)return (0);
   CSortable *comp = (CSortable*)node;
   
   if(comp.key==this.key) return (0);
   int result = ((this.key>comp.key)*2)-1;
   if (mode ==2) result *=-1;
   return (result);  
   
}
