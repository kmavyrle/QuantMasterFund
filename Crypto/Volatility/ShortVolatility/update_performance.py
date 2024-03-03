import pandas as pd
import numpy as np
import nest_asyncio
nest_asyncio.apply()
import account_mgmt as accmgmt
import csv
import os

creds = pd.read_csv(r'C:\Users\kmavy\OneDrive\Desktop\credentials.csv')
#dep = float(input('Enter Deposit Amount:'))
client_id = creds['client_id'].values[0]
client_secret =creds['client_secret'].values[0]

ws = accmgmt.DeribitWS(client_id=client_id, client_secret=client_secret, live=True)
positions = ws.get_positions(currency='ETH')['result']
pnl,delta,vega,theta,gamma = 0,0,0,0,0


perf_path =os.path.join(os.getcwd(),'performance_analytics\\floating_rets.csv') 
greeks_path = os.path.join(os.getcwd(),'performance_analytics\\portfolio_greeks.csv') 

rets = pd.read_csv(r'performance_analytics\\floating_rets.csv',index_col = 0)
prev_rets = rets.sum()
print(prev_rets)



c=1
ret=0
for dets in positions:
    print(f"Position {dets['direction']} {dets['instrument_name']} Floating PnL:{dets['floating_profit_loss_usd']} Posn: {dets['direction']} {dets['size']}")
    ret+=(dets['total_profit_loss'])
    delta +=dets['delta']
    theta +=dets['theta']
    vega +=dets['vega']
    gamma+=dets['gamma']
    c+=1
print('Total Profit: ',ret)
ret = ret-prev_rets
print('''


''')



### Get Floating PnL
shortvolpnl = pd.DataFrame([ret[0]],index = [pd.datetime.today().strftime("%Y-%m-%d")],columns = ['daily_pnl'])
portfolio_greeks = pd.DataFrame(np.array([delta*10,vega,theta,gamma]).reshape(-1,4),index = [pd.datetime.today().strftime("%Y-%m-%d")],columns = ['delta10','vega','theta','gamma1000'])

with open(perf_path,'a',newline = '') as csvfile:
    writer = csv.writer(csvfile)
    for i in range(len(shortvolpnl)):
        temp = shortvolpnl.reset_index()
        row = temp.iloc[i].values
        writer.writerow(row)
csvfile.close()



with open(greeks_path,'a',newline = '') as csvfile:
    writer = csv.writer(csvfile)
    for i in range(len(portfolio_greeks)):
        temp = portfolio_greeks.reset_index()
        row = temp.iloc[i].values
        writer.writerow(row)
csvfile.close()





rets = pd.read_csv(r'performance_analytics\\floating_rets.csv',index_col = 0)
rets.index = [dt.strftime("%Y-%m-%d") for dt in pd.to_datetime(rets.index)]
rets = rets[~rets.index.duplicated(keep='last')]

### Get Realized PnL
start_dt = int(pd.to_datetime('20240101').timestamp()*1000)
end_dt = int(pd.datetime.today().timestamp()*1000)
trade_log = ws.get_trade_log("ETH",start_dt,end_dt)
realized_pnl = ws.get_agg_rel_pnl(trade_log)
realized_pnl = realized_pnl.sort_index()
rel_pnl_path = os.path.join(os.getcwd(),'performance_analytics\\realized_rets.csv') 
realized_pnl.to_csv(rel_pnl_path)

#Combine Realized and Floating PnL
print(rets,realized_pnl)

rets = pd.concat([rets,realized_pnl[['PnL']].groupby(realized_pnl.index).sum()],axis=1).fillna(0).sum(axis=1)
rets = pd.DataFrame(rets.cumsum(),columns = ['Cumulative Returns (ETH)'])
pic= rets.plot(title = 'Cumulative Returns (ETH)').get_figure()
pic.savefig('CumulativePerformance.png')

# Get Greeks
greeks = pd.read_csv(r'performance_analytics\\portfolio_greeks.csv',index_col = 0)
greeks= greeks[~greeks.index.duplicated(keep='last')]
pic = greeks.plot(title = 'Greeks Dollar Exposure').get_figure()
pic.savefig('GreeksExposure.png')

print('Success')