class Store {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String? description;
  final String? location;
  final String status;
  final String? currency;
  final String? country;
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.description,
    this.location,
    required this.status,
    this.currency,
    this.country,
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      location: json['location'],
      status: json['status'],
      currency: json['currency'],
      country: json['country'],
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'description': description,
      'location': location,
      'status': status,
      'currency': currency,
      'country': country,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
