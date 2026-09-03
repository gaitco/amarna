import 'dart:io';

import 'package:maat/maat.dart';
import 'package:amarna/amarna.dart';
import 'package:test/test.dart';

Config mailConfig() => Config({
  'mail': {
    'default': 'array',
    'mailers': {
      'array': {'transport': 'array'},
      'log': {'transport': 'log'},
      'smtp': {
        'transport': 'smtp',
        'host': 'smtp.example.com',
        'port': 465,
        'username': 'user',
        'password': 'secret',
        'encryption': 'ssl',
      },
    },
    'from': {'address': 'hello@example.com', 'name': 'Example'},
  },
});

void main() {
  tearDown(MailManager.resetExtensions);

  test('manager caches named mailers and maps configured transports', () {
    final manager = MailManager(mailConfig());
    final array = manager.mailer();
    expect(identical(array, manager.mailer('array')), isTrue);
    expect(array.transport, isA<ArrayTransport>());
    expect(array.from?.email, 'hello@example.com');
    expect(manager.mailer('log').transport, isA<LogTransport>());

    final smtp = manager.mailer('smtp').transport as SmtpTransport;
    expect(smtp.server.host, 'smtp.example.com');
    expect(smtp.server.port, 465);
    expect(smtp.server.ssl, isTrue);
    expect(smtp.server.username, 'user');
  });

  test('manager rejects missing mailers and unknown transports', () {
    final manager = MailManager(mailConfig());
    expect(() => manager.mailer('missing'), throwsStateError);
    final unknown = Config({
      'mail': {
        'default': 'x',
        'mailers': {
          'x': {'transport': 'unknown'},
        },
      },
    });
    expect(() => MailManager(unknown).mailer(), throwsStateError);
  });

  test('extend adds a custom transport', () {
    MailManager.extend('custom', (_) => ArrayTransport());
    final manager = MailManager(
      Config({
        'mail': {
          'default': 'custom',
          'mailers': {
            'custom': {'transport': 'custom'},
          },
        },
      }),
    );
    expect(manager.mailer().transport, isA<ArrayTransport>());
  });

  test('provider binds manager and facade resolves it', () async {
    final directory = Directory.systemTemp.createTempSync('amarna-manager');
    addTearDown(() {
      Application.reset();
      directory.deleteSync(recursive: true);
    });
    final application =
        await Application.configure(basePath: directory.path, environment: {})
            .withConfig(mailConfig().all())
            .withProviders([MailServiceProvider.new])
            .create();

    expect(identical(application.make<MailManager>(), Mail.manager), isTrue);
    expect(Mail.mailer().transport, isA<ArrayTransport>());
  });
}
