from django.db import models # type: ignore
from django.contrib.auth.models import AbstractUser, User # type: ignore
from datetime import datetime, timedelta
from django.utils import timezone

import random
# 1. Custom User Model
class User(AbstractUser):
    ROLE_CHOICES = (
        ('client', 'Client'),
        ('creative', 'Creative Professional'),
        ('admin', 'Platform Admin'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='client')
    phone_number = models.CharField(max_length=15, blank=True, null=True)

    def __str__(self):
        return f"{self.username} ({self.role})"
    
# 1.5 Email OTP for Verification
class EmailOTP(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="email_otp")
    otp_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_verified = models.BooleanField(default=False)

    def generate_otp(self):
        self.otp_code = str(random.randint(100000, 999999))
        self.created_at = timezone.now()
        self.save()
        return self.otp_code

    def is_expired(self):
        return self.created_at < timezone.now() - timedelta(minutes=10)


# 2. Industry Category
class IndustryCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    icon_code = models.CharField(max_length=50, help_text="Flutter icon name (e.g. 'camera')", default='circle')
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "Industry Categories"

    def __str__(self):
        return self.name

# 3. Sub-Category
class SubCategory(models.Model):
    industry = models.ForeignKey(IndustryCategory, related_name='subcategories', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    
    class Meta:
        verbose_name_plural = "Sub Categories (Roles)"
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.industry.name})"

# 4. Creative Profile
class CreativeProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='creative_profile')
    sub_category = models.ForeignKey(SubCategory, on_delete=models.PROTECT, related_name='creatives')
    
    bio = models.TextField(help_text="Tell clients about your experience.")
    portfolio_url = models.URLField(blank=True, null=True)
    
    # Profile Image for the avatar in the app
    profile_image = models.ImageField(upload_to='creative_avatars/', blank=True, null=True)
    
    # Kept as hourly_rate as requested
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    is_verified = models.BooleanField(default=False, help_text="Admin must check this to list the profile.")
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.sub_category.name}"

# 5. Bookings (Services)
class Booking(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('disputed', 'Disputed'),
    )

    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookings_made')
    creative = models.ForeignKey(CreativeProfile, on_delete=models.CASCADE, related_name='bookings_received')
    package = models.ForeignKey('ServicePackage', on_delete=models.SET_NULL, null=True, blank=True)

    booking_date = models.DateField()
    booking_time = models.TimeField()
    
    project_type = models.CharField(max_length=50, default='Hourly')
    requirements = models.TextField()
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Booking: {self.client.username} -> {self.creative.user.username} ({self.status})"

# 6. Service Packages
class ServicePackage(models.Model):
    creative = models.ForeignKey(CreativeProfile, on_delete=models.CASCADE, related_name='packages')
    title = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_time = models.CharField(max_length=100)
    
    def __str__(self):
        return f"{self.title} - {self.price}"

# 7. Physical Products
class Product(models.Model):
    creative = models.ForeignKey(CreativeProfile, on_delete=models.CASCADE, related_name='products')
    name = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.IntegerField(default=1)
    
    image_url = models.ImageField(upload_to='product_images/', blank=True, null=True)
    
    def __str__(self):
        return f"{self.name} (${self.price})"

# 8. Orders (Products)
class Order(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    )
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders_made')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='orders_received')
    quantity = models.IntegerField(default=1)
    total_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.total_price:
            self.total_price = self.product.price * self.quantity
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Order: {self.client.username} bought {self.product.name}"

# 9. NEW: User Interests (For Recommendations)
class UserInterest(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='interests')
    sub_category = models.ForeignKey(SubCategory, on_delete=models.CASCADE, related_name='interested_users')

    class Meta:
        unique_together = ('user', 'sub_category') # Prevent duplicate interests

    def __str__(self):
        return f"{self.user.username} -> {self.sub_category.name}"
    


# 10. Contract Agreement
class Contract(models.Model):
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='contract')
    body_text = models.TextField(help_text="The legal text of the agreement.")
    
    is_client_signed = models.BooleanField(default=False)
    client_signed_at = models.DateTimeField(null=True, blank=True)
    
    is_creative_signed = models.BooleanField(default=False)
    creative_signed_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Contract #{self.id} for Booking #{self.booking.id}"


# ... (existing imports)

class ChatMessage(models.Model):
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Message by {self.sender.username} in Booking #{self.booking.id}"