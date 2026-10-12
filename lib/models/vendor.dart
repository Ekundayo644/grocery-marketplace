class Vendor {
  final String id;
  final String userId;
  final String storeName;
  final String storeSlug;
  final String? storeDescription;
  final String? storeLogo;
  final String businessType;
  final String? cacNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? address;
  final String? city;
  final String? state;
  final String verificationStatus;
  final String? verificationNotes;
  final bool isActive;
  final double rating;
  final int totalOrders;
  final double totalRevenue;
  final double commissionRate;

  Vendor({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.storeSlug,
    this.storeDescription,
    this.storeLogo,
    required this.businessType,
    this.cacNumber,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.address,
    this.city,
    this.state,
    required this.verificationStatus,
    this.verificationNotes,
    required this.isActive,
    required this.rating,
    required this.totalOrders,
    required this.totalRevenue,
    required this.commissionRate,
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory Vendor.fromMap(Map<String, dynamic> m) {
    return Vendor(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      storeName: m['store_name'] as String,
      storeSlug: m['store_slug'] as String,
      storeDescription: m['store_description'] as String?,
      storeLogo: m['store_logo'] as String?,
      businessType: (m['business_type'] ?? 'individual') as String,
      cacNumber: m['cac_number'] as String?,
      bankName: m['bank_name'] as String?,
      bankAccountNumber: m['bank_account_number'] as String?,
      bankAccountName: m['bank_account_name'] as String?,
      address: m['address'] as String?,
      city: m['city'] as String?,
      state: m['state'] as String?,
      verificationStatus: (m['verification_status'] ?? 'pending') as String,
      verificationNotes: m['verification_notes'] as String?,
      isActive: (m['is_active'] ?? true) as bool,
      rating: ((m['rating'] ?? 0) as num).toDouble(),
      totalOrders: (m['total_orders'] ?? 0) as int,
      totalRevenue: ((m['total_revenue'] ?? 0) as num).toDouble(),
      commissionRate: ((m['commission_rate'] ?? 15) as num).toDouble(),
    );
  }
}