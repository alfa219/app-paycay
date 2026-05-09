import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String firstName;
  final String email;
  final String phone;
  final double balance;
  final String rfid;
  final String role;

  const UserModel({
    this.uid = '',
    required this.name,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.balance,
    required this.rfid,
    this.role = 'user',
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = data['name'] as String? ?? '';
    return UserModel(
      uid: doc.id,
      name: name,
      firstName: data['firstName'] as String? ??
          (name.isEmpty ? '' : name.split(' ').first),
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      rfid: data['rfid'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'firstName': firstName,
        'email': email,
        'phone': phone,
        'balance': balance,
        'rfid': rfid,
        'role': role,
      };

  UserModel copyWith({
    String? name,
    String? firstName,
    String? phone,
    double? balance,
    String? rfid,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      email: email,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
      rfid: rfid ?? this.rfid,
      role: role ?? this.role,
    );
  }
}
