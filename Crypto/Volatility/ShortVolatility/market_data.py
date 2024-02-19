import asyncio
import websockets
import json
import pandas as pd
import datetime as dt
import nest_asyncio
from concurrent.futures import ThreadPoolExecutor
nest_asyncio.apply()

import datetime
from pandas.io.json import json_normalize
import numpy as np
from scipy import interpolate
import statsmodels.api as sm



async def call_api(msg):
   # Create API Websocket
   async with websockets.connect('wss://test.deribit.com/ws/api/v2') as websocket:
       await websocket.send(msg)
       while websocket.open:
           response = await websocket.recv()
           return response
def get_timeframes():
    timeframes = {'1min':1,'3min':3,'5min':5,'10min':10,'15min':15,'30min':30,'1hr':60,'2hr':'120','3hr':180,'6hr':360,'12hr':720,'1d':'1D'}
    return timeframes

def async_loop(api, message):
    return asyncio.get_event_loop().run_until_complete(api(message))
   

class HistData():
    def __init__(self,currency ='BTC'):
        self.url = 'https://www.deribit.com/api/v2/public/'
        self.currency = currency

    async def call_api(self,msg):
        # Create API Websocket
        async with websockets.connect('wss://test.deribit.com/ws/api/v2') as websocket:
            await websocket.send(msg)
            while websocket.open:
                response = await websocket.recv()
                return response
    def get_timeframes(self):
        timeframes = {'1min':1,'3min':3,'5min':5,'10min':10,'15min':15,'30min':30,'1hr':60,'2hr':'120','3hr':180,'6hr':360,'12hr':720,'1d':'1D'}
        return timeframes

    def async_loop(self,api, message):
        return asyncio.get_event_loop().run_until_complete(api(message))


    def get_hist_data(self,start, end, instrument, timeframe):
        '''
        Function generates historical price data for the instrument
        Params:
        1. start: the start date in unix time format * 1000
        2. end: the end date in unix time format * 1000
        3. instrument: the desired instrument of interest
        4. timeframe: determines the granularity of data used
        '''
        msg = \
            {
                "jsonrpc": "2.0",
                "id": 832,
                "method": "public/get_tradingview_chart_data",
                "params": {
                    "instrument_name": instrument,
                    "start_timestamp": start,
                    "end_timestamp": end,
                    "resolution": timeframe
                }
            }
        json_resp = async_loop(call_api, json.dumps(msg))
        res = json.loads(json_resp)
        df = pd.DataFrame(res['result'])
        df['ticks'] = df.ticks / 1000
        df['timestamp'] = [dt.datetime.fromtimestamp(date) for date in df.ticks]
        df.set_index('timestamp',inplace = True)
        return df

    def get_hist_vol_idx(self,start,end,timeframe):
        msg = \
        {
        "jsonrpc" : "2.0",
        "id" : 833,
        "method" : "public/get_volatility_index_data",
        "params" : {
            "currency" : self.currency,
            "start_timestamp" : start,
            "end_timestamp" : end,
            "resolution" : timeframe
        }
        }
        json_resp = async_loop(call_api,json.dumps(msg))
        res = json.loads(json_resp)
        df = pd.DataFrame(res['result']['data'])
        df.columns = ['timestamp','open','high','low','close']
        df['timestamp'] = [dt.datetime.fromtimestamp(date) for date in df['timestamp']/1000]
        df.set_index('timestamp',inplace = True)
        return df

    def get_idx_price(self):
        if self.currency == 'BTC':
            idx_name = 'btc_usd'
        elif self.currency =='ETH':
            idx_name ='eth_usd'
        elif self.currency =='SOL':
            idx_name = 'sol_usd'
        msg = \
            {"jsonrpc": "2.0",
            "method": "public/get_index_price",
            "id": 42,
            "params": {
                "index_name": idx_name}
            }
        json_resp = async_loop(call_api,json.dumps(msg))
        res = json.loads(json_resp)
        return res['result']['index_price']


class Options():
    def __init__(self,currency ='BTC'):
        self.url = 'https://www.deribit.com/api/v2/public/'
        self.currency = currency

    async def call_api(self,msg):
        # Create API Websocket
        async with websockets.connect('wss://test.deribit.com/ws/api/v2') as websocket:
            await websocket.send(msg)
            while websocket.open:
                response = await websocket.recv()
                return response
    def get_timeframes(self):
        timeframes = {'1min':1,'3min':3,'5min':5,'10min':10,'15min':15,'30min':30,'1hr':60,'2hr':'120','3hr':180,'6hr':360,'12hr':720,'1d':'1D'}
        return timeframes

    def async_loop(self,api, message):
        return asyncio.get_event_loop().run_until_complete(api(message))
    
    def get_all_active_options(self):
        import urllib.request, json
        url =  f"https://deribit.com/api/v2/public/get_instruments?currency={self.currency}&kind=option&expired=false"
        with urllib.request.urlopen(url) as url:
            data = json.loads(url.read().decode())
        data = pd.DataFrame(data['result']).set_index('instrument_name')
        data['creation_date'] = pd.to_datetime(data['creation_timestamp'], unit='ms')
        data['expiration_date'] = pd.to_datetime(data['expiration_timestamp'], unit='ms')
        print(f'{data.shape[0]} active options.')
        return data


    # Get Tick data for a given instrument from the Deribit API
    def get_tick_data(self,instrument_name):
        import urllib.request, json
        url =  f"https://deribit.com/api/v2/public/ticker?instrument_name={instrument_name}"
        with urllib.request.urlopen(url) as url:
            data = json.loads(url.read().decode())
        data = json_normalize(data['result'])
        #data.index = [instrument_name]
        return data
    ### Add additional metrics to data



    def get_atm_strike(curncy='BTC',type = 'C'):
        curr_price = get_idx_price(idx_name=curncy)
        active_options = get_all_active_options(currency = curncy)
        active_options['type'] = [cont[-1] for cont in active_options.index]
        active_options = active_options[active_options['type']==type]
        atm_cont = active_options.loc[(active_options['strike']-curr_price).abs().idxmin()].name
        return atm_cont
    
    def get_option_chain(self,target_expiry,option_type):
        eth_active_options = self.get_all_active_options()
        target_expiry = int((pd.to_datetime(target_expiry)+datetime.timedelta(20)).timestamp()*1000)
        print(target_expiry)
        eth_options = eth_active_options[(eth_active_options['expiration_timestamp']-target_expiry>0)]
        target_expiry = eth_options['expiration_timestamp'].iloc[0]
        print('Expiration Date: ',datetime.datetime.fromtimestamp(target_expiry/1000))

        desired_options = eth_active_options[(eth_active_options['expiration_timestamp']==target_expiry) & (eth_active_options['option_type']==option_type)]
        pool = ThreadPoolExecutor(max_workers = 20)
        option_chain = pd.DataFrame()
        for data in pool.map(self.get_tick_data,desired_options.index):
            option_chain= pd.concat([option_chain,data])
        option_chain['strike'] = [float(strike.split('-')[2]) for strike in option_chain['instrument_name']]
        option_chain['expiration_date'] = len(option_chain)*[datetime.datetime.fromtimestamp(target_expiry/1000)]
        option_chain['dte']= [(dt - pd.datetime.today()).days for dt in option_chain['expiration_date']]

        return option_chain


    

