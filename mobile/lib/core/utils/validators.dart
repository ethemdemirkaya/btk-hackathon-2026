class AppValidators {
  AppValidators._();

  static String? required(String? value, [String field = 'Bu alan']) {
    if (value == null || value.trim().isEmpty) return '$field zorunludur.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta zorunludur.';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(value.trim())) return 'Geçerli bir e-posta girin.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre zorunludur.';
    if (value.length < 8) return 'Şifre en az 8 karakter olmalı.';
    return null;
  }

  static String? passwordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) return 'Şifre tekrarı zorunludur.';
    if (value != password) return 'Şifreler eşleşmiyor.';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Tutar']) {
    if (value == null || value.trim().isEmpty) return '$field zorunludur.';
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null) return 'Geçerli bir sayı girin.';
    if (n < 0) return '$field sıfır veya daha büyük olmalı.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 && digits.length != 11) {
      return 'Geçerli bir telefon girin (05XX XXX XX XX).';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String field = 'Bu alan']) {
    if (value != null && value.length > max) {
      return '$field en fazla $max karakter olabilir.';
    }
    return null;
  }
}
