# Amarna Mail

Mailables, configurable transports, delivery events, and testing fakes for
Maat applications.

```dart
class WelcomeMail extends Mailable {
  @override
  Envelope envelope() => const Envelope(subject: 'Welcome');

  @override
  Content content() => const Content(text: 'Thanks for joining.');
}

await Mail.to('ada@example.com').send(WelcomeMail());
```

Register `MailServiceProvider` during application bootstrap. Amarna includes
SMTP, log, and in-memory array transports, plus the `make:mail` generator.
