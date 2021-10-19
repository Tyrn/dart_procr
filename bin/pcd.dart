#!/usr/bin/env dscript
/*
@pubspec.yaml
name: pcd
dependencies:
  path:
  args:
  tuple:
*/

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart' as gs;
import 'package:tuple/tuple.dart';

/// Returns true, if [path] has extension [ext], case and leading dot insensitive.
///
bool hasExtOf(String path, String ext) {
  var e = ext == "" || ext[0] == "." ? ext : "." + ext;

  return p.extension(path).toUpperCase() == e.toUpperCase();
}

/// Compares two lists of integers, string-style.
///
int arrayCmp(List<int> x, List<int> y) {
  if (x.length == 0) return y.length == 0 ? 0 : -1;
  if (y.length == 0) return x.length == 0 ? 0 : 1;
  var i = 0;
  for (; x[i] == y[i]; i++) {
    if (i == x.length - 1 || i == y.length - 1) {
      // The short array is a prefix of the long one; end reached. All is equal so far.
      if (x.length == y.length)
        return 0; // The long array is no longer than the short one.
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

/// Compares two paths (directories).
///
int comparePath(String x, String y) {
  return opt['sort-lex'] ? x.compareTo(y) : strcmpNaturally(x, y);
}

/// Compares two paths, filenames only, ignoring extensions.
///
int compareFile(String x, String y) {
  var a = p.dirname(x) + p.basenameWithoutExtension(x);
  var b = p.dirname(y) + p.basenameWithoutExtension(y);

  return opt['sort-lex'] ? a.compareTo(b) : strcmpNaturally(a, b);
}

/// Returns a raw list of the [path] offspring.
///
List listOffspring(String path) {
  var dir = new Directory(path);
  return dir.listSync();
}

/// Returns a sorted list of directory paths, according to options.
///
List<String> groomDirs(List offspring, {bool reverse: false}) {
  return offspring
      .where((x) => x is Directory)
      .map((x) => x.path.toString())
      .toList(growable: false)
    ..sort(reverse ? (x, y) => comparePath(y, x) : comparePath);
}

/// Returns a sorted list of file paths, according to options.
///
List<String> groomFiles(List offspring, {bool reverse: false}) {
  return offspring
      .where((x) => x is File && isAudiofile(x.path))
      .map((x) => x.path.toString())
      .toList(growable: false)
    ..sort(reverse ? (x, y) => compareFile(y, x) : compareFile);
}

var rInt = new RegExp(r'\d+');
var rDot = new RegExp(r'[\s.]+');
var rHyph = new RegExp(r'\s*(?:-\s*)+');
var rSubstring = new RegExp(r'\"(?:\\.|[^\"\\])*\"');

/// Reduces comma delimited list of [authors] to initials.
///
String makeInitials(String authors) {
  return authors
      .replaceAll(rSubstring, " ")
      .replaceAll('"', " ")
      .split(",")
      .where((author) =>
          author.replaceAll(".", "").replaceAll("-", "").trim() != "")
      .map((author) =>
          author
              .split("-")
              .where((author) => author.replaceAll(".", "").trim() != "")
              .map((barrel) => barrel
                  .split(rDot)
                  .where((name) => name != "")
                  .map((name) => name[0])
                  .join(".")
                  .toUpperCase())
              .join("-") +
          ".")
      .join(",");
}

/// Returns true, if [path] is a recognized audio file.
///
bool isAudiofile(String path) {
  var e = ['.MP3', '.M4A', '.M4B', '.OGG', '.WMA', '.FLAC'];

  return e.indexOf(p.extension(path).toUpperCase()) < 0 ? false : true;
}

/// Returns full recursive count of audiofiles in the [path] directory.
///
int audiofilesCount(String path) {
  var dir = new Directory(path);
  var cnt = 0;

  List contents = dir.listSync(recursive: true);
  for (var x in contents) {
    if (x is File && isAudiofile(x.path)) cnt++;
  }
  return cnt;
}

String decorateDirName(int i, String path) {
  return (opt['strip-decorations'] ? '' : i.toString().padLeft(3, "0") + '-') +
      p.basename(path);
}

String artist({prefix = "", suffix = ""}) {
  if (opt['artist'] != null) {
    return prefix + opt['artist'] + suffix;
  }
  return "";
}

String decorateFileName(int i, List<String> dstStep, String path) {
  if (opt['strip-decorations']) return p.basename(path);
  var prefix = i.toString().padLeft(_wdh_, "0") +
      (opt['prepend-subdir-name'] && !opt['tree-dst'] && dstStep.length > 0
          ? '-' + dstStep.join('-') + '-'
          : '-');
  return prefix +
      (opt['unified-name'] == null
          ? p.basename(path)
          : opt['unified-name'] + artist(prefix: " - ") + p.extension(path));
}

void copyFile(int i, String src, String dst, {bool reverse: false}) {
  new File(src).copySync(dst);
  opt['verbose']
      ? print(i.toString().padLeft(_wdh_, ' ') + '/$_tot_ $dst')
      : stdout.write('.');
}

void traverseTreeDst(String src, String dstRoot, List<String> dstStep) {
  var g = listOffspring(src), dirs = groomDirs(g), files = groomFiles(g);

  dirs.asMap().forEach((i, dir) {
    var step = new List<String>.from(dstStep);
    step.add(decorateDirName(i, dir));
    new Directory(p.join(dstRoot, p.joinAll(step))).createSync();
    traverseTreeDst(dir, dstRoot, step);
  });
  files.asMap().forEach((i, file) {
    var dstPath = p.join(dstRoot,
        p.join(p.joinAll(dstStep), decorateFileName(i, dstStep, file)));
    //copyFile(file, dstPath);
  });
}

Iterable<Tuple4<int, String, String, String>> walkFileTree(
    String src, String dstRoot, List<int> fcount, List<String> dstStep) sync* {
  var g = listOffspring(src),
      dirs = groomDirs(g, reverse: opt['reverse']),
      files = groomFiles(g, reverse: opt['reverse']);

  Iterable<Tuple4<int, String, String, String>> dirFlat(
      List<String> dirs) sync* {
    for (var directory in dirs) {
      var step = new List<String>.from(dstStep);
      step.add(p.basename(directory));
      yield* walkFileTree(p.join(src, directory), dstRoot, fcount, step);
    }
  }

  Iterable<Tuple4<int, String, String, String>> fileFlat(
      List<String> files) sync* {
    for (var file in files) {
      yield Tuple4(fcount[0], p.join(src, file), dstRoot,
          decorateFileName(fcount[0], dstStep, file));
      (opt['reverse']) ? fcount[0]-- : fcount[0]++;
    }
  }

  yield* dirFlat(dirs);
  yield* fileFlat(files);
}

var _tot_ = 0;
var _wdh_ = 0;

void groom(String src, String dst) {
  walkFileTree(src, dst, (opt['reverse']) ? [_tot_] : [1], []).forEach((t) {
    copyFile(t.item1, t.item2, p.join(t.item3, t.item4));
  });
}

/// Sets up boilerplate required by the options; runs the show.
///
void buildAlbum() {
  _tot_ = audiofilesCount(srcDir);
  _wdh_ = _tot_.toString().length;

  if (_tot_ < 1) {
    print(
        'There are no supported audio files in the source directory "${srcDir}".');
    exit(0);
  }
  var prefix =
      opt['album-num'] == null ? '' : opt['album-num'].padLeft(2, "0") + '-';
  var baseDst = prefix +
      (opt['unified-name'] == null
          ? p.basename(srcDir)
          : artist(suffix: " - ") + opt['unified-name']);
  var executiveDst = p.join(dstDir, (opt['drop-dst'] ? '' : baseDst));

  if (!opt['drop-dst']) {
    if (FileSystemEntity.isDirectorySync(executiveDst)) {
      print('Destination directory "${executiveDst}" already exists.');
      exit(0);
    } else {
      new Directory(executiveDst).createSync();
    }
  }
  // Running, at last!
  if (opt['verbose']) {
    groom(srcDir, executiveDst);
  } else {
    stdout.write('Starting ');
    groom(srcDir, executiveDst);
    print(' Done($_tot_)');
  }
}

main(List<String> arguments) {
  opt = retrieveArgs(arguments);
  srcDir = checkDirectory(opt.rest[0]);
  dstDir = checkDirectory(opt.rest[1], "Destination");

  buildAlbum();
}

var opt = null;
var srcDir = null;
var dstDir = null;

String checkDirectory(String path, [String kindOf = "Source"]) {
  var dir = p.canonicalize(path);

  if (!FileSystemEntity.isDirectorySync(dir)) {
    print('$kindOf directory "$dir" is not there.');
    exit(0);
  }
  return dir;
}

var description = '''
    Damastes a.k.a. Procrustes is a CLI utility for copying directories and subdirectories
    containing supported audio files in sequence, naturally sorted.
    The end result is a "flattened" copy of the source subtree. "Flattened" means
    that only a namesake of the root source directory is created, where all the files get
    copied to, names prefixed with a serial number. Tag "Track Number"
    is set, tags "Title", "Artist", and "Album" can be replaced optionally.
    The writing process is strictly sequential: either starting with the number one file,
    or in the reverse order. This can be important for some mobile devices.
    \u{274c} Broken media;
    \u{2754} Suspicious media.

    Example:

    robinson-crusoe \$ damastes -va 'Daniel "Goldeneye" Defoe' -u 'Robinson Crusoe' .
    /run/media/player
''';
var unifiedNameHelp = '''
Destination root directory name and file names are based on <name>,
serial number prepended, file extensions retained; also album tag,
if the latter is not specified explicitly.''';

retrieveArgs(List<String> arguments) {
  var parser = new gs.ArgParser(allowTrailingOptions: false);

  parser.addFlag("help", abbr: "h", negatable: false);
  parser.addFlag("version", abbr: "V", negatable: false);
  parser.addFlag("verbose",
      abbr: "v", help: "Verbose output.", negatable: false);
  parser.addFlag("drop-tracknumber",
      abbr: "d", help: "Do not set track numbers.", negatable: false);
  parser.addFlag("strip-decorations",
      abbr: "s",
      help: "Strip file and directory name decorations.",
      negatable: false);
  parser.addFlag("file-title",
      abbr: "f", help: "Use file name for title tag.", negatable: false);
  parser.addFlag("file-title-num",
      abbr: "F",
      help: "Use numbered file name for title tag.",
      negatable: false);
  parser.addFlag("sort-lex",
      abbr: "x", help: "Sort files lexicographically.", negatable: false);
  parser.addFlag("tree-dst",
      abbr: "t",
      help: "Retain the tree structure of the source album at destination.",
      negatable: false);
  parser.addFlag("drop-dst",
      abbr: "p",
      help: "Do not create destination directory.",
      negatable: false);
  parser.addFlag("reverse",
      abbr: "r",
      help:
          "Copy files in reverse order (number one file is the last to be copied).",
      negatable: false);
  parser.addFlag("overwrite",
      abbr: "w",
      help: "Silently remove existing destination directory (not recommended).",
      negatable: false);
  parser.addFlag("dry-run",
      abbr: "y",
      help: "Without actually modifying anything (trumps -w, too).",
      negatable: false);
  parser.addFlag("count",
      abbr: "c", help: "Just count the files.", negatable: false);
  parser.addFlag("prepend-subdir-name",
      abbr: "i",
      help: "Prepend current subdirectory name to a file name.",
      negatable: false);
  parser.addOption("file-type",
      abbr: "e",
      valueHelp: "extension",
      help: "Accept only audio files of the specified type.");
  parser.addOption("unified-name",
      abbr: "u", valueHelp: "name", help: unifiedNameHelp);
  parser.addOption("artist", abbr: "a", valueHelp: "tag", help: "Artist tag.");
  parser.addOption("album", abbr: "m", valueHelp: "tag", help: "Album tag.");
  parser.addOption("album-num",
      abbr: "b",
      valueHelp: "number",
      help: "0..99; prepend <number> to the destination root directory name.");
  parser.addFlag("context", help: "Print clean context.", negatable: false);
  parser.addFlag("no-console", help: "No console mode.", negatable: false);

  var rg = parser.parse(arguments);

  if (rg['help'] || arguments.length == 0) {
    print(description);
    print(parser.usage);
    exit(0);
  }
  if (rg['version'] || arguments.length == 0) {
    print("Version");
    exit(0);
  }
  if (rg.rest.length < 2) {
    print("Source and/or destination directory is missing.");
    exit(0);
  }
  return rg;
}
