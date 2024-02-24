
import pandas as pd
import datetime as dt
import datetime
import csv

from market_data import HistData
from market_data import Options

import warnings
warnings.filterwarnings("ignore")

import os

eth_hdata = Options('ETH')
btc_hdata = Options('BTC')

ethpath =os.path.join(os.getcwd(),'data/eth_hist_option_chain.csv') 
btcpath =os.path.join(os.getcwd(),'data/btc_hist_option_chain.csv')

eth_options = eth_hdata.get_all_active_options()
btc_options = btc_hdata.get_all_active_options()
eth_options['Date']=[pd.datetime.today().strftime('%Y-%m-%d')]*len(eth_options)
btc_options['Date']=[pd.datetime.today().strftime('%Y-%m-%d')]*len(btc_options)
eth_options['Time']=[pd.datetime.today().time()]*len(eth_options)
btc_options['Time']=[pd.datetime.today().time()]*len(btc_options)

#eth_options.to_csv(ethpath)
#btc_options.to_csv(btcpath)

with open(ethpath,'a',newline = '') as csvfile:
    writer = csv.writer(csvfile)
    for i in range(len(eth_options)):
        temp = eth_options.reset_index()
        row = temp.iloc[i].values
        writer.writerow(row)
csvfile.close()

with open(btcpath,'a',newline = '') as csvfile:
    writer = csv.writer(csvfile)
    for i in range(len(btc_options)):
        temp = btc_options.reset_index()
        row = temp.iloc[i].values
        writer.writerow(row)
csvfile.close()
