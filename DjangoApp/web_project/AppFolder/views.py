from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpRequest, HttpResponse, JsonResponse
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from .forms import *
from django.contrib.auth import update_session_auth_hash
from .models import *
from django.db.models import Q


# Create your views here.
   
def main(request):  
    flowers = Flower.objects.all()
    return render(request, "AppFolder/main.html", {'flowers': flowers})

def search(request):
    
    # Get the search term from the query parameters
    search_term = request.GET.get('search', '')
    print(f"Search Term: {search_term}")
    # Perform a case-insensitive search on the flower names
    flowers = Flower.objects.filter(Q(name__icontains=search_term))
    context = {
        'flowers': flowers,
    }

    return render(request, 'AppFolder/search.html', context)
    
def bouquet(request):
    flowers = Flower.objects.all()
    return render(request, 'AppFolder/bouquet.html', {'flowers': flowers})

def article(request):
    return render(request, "AppFolder/article.html")

def user_logout(request):
    logout(request)
    messages.success(request,("you have been logged out!"))
    return redirect('main')

def user_login(request):
    if request.method == 'POST':
        login_form = Login(request.POST)
        if login_form.is_valid():
            username = login_form.cleaned_data['username']
            password = login_form.cleaned_data['password']
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                # Redirect to home page
                return redirect('main')
            else:
                # Authentication failed
                login_form.add_error(None, 'Invalid username or password')
    else:
        login_form = Login()

    return render(request, 'AppFolder/login.html', {'login_form': login_form})


def registration(request):
    if request.method == 'POST':
        registration_form = Registration(request.POST)
        if registration_form.is_valid():
            registration_form.save()
            username = registration_form.cleaned_data['username']
            password = registration_form.cleaned_data['password1']
            user = authenticate(request, username=username, password=password)
            login(request, user)
            
            return redirect('main')
        else:
            # Authentication failed
            registration_form.add_error(None, 'Invalid username or password')
    else:
        registration_form = Registration()

    return render(request, 'AppFolder/registration.html', {'registration_form': registration_form})

def profile(request):
    if request.method == 'POST':
        # Update User Information
        update_info_form = UpdateInfoForm(request.POST, instance=request.user)
        if update_info_form.is_valid():
            update_info_form.save()
            return redirect('profile')

        # Change Password
        change_password_form = ChangePasswordForm(request.POST)
        if change_password_form.is_valid():
            current_password = change_password_form.cleaned_data['current_password']
            new_password = change_password_form.cleaned_data['new_password']
            confirm_new_password = change_password_form.cleaned_data['confirm_new_password']

            if request.user.check_password(current_password) and new_password == confirm_new_password:
                request.user.set_password(new_password)
                request.user.save()
                update_session_auth_hash(request, request.user)  # Update session to prevent logout
                return redirect('profile')
    
    else:
        update_info_form = UpdateInfoForm(instance=request.user)
        change_password_form = ChangePasswordForm()
    return render(request, "AppFolder/profile.html")


def payment(request):
    order_instance = Order.objects.get(customer=request.user, status='Pending')
    cart_items = OrderItem.objects.filter(order=order_instance)
    total_price = sum(item.amount for item in cart_items)

    if request.method == 'POST':
        form = Payment(request.POST)
        if form.is_valid():
            # Process the payment logic
            messages.success(request, "Thank you! The order is placed")
            return redirect('main')
        else:
            form.add_error(None, 'Invalid payment')
    else:
        form = Payment()

    context = {'form': form, 'total_price': total_price}  # Include 'total_price' in the context
    return render(request, 'AppFolder/payment.html', context)

def flower_detail(request, flower_name):
    flower = get_object_or_404(Flower, name=flower_name)
    return render(request, 'AppFolder/flower_detail.html', {'flower': flower})



def add_to_cart(request, flower_name):
    # Get the flower object
    flower = get_object_or_404(Flower, name=flower_name)

    # Check if the user has an active order, if not, create one
    if not request.user.is_authenticated:
        messages.error(request, 'You need to be logged in to add items to your cart.')
        return redirect('login')

    customer = request.user
    order, created = Order.objects.get_or_create(customer=customer, status='Pending')

    # Check if the flower is already in the cart, if yes, update quantity
    order_item, created = OrderItem.objects.get_or_create(item=flower, amount=flower.price)

    # Update the quantity and amount
    quantity = int(request.POST.get('quantity', 1))
    order_item.quantity += quantity
    order_item.amount = order_item.quantity * flower.price
    order_item.save()

    # Associate the order item with the order
    order.items.add(order_item)

    messages.success(request, f'{flower.name} added to your cart.')

    return redirect('cart')

def cart(request):
    # Retrieve cart items for the current user
    cart_items = OrderItem.objects.filter(order__customer=request.user)

    # Calculate total price
    total_price = sum(item.amount for item in cart_items)

    context = {
        'cart_items': cart_items,
        'total_price': total_price,
    }

    return render(request, 'AppFolder/cart.html', context)