from django.shortcuts import render, redirect
from django.contrib.auth import authenticate
from bfs_app.models import *


def index(request):
    return render(request, 'index.html')


def about(request):
    return render(request, 'about.html')


def contacts(request):
    return render(request, 'contacts.html')


def login(request):
    return render(request, 'login.html')


def faq(request):
    return render(request, 'fuck u')


def new_user(request):
    if request.method == 'POST':
        username, email, wallet = request.POST['username'], request.POST['email'], request.POST['wallet']
        if username and email and wallet:
            user = User(username=username, email=email, wallet=wallet)
            user.save()
            authenticate(wallet=wallet)
            return redirect('/')
    else:
        return redirect('/')
