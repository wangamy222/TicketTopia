from django import forms

class LoginForm(forms.Form):
    uid = forms.CharField(max_length=50)
    password = forms.CharField(widget=forms.PasswordInput)