#!/usr/bin/env dscript

/*
@pubspec.yaml
name: pcd
dependencies:
  path:
  args:
*/

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart' as gs;


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
  return rInt.allMatches(s).map((m) => int.parse(m[0])).toList(growable: false);
}


var rInt = new RegExp(r'\d+');
var rDot = new RegExp(r'[\s.]+');
var rHyph = new RegExp(r'\s*(?:-\s*)+');
var rSubstring = new RegExp(r'\"(?:\\.|[^\"\\])*\"');


/// Reduces comma delimited list of [authors] to initials.
/// 
String makeInitials(String authors) {
  var bySpace = (s) => s.split(rDot).where((x) => x != "")
                                    .map((x) => x[0]).join(".").toUpperCase();
  var byHyph = (s) => s.split(rHyph).map((x) => bySpace(x)).join("-") + ".";

  return authors.replaceAll(rSubstring, " ").split(",").map((x) => byHyph(x)).join(",");
}


List listOffspring(String path) {
  var dir = new Directory(path);
  return dir.listSync();
}


List<String> groomDirs(List offspring) {
  return offspring.where((x) => x is Directory).map((x) => x.path).toList(growable: false)
                  ..sort();
}


List<String> groomFiles(List offspring) {
  return offspring.where((x) => x is File).map((x) => x.path).toList(growable: false)
                  ..sort();
}


int audiofilesCount(String path) {
  var dir = new Directory(path);
  var cnt = 0;

  List contents = dir.listSync();
  for (var fileOrDir in contents) {
    if (fileOrDir is File) {
      print(fileOrDir.path);
      cnt++;
    } else if (fileOrDir is Directory) {
      print('${fileOrDir.path} (dir)');
    }
  }
  return cnt;
}


buildAlbum() {
  audiofilesCount(srcDir);
}


main(List<String> arguments) {
  opt = retrieveArgs(arguments);
  srcDir = checkDirectory(opt.rest[0]);
  dstDir = checkDirectory(opt.rest[1], "Destination");

  // buildAlbum();

  var offsp = listOffspring(srcDir), dirs = groomDirs(offsp), files = groomFiles(offsp);
  dirs.forEach(print); print('');
  files.forEach(print);

  print('src: "$srcDir", dst: "$dstDir"');
}


var opt = null;
var srcDir = null;
var dstDir = null;


String checkDirectory(String path, [String kindOf="Source"]) {
  var dir = p.canonicalize(path);

  if(!FileSystemEntity.isDirectorySync(dir)) {
    print('$kindOf directory "$dir" is not there.');
    exit(0);
  }
  return dir;
}


var description = '''
pcd "Procrustes" SmArT is a CLI utility for copying subtrees containing supported audio
files in sequence, naturally sorted.
The end result is a "flattened" copy of the source subtree. "Flattened" means
that only a namesake of the root source directory is created, where all the files get
copied to, names prefixed with a serial number. Tag "Track Number"
is set, tags "Title", "Artist", and "Album" can be replaced optionally.
The writing process is strictly sequential: either starting with the number one file,
or in the reversed order. This can be important for some mobile devices.
''';
var unifiedNameHelp = '''
destination root directory name and file names are based on <name>,
serial number prepended, file extensions retained; also album tag,
if the latter is not specified explicitly''';


retrieveArgs(List<String> arguments) {
  var parser = new gs.ArgParser(allowTrailingOptions: false);

  parser.addFlag("help", abbr: "h", negatable: false);
  parser.addFlag("verbose", abbr: "v", help: "verbose output", negatable: false);
  parser.addFlag("drop-tracknumber", abbr: "d", help: "do not set track numbers", negatable: false);
  parser.addFlag("strip-decorations", abbr: "s", help: "strip file and directory name decorations", negatable: false);
  parser.addFlag("file-title", abbr: "f", help: "use file name for title tag", negatable: false);
  parser.addFlag("file-title-num", abbr: "F", help: "use numbered file name for title tag", negatable: false);
  parser.addFlag("sort-lex", abbr: "x", help: "sort files lexicographically", negatable: false);
  parser.addFlag("tree-dst", abbr: "t", help: "retain the tree structure of the source album at destination", negatable: false);
  parser.addFlag("drop-dst", abbr: "p", help: "do not create destination directory", negatable: false);
  parser.addFlag("reverse", abbr: "r", help: "copy files in reverse order (number one file is the last to be copied)", negatable: false);
  parser.addFlag("prepend-subdir-name", abbr: "i", help: "prepend current subdirectory name to a file name", negatable: false);
  parser.addOption("file-type", abbr: "e", valueHelp: "extension", help: "accept only audio files of the specified type");
  parser.addOption("unified-name", abbr: "u", valueHelp: "name", help: unifiedNameHelp);
  parser.addOption("album-num", abbr: "b", valueHelp: "number", help: "0..99; prepend <number> to the destination root directory name");
  parser.addOption("artist-tag", abbr: "a", valueHelp: "tag", help: "artist tag name");
  parser.addOption("album-tag", abbr: "g", valueHelp: "tag", help: "album tag name");

  var rg = parser.parse(arguments);

  if(rg['help'] || arguments.length == 0) {
    print(description);
    print(parser.usage);
    exit(0);
  }
  if(rg.rest.length < 2) {
    print("Source and/or destination directory is missing.");
    exit(0);
  }
  return rg;
}