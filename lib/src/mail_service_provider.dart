import 'package:maat/maat.dart';

import 'mail_manager.dart';

class MailServiceProvider extends ServiceProvider {
  MailServiceProvider(super.app);

  @override
  void register() {
    this.app.singleton<MailManager>(
      (_) => MailManager(
        this.app.config,
        events: () => this.app.make<Dispatcher>(),
      ),
    );
  }
}
