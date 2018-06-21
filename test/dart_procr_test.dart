import 'package:dart_procr/dart_procr.dart';
import 'package:test/test.dart';

void main() {
  
  test('Strings and lists of strings, review.', () {
    expect(["alfa", "bravo"].join(", "), "alfa, bravo");
    expect("щука"[0].toUpperCase(), "Щ");
    expect('alfa, bravo'.split(','), ["alfa", " bravo"]);
    expect("Kubler - -Ross".split(new RegExp(r'\s*(?:-\s*)+')), ["Kubler", "Ross"]);
    expect('alfa"br"bravo"ch"charlie'
                  .replaceAll(new RegExp(r'\"(?:\\.|[^\"\\])*\"'), " "),
            "alfa bravo charlie");
  });

  test('makeInitials: reduces a list of authors to a list of initials.', () {
    expect(makeInitials("John ronald reuel Tolkien"), "J.R.R.T.");
    expect(makeInitials("  e.B.Sledge "), "E.B.S.");
    expect(makeInitials("Apsley Cherry-Garrard"), "A.C-G.");
    expect(makeInitials("Windsor Saxe-\tCoburg - Gotha"), "W.S-C-G.");
    expect(makeInitials("Elisabeth Kubler-- - Ross"), "E.K-R.");
    expect(makeInitials("  Fitz-Simmons Ashton-Burke Leigh"), "F-S.A-B.L.");
    expect(makeInitials('Arleigh "31-knot"Burke '), "A.B.");
    expect(makeInitials('Harry "Bing" Crosby, Kris "Tanto" Paronto'), "H.C.,K.P.");
    expect(makeInitials("a.s.,b.s."), "A.S.,B.S.");
    expect(makeInitials("A. Strugatsky, B...Strugatsky."), "A.S.,B.S.");
    expect(makeInitials("Иржи Кропачек, Йозеф Новотный"), "И.К.,Й.Н.");
  });

}
