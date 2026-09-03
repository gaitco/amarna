import 'package:maat/maat.dart';
import 'package:khnum_maat/khnum_maat.dart';

import 'address.dart';
import 'email.dart';

class Envelope {
  const Envelope({
    this.subject,
    this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.replyTo = const [],
  });

  final String? subject;
  final Address? from;
  final List<Address> to;
  final List<Address> cc;
  final List<Address> bcc;
  final List<Address> replyTo;
}

class Content {
  const Content({this.view, this.text, this.html, this.data = const {}});

  final String? view;
  final String? text;
  final String? html;
  final Map<String, Object?> data;
}

abstract class Mailable {
  Envelope envelope();

  Content content();

  List<Attachment> attachments() => const [];

  Future<Email> build({List<Address> to = const []}) async {
    final messageEnvelope = envelope();
    final messageContent = content();
    final email = Email()
      ..from = messageEnvelope.from
      ..to.addAll([...to, ...messageEnvelope.to])
      ..cc.addAll(messageEnvelope.cc)
      ..bcc.addAll(messageEnvelope.bcc)
      ..replyTo.addAll(messageEnvelope.replyTo)
      ..subject = messageEnvelope.subject ?? Str.headline(runtimeType)
      ..text = messageContent.text
      ..html = messageContent.html
      ..attachments.addAll(attachments());
    if (messageContent.view != null) {
      email.html = await renderView(messageContent.view!, messageContent.data);
    }
    return email;
  }
}
