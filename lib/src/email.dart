import 'address.dart';

class Email {
  Address? from;
  final List<Address> to = [];
  final List<Address> cc = [];
  final List<Address> bcc = [];
  final List<Address> replyTo = [];
  String subject = '';
  String? html;
  String? text;
  final List<Attachment> attachments = [];
  final Map<String, String> headers = {};

  bool hasTo(String email) =>
      to.any((address) => address.email.toLowerCase() == email.toLowerCase());
}
