from django.core.cache import cache
from django.utils import timezone
from django.contrib.auth import get_user_model

def get_status_count():
    now = timezone.now()
    User = get_user_model()
    count = 0
    for user in User.objects.all():
        cache_key = f'user_last_seen_{user.uid}'
        last_seen = cache.get(cache_key)
        if last_seen and (now - last_seen).total_seconds() <= 300:
            count += 1
    return count