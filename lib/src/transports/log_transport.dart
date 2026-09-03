import 'package:maat/maat.dart';

import '../email.dart';
import 'transport.dart';

class LogTransport implements Transport {
  LogTransport([void Function(Object message)? write])
    : _write = write ?? Log.info;

  final void Function(Object message) _write;

  @override
  Future<void> send(Email email) async {
    _write(
      'Mail to=${email.to.map((address) => address.email).join(',')} '
      'subject=${email.subject}\n${email.text ?? email.html ?? ''}',
    );
  }
}
