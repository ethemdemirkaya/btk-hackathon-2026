class UserModel {
  final int id;
  final String name;
  final String email;
  final double monthlyIncome;
  final String? phone;
  final String? birthDate;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.monthlyIncome,
    this.phone,
    this.birthDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        monthlyIncome:
            (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
        phone: json['phone'] as String?,
        birthDate: json['birth_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'monthly_income': monthlyIncome,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birth_date': birthDate,
      };
}
