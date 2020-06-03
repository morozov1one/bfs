from django.shortcuts import render, redirect
from django.db.utils import IntegrityError
from django.contrib.auth import authenticate, login, logout
from django.http import HttpResponse
from bfs_app.models import *
from web3 import Web3, eth
import json


def index(request):
    return render(request, 'index.html', {'user': request.user})


def about(request):
    return render(request, 'about.html')


def contacts(request):
    return render(request, 'contacts.html')


def faq(request):
    return render(request, 'fuck u')


def logout_view(request):
    logout(request)
    return redirect('/')


def new_user(request):
    if request.method == 'POST':
        username, email, password, private_key = request.POST['username'], request.POST['email'], \
                                                 request.POST['password'], request.POST['private_key']
        if username and email and password and private_key:
            with open('solidity/abi/bfs_contracts_sol_Main.abi', 'r') as abi, \
                    open('solidity/bin/bfs_contracts_sol_Main.bin', 'r') as bytecode, \
                    open('solidity/tokens/infura', 'r') as infura:
                web3 = Web3(Web3.HTTPProvider('https://goerli.infura.io/v3/' + infura.read()))
                keystore = web3.eth.account.encrypt(private_key=private_key, password=password)
                acc = eth.Account.privateKeyToAccount(private_key=private_key)
                web3.eth.account = acc.address
                tmp_contract = web3.eth.contract(abi=abi.read(), bytecode=bytecode.read())
                print(tmp_contract)
                txn = tmp_contract.constructor().buildTransaction(
                    {
                        'chainId': 5,
                        'gas': 8000000,
                        'gasPrice': web3.eth.gasPrice,
                        'nonce': web3.eth.getTransactionCount(web3.eth.account, 'pending'),
                    }
                )
                signed_txn = eth.Account.sign_transaction(txn, private_key)
                txn_hash = web3.eth.sendRawTransaction(signed_txn.rawTransaction)
                tx_receipt = web3.eth.waitForTransactionReceipt(txn_hash)
                print(tx_receipt)

                user = User.objects.create_user(username=username, email=email, password=password,
                                                keystore=str(keystore), main_contract_address=tx_receipt['contractAddress'])
                user.save()
                login(request, authenticate(username=username, email=email, password=password))
    return redirect('/')
