import 'package:mailer/smtp_server.dart';
import 'package:maat/maat.dart';

import 'address.dart';
import 'mailer.dart';
import 'transports/array_transport.dart';
import 'transports/log_transport.dart';
import 'transports/smtp_transport.dart';
import 'transports/transport.dart';

typedef TransportFactory = Transport Function(Map<String, dynamic> settings);

class MailManager {
  MailManager(this.config, {this.events});

  final Config config;
  final Dispatcher? Function()? events;
  final Map<String, Mailer> _mailers = {};

  static final Map<String, TransportFactory> _extensions = {};

  static void extend(String transport, TransportFactory factory) =>
      _extensions[transport] = factory;

  static void resetExtensions() => _extensions.clear();

  Mailer mailer([String? name]) {
    final selected = name ?? config.get('mail.default', 'log');
    if (selected is! String) {
      throw StateError('config("mail.default") must be a String.');
    }
    return _mailers.putIfAbsent(selected, () => _makeMailer(selected));
  }

  Mailer _makeMailer(String name) {
    final raw = config.get('mail.mailers.$name');
    if (raw is! Map) {
      throw StateError('No mailer named "$name" in config("mail.mailers").');
    }
    final settings = Map<String, dynamic>.from(raw);
    final transportName = settings['transport'] ?? name;
    if (transportName is! String) {
      throw StateError('Mailer "$name" must have a String transport.');
    }

    final transport =
        _extensions[transportName]?.call(settings) ??
        switch (transportName) {
          'array' => ArrayTransport(),
          'log' => LogTransport(),
          'smtp' => _smtp(settings),
          _ => throw StateError(
            'No mail transport registered for "$transportName".',
          ),
        };
    return Mailer(transport, from: _from(), events: events);
  }

  SmtpTransport _smtp(Map<String, dynamic> settings) {
    final host = settings['host'];
    final port = settings['port'] ?? 587;
    final username = settings['username'];
    final password = settings['password'];
    final encryption = settings['encryption'];
    if (host is! String || port is! int) {
      throw StateError('SMTP mailer requires a String host and int port.');
    }
    if (username != null && username is! String) {
      throw StateError('SMTP username must be a String.');
    }
    if (password != null && password is! String) {
      throw StateError('SMTP password must be a String.');
    }
    if (encryption != null && encryption is! String) {
      throw StateError('SMTP encryption must be a String or null.');
    }
    return SmtpTransport(
      SmtpServer(
        host,
        port: port,
        username: username as String?,
        password: password as String?,
        ssl: encryption == 'ssl',
        allowInsecure: encryption == null || encryption == '',
      ),
    );
  }

  Address? _from() {
    final raw = config.get('mail.from');
    if (raw == null) return null;
    if (raw is! Map || raw['address'] is! String) {
      throw StateError('config("mail.from.address") must be a String.');
    }
    final name = raw['name'];
    if (name != null && name is! String) {
      throw StateError('config("mail.from.name") must be a String or null.');
    }
    return Address(raw['address'] as String, name as String?);
  }
}
