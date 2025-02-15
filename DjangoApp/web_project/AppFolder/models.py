from django.db import models
from django.contrib.auth.models import AbstractUser
import datetime


class Customer(AbstractUser):
    username = models.CharField(max_length=50, unique=True)
    email = models.EmailField(unique=True, null=True)
    password = models.CharField(max_length=100)
    fullname = models.CharField(max_length=50, blank=True, null=True)
    address = models.CharField(max_length=50, blank=True, null=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
   
    def __str__(self):
        return self.username

class Flower(models.Model):
    name = models.CharField(primary_key=True, max_length=30)
    category = models.BooleanField(default=False)
    description = models.CharField(max_length=250, default="", null=True)
    quantity = models.IntegerField(null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to="uploads/flower/")

    def __str__(self):
        return self.name
    
class OrderItem(models.Model):
    item = models.ForeignKey(Flower, on_delete=models.CASCADE)
    quantity = models.IntegerField(default=0)
    amount = models.DecimalField(decimal_places=2, max_digits=5, default=2.99)

    def __str__(self):
        return self.item.name  
     
class Order(models.Model):
    order_number = models.AutoField(primary_key=True)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    date = models.DateField(default=datetime.date.today)
    items = models.ManyToManyField(OrderItem)
    status = models.CharField(max_length=20, default="Pending", choices=[
        ('Pending','Pending'),
        ('Placed', 'Placed'),
        ('Processing', 'Processing'),
        ('Shipped', 'Shipped'),
        ('Delivered', 'Delivered'),
        ('Canceled', 'Canceled'),
    ])
    
    def get_cart_item(self):
        return self.item.all()
    
    def get_cart_amount(self):
        return sum([item.amount for item in self.items.all()])
    
    def __str__(self):
        return str(self.order_number)
    
class CreditCard(models.Model):
    card_number = models.AutoField(primary_key=True)
    customer = models.OneToOneField(Customer, on_delete=models.CASCADE, unique=True)
    expire_date = models.DateField(auto_now=False, auto_now_add=False)
    CVV = models.CharField(max_length=3)

    def __str__(self):
        return str(self.card_number)

class Payment(models.Model):
    payment_number = models.AutoField(primary_key=True)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, unique=True)
    card_number = models.OneToOneField(CreditCard, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField(auto_now_add=True)

    def __str__(self):
        return str(self.payment_number)
