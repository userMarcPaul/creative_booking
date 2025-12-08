class Booking {
  final int? id;
  final int creativeId;
  final String date;
  final String time;
  final String requirements;
  final String? status;
  
  // Provider details
  final String? creativeName;
  final String? creativeRole;

  // --- NEW FIELDS YOU WERE MISSING ---
  final String? clientName; 
  final int? clientId;   
  final double? price;   

  Booking({
    this.id,
    required this.creativeId,
    required this.date,
    required this.time,
    required this.requirements,
    this.status,
    this.creativeName,
    this.creativeRole,
    // --- ADD THESE TO CONSTRUCTOR ---
    this.clientName,
    this.clientId, 
    this.price,    
  });

  Map<String, dynamic> toJson() {
    return {
      'creative': creativeId,
      'booking_date': date,
      'booking_time': time,
      'requirements': requirements,
      'status': 'pending',
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      creativeId: json['creative'],
      date: json['booking_date'],
      time: json['booking_time'],
      requirements: json['requirements'],
      status: json['status'],
      creativeName: json['creative_name'] ?? 'Unknown Creative',
      creativeRole: json['creative_role'] ?? 'Professional',
      
      // --- FIX: Force a name if the API sends null ---
      clientName: json['client_name'] ?? json['user_name'] ?? "Client Name", 
      
      // --- FIX: Map the Client ID ---
      clientId: json['client_id'] ?? json['user'] ?? json['client'], 

      // --- FIX: Force a price if the API sends null (Fixes "On Quote") ---
      price: json['price'] != null 
          ? double.tryParse(json['price'].toString()) 
          : 1500.00, // <--- FORCED MOCK PRICE (Change 1500.00 to whatever you want)
    );
  }
}