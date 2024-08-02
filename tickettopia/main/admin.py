from django.contrib import admin
from django import forms
from . import models
from django.core.exceptions import ValidationError
from django.utils.dateparse import parse_date

class UserAdminForm(forms.ModelForm):
    class Meta:
        model = models.User
        fields = '__all__'
        widgets = {
            'birthday': forms.DateInput(attrs={'type': 'date'}),
            'created_at': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'last_login': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
        }

    def clean_birthday(self):
        birthday = self.cleaned_data.get('birthday')
        if isinstance(birthday, str):
            try:
                return parse_date(birthday)
            except ValueError:
                raise ValidationError('Invalid date format. Please use YYYY-MM-DD.')
        return birthday

class UserAdmin(admin.ModelAdmin):
    form = UserAdminForm
    list_display = ['uid', 'name', 'birthday', 'phonenumber', 'state', 'is_active', 'is_staff']
    list_filter = ['is_active', 'is_staff', 'state']
    search_fields = ['uid', 'name', 'phonenumber']

admin.site.register(models.User, UserAdmin)
admin.site.register(models.Payment)
admin.site.register(models.Reservation)
admin.site.register(models.Ticket)