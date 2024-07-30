from django.urls import path
from . import views
from django.contrib.auth import views as auth_views

urlpatterns = [
    path('', views.index, name='index'),
    path('concertinfo/', views.concertinfo, name='concertinfo'),
    path('reservation/', views.reservation, name='reservation'),
    path('reservationlog/', views.reservationlog, name='reservationlog'),
    path('reservationcheck/', views.reservationcheck, name='reservationcheck'),
    path('notice/', views.notice, name='notice'),
    path('join/', views.join, name='join'),
    path('join/joinSuccess/', views.joinSuccess, name='joinSuccess'),
    path('login/', views.user_login, name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
    path('create-payment/', views.create_payment, name='create_payment'),
    path('join-queue/', views.join_queue, name='join_queue'),
    path('check-queue-status/', views.check_queue_status,
         name='check_queue_status'),
    path('waiting-room/', views.waiting_room, name='waiting_room'),
]
