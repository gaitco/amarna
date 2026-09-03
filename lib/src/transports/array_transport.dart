import '../email.dart';
import 'transport.dart';

class ArrayTransport implements Transport {
  final List<Email> emails = [];

  @override
  Future<void> send(Email email) async => emails.add(email);
}
