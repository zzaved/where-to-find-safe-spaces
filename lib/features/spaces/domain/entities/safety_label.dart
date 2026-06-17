/// The three safety classifications a place can have.
enum SafetyLabel {
  safe('safe'),
  neutral('neutral'),
  notSafe('not_safe');

  const SafetyLabel(this.apiValue);

  /// Value as stored/returned by the backend.
  final String apiValue;

  static SafetyLabel fromApi(String? value) {
    return SafetyLabel.values.firstWhere(
      (label) => label.apiValue == value,
      orElse: () => SafetyLabel.neutral,
    );
  }
}
