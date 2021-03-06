import 'dart:convert';

import 'package:logger/src/logger.dart';
import 'package:logger/src/log_printer.dart';
import 'package:logger/src/ansi_color.dart';

/// Default implementation of [LogPrinter].
///
/// Outut looks like this:
/// ```
/// ┌──────────────────────────
/// │ Error info
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Method stack history
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Log message
/// └──────────────────────────
/// ```
class PrettyPrinter extends LogPrinter {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = "─";
  static const singleDivider = "-";

  static final levelColors = {
    Level.verbose: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: AnsiColor.none(),
    Level.info: AnsiColor.fg(2),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.wtf: AnsiColor.fg(199),
  };

  static final levelPrefix = {
    Level.verbose: AnsiColor.txt("VERBOSE "),
    Level.debug: AnsiColor.txt("  DEBUG "),
    Level.info: AnsiColor.txt("   INFO "),
    Level.warning: AnsiColor.txt("WARNING "),
    Level.error: AnsiColor.txt("  ERROR "),
    Level.wtf: AnsiColor.txt("  FATAL "),
  };

  static final levelEmojis = {
    Level.verbose: '',
    Level.debug: '🐛 ',
    Level.info: '💡 ',
    Level.warning: '⚠️ ',
    Level.error: '⛔ ',
    Level.wtf: '👾 ',
  };

  static final stackTraceRegex = RegExp(r'#[0-9]+[\s]+(.+) \(([^\s]+)\)');

  static DateTime? _startTime;

  final int methodCount;
  final int errorMethodCount;
  final int lineLength;
  final bool colors;
  final bool prefix;
  final bool printEmojis;
  final bool printTime;
  final bool isNeedBorder;

  String _topBorder = '';
  String _middleBorder = '';
  String _bottomBorder = '';
  String _verticalLine = '';
  String _boldAnsi = "\u001b[1m";

  PrettyPrinter({
    this.methodCount = 2,
    this.errorMethodCount = 8,
    this.lineLength = 120,
    this.colors = true,
    this.prefix = false,
    this.printEmojis = true,
    this.printTime = false,
    this.isNeedBorder = true,
  }) {
    _startTime ??= DateTime.now();

    var doubleDividerLine = StringBuffer();
    var singleDividerLine = StringBuffer();
    for (int i = 0; i < lineLength - 1; i++) {
      doubleDividerLine.write(doubleDivider);
      singleDividerLine.write(singleDivider);
    }

    if (isNeedBorder) {
      _topBorder = "$topLeftCorner$doubleDividerLine";
      _middleBorder = "$middleCorner$singleDividerLine";
      _bottomBorder = "$bottomLeftCorner$doubleDividerLine";
      _verticalLine = verticalLine;
    }
  }

  @override
  List<String?> log(LogEvent event) {
    var tag = event.tag;
    var messageStr = stringifyMessage(event.message);

    String? stackTraceStr;
    if (event.stackTrace == null) {
      if (event.level == Level.error) {
        if (errorMethodCount > 0) {
          stackTraceStr =
              formatStackTrace(StackTrace.current, errorMethodCount);
        }
      } else {
        if (methodCount > 0) {
          stackTraceStr = formatStackTrace(StackTrace.current, methodCount);
        }
      }
    } else if (errorMethodCount > 0) {
      stackTraceStr = formatStackTrace(event.stackTrace, errorMethodCount);
    }

    var errorStr = event.error?.toString();

    String? timeStr;
    if (printTime) {
      timeStr = getTime();
    }

    return _formatAndPrint(
      event.level,
      messageStr,
      timeStr,
      errorStr,
      stackTraceStr,
      tag,
    );
  }

  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    var lines = stackTrace.toString().split("\n");

    var formatted = <String>[];
    var count = 0;
    for (var line in lines) {
      var match = stackTraceRegex.matchAsPrefix(line);
      if (match != null) {
        if (match.group(2)!.startsWith('package:logger')) {
          continue;
        }
        var newLine = "#$count   ${match.group(1)} (${match.group(2)})";
        formatted.add(newLine.replaceAll('<anonymous closure>', '()'));
        if (++count == methodCount) {
          break;
        }
      } else {
        formatted.add(line);
      }
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }

  String getTime() {
    String _threeDigits(int n) {
      if (n >= 100) return "$n";
      if (n >= 10) return "0$n";
      return "00$n";
    }

    String _twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    var now = DateTime.now();
    String h = _twoDigits(now.hour);
    String min = _twoDigits(now.minute);
    String sec = _twoDigits(now.second);
    String ms = _threeDigits(now.millisecond);
    var timeSinceStart = now.difference(_startTime!).toString();
    return "$h:$min:$sec.$ms (+$timeSinceStart)";
  }

  String stringifyMessage(dynamic message) {
    if (message is Map || message is Iterable) {
      var encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(message);
    } else {
      return message.toString();
    }
  }

  AnsiColor? _getLevelColor(Level level) {
    if (colors) {
      return levelColors[level];
    } else {
      if (prefix) {
        return levelPrefix[level];
      } else {
        return AnsiColor.none();
      }
    }
  }

  AnsiColor? _getErrorColor(Level level) {
    if (colors) {
      if (level == Level.wtf) {
        return levelColors[Level.wtf]!.toBg();
      } else {
        return levelColors[Level.error]!.toBg();
      }
    } else {
      if (prefix) {
        return levelPrefix[level];
      } else {
        return AnsiColor.none();
      }
    }
  }

  String? _getEmoji(Level level) {
    if (printEmojis) {
      return levelEmojis[level];
    } else {
      return "";
    }
  }

  List<String?> _formatAndPrint(
    Level level,
    String message,
    String? time,
    String? error,
    String? stacktrace,
    String? tag,
  ) {
    List<String?> buffer = [];
    var color = _getLevelColor(level)!;
    buffer.add(color(_topBorder));

    if (null != tag && tag.isNotEmpty) {
      buffer..add(color('$_verticalLine 🌴$_boldAnsi $tag'))..add(color(_middleBorder));
    }

    if (error != null) {
      var errorColor = _getErrorColor(level);
      for (var line in error.split('\n')) {
        buffer.add(
          color('$_verticalLine ') +
              errorColor!.resetForeground +
              errorColor(line) +
              errorColor.resetBackground,
        );
      }
      buffer.add(color(_middleBorder));
    }

    if (stacktrace != null) {
      for (var line in stacktrace.split('\n')) {
        buffer.add('$color$_verticalLine $line');
      }
      buffer.add(color(_middleBorder));
    }

    if (time != null) {
      buffer..add(color('$_verticalLine $time'))..add(color(_middleBorder));
    }

    var emoji = _getEmoji(level);
    final pattern = new RegExp('.{1,116}'); // 1024 is the size of each chunk
    pattern.allMatches(message).forEach(
        (match) => buffer.add(color('$_verticalLine $emoji${match.group(0)}')));
    buffer.add(color(_bottomBorder));

    return buffer;
  }
}
