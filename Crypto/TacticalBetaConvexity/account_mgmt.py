import asyncio
import websockets
import json
import nest_asyncio
import pandas as pd
import numpy as np
import datetime
from concurrent.futures import ThreadPoolExecutor
from functools import partial
nest_asyncio.apply()


class DeribitWS:

    def __init__(self, client_id, client_secret, live=False):

        if not live:
            self.url = 'wss://test.deribit.com/ws/api/v2'
        elif live:
            self.url = 'wss://www.deribit.com/ws/api/v2'
        else:
            raise Exception('live must be a bool, True=real, False=paper')


        self.client_id = client_id
        self.client_secret = client_secret

        self.auth_creds = {
              "jsonrpc" : "2.0",
              "id" : 0,
              "method" : "public/auth",
              "params" : {
                "grant_type" : "client_credentials",
                "client_id" : self.client_id,
                "client_secret" : self.client_secret
              }
            }
        self.test_creds()

        self.msg = {
            "jsonrpc": "2.0",
            "id": 0,
            "method": None,
        }

    async def pub_api(self, msg):
        async with websockets.connect(self.url) as websocket:
            await websocket.send(msg)
            while websocket.open:
                response = await websocket.recv()
                return json.loads(response)

    async def priv_api(self, msg):
        async with websockets.connect(self.url) as websocket:
            await websocket.send(json.dumps(self.auth_creds))
            while websocket.open:
                response = await websocket.recv()
                await websocket.send(msg)
                response = await websocket.recv()
                break
            return json.loads(response)

    @staticmethod
    def async_loop(api, message):
        return asyncio.get_event_loop().run_until_complete(api(message))

    def test_creds(self):
        response = self.async_loop(self.pub_api, json.dumps(self.auth_creds))
        if 'error' in response.keys():
            raise Exception(f"Auth failed with error {response['error']}")
        else:
            print("Authentication success")

    def market_order(self, instrument, amount, direction):
        params = {
                "instrument_name" : instrument,
                "amount" : amount,
                "type" : "market",
              }

        if direction.lower() == 'long':
            side = 'buy'
        elif direction.lower() == 'short':
            side = 'sell'
        else:
            raise ValueError('direction must be long or short')

        self.msg["method"] = f"private/{side}"
        self.msg["params"] = params

        response = self.async_loop(self.priv_api, json.dumps(self.msg))

        return response


    def limit_order(self, instrument, amount, direction, price,
                   post_only, reduce_only):
        params = {
            "instrument_name": instrument,
            "amount": amount,
            "type": "limit",
            "price": price,
            "post_only":  post_only,
            "reduce_only": reduce_only

        }
        if direction.lower() == 'long':
            side = 'buy'
        elif direction.lower() == 'short':
            side = 'sell'
        else:
            raise ValueError('direction must be long or short')

        self.msg["method"] = f"private/{side}"
        self.msg["params"] = params
        response = self.async_loop(self.priv_api, json.dumps(self.msg))
        return response

    # market data methods
    def get_data(self, instrument, start, end, timeframe):
        params =  {
                "instrument_name": instrument,
                "start_timestamp": start,
                "end_timestamp": end,
                "resolution": timeframe
            }

        self.msg["method"] = "public/get_tradingview_chart_data"
        self.msg["params"] = params

        data = self.async_loop(self.pub_api, json.dumps(self.msg))
        return data

    def get_orderbook(self, instrument, depth=5):
        params = {
            "instrument_name": instrument,
            "depth": depth
        }
        self.msg["method"] = "public/get_order_book"
        self.msg["params"] = params

        order_book = self.async_loop(self.pub_api, json.dumps(self.msg))
        return order_book

    def get_quote(self, instrument):
        params = {
            "instrument_name": instrument
        }
        self.msg["method"] = "public/ticker"
        self.msg["params"] = params
        quote = self.async_loop(self.pub_api, json.dumps(self.msg))

        return quote['result']['last_price']

    #account methods
    def account_summary(self, currency, extended=True):
        params = {
            "currency": currency,
            "extended": extended
        }

        self.msg["method"] = "private/get_account_summary"
        self.msg["params"] = params
        summary = self.async_loop(self.priv_api, json.dumps(self.msg))
        return summary

    def get_positions(self, currency, kind="option"):
        params = {
            "currency": currency,
            "kind": kind
        }
        self.msg["method"] = "private/get_positions"
        self.msg["params"] = params
        positions = self.async_loop(self.priv_api, json.dumps(self.msg))
        return positions
    

    def available_instruments(self, currency, kind="future", expired=False):
        params = {
            "currency": currency,
            "kind": kind,
            "expired": expired
        }

        self.msg["method"] = "public/get_instruments"
        self.msg["params"] = params
        resp = self.async_loop(self.pub_api, json.dumps(self.msg))
        instruments = [d["instrument_name"] for d in resp['result']]
        return instruments
    


#    def get_trade_hist(self,currency,count = 10):
#        params={
#            'currency':currency,
#            'count':count
#        }
#        self.msg['method'] = "private/get_trigger_order_history"
#        self.msg['params']=params
#        resp = self.async_loop(self.priv_api, json.dumps(self.msg))
#        return resp

    def get_trade_hist(self,currency,start,end):
        params={
            'currency':currency,
            'start_timestamp':start,
            'end_timestamp':end
        }
        self.msg['method'] = "private/get_transaction_log"
        self.msg['params']=params
        resp = self.async_loop(self.priv_api, json.dumps(self.msg))

        return resp
    
    def get_trade_log(self,currency,start,end):
        log = self.get_trade_hist(currency,start,end)
        logs = pd.DataFrame()
        ttd_instrument_hist = []
        for i in range(len(log['result']['logs'])):
            instrument = log['result']['logs'][i]['instrument_name']
            ttd_instrument_hist.append(instrument)
            #if instrument =="ETH-8MAR24-3600-C" or instrument =='ETH-8MAR':
            temp = pd.DataFrame(log['result']['logs'][i].values(),index =log['result']['logs'][i].keys())
            logs = pd.concat([logs,temp],axis=1)
        trade_log = logs.T
        trade_log.index = range(len(trade_log))
        trade_log['datetime'] = [datetime.datetime.fromtimestamp(int(str(dt)[:-3])) for dt in trade_log.timestamp]
        trade_log['Date'] = [dt.strftime("%Y-%m-%d") for dt in trade_log.datetime]
        trade_log['side']=trade_log['side'].replace('-',"N.A. N.A.")
        trade_log['direction'] = [side.split(" ")[1] for side in trade_log.side]
        trade_log['direction'] = [1 if direction =='buy' else -1 if direction =='sell' else 0 for direction in trade_log.direction]
        trade_log['trade_type'] = [side.split(" ")[0] for side in trade_log.side]
        return trade_log
    
    def get_realized_pnl(self,trade_log,instrument):
        def net_closing_px(exits):
            weighted_exit = sum(exits['direction']*exits['amount']*exits['price'])/sum(exits['amount'])
            return weighted_exit
        
        trade_log = trade_log[trade_log['instrument_name']==instrument]
        realized_position = sum((trade_log['direction']*trade_log['amount']).dropna())
        entries = trade_log[trade_log['trade_type']=='open']
        exits = trade_log[trade_log['trade_type']=='close']
        #return exits
        if exits.empty or entries.empty:
            return pd.DataFrame()
        weighted_entry = sum(entries['direction']*entries['amount']*entries['price'])/sum(entries['amount'])
        weighted_exits = exits.groupby('Date').apply(net_closing_px)
        weighted_exits = pd.DataFrame(weighted_exits,columns = ['PnL'])
        realized_pnl = -(weighted_exits - weighted_entry)
        realized_pnl['instrument']=[instrument]*len(realized_pnl)
        #realized_pnl = (weighted_exit - weighted_entry)/abs(realized_position)
        #print(weighted_entry,weighted_exit,realized_position)
        return realized_pnl
    
    def get_agg_rel_pnl(self,trade_log):
        pool = ThreadPoolExecutor(max_workers = 20)
        RealizedPnL = pd.DataFrame()
        agg_rel_pnl_func = partial(self.get_realized_pnl,trade_log)
        ttd_instruments = set(trade_log.instrument_name)
        for data in pool.map(agg_rel_pnl_func,ttd_instruments):
            RealizedPnL = pd.concat([RealizedPnL,data],axis=0)
        RealizedPnL['type'] = [len(i.split("-")) for i in RealizedPnL['instrument']]
        RealizedPnL['type'] = ['option' if i==4 else 'future' if i==2 else 'spot' if i==1 else "unknown" for i in RealizedPnL['type']]
        return RealizedPnL
