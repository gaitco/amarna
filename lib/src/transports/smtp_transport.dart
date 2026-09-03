import 'dart:io';

import 'package:mailer/mailer.dart' as smtp;
import 'package:mailer/smtp_server.dart';

import '../address.dart';
import '../email.dart';
import 'transport.dart';

typedef SmtpSender =
    Future<void> Function(smtp.Message message, SmtpServer server);

class SmtpTransport implements Transport {
  SmtpTransport(this.server, {SmtpSender? sender}) : _sender = sender ?? _send;

  final SmtpServer server;
  final SmtpSender _sender;

  @override
  Future<void> send(Email email) async {
    if (email.from == null) {
      throw StateError('SMTP email requires a from address.');
    }
    await _sender(_message(email), server);
  }

  smtp.Message _message(Email email) {
    final message = smtp.Message()
      ..from = _address(email.from!)
      ..recipients.addAll(email.to.map(_address))
      ..ccRecipients.addAll(email.cc.map(_address))
      ..bccRecipients.addAll(email.bcc.map(_address))
      ..subject = email.subject
      ..text = email.text
      ..html = email.html
      ..headers.addAll(email.headers);
    if (email.replyTo.isNotEmpty) {
      message.headers['reply-to'] = email.replyTo.map(_address).toList();
    }
    for (final attachment in email.attachments) {
      message.attachments.add(_attachment(attachment));
    }
    return message;
  }

  smtp.Address _address(Address address) =>
      smtp.Address(address.email, address.name);

  smtp.Attachment _attachment(Attachment attachment) {
    if (attachment.path != null) {
      return smtp.FileAttachment(
        File(attachment.path!),
        contentType: attachment.mime,
        fileName: attachment.name,
      );
    }
    return smtp.StreamAttachment(
      Stream.value(attachment.data!),
      attachment.mime ?? 'application/octet-stream',
      fileName: attachment.name,
    );
  }

  static Future<void> _send(smtp.Message message, SmtpServer server) async {
    await smtp.send(message, server);
  }
}
