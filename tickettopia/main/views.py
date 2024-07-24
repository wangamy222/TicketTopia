from django.shortcuts import render, redirect
from django.views.decorators.cache import never_cache
from django.contrib.auth import authenticate, login
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.db import transaction
from .models import User, Payment

import logging
logger = logging.getLogger(__name__)


def reservationlog(request):
    if request.user.is_authenticated:
        try:
            # First filter, then get the latest
            payments = Payment.objects.filter(uid=request.user.uid).order_by('-seq')
            if payments.exists():
                payment = payments.first()
            else:
                payment = None
        except Payment.DoesNotExist:
            payment = None
    else:
        payment = None

    context = {
        'payment': payment,
        'user': request.user,
    }
    return render(request, 'reservationlog.html', context)


def reservationcheck(request):
    if request.user.is_authenticated:
        try:
            # First filter, then get the latest
            payments = Payment.objects.filter(uid=request.user.uid).order_by('-seq')
            if payments.exists():
                payment = payments.first()
            else:
                payment = None
        except Payment.DoesNotExist:
            payment = None
    else:
        payment = None

    context = {
        'payment': payment,
        'user': request.user,
    }
    return render(request, 'reservationcheck.html', context)

@csrf_exempt
@require_POST
def create_payment(request):
    try:
        with transaction.atomic():
            last_payment = Payment.objects.last()
            seq = last_payment.seq + 1 if last_payment else 1

            payment = Payment.objects.create(
                pid=f"ET-{seq}",
                tid=f"TS-07272024-{seq}",
                uid=request.user.uid if request.user.is_authenticated else 'anonymous',
                uname=request.user.name if request.user.is_authenticated else 'Anonymous',
                state='1'
            )

        return JsonResponse({
            'success': True,
            'pid': payment.pid,
            'tid': payment.tid
        })
    except Exception as e:
        return JsonResponse({'success': False, 'error': str(e)})
        
""" @csrf_exempt
@require_POST
def create_payment(request):
    try:
        with transaction.atomic():
            last_payment = Payment.objects.last()
            seq = last_payment.seq + 1 if last_payment else 1

            if seq > 30000:
                # Raise an exception to stop the reservation process
                raise Exception('Reservation limit exceeded. Reservation stopped.')

            payment = Payment.objects.create(
                pid=f"ET-{seq}",
                tid=f"TS-07272024-{seq}",
                uid=request.user.uid if request.user.is_authenticated else 'anonymous',
                uname=request.user.name if request.user.is_authenticated else 'Anonymous',
                state='1'
            )

            return JsonResponse({
                'success': True,
                'pid': payment.pid,
                'tid': payment.tid
            })

    except Exception as e:
        return JsonResponse({'success': False, 'error': str(e)}) """


@login_required
def reservation_view(request):
    context = {
        'logged_in_user_name': request.user.name  
    }
    print(f"Passing user name to template: {request.user.name}")  
    return render(request, 'reservation.html', context)


def user_login(request):
    if request.method == 'POST':
        username = request.POST['uid']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return JsonResponse({'success': True, 'redirect_url': '/'})
        else:
            user_exists = User.objects.filter(uid=username).exists()
            if not user_exists:
                return JsonResponse({'success': False, 'message': '등록된 사용자가 아닙니다'})
            else:
                return JsonResponse({'success': False, 'message': 'Invalid credentials'})

    return render(request, 'login.html', {'user': request.user})



def join(request):
    if request.method == 'POST':
        uid = request.POST.get('uid')
        password = request.POST.get('password')
        name = request.POST.get('name')
        birthday = request.POST.get('birthday')
        phonenumber = request.POST.get('phonenumber')

        if not all([uid, password, name, birthday, phonenumber]):
            return JsonResponse({'success': False, 'message': '모든 필드를 입력해주세요.'})

        try:
            if User.objects.filter(uid=uid).exists():
                return JsonResponse({'success': False, 'message': '이미 사용 중인 아이디입니다. 다른 아이디를 사용해 주세요.'})

            User.objects.create_user(
                uid=uid,
                password=password,
                name=name,
                birthday=birthday,
                phonenumber=phonenumber,
                state='active'
            )
            return JsonResponse({'success': True, 'message': '회원가입이 완료되었습니다.', 'redirect_url': '/'})
        except Exception as e:
            return JsonResponse({'success': False, 'message': f'오류가 발생했습니다: {str(e)}'})

    return render(request, 'join.html')

@never_cache
def joinSuccess(request):
    if not request.session.pop('join_success', False):
        return redirect('join')
    return render(request, 'joinSuccess.html')


def index(request):
    return render(request, 'index.html')


def concertinfo(request):
    return render(request, 'concertinfo.html')


def reservation(request):
    if request.method == 'POST':
        pass
    return render(request, 'reservation.html')


def notice(request):
    return render(request, 'notice.html')
