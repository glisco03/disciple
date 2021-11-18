const symmetricOperators = {"l": "**", "o": "*", "m": "~~", "item": "**", "thing": "*"};

const asymmetricOperators = {"br": "\n", "br2": "\n\n", "li": "\n - ", "p": "\n\n"};

String markdownify(String patchouli, [bool relativizeLinks = true]) {
  final opStack = <StyleOp>[];
  final outBuffer = StringBuffer();

  for (var unit in patchouli.codeUnits) {
    var char = String.fromCharCode(unit);

    if (char == "\$") {
      // print("Pushing operation");
      opStack.add(StyleOp());
      continue;
    } else if (opStack.isNotEmpty) {
      if (char == "(") {
        if (!opStack.last.opened) {
          // print("Opening operation");
          opStack.last.open();
          continue;
        }
      } else if (char == ")") {
        if (!opStack.last.closed) {
          // print("Closing operation");
          var last = opStack.last;
          if (last.closeAndParse(relativizeLinks)) {
            // print("Operation closed, writing operand '${last.operand}' to buffer");
            outBuffer.write(last.operand);
            if (!last.symmetric) opStack.removeLast();
          } else {
            // print("Symmetry operation closed, popping from stack");
            opStack.removeLast();
            if (opStack.isNotEmpty) {
              outBuffer.write(opStack.last.delimiter ?? opStack.last.operand);
              // print("Writing operand '${opStack.last.closer ?? opStack.last.operand}' to buffer");
              opStack.removeLast();
            } else {
              print("  -- WARNING: Skipping symmetry operator as no counterpart was found on the stack");
            }
          }
          continue;
        }
      } else if (opStack.last.opened && !opStack.last.closed) {
        // print("Appending '$char' to operand '${opStack.last.operand}' => '${opStack.last.operand + char}'");
        opStack.last.operand += char;
        continue;
      }
    }

    // print("Writing '$char' to buffer");
    outBuffer.write(char);
  }

  return outBuffer.toString();
}

class StyleOp {
  static RegExp linkRegex = RegExp("l:.+:.+");
  static RegExp colorRegex = RegExp(r"^#([A-Fa-f0-9]{0,6})$");

  bool _opened = false;
  bool _closed = false;
  bool _symmetric = false;
  String operand = "";
  String? delimiter;

  get closed => _closed;

  get opened => _opened;

  get symmetric => _symmetric;

  void open() => _opened = true;

  /// Marks this operation as closed and tries to parse the operand.
  ///
  /// Returns [false] if the operand is empty and thus represents
  /// the symmetry operator
  bool closeAndParse(bool relativizeLinks) {
    _closed = true;

    if (operand.isEmpty) return false;

    if (symmetricOperators.containsKey(operand)) {
      _symmetric = true;
      operand = symmetricOperators[operand]!;
    } else if (asymmetricOperators.containsKey(operand)) {
      _symmetric = false;
      operand = asymmetricOperators[operand]!;
    } else if (operand.contains(linkRegex)) {
      _symmetric = true;

      String link;
      if (operand.contains("https://")) {
        link = operand.substring(2);
      } else {
        final sectionIndex = operand.lastIndexOf("#");
        link = operand.substring(operand.indexOf(":", operand.indexOf(":") + 1) + 1, sectionIndex == -1 ? operand.length : sectionIndex);
        if (relativizeLinks) link = ("../" * (r"/".allMatches(link).length + 1)) + link;
      }

      operand = "[";
      delimiter = "]($link)";
    } else if (operand.contains(colorRegex)) {
      _symmetric = true;
      operand = "";
    } else {
      print("  -- WARNING: Unable to parse unknown operator '$operand'");
    }

    return true;
  }
}
