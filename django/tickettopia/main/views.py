from django.shortcuts import render

def index(request):
    return render(request, 'index.html')

def concertinfo(request):
    return render(request, 'concertinfo.html')

def reservation(request):
    if request.method == 'POST':
        # Handle form submission
        pass
    return render(request, 'reservation.html')


def reservationlog(request):
    return render(request, 'reservationlog.html')

def reservationcheck(request):
    return render(request, 'reservationcheck.html')

def notice(request):
    return render(request, 'notice.html')

def join(request):
    if request.method == 'POST':
        # Handle form submission
        pass
    return render(request, 'join.html')