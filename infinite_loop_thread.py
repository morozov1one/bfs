import os
from threading import Thread, Event
from time import time, sleep
import datetime
from web3 import Web3, HTTPProvider, eth
import requests
import json


def get_usd_eth():
    r = requests.get('https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=ETH')
    return json.loads(r.text)['ETH']


class UpdateSmartContract(Thread):
    def __init__(self):
        Thread.__init__(self)
        with open('solidity/tokens/infura', 'r') as file:
            self.w3 = Web3(HTTPProvider('https://goerli.infura.io/v3/' + file.read()))
        self.prices = {
            0: 1,
            1: 10,
            2: 50,
            3: 2,
        }
        self.kill = Event()
        if datetime.datetime.now().time() < datetime.time(12):
            self.updated_midday = False
        else:
            self.updated_midday = True

    def update(self):
        with open('solidity/tokens/private_key', 'r') as file:
            private_key = file.read()
        with open('solidity/abi/bfs_contracts_sol_Admin.abi', 'r') as file:
            abi = file.read()
        contract_address = '0x3b1C4370D52692dFfbe0cFC9C2cc0935b0d0f747'
        self.w3.eth.account = '0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef'
        tmp_contract = self.w3.eth.contract(address=contract_address, abi=abi)
        eth.Account.privateKeyToAccount(private_key=private_key)
        for account in range(4):
            wei = int(self.prices[account] * get_usd_eth() * 10 ** 18)
            txn = tmp_contract.functions.setPrice(account, wei).buildTransaction(
                {
                    'chainId': 5,
                    'gas': 300000,
                    'gasPrice': self.w3.eth.gasPrice,
                    'nonce': self.w3.eth.getTransactionCount(self.w3.eth.account, 'pending'),
                }
            )
            signed_txn = eth.Account.sign_transaction(txn, private_key)
            self.w3.eth.sendRawTransaction(signed_txn.rawTransaction)

    def run(self):
        next_time = time()
        while not self.kill.is_set():
            sleep(30)
            if datetime.datetime.now().time() >= datetime.time(12) and not self.updated_midday:
                self.update()
                self.updated_midday = True
            if datetime.datetime.now().time() < datetime.time(12) and self.updated_midday:
                self.update()
                self.updated_midday = False

            """
            next_time += 12 * 60 * 60
            sleep_time = next_time - time()
            if sleep_time > 0:
                sleep(sleep_time)
            """


t = UpdateSmartContract()


def start_thread():
    """
        Start infinite loop in a thread for updating Admin smart-contract every 12 hours
    """
    global t
    t.start()


def stop_thread():
    global t
    t.kill.set()
    t.join()
