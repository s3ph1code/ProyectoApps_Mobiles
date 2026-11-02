enum AccountStatus {
  active('active'),
  suspended('suspended'),
  deactivated('deactivated');

  const AccountStatus(this.code);

  final String code;

  static AccountStatus fromCode(String code) => AccountStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => AccountStatus.active,
  );
}
