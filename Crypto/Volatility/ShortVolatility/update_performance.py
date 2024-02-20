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
c=1
for dets in positions:
    #print(dets)
    print(f"Position {dets['direction']} {dets['instrument_name']} PnL:",dets['floating_profit_loss_usd'])
    pnl+=dets['floating_profit_loss_usd']
    delta +=dets['delta']
    theta +=dets['theta']
    vega +=dets['vega']
    gamma+=dets['gamma']
    c+=1

print('''


''')

shortvolpnl = pd.DataFrame([pnl],index = [pd.datetime.today()],columns = ['daily_pnl'])
portfolio_greeks = pd.DataFrame(np.array([delta,vega,theta,gamma]).reshape(-1,4),index = [pd.datetime.today()],columns = ['delta','vega','theta','gamma'])

perf_path =os.path.join(os.getcwd(),'performance_analytics\\perf_analytics.csv') 
greeks_path = os.path.join(os.getcwd(),'performance_analytics\\portfolio_greeks.csv') 

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
pic = rets.plot(title = 'Cumulative Returns (USD)').get_figure()
pic.savefig('CumulativePerformance.png')

