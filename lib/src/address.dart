class Address {
  const Address(this.email, [this.name]);

  final String email;
  final String? name;

  static Address resolve(Object recipient) {
    if (recipient is Address) return recipient;
    if (recipient is String) return Address(recipient);

    final dynamic value = recipient;
    Object? email;
    try {
      email = value.email;
    } on NoSuchMethodError {
      throw ArgumentError.value(recipient, 'recipient', 'must have an email');
    }
    if (email is! String) {
      throw ArgumentError.value(
        recipient,
        'recipient',
        'email must be a String',
      );
    }

    String? name;
    try {
      final candidate = value.name;
      if (candidate is String) name = candidate;
    } on NoSuchMethodError {
      // A name is optional.
    }
    return Address(email, name);
  }

  static List<Address> list(Object recipients) {
    if (recipients is Iterable) {
      return recipients
          .map((recipient) => resolve(recipient as Object))
          .toList();
    }
    return [resolve(recipients)];
  }
}

class Attachment {
  Attachment.fromPath(String path, {String? as, this.mime})
    : path = path,
      data = null,
      name = as ?? path.replaceAll('\\', '/').split('/').last;

  Attachment.fromData(List<int> bytes, this.name, {this.mime})
    : path = null,
      data = List.unmodifiable(bytes);

  final String? path;
  final List<int>? data;
  final String name;
  final String? mime;
}
