import 'dart:io';

import 'package:maat/maat.dart';
import 'package:amarna/amarna.dart';
import 'package:khnum_maat/khnum_maat.dart';
import 'package:test/test.dart';

class ReceiptMail extends Mailable {
  @override
  Envelope envelope() => const Envelope(
    from: Address('sender@example.com', 'Sender'),
    to: [Address('envelope@example.com')],
    cc: [Address('cc@example.com')],
    subject: 'Your receipt',
  );

  @override
  Content content() => const Content(html: '<b>Paid</b>', text: 'Paid');

  @override
  List<Attachment> attachments() => [
    Attachment.fromData([1, 2], 'receipt.pdf', mime: 'application/pdf'),
  ];
}

class PasswordReset extends Mailable {
  @override
  Envelope envelope() => const Envelope();

  @override
  Content content() => const Content(text: 'Reset');
}

class WelcomeMail extends Mailable {
  @override
  Envelope envelope() => const Envelope();

  @override
  Content content() =>
      const Content(view: 'mail.welcome', data: {'name': 'Ada'});
}

void main() {
  test(
    'build applies envelope, pending recipients, content, and attachments',
    () async {
      final email = await ReceiptMail().build(
        to: const [Address('pending@example.com')],
      );

      expect(email.from?.email, 'sender@example.com');
      expect(email.to.map((address) => address.email), [
        'pending@example.com',
        'envelope@example.com',
      ]);
      expect(email.cc.single.email, 'cc@example.com');
      expect(email.subject, 'Your receipt');
      expect(email.html, '<b>Paid</b>');
      expect(email.text, 'Paid');
      expect(email.attachments.single.name, 'receipt.pdf');
    },
  );

  test('subject defaults to the mailable class headline', () async {
    expect((await PasswordReset().build()).subject, 'Password Reset');
  });

  test('Content.view renders through the bound Khnum engine', () async {
    final directory = Directory.systemTemp.createTempSync('amarna-view');
    addTearDown(() {
      Application.reset();
      directory.deleteSync(recursive: true);
    });
    final file = File.fromUri(
      directory.uri.resolve('resources/views/mail/welcome.khnum.html'),
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('Hello {{ name }}');
    await Application.configure(basePath: directory.path, environment: {})
        .withConfig({
          'app': {'debug': true},
        })
        .withProviders([ViewServiceProvider.new])
        .create();

    expect((await WelcomeMail().build()).html, 'Hello Ada');
  });
}
