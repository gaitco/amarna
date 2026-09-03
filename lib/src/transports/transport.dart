import '../email.dart';

abstract class Transport {
  Future<void> send(Email email);
}
