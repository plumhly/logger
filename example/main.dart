import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

void main() {
  print(
      'Run with either `dart example/main.dart` or `dart --enable-asserts example/main.dart`.');
  demo();
}

void demo() {
  logger.d("TAG", 'Log message with 2 methods');

  loggerNoStack.i("TAG", 'Info message',);

  loggerNoStack.w("TAG", 'Just a warning!', null, null);

  logger.e("TAG", 'Error! Something bad happened', 'Test Error', null);

  loggerNoStack.v("TAG", {'key': 5, 'value': 'something'});

  Logger(printer: SimplePrinter(colors: true)).v("TAG", 'boom');
}
