import 'package:maat_amarna/maat_amarna.dart';
import 'package:test/test.dart';

class Recipient {
  Recipient(this.email, this.name);

  final String email;
  final String name;
}

class EmailOnly {
  EmailOnly(this.email);

  final String email;
}

void main() {
  test('Address resolves strings, addresses, objects, and lists', () {
    const existing = Address('one@example.com', 'One');
    expect(identical(Address.resolve(existing), existing), isTrue);
    expect(Address.resolve('two@example.com').email, 'two@example.com');
    final object = Address.resolve(Recipient('three@example.com', 'Three'));
    expect(object.email, 'three@example.com');
    expect(object.name, 'Three');
    expect(Address.resolve(EmailOnly('four@example.com')).name, isNull);
    expect(
      Address.list(['a@example.com', existing]).map((address) => address.email),
      ['a@example.com', 'one@example.com'],
    );
    expect(() => Address.resolve(Object()), throwsArgumentError);
  });

  test('attachments retain their source and safe byte copy', () {
    final bytes = [1, 2, 3];
    final data = Attachment.fromData(
      bytes,
      'report.pdf',
      mime: 'application/pdf',
    );
    bytes[0] = 9;
    expect(data.data, [1, 2, 3]);
    expect(data.name, 'report.pdf');
    expect(data.mime, 'application/pdf');

    final path = Attachment.fromPath('/tmp/invoice.pdf', as: 'invoice-42.pdf');
    expect(path.path, '/tmp/invoice.pdf');
    expect(path.name, 'invoice-42.pdf');
  });

  test('Email has address buckets, headers, attachments, and '
      'case-insensitive hasTo', () {
    final email = Email()
      ..to.add(const Address('Ada@Example.com'))
      ..cc.add(const Address('cc@example.com'))
      ..bcc.add(const Address('bcc@example.com'))
      ..replyTo.add(const Address('reply@example.com'))
      ..headers['X-Trace'] = 'abc'
      ..attachments.add(Attachment.fromData([1], 'one.bin'));

    expect(email.hasTo('ada@example.com'), isTrue);
    expect(email.hasTo('nobody@example.com'), isFalse);
    expect(email.cc.single.email, 'cc@example.com');
    expect(email.bcc.single.email, 'bcc@example.com');
    expect(email.replyTo.single.email, 'reply@example.com');
    expect(email.headers, {'X-Trace': 'abc'});
    expect(email.attachments.single.name, 'one.bin');
  });
}
