import 'package:dart_procr/dart_procr.dart';
import '../bin/pcd.dart';
import 'package:test/test.dart';

void main() {
  test('padLeft: string padding.', () {
    expect(3.toString().padLeft(5, "0"), "00003");
    expect(15331.toString().padLeft(3, "0"), "15331");
  });

  test('hasExtOf: checks extension.', () {
    expect(hasExtOf("/alfa/bra.vo/charlie.ogg", "OGG"), true);
    expect(hasExtOf("/alfa/bra.vo/charlie.ogg", ".ogg"), true);
    expect(hasExtOf("/alfa/bra.vo/charlie.ogg", "mp3"), false);
  });

  test('compareTo: compares strings, C-style.', () {
    expect("alfa".compareTo("alfa"), 0);
    expect("alfa".compareTo("bravo"), -1);
  });

  test('arrayCmp: compares lists of integers, string-style.', () {
    expect(arrayCmp([], []), 0);
    expect(arrayCmp([1], []), 1);
    expect(arrayCmp([3], []), 1);
    expect(arrayCmp([1, 2, 3], [1, 2, 3, 4, 5]), -1);
    expect(arrayCmp([1, 4], [1, 4, 16]), -1);
    expect(arrayCmp([2, 8], [2, 2, 3]), 1);
    expect(arrayCmp([0, 0, 2, 4], [0, 0, 15]), -1);
    expect(arrayCmp([0, 13], [0, 2, 2]), 1);
    expect(arrayCmp([11, 2], [11, 2]), 0);
  });

  test('strcmpNaturally: compares strings naturally.', () {
    expect(strcmpNaturally("", ""), 0);
    expect(strcmpNaturally("2a", "10a"), -1);
    expect(strcmpNaturally("alfa", "bravo"), -1);
  });

  test('strStripNumbers: creates a list of integers, embedded in a string.',
      () {
    expect(strStripNumbers("ab11cdd2k.144"), [11, 2, 144]);
    expect(strStripNumbers("Ignacio Vazquez-Abrams"), []);
  });

  // There are four delimiters: comma, hyphen, dot, and space. makeInitials()
  // syntax philosophy: if a delimiter is misplaced, it's ignored.
  test("makeInitials: reduces a list of authors to a list of initials.", () {
    expect(makeInitials(""), "");
    expect(makeInitials(" "), "");
    expect(makeInitials(".. , .. "), "");
    expect(makeInitials(" ,, .,"), "");
    expect(makeInitials(", a. g, "), "A.G.");
    expect(makeInitials("- , -I.V.-A,E.C.N-, ."), "I.V-A.,E.C.N.");
    expect(makeInitials("John ronald reuel Tolkien"), "J.R.R.T.");
    expect(makeInitials("  e.B.Sledge "), "E.B.S.");
    expect(makeInitials("Apsley Cherry-Garrard"), "A.C-G.");
    expect(makeInitials("Windsor Saxe-\tCoburg - Gotha"), "W.S-C-G.");
    expect(makeInitials("Elisabeth Kubler-- - Ross"), "E.K-R.");
    expect(makeInitials("  Fitz-Simmons Ashton-Burke Leigh"), "F-S.A-B.L.");
    expect(makeInitials('Arleigh "31-knot"Burke '), "A.B.");
    expect(
        makeInitials('Harry "Bing" Crosby, Kris "Tanto" Paronto'), "H.C.,K.P.");
    expect(
        makeInitials(
            "William J. \"Wild Bill\" Donovan, Marta \"Cinta Gonzalez"),
        "W.J.D.,M.C.G.");
    expect(makeInitials("a.s , - . ,b.s."), "A.S.,B.S.");
    expect(makeInitials("A. Strugatsky, B...Strugatsky."), "A.S.,B.S.");
    expect(makeInitials("Иржи Кропачек,, Йозеф Новотный"), "И.К.,Й.Н.");
    expect(makeInitials("Österreich über alles"), "Ö.Ü.A.");
  });

  test('Strings and lists of strings, review.', () {
    expect(["alfa", "bravo"].join(", "), "alfa, bravo");
    expect("щука"[0].toUpperCase(), "Щ");
    expect('alfa, bravo'.split(','), ["alfa", " bravo"]);
    expect("Kubler - -Ross".split(rHyph), ["Kubler", "Ross"]);
    expect('alfa"br"bravo"ch"charlie'.replaceAll(rSubstring, " "),
        "alfa bravo charlie");
  });
}
