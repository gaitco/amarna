import 'package:maat/maat.dart';

import 'address.dart';
import 'email.dart';
import 'events.dart';
import 'mailable.dart';
import 'transports/transport.dart';

class Mailer {
  Mailer(this.transport, {this.from, this.events});

  final Transport transport;
  final Address? from;
  final Dispatcher? Function()? events;

  PendingMail to(Object recipients) => PendingMail(this).to(recipients);

  PendingMail cc(Object recipients) => PendingMail(this).cc(recipients);

  PendingMail bcc(Object recipients) => PendingMail(this).bcc(recipients);

  Future<void> send(
    Mailable mailable, {
    List<Address> to = const [],
    List<Address> cc = const [],
    List<Address> bcc = const [],
  }) async {
    final email = await mailable.build(to: to);
    email.cc.insertAll(0, cc);
    email.bcc.insertAll(0, bcc);
    await sendEmail(email);
  }

  Future<void> raw(String text, void Function(Email email) build) async {
    final email = Email()..text = text;
    build(email);
    await sendEmail(email);
  }

  Future<void> sendEmail(Email email) async {
    email.from ??= from;
    if (email.from == null) {
      throw StateError('Mail requires a from address.');
    }
    if (email.to.isEmpty && email.cc.isEmpty && email.bcc.isEmpty) {
      throw StateError('Mail requires at least one recipient.');
    }

    final dispatcher = events?.call();
    if (dispatcher != null &&
        await dispatcher.until(MessageSending(email)) == false) {
      return;
    }
    await transport.send(email);
    if (dispatcher != null) await dispatcher.dispatch(MessageSent(email));
  }
}

class PendingMail {
  PendingMail(this._mailer);

  final Mailer _mailer;
  final List<Address> _to = [];
  final List<Address> _cc = [];
  final List<Address> _bcc = [];

  PendingMail to(Object recipients) {
    _to.addAll(Address.list(recipients));
    return this;
  }

  PendingMail cc(Object recipients) {
    _cc.addAll(Address.list(recipients));
    return this;
  }

  PendingMail bcc(Object recipients) {
    _bcc.addAll(Address.list(recipients));
    return this;
  }

  Future<void> send(Mailable mailable) =>
      _mailer.send(mailable, to: _to, cc: _cc, bcc: _bcc);
}
