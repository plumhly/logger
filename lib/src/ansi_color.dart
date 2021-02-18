class AnsiColor {
  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const ansiEsc = '\x1B[';

  /// Reset all colors and options for current SGRs to terminal defaults.
  static const ansiDefault = "${ansiEsc}0m";

  final int fg;
  final int bg;
  final bool color;
  final String prefix;

  AnsiColor.none()
      : fg = null,
        bg = null,
        color = false,
        prefix = "";

  AnsiColor.fg(this.fg)
      : bg = null,
        color = true,
        prefix = "";

  AnsiColor.bg(this.bg)
      : fg = null,
        color = true,
        prefix = "";

  AnsiColor.txt(this.prefix)
      : fg = null,
        bg = null,
        color = false;

  String toString() {
    if (color) {
      if (fg != null) {
        return "${ansiEsc}38;5;${fg}m";
      } else if (bg != null) {
        return "${ansiEsc}48;5;${bg}m";
      } else {
        return "";
      }
    } else {
      return prefix;
    }
  }

  String call(String msg) {
    if (color) {
      return "${this}$msg$ansiDefault";
    } else {
      return "${this}$msg";
    }
  }

  AnsiColor toFg() => AnsiColor.fg(bg);

  AnsiColor toBg() => AnsiColor.bg(fg);

  /// Defaults the terminal's foreground color without altering the background.
  String get resetForeground => color ? "${ansiEsc}39m" : "";

  /// Defaults the terminal's background color without altering the foreground.
  String get resetBackground => color ? "${ansiEsc}49m" : "";

  static int grey(double level) => 232 + (level.clamp(0.0, 1.0) * 23).round();
}
