import 'package:amarna/amarna.dart';

class WelcomeMail extends Mailable {
  @override
  Envelope envelope() => const Envelope(subject: 'Welcome');

  @override
  Content content() => const Content(text: 'Thanks for joining.');
}

Future<void> main() async {
  final transport = ArrayTransport();
  final mailer = Mailer(
    transport,
    from: const Address('hello@example.com', 'Example'),
  );

  await mailer.to('ada@example.com').send(WelcomeMail());
  print(transport.emails.single.subject);
}
