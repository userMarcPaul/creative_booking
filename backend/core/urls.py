from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    RegisterView, LoginView,
    IndustryList, SubCategoryList, CreativeList,
    BookingCreate, BookingList, BookingDetail,
    CreateCreativeProfile, CreativeProfileDetail,
    ProductList, ProductDetail, 
    OrderList, OrderDetail, 
    ServicePackageList,
    save_user_interests, 
    recommended_creatives,
    VerifyEmailOTP, 
    ResendEmailOTP,
    # Admin Views
    AdminPendingCreatives, admin_manage_creative,
    # Contract Views
    get_booking_contract, sign_contract,
    # Chat ViewSet
    ChatMessageViewSet 
)

# 1. Create a Router
router = DefaultRouter()
router.register(r'messages', ChatMessageViewSet, basename='chatmessage')

urlpatterns = [
    # --- Router URLs ---
    path('', include(router.urls)),

    # --- NEW: Nested Chat Path (Fixes the 404 Error) ---
    path('bookings/<int:booking_id>/messages/', ChatMessageViewSet.as_view({'get': 'list', 'post': 'create'}), name='booking-messages'),

    # Auth
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),

    # Email Verification
    path("verify-email/", VerifyEmailOTP.as_view(), name="verify-email"),
    path("resend-otp/", ResendEmailOTP.as_view(), name="resend-otp"),

    # Data & Search
    path('industries/', IndustryList.as_view(), name='industry-list'),
    path('subcategories/', SubCategoryList.as_view(), name='subcategory-list'),
    path('creatives/', CreativeList.as_view(), name='creative-list'),

    # Recommendations & Interests
    path('save-interests/', save_user_interests, name='save-interests'),
    path('creatives/recommended/', recommended_creatives, name='recommended-creatives'),

    # Products & Orders (E-commerce)
    path('products/', ProductList.as_view(), name='product-list'),
    path('products/<int:pk>/', ProductDetail.as_view(), name='product-detail'),
    
    # Orders
    path('orders/', OrderList.as_view(), name='order-list'),
    path('orders/<int:pk>/', OrderDetail.as_view(), name='order-detail'), 
    
    path('service-packages/', ServicePackageList.as_view(), name='service-package-list'),

    # Bookings (Services)
    path('bookings/', BookingCreate.as_view(), name='booking-create'),
    path('my-bookings/', BookingList.as_view(), name='booking-list'),
    path('bookings/<int:pk>/', BookingDetail.as_view(), name='booking-detail'),

    # Profile
    path('create-profile/', CreateCreativeProfile.as_view(), name='create-profile'),
    path('creative-profile/', CreativeProfileDetail.as_view(), name='creative-profile-detail'),

    # Contract
    path('contract/booking/<int:booking_id>/', get_booking_contract, name='get-contract'),
    path('contract/sign/<int:contract_id>/', sign_contract, name='sign-contract'),

    # Admin
    path('admin/pending-creatives/', AdminPendingCreatives.as_view(), name='admin-pending-list'),
    path('admin/manage-creative/<int:pk>/', admin_manage_creative, name='admin-manage-creative'),
]