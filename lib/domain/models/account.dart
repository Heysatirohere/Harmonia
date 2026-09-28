/// Conta autenticada do usuário no HarmonIA (RF01 / RF18)
///
/// Representação agnóstica de provedor: a camada de apresentação nunca
/// manipula diretamente o `User` do Supabase.
class Account {
  final String id;
  final String email;
  final String? fullName;
  final DateTime? createdAt;

  const Account({
    required this.id,
    required this.email,
    this.fullName,
    this.createdAt,
  });

  /// Nome de exibição: nome completo ou prefixo do e-mail
  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  /// Inicial monogramada para o avatar editorial
  String get monogram => displayName.isEmpty ? '·' : displayName[0].toUpperCase();

  Account copyWith({String? email, String? fullName}) {
    return Account(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt,
    );
  }
}
