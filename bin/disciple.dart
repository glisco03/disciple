import 'dart:convert';
import 'dart:io';

import 'convert.dart';

const version = "0.1";

String entriesDirectory = "";

void main(List<String> arguments) {
  print("disciple $version");

  entriesDirectory = arguments[0] + "/en_us/entries/";

  print("-- Reading book info");
  final bookFile = File("${File(arguments[0]).path}/book.json");
  if (!bookFile.existsSync()) throw "Could not find 'book.json'";

  final bookJson = jsonDecode(bookFile.readAsStringSync());
  final outBuffer = StringBuffer();

  outBuffer.write("# ${bookJson["name"]}\n\n");
  outBuffer.write(markdownify(bookJson["landing_text"], false));

  print("-- Writing index file");

  final outFile = File("${bookJson["name"]}/index.md");
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(outBuffer.toString());

  print("-- Reading entries");

  var files = Directory(entriesDirectory).listSync(recursive: true).whereType<File>().toList();

  print("-- Queued ${files.length} entries for conversion");

  for (var entryFile in files) {
    processFile(bookJson["name"], entryFile.path.replaceFirst(entriesDirectory, ""));
  }

  print("-- Finished");
}

void processFile(String outPath, String entryPath) {
  var file = File(entriesDirectory + entryPath);
  var json = jsonDecode(file.readAsStringSync());

  var pages = (json["pages"] as List<dynamic>).whereType<Map<String, dynamic>>().where((element) => element.containsKey("text")).toList();

  final outBuffer = StringBuffer();
  outBuffer.write("# ${json["name"]}\n\n");

  for (int idx = 1; idx <= pages.length; idx++) {
    var page = pages[idx - 1];
    var mdText = markdownify(page["text"]);

    outBuffer.write("$mdText\n\n");
  }

  final outFile = File("$outPath/${entryPath.replaceFirst("json", "md")}");
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(outBuffer.toString());
}
