from django.contrib import admin
from . import models

# Dynamically register all models
""" for model_name in dir(models):
    model = getattr(models, model_name)
    if isinstance(model, type) and issubclass(model, models.Model):
        admin.site.register(model)
         """
         
admin.site.register(models.Payment)
admin.site.register(models.Reservation)
admin.site.register(models.Ticket)
admin.site.register(models.User)