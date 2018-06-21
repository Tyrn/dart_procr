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