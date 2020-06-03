from django.shortcuts import render, redirect
from django.db.utils import IntegrityError
from django.contrib.auth import authenticate, login, logout
from django.http import HttpResponse
from bfs_app.models import *
from web3 import Web3, eth
import json
import os


def get_transaction_params(web3):
    return {
        'chainId': 5,
        'gas': 4000000,
        'gasPrice': web3.eth.gasPrice,
        'nonce': web3.eth.getTransactionCount(web3.eth.account, 'pending'),
    }


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
                    open('solidity/abi/bfs_contracts_sol_Admin.abi', 'r') as admin_abi, \
                    open('solidity/tokens/private_key', 'r') as admin, \
                    open('solidity/tokens/infura', 'r') as infura:
                abi = abi.read()
                admin_abi = admin_abi.read()

                web3 = Web3(Web3.HTTPProvider('https://goerli.infura.io/v3/' + infura.read()))

                """
                    Encrypt private key
                """
                keystore = web3.eth.account.encrypt(private_key=private_key, password=password)

                web3.eth.account = eth.Account.privateKeyToAccount(private_key=private_key).address

                """
                    Deploy Main contract
                """
                tmp_contract = web3.eth.contract(abi=abi, bytecode=bytecode.read())
                print(web3.eth.gasPrice)
                print(web3.eth.gasPrice * 300000 / 10**18)
                txn = tmp_contract.constructor().buildTransaction(get_transaction_params(web3))
                txn_hash = web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
                main_contract_address = web3.eth.waitForTransactionReceipt(txn_hash)['contractAddress']
                print(main_contract_address)

                """
                    Call createProfile() function from Main contract
                """
                tmp_contract = web3.eth.contract(abi=abi, address=main_contract_address)
                txn = tmp_contract.functions.createProfiles().buildTransaction(get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)

                """
                    Send 2 overridden setUserAddress() functions of Admin contract
                """
                web3.eth.account = eth.Account.privateKeyToAccount(private_key=admin.read()).address
                tmp_contract = web3.eth.contract(abi=admin_abi, address=os.environ['ADMIN_CONTRACT_ADDRESS'])
                txn1 = tmp_contract.functions.setUserAddress(web3.eth.account).buildTransaction(get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn1, private_key).rawTransaction)
                txn2 = tmp_contract.functions.setUserAddress(web3.eth.account, main_contract_address).buildTransaction(get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn2, private_key).rawTransaction)

                """
                    Create new User object
                """
                '''
                user = User.objects.create_user(username=username,
                                                email=email,
                                                password=password,
                                                keystore=str(keystore),
                                                main_contract_address=main_contract_address)
                user.save()
                login(request, authenticate(username=username, email=email, password=password))
                '''
    return redirect('/')
