import 'package:mailer/mailer.dart' as smtp;
import 'package:mailer/smtp_server.dart';
import 'package:maat_amarna/maat_amarna.dart';
import 'package:test/test.dart';

Email sample() => Email()
  ..from = const Address('from@example.com', 'From')
  ..to.add(const Address('to@example.com', 'To'))
  ..cc.add(const Address('cc@example.com'))
  ..bcc.add(const Address('bcc@example.com'))
  ..replyTo.add(const Address('reply@example.com'))
  ..subject = 'Subject'
  ..text = 'Plain'
  ..html = '<b>HTML</b>'
  ..headers['X-Test'] = 'yes'
  ..attachments.add(Attachment.fromData([1, 2], 'data.bin'));

void main() {
  test('array transport retains sent emails in order', () async {
    final transport = ArrayTransport();
    final first = sample();
    final second = sample()..subject = 'Second';
    await transport.send(first);
    await transport.send(second);
    expect(transport.emails, [first, second]);
  });

  test('log transport writes recipients, subject, and body', () async {
    final lines = <Object>[];
    await LogTransport(lines.add).send(sample());
    final output = lines.join('\n');
    expect(output, contains('to@example.com'));
    expect(output, contains('Subject'));
    expect(output, contains('Plain'));
  });

  test('smtp transport maps the complete email into mailer Message', () async {
    smtp.Message? captured;
    final server = SmtpServer('smtp.example.com');
    final transport = SmtpTransport(
      server,
      sender: (message, actualServer) async {
        expect(identical(actualServer, server), isTrue);
        captured = message;
      },
    );

    await transport.send(sample());

    final message = captured!;
    expect(message.fromAsAddress.mailAddress, 'from@example.com');
    expect(message.recipientsAsAddresses.single.mailAddress, 'to@example.com');
    expect(message.ccsAsAddresses.single.mailAddress, 'cc@example.com');
    expect(message.bccsAsAddresses.single.mailAddress, 'bcc@example.com');
    expect(message.subject, 'Subject');
    expect(message.text, 'Plain');
    expect(message.html, '<b>HTML</b>');
    expect(message.headers['X-Test'], 'yes');
    final replyTo = message.headers['reply-to'] as Iterable<smtp.Address>;
    expect(replyTo.single.mailAddress, 'reply@example.com');
    expect(message.attachments.single.fileName, 'data.bin');
  });

  test('smtp transport rejects an email without a sender', () async {
    final transport = SmtpTransport(
      SmtpServer('smtp.example.com'),
      sender: (_, _) async {},
    );
    await expectLater(
      transport.send(Email()..to.add(const Address('to@example.com'))),
      throwsStateError,
    );
  });
}
