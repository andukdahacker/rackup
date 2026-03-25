import 'package:rackup/app/app.dart';
import 'package:rackup/bootstrap.dart';
import 'package:rackup/core/config/dev_config.dart';

Future<void> main() async {
  await bootstrap(
    (deviceIdentityService) => App(
      config: const DevConfig(),
      deviceIdentityService: deviceIdentityService,
    ),
  );
}
