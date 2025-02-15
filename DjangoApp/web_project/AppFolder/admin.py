from django.contrib import admin
from .models import *

# Register your models here.
admin.site.register(Customer)
admin.site.register(Flower)
admin.site.register(Order)
admin.site.register(Payment)
admin.site.register(CreditCard)