import 'package:maat/testing.dart';

import 'address.dart';
import 'email.dart';
import 'mail_manager.dart';
import 'mailable.dart';
import 'mailer.dart';
import 'transports/array_transport.dart';

class MailFake extends MailManager {
  MailFake(MailManager manager) : super(manager.config);

  final List<Mailable> _sent = [];
  final List<Email> _emails = [];

  late final Mailer _fakeMailer = _FakeMailer(_sent, _emails);

  List<Email> get emails => List.unmodifiable(_emails);

  @override
  Mailer mailer([String? name]) => _fakeMailer;

  List<T> sent<T extends Mailable>([bool Function(T mail)? where]) {
    final matches = _sent.whereType<T>();
    return (where == null ? matches : matches.where(where)).toList();
  }

  void assertSent<T extends Mailable>([bool Function(T mail)? where]) {
    if (sent<T>(where).isEmpty) {
      throw TestClientAssertionError(
        'The expected [$T] mailable was not sent.',
      );
    }
  }

  void assertNotSent<T extends Mailable>([bool Function(T mail)? where]) {
    if (sent<T>(where).isNotEmpty) {
      throw TestClientAssertionError('The unexpected [$T] mailable was sent.');
    }
  }

  void assertNothingSent() {
    if (_sent.isNotEmpty || _emails.isNotEmpty) {
      throw TestClientAssertionError(
        '${_sent.length} mailables and ${_emails.length} raw emails were sent.',
      );
    }
  }

  void assertSentCount(int count) {
    if (_sent.length != count) {
      throw TestClientAssertionError(
        'Expected $count mailables, but ${_sent.length} were sent.',
      );
    }
  }
}

class _FakeMailer extends Mailer {
  _FakeMailer(this.sent, this.emails) : super(ArrayTransport());

  final List<Mailable> sent;
  final List<Email> emails;

  @override
  Future<void> send(
    Mailable mailable, {
    List<Address> to = const [],
    List<Address> cc = const [],
    List<Address> bcc = const [],
  }) async => sent.add(mailable);

  @override
  Future<void> sendEmail(Email email) async => emails.add(email);
}
