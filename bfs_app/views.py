from django.shortcuts import render


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
