#!/usr/bin/env dscript

/*
@pubspec.yaml
name: pcd
dependencies:
  path:
  args:
*/

import 'package:path/path.dart' as p;


/// Returns true, if [path] has extension [ext], case and leading dot insensitive.
///
bool hasExtOf(String path, String ext) {
  var e = ext == "" || ext[0] == "." ? ext : "." + ext;

  return p.extension(path).toUpperCase() == e.toUpperCase();
}


/// Compares two lists of integers, string-style.
///
int arrayCmp(List<int> x, List<int> y) {
  if(x.length == 0) return y.length == 0 ? 0 : -1;
  if(y.length == 0) return x.length == 0 ? 0 : 1;
  var i = 0;
  for(; x[i] == y[i]; i++) {
    if(i == x.length - 1 || i == y.length - 1) {
      // The short array is a prefix of the long one; end reached. All is equal so far.
      if(x.length == y.length) return 0;  // The long array is no longer than the short one.
      return x.length < y.length ? -1 : 1;
    }
  }
  // Difference encountered.
  return x[i] < y[i] ? -1 : 1;
}


/// If both strings contain digits, returns numerical comparison based on the numeric
/// values embedded in the strings, otherwise returns the standard string comparison.
/// The idea of the natural sort as opposed to the standard lexicographic sort is one of coping
/// with the possible absence of the leading zeros in 'numbers' of files or directories.
///
int strcmpNaturally(String x, String y) {
  var a = strStripNumbers(x), b = strStripNumbers(y);

  return a.length != 0 && b.length != 0 ? arrayCmp(a, b) : x.compareTo(y);
}


/// Returns a vector of integer numbers, embedded in [s].
///
List<int> strStripNumbers(String s) {
  var num = new RegExp(r'\d+');

  return num.allMatches(s).map((m) => int.parse(m[0])).toList();
}


/// Reduces comma delimited list of [authors] to initials.
/// 
String makeInitials(String authors) {
  var rSep = new RegExp(r'[\s.]+');
  var rHyph = new RegExp(r'\s*(?:-\s*)+');
  var rSubstring = new RegExp(r'\"(?:\\.|[^\"\\])*\"');

  var bySpace = (s) => s.split(rSep).where((x) => x != "")
                                    .map((x) => x[0]).join(".").toUpperCase();
  var byHyph = (s) => s.split(rHyph).map((x) => bySpace(x)).join("-") + ".";

  return authors.replaceAll(rSubstring, " ").split(",").map((x) => byHyph(x)).join(",");
}


main(List<String> arguments) {
  // print('Hello world: ${dart_procr.calculate()}!');
  arguments.forEach(print);
}
