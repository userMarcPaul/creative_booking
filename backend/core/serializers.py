from rest_framework import serializers # type: ignore
from .models import User, IndustryCategory, SubCategory, CreativeProfile, Booking, ServicePackage, Product, Order , Contract, ChatMessage

# --- NEW: Registration Serializer ---
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'password', 'email', 'first_name', 'last_name', 'role']
        read_only_fields = ['id']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=validated_data.get('role', 'client')
        )
        return user


# --- EXISTING SERIALIZERS ---

class UserSerializer(serializers.ModelSerializer):
    is_email_verified = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'is_email_verified']

    def get_is_email_verified(self, obj):
        return hasattr(obj, 'email_otp') and obj.email_otp.is_verified

class IndustryCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = IndustryCategory
        fields = ['id', 'name', 'icon_code', 'description']


class SubCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SubCategory
        fields = ['id', 'name', 'industry']


class ServicePackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServicePackage
        fields = ['id', 'creative', 'title', 'description', 'price', 'delivery_time']


# -------------------------------
#  PRODUCT SERIALIZER
# -------------------------------
class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'creative', 'name', 'description', 'price', 'stock', 'image_url']

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        request = self.context.get('request')
        
        if instance.image_url and request:
            image_url = instance.image_url.url
            representation['image_url'] = request.build_absolute_uri(image_url)
            
        return representation


class OrderSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    client_name = serializers.CharField(source='client.username', read_only=True)

    class Meta:
        model = Order
        fields = ['id', 'client', 'client_name', 'product', 'product_name', 
                  'quantity', 'total_price', 'status', 'created_at']


# -------------------------------
#  CREATIVE PROFILE SERIALIZER
# -------------------------------
class CreativeProfileSerializer(serializers.ModelSerializer):
    # 1. User Info
    user = UserSerializer(read_only=True)
    
    # 2. SubCategory
    sub_category = SubCategorySerializer(read_only=True)
    sub_category_id = serializers.PrimaryKeyRelatedField(
        queryset=SubCategory.objects.all(), source='sub_category', write_only=True
    )

    # 3. Helper Fields
    role_name = serializers.CharField(source='sub_category.name', read_only=True)
    industry_name = serializers.CharField(source='sub_category.industry.name', read_only=True)
    
    # 4. Nested Data
    packages = ServicePackageSerializer(many=True, read_only=True)
    products = ProductSerializer(many=True, read_only=True)

    # 5. Profile Image URL
    profile_image_url = serializers.SerializerMethodField()

    class Meta:
        model = CreativeProfile
        fields = [
            'id', 'user', 'role_name', 'industry_name',
            'sub_category', 'sub_category_id',
            'bio', 'hourly_rate', 'rating', 'portfolio_url',
            'profile_image_url', 
            'is_verified', 'packages', 'products'
        ]

    def get_profile_image_url(self, obj):
        request = self.context.get('request')
        if obj.profile_image and request:
            return request.build_absolute_uri(obj.profile_image.url)
        return None


# -------------------------------
#  BOOKING SERIALIZER
# -------------------------------
class BookingSerializer(serializers.ModelSerializer):
    creative_name = serializers.CharField(source='creative.user.first_name', read_only=True)
    creative_role = serializers.CharField(source='creative.sub_category.name', read_only=True)
    client_name = serializers.CharField(source='client.username', read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'client', 'client_name',
            'creative', 'creative_name', 'creative_role',
            'booking_date', 'booking_time', 'project_type',
            'requirements', 'status', 'created_at'
        ]

class ContractSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contract
        fields = ['id', 'booking', 'body_text', 'is_client_signed', 'is_creative_signed', 'created_at']

# ==============================
# OTP VERIFICATION SERIALIZERS
# ==============================
class VerifyOTPSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    otp = serializers.CharField(max_length=6)


class ResendOTPSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()


# ===========================================
#  CHAT MESSAGE SERIALIZER (UPDATED)
# =========================================== 

class ChatMessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    # Optional: Add sender name for easier UI display
    sender_name = serializers.CharField(source='sender.username', read_only=True)

    class Meta:
        model = ChatMessage
        # IMPORTANT: Ensure 'message' matches your model field name. 
        # If your model uses 'content', change 'message' to 'content' here.
        fields = ['id', 'booking', 'sender', 'sender_id', 'sender_name', 'message', 'created_at']
        
        # FIX: Make booking read-only so the serializer doesn't complain it's missing from the body
        read_only_fields = ['booking', 'created_at']