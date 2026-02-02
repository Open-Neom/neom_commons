// import '../../utils/string_utilities.dart';
//
// extension NeomStringExtension on String {
//   /// capitalize the String
//   String get capitalize => StringUtilities.capitalize(this);
//   /// Capitalize the first letter of the String
//   String get capitalizeFirst => StringUtilities.capitalizeFirst(this);
//
// }
static String removeAllWhitespace(String value) {
return value.replaceAll(' ', '');
}