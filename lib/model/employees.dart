// Employee role enum matching the database enum
enum EmployeeRole {
  owner('Owner'),
  manager('Manager'),
  cashier('Cashier'),
  staff('Staff');

  const EmployeeRole(this.value);
  final String value;

  static EmployeeRole fromString(String value) {
    return EmployeeRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => EmployeeRole.staff,
    );
  }
}

// Base Employee model for the employees table
class Employee {
  final String id; // UUID from auth.users
  final String fullName;
  final String username;
  final String? phone;
  final bool isActive;
  final DateTime? deactivatedAt;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.fullName,
    required this.username,
    this.phone,
    this.isActive = true,
    this.deactivatedAt,
    required this.createdAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'] ?? '',
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      deactivatedAt: json['deactivated_at'] != null
          ? DateTime.parse(json['deactivated_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'is_active': isActive,
      'deactivated_at': deactivatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Employee copyWith({
    String? id,
    String? fullName,
    String? username,
    String? phone,
    bool? isActive,
    DateTime? deactivatedAt,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Store Employee model for the store_employees table
class StoreEmployee {
  final String id;
  final String storeId;
  final String employeeId;
  final EmployeeRole role;
  final DateTime createdAt;
  final Employee? employee; // Optional joined employee data

  StoreEmployee({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.role,
    required this.createdAt,
    this.employee,
  });

  factory StoreEmployee.fromJson(Map<String, dynamic> json) {
    return StoreEmployee(
      id: json['id'],
      storeId: json['store_id'],
      employeeId: json['employee_id'],
      role: EmployeeRole.fromString(json['role']),
      createdAt: DateTime.parse(json['created_at']),
      employee: json['employees'] != null
          ? Employee.fromJson(json['employees'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'employee_id': employeeId,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StoreEmployee copyWith({
    String? id,
    String? storeId,
    String? employeeId,
    EmployeeRole? role,
    DateTime? createdAt,
    Employee? employee,
  }) {
    return StoreEmployee(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      employee: employee ?? this.employee,
    );
  }

  // Helper to get display name
  String get displayName => employee?.fullName ?? 'Unknown Employee';

  // Helper to get phone
  String? get phone => employee?.phone;

  // Helper to get username
  String? get username => employee?.username;
}
