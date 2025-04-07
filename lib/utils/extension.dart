// String extension methods
extension StringExtension on String {
  /// Capitalizes the first letter of a string
  String capitalizeFirst() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
