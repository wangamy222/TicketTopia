from django.shortcuts import render, redirect
from django.contrib import messages
from .models import User
from django.db import IntegrityError
from django.contrib.auth.hashers import make_password
from django.views.decorators.cache import never_cache
from django.contrib.auth import authenticate, login
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login
from django.shortcuts import render, redirect
from django.http import JsonResponse



from django.contrib.auth import authenticate, login
from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.contrib import messages
from .models import User
from django.contrib.auth.hashers import make_password
from django.db import IntegrityError
from django.views.decorators.cache import never_cache

import logging

logger = logging.getLogger(__name__)

def user_login(request):
    if request.method == 'POST':
        username = request.POST['uid']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return JsonResponse({'success': True})
        else:
            user_exists = User.objects.filter(uid=username).exists()
            if not user_exists:
                return JsonResponse({'success': False, 'message': 'User does not exist'})
            else:
                return JsonResponse({'success': False, 'message': 'Invalid credentials'})
    return render(request, 'login.html')


@never_cache
def join(request):
    if request.method == 'POST':
        uid = request.POST.get('uid')
        password = request.POST.get('password')
        name = request.POST.get('name')
        birthday = request.POST.get('birthday')
        phonenumber = request.POST.get('phonenumber')

        if not all([uid, password, name, birthday, phonenumber]):
            messages.error(request, '모든 필드를 입력해주세요.')
            return render(request, 'join.html')

        try:
            User.objects.create_user(
                uid=uid,
                password=password,  # This will be hashed in the manager
                name=name,
                birthday=birthday,
                phonenumber=phonenumber,
                state='active'
            )
            request.session['join_success'] = True
            return redirect('joinSuccess')
        except IntegrityError:
            messages.error(request, '이미 사용 중인 아이디입니다. 다른 아이디를 사용해 주세요.')
        except Exception as e:
            messages.error(request, f'오류가 발생했습니다: {str(e)}')

    return render(request, 'join.html')

@never_cache
def joinSuccess(request):
    if not request.session.pop('join_success', False):
        return redirect('join')
    return render(request, 'joinSuccess.html')


""" class Command(BaseCommand):
    help = 'Check if a password is correct for a given user'

    def add_arguments(self, parser): 
        parser.add_argument('uid', type=str)
        parser.add_argument('password', type=str)

    def handle(self, *args, **options):
        uid = options['uid']
        password = options['password']
        user = User.objects.get(uid=uid)
        is_correct = check_password(password, user.password)
        self.stdout.write(self.style.SUCCESS(f'Password is correct: {is_correct}'))


def user_login(request):
    if request.method == 'POST':
        username = request.POST['uid']
        password = request.POST['password']
        print(f"Attempting login with uid: {username}")  # Debugging line
        user = authenticate(request, username=username, password=password)
        if user is not None:
            print(f"Authentication successful for user: {user}")  # Debugging line
            login(request, user)
            return JsonResponse({'success': True})
        else:
            print("Authentication failed")  # Debugging line
            return JsonResponse({'success': False})
    return render(request, 'login.html') """

def index(request):
    return render(request, 'index.html')


""" def index(request):
    return render(request, 'index.html') """


def concertinfo(request):
    return render(request, 'concertinfo.html')


def reservation(request):
    if request.method == 'POST':
        # Handle form submission
        pass
    return render(request, 'reservation.html')


def reservationlog(request):
    return render(request, 'reservationlog.html')


def reservationNolog(request):
    return render(request, 'reservationNolog.html')


def reservationcheck(request):
    return render(request, 'reservationcheck.html')


def notice(request):
    return render(request, 'notice.html')


""" @never_cache
def join(request):
    if request.method == 'POST':
        uid = request.POST.get('uid')
        password = request.POST.get('password')
        name = request.POST.get('name')
        birthday = request.POST.get('birthday')
        phonenumber = request.POST.get('phonenumber')

        if not all([uid, password, name, birthday, phonenumber]):
            messages.error(request, '모든 필드를 입력해주세요.')
            return render(request, 'join.html')

        try:
            User.objects.create(
                uid=uid,
                password=make_password(password),
                name=name,
                birthday=birthday,
                phonenumber=phonenumber,
                state='active'
            )

            request.session['join_success'] = True
            # This should now match your URL name
            return redirect('joinSuccess')
        except IntegrityError:
            messages.error(request, '이미 사용 중인 아이디입니다. 다른 아이디를 사용해 주세요.')
        except Exception as e:
            messages.error(request, f'오류가 발생했습니다: {str(e)}')

    return render(request, 'join.html')


@never_cache
def joinSuccess(request):
    if not request.session.pop('join_success', False):
        return redirect('join')
    return render(request, 'joinSuccess.html') """
