class Address {
  final String id;
  final String userId;
  final String? label;
  final String recipientName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String? postalCode;
  final String? deliveryNotes;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    this.country = 'Nigeria',
    this.postalCode,
    this.deliveryNotes,
    this.isDefault = false,
  });

  String get shortLine => '$addressLine1, $city, $state';

  factory Address.fromMap(Map<String, dynamic> m) {
    return Address(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      label: m['label'] as String?,
      recipientName: m['recipient_name'] as String,
      phone: m['phone'] as String,
      addressLine1: m['address_line1'] as String,
      addressLine2: m['address_line2'] as String?,
      city: m['city'] as String,
      state: m['state'] as String,
      country: (m['country'] ?? 'Nigeria') as String,
      postalCode: m['postal_code'] as String?,
      deliveryNotes: m['delivery_notes'] as String?,
      isDefault: (m['is_default'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'delivery_notes': deliveryNotes,
      'is_default': isDefault,
    };
  }
}