import 'package:maat/maat.dart';
import 'package:amarna/amarna.dart';
import 'package:test/test.dart';

class GreetingMail extends Mailable {
  @override
  Envelope envelope() => const Envelope(to: [Address('inside@example.com')]);

  @override
  Content content() => const Content(text: 'Hello');
}

void main() {
  test(
    'pending recipients merge with mailable and default from is applied',
    () async {
      final transport = ArrayTransport();
      final mailer = Mailer(
        transport,
        from: const Address('default@example.com', 'Default'),
      );

      await mailer
          .to('to@example.com')
          .cc('cc@example.com')
          .bcc('bcc@example.com')
          .send(GreetingMail());

      final email = transport.emails.single;
      expect(email.from?.email, 'default@example.com');
      expect(email.to.map((address) => address.email), [
        'to@example.com',
        'inside@example.com',
      ]);
      expect(email.cc.single.email, 'cc@example.com');
      expect(email.bcc.single.email, 'bcc@example.com');
    },
  );

  test('raw builds and sends one Email', () async {
    final transport = ArrayTransport();
    final mailer = Mailer(
      transport,
      from: const Address('default@example.com'),
    );
    await mailer.raw('Plain body', (email) {
      email
        ..to.add(const Address('to@example.com'))
        ..subject = 'Raw';
    });
    expect(transport.emails.single.text, 'Plain body');
    expect(transport.emails.single.subject, 'Raw');
  });

  test(
    'MessageSending may cancel and MessageSent follows transport success',
    () async {
      final dispatcher = Dispatcher();
      final transport = ArrayTransport();
      final seen = <String>[];
      dispatcher.listen<MessageSending>((event) {
        seen.add('sending:${event.email.subject}');
        return event.email.subject == 'Blocked' ? false : null;
      });
      dispatcher.listen<MessageSent>(
        (event) => seen.add('sent:${event.email.subject}'),
      );
      final mailer = Mailer(
        transport,
        from: const Address('default@example.com'),
        events: () => dispatcher,
      );

      await mailer.sendEmail(
        Email()
          ..to.add(const Address('to@example.com'))
          ..subject = 'Blocked',
      );
      await mailer.sendEmail(
        Email()
          ..to.add(const Address('to@example.com'))
          ..subject = 'Allowed',
      );

      expect(transport.emails.map((email) => email.subject), ['Allowed']);
      expect(seen, ['sending:Blocked', 'sending:Allowed', 'sent:Allowed']);
    },
  );

  test('send rejects missing from and recipients before transport', () async {
    final mailer = Mailer(ArrayTransport());
    await expectLater(mailer.sendEmail(Email()), throwsStateError);
    await expectLater(
      mailer.sendEmail(Email()..from = const Address('from@example.com')),
      throwsStateError,
    );
  });
}
