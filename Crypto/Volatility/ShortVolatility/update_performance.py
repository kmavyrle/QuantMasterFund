import pandas as pd
import numpy as np
import nest_asyncio
nest_asyncio.apply()
import account_mgmt as accmgmt
import csv
import os

creds = pd.read_csv(r'C:\Users\kmavy\OneDrive\Desktop\credentials.csv')

client_id = creds['client_id'].values[0]
client_secret =creds['client_secret'].values[0]

ws = accmgmt.DeribitWS(client_id=client_id, client_secret=client_secret, live=True)
positions = ws.get_positions(currency='ETH')['result']
pnl,delta,vega,theta,gamma = 0,0,0,0,0


perf_path =os.path.join(os.getcwd(),'performance_analytics\\perf_analytics.csv') 
greeks_path = os.path.join(os.getcwd(),'performance_analytics\\portfolio_greeks.csv') 

rets = pd.read_csv(r'performance_analytics\\perf_analytics.csv',index_col = 0)
prev_rets = (1+rets).prod()-1
dep = float(input('Enter Deposit Amount:'))
c=1
ret=0
for dets in positions:
    print(f"Position {dets['direction']} {dets['instrument_name']} PnL:",dets['floating_profit_loss_usd'])
    ret+=(dets['floating_profit_loss_usd']+dets['realized_profit_loss'])
    ret = ret/dep
    ret = ((1+ret)/(1+prev_rets))-1
    delta +=dets['delta']
    theta +=dets['theta']
    vega +=dets['vega']
    gamma+=dets['gamma']
    c+=1

print('''


''')

shortvolpnl = pd.DataFrame([ret[0]],index = [pd.datetime.today().strftime("%Y-%m-%d")],columns = ['daily_pnl'])
portfolio_greeks = pd.DataFrame(np.array([delta,vega,theta,gamma]).reshape(-1,4),index = [pd.datetime.today().strftime("%Y-%m-%d")],columns = ['delta','vega','theta','gamma'])



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


rets = pd.read_csv(r'performance_analytics\\perf_analytics.csv',index_col = 0)
rets = rets[~rets.index.duplicated(keep='last')]
pic = (((1+rets).cumprod()-1)*100).plot(title = 'Cumulative Returns (%)').get_figure()
pic.savefig('CumulativePerformance.png')

greeks = pd.read_csv(r'performance_analytics\\portfolio_greeks.csv',index_col = 0)
greeks= greeks[~greeks.index.duplicated(keep='last')]
pic = greeks.plot(title = 'Greeks Dollar Exposure').get_figure()
pic.savefig('GreeksExposure.png')