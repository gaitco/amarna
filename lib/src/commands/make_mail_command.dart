import 'package:maat/maat.dart';

class MakeMailCommand extends GeneratorCommand {
  @override
  String get name => 'make:mail';

  @override
  String get description => 'Create a new mailable class';

  @override
  String get type => 'Mailable';

  @override
  String get directory => 'lib/app/mail';

  @override
  String stub(String className) =>
      '''
import 'package:maat_amarna/maat_amarna.dart';

class $className extends Mailable {
  @override
  Envelope envelope() => const Envelope();

  @override
  Content content() => const Content(text: '');
}
''';
}
