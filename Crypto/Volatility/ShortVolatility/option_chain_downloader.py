
import pandas as pd
import datetime as dt
import datetime
import csv

from market_data import HistData
from market_data import Options

import warnings
warnings.filterwarnings("ignore")

import os

eth_opt = Options('ETH')
btc_opt = Options('BTC')
eth_hdata = HistData('ETH')
btc_hdata = HistData('BTC')

btc_spot = btc_hdata.get_idx_price()
eth_spot = eth_hdata.get_idx_price()

ethpath =os.path.join(os.getcwd(),'data/eth_hist_option_chain.csv') 
btcpath =os.path.join(os.getcwd(),'data/btc_hist_option_chain.csv')



eth_options = eth_opt.get_full_option_chain(eth_spot)
btc_options = btc_opt.get_full_option_chain(btc_spot)


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


