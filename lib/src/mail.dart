import 'package:maat/maat.dart';

import 'email.dart';
import 'mail_fake.dart';
import 'mail_manager.dart';
import 'mailable.dart';
import 'mailer.dart';

abstract final class Mail {
  static MailManager get manager => app<MailManager>();

  static Mailer mailer([String? name]) => manager.mailer(name);

  static PendingMail to(Object recipients) => mailer().to(recipients);

  static PendingMail cc(Object recipients) => mailer().cc(recipients);

  static PendingMail bcc(Object recipients) => mailer().bcc(recipients);

  static Future<void> send(Mailable mailable) => mailer().send(mailable);

  static Future<void> raw(String text, void Function(Email email) build) =>
      mailer().raw(text, build);

  static MailFake fake() {
    final fake = MailFake(manager);
    Application.current.instance<MailManager>(fake);
    return fake;
  }
}
