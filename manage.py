#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
from threading import Thread
from time import time, sleep
from web3 import Web3, HTTPProvider, eth
import requests
import json


def get_usd_eth():
    r = requests.get('https://min-api.cryptocompare.com/data/price?fsym=USD&tsyms=ETH')
    return json.loads(r.text)['ETH']


class UpdateSmartContract(Thread):
    def __init__(self):
        with open('infura_api_token', 'r') as file:
            self.w3 = Web3(HTTPProvider('https://ropsten.infura.io/v3/' + file.read()))
        self.prices = {
            1: 1,
            2: 10,
            3: 50,
            4: 2,
        }
        Thread.__init__(self)

    def update(self):
        with open('private_key', 'r') as file:
            private_key = file.read()
        abi = ''
        contract_address = ''
        self.w3.eth.account = '0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef'
        tmp_contract = self.w3.eth.contract(address=contract_address, abi=abi)
        for account in range(4):
            wei = self.prices[account] * get_usd_eth() / 10**18
            txn = tmp_contract.functions.setPrice(account, wei).buildTransaction(
                {
                    'chainId': 3,
                    'gas': 300000,
                    'gasPrice': self.w3.eth.gasPrice,
                    'nonce': self.w3.eth.getTransactionCount(self.w3.eth.account),
                    'value': 0,
                }
            )
            signed_txn = eth.Account.sign_transaction(txn, private_key)
            self.w3.eth.sendRawTransaction(signed_txn.rawTransaction)

    def run(self):
        next_time = time()
        while True:
            self.update()
            next_time += 12 * 60 * 60
            sleep_time = next_time - time()
            if sleep_time > 0:
                sleep(sleep_time)


def main():
    """
        Start infinite loop in second thread for updating Admin smart-contract every 12 hours
    """
    thread = UpdateSmartContract()
    thread.start()

    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bfs.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
