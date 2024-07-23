from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('concertinfo/', views.concertinfo, name='concertinfo'),
    path('reservation/', views.reservation, name='reservation'),
    path('reservationlog/', views.reservationlog, name='reservationlog'),
    path('reservation/reservationcheck/', views.reservationcheck, name='reservationcheck'),
    path('notice/', views.notice, name='notice'),
    path('join/', views.join, name='join'),
]