from django.shortcuts import render, redirect
from django.db.utils import IntegrityError
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from bfs_app.models import *
from web3 import Web3, eth
import json
import os
from infinite_loop_thread import get_usd_eth


def get_transaction_params(web3, value=0):
    return {
        'chainId': 5,
        'gas': 4000000,
        'gasPrice': 25000000,
        'nonce': web3.eth.getTransactionCount(web3.eth.account, 'pending'),
        'value': value
    }


def connect_to_infura():
    with open('solidity/tokens/infura', 'r') as infura:
        return Web3(Web3.HTTPProvider('https://goerli.infura.io/v3/' + infura.read()))


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


@login_required()
def profile(request):
    return render(request, 'profile.html', {'user': User.objects.get(username=request.user)})


@login_required()
def call_contract_function(request):
    if request.method == 'POST':
        function_type = request.POST['type']
        user = User.objects.get(username=request.user.username)
        _id, password = request.POST['id'], request.POST['id']
        if len(_id) < 42:
            _id = User.objects.get(username=_id).address
        if not user.check_password(password):
            return HttpResponse('Wrong password!')
        web3 = connect_to_infura()
        private_key = web3.eth.account.decrypt(keyfile_json=user.keystore, password=password)
        web3.eth.account = user.address
        if user.account_type == 0:
            if function_type == '0':
                amount = request.POST['amount']
                web3.eth.sendTransaction({'to': _id, 'from': web3.eth.account, 'value': amount * 10 ** 18})
            elif function_type == '1':
                amount = request.POST['amount']
                with open('solidity/abi/bfs_contracts_sol_User.abi', 'r') as abi:
                    tmp_contract = web3.eth.contract(address=user.user_contract_address, abi=abi.read())
                txn = tmp_contract.functions.setDeposit(
                    User.objects.get(address=_id).main_contract_address).buildTransaction(
                    get_transaction_params(web3, amount * 10 ** 18))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
            elif function_type == '2':
                with open('solidity/abi/bfs_contracts_sol_User.abi', 'r') as abi:
                    tmp_contract = web3.eth.contract(address=user.user_contract_address, abi=abi.read())
                txn = tmp_contract.functions.getMoneyFromDeposit(
                    User.objects.get(address=_id).main_contract_address).buildTransaction(
                    get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
        elif user.account_type == 1:
            if function_type == '0':
                amount = request.POST['amount']
                web3.eth.sendTransaction({'to': _id, 'from': web3.eth.account, 'value': amount * 10 ** 18})
            elif function_type == '1':
                percent, time = request.POST['percent'], request.POST['time']
                with open('solidity/abi/bfs_contracts_sol_Banker.abi', 'r') as abi:
                    tmp_contract = web3.eth.contract(address=user.banker_contract_address, abi=abi.read())
                txn = tmp_contract.functions.getDeposit(_id, percent, time).buildTransaction(
                    get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
            elif function_type == '2':
                with open('solidity/abi/bfs_contracts_sol_Banker.abi', 'r') as abi:
                    tmp_contract = web3.eth.contract(address=user.banker_contract_address, abi=abi.read())
                txn = tmp_contract.functions.returnMoney().buildTransaction(
                    get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)


@login_required()
def buy_account(request):
    if request.method == 'GET':
        return render(request, 'buy.html', {'account': request.GET.get('account', None), 'user': request.user})
    elif request.method == 'POST':
        username, password, acc_type = request.POST['username'], request.POST['password'], request.POST['type']
        user = User.objects.get(username=username)
        if user.check_password(password):
            web3 = connect_to_infura()
            private_key = web3.eth.account.decrypt(keyfile_json=user.keystore, password=password)
            web3.eth.account = web3.eth.account.privateKeyToAccount(private_key).address
            with open('solidity/abi/bfs_contracts_sol_Main.abi', 'r') as abi:
                tmp_contract = web3.eth.contract(address=user.main_contract_address, abi=abi.read())
            txn = tmp_contract.functions.addDays(1, int(request.POST['type'])).buildTransaction(
                get_transaction_params(web3, int(1.1 * get_usd_eth() * 10 ** 18) if acc_type == '0' else int(
                    1.1 * get_usd_eth() * 10 ** 19)))
            txn_hash = web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
            web3.eth.waitForTransactionReceipt(txn_hash)
            user.account_type = int(acc_type)
            user.save()

            return redirect('/')
        return HttpResponse('Wrong password')


def new_user(request):
    if request.method == 'POST':
        username, email, password, private_key = request.POST['username'], request.POST['email'], \
                                                 request.POST['password'], request.POST['private_key']
        if username and email and password and private_key:
            with open('solidity/abi/bfs_contracts_sol_Main.abi', 'r') as abi, \
                    open('solidity/bin/bfs_contracts_sol_Main.bin', 'r') as bytecode, \
                    open('solidity/abi/bfs_contracts_sol_Admin.abi', 'r') as admin_abi, \
                    open('solidity/tokens/private_key', 'r') as admin:
                abi = abi.read()
                admin_abi = admin_abi.read()
                admin_private_key = admin.read()

                web3 = connect_to_infura()

                """
                    Encrypt private key
                """
                keystore = web3.eth.account.encrypt(private_key=private_key, password=password)

                web3.eth.account = eth.Account.privateKeyToAccount(private_key=private_key).address

                """
                    Deploy Main contract
                """
                tmp_contract = web3.eth.contract(abi=abi, bytecode=bytecode.read())
                txn = tmp_contract.constructor().buildTransaction(get_transaction_params(web3))
                txn_hash = web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction)
                main_contract_address = web3.eth.waitForTransactionReceipt(txn_hash)['contractAddress']
                print(main_contract_address);
                """
                    Call createProfile() function from Main contract
                """
                tmp_contract = web3.eth.contract(abi=abi, address=main_contract_address)
                txn = tmp_contract.functions.createProfiles().buildTransaction(get_transaction_params(web3))
                web3.eth.waitForTransactionReceipt(
                    web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn, private_key).rawTransaction))

                """
                    Get addresses of User and Banker contracts
                """
                banker_contract_address = tmp_contract.functions.getBankerAddress().call()
                user_contract_address = tmp_contract.functions.getUserAddress().call()

                """
                    Send 2 overridden setUserAddress() functions of Admin contract
                """
                web3.eth.account = eth.Account.privateKeyToAccount(private_key=admin_private_key).address
                tmp_contract = web3.eth.contract(abi=admin_abi, address=os.environ['ADMIN_CONTRACT_ADDRESS'])
                txn1 = tmp_contract.functions.setUserAddress(web3.eth.account).buildTransaction(
                    get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn1, admin_private_key).rawTransaction)
                txn2 = tmp_contract.functions.setUserAddress(web3.eth.account, main_contract_address).buildTransaction(
                    get_transaction_params(web3))
                web3.eth.sendRawTransaction(eth.Account.sign_transaction(txn2, admin_private_key).rawTransaction)

                """
                    Create new User object
                """
                user = User.objects.create_user(username=username,
                                                email=email,
                                                password=password,
                                                keystore=json.dumps(keystore),
                                                address=web3.eth.account,
                                                main_contract_address=main_contract_address,
                                                user_contract_address=user_contract_address,
                                                banker_contract_address=banker_contract_address)
                user.save()
                login(request, authenticate(username=username, email=email, password=password))
                return redirect('/')
        else:
            return HttpResponse('Fill the form!')
    return HttpResponse('Only POST request!')
