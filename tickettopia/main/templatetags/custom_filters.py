from django import template

register = template.Library()

@register.filter
def split_at(value, delimiter):
    return value.split(delimiter)[0]