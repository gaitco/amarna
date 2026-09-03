import 'dart:io';

import 'package:maat/maat.dart';
import 'package:maat/testing.dart';
import 'package:maat_amarna/maat_amarna.dart';
import 'package:test/test.dart';

class WelcomeMail extends Mailable {
  WelcomeMail(this.userId);

  final int userId;

  @override
  Envelope envelope() => const Envelope();

  @override
  Content content() => const Content(text: 'Welcome');
}

class OtherMail extends WelcomeMail {
  OtherMail() : super(0);
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('mail-fake');
    await Application.configure(basePath: directory.path, environment: {})
        .withConfig({
          'mail': {
            'default': 'array',
            'mailers': {
              'array': {'transport': 'array'},
            },
            'from': {'address': 'from@example.com'},
          },
        })
        .withProviders([MailServiceProvider.new])
        .create();
  });

  tearDown(() {
    Application.reset();
    directory.deleteSync(recursive: true);
  });

  final fails = throwsA(isA<TestClientAssertionError>());

  test('fake records mailables and raw emails without transport', () async {
    final fake = Mail.fake();
    expect(identical(app<MailManager>(), fake), isTrue);

    await Mail.to('ada@example.com').send(WelcomeMail(7));
    await Mail.raw('Body', (email) {
      email
        ..from = const Address('from@example.com')
        ..to.add(const Address('ada@example.com'));
    });

    expect(fake.sent<WelcomeMail>().single.userId, 7);
    expect(fake.emails.single.text, 'Body');
    fake.assertSent<WelcomeMail>();
    fake.assertSent<WelcomeMail>((mail) => mail.userId == 7);
    fake.assertNotSent<OtherMail>();
    fake.assertSentCount(1);
  });

  test('fake assertion failures use framework assertion error', () async {
    final fake = Mail.fake();
    expect(() => fake.assertSent<WelcomeMail>(), fails);
    fake.assertNothingSent();
    await Mail.to('ada@example.com').send(WelcomeMail(1));
    expect(() => fake.assertNothingSent(), fails);
    expect(() => fake.assertNotSent<WelcomeMail>(), fails);
    expect(() => fake.assertSentCount(2), fails);
  });
}
