import 'dart:io';

import 'package:maat/maat.dart';
import 'package:amarna/amarna.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late Sesh maat;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('make-mail');
    final application = await Application.configure(
      basePath: directory.path,
      environment: {},
    ).create();
    maat = Sesh(application, commands: [MakeMailCommand()]);
  });

  tearDown(() {
    Application.reset();
    directory.deleteSync(recursive: true);
  });

  test(
    'make:mail generates a formatted mailable and honors force',
    () async {
      expect(await maat.run(['make:mail', 'OrderShippedMail']), 0);
      final generated = File.fromUri(
        directory.uri.resolve('lib/app/mail/order_shipped_mail.dart'),
      );
      expect(generated.existsSync(), isTrue);
      final source = generated.readAsStringSync();
      expect(
        source,
        contains("import 'package:amarna/amarna.dart';"),
      );
      expect(source, contains('class OrderShippedMail extends Mailable'));
      expect(source, contains('Envelope envelope()'));
      expect(source, contains('Content content()'));

      expect(await maat.run(['make:mail', 'OrderShippedMail']), 1);
      expect(await maat.run(['make:mail', 'OrderShippedMail', '--force']), 0);

      final amarnaPath = Directory.current.path;
      final packages = Directory.current.parent.uri;
      final maatPath = packages.resolve('maat').toFilePath();
      final khnumPath = packages.resolve('khnum_maat').toFilePath();
      final khnumCorePath = packages.resolve('khnum').toFilePath();
      File.fromUri(directory.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: generated_mail_app
publish_to: none
environment:
  sdk: ^3.12.0
dependencies:
  amarna:
    path: $amarnaPath
dependency_overrides:
  maat:
    path: $maatPath
  khnum_maat:
    path: $khnumPath
  khnum:
    path: $khnumCorePath
''');
      final pubGet = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: directory.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');
      final analyze = await Process.run('dart', [
        'analyze',
        '--fatal-infos',
      ], workingDirectory: directory.path);
      expect(analyze.exitCode, 0, reason: '${analyze.stdout}${analyze.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
