import 'package:rackup/app/app.dart';
import 'package:rackup/bootstrap.dart';
import 'package:rackup/core/config/staging_config.dart';

Future<void> main() async {
  await bootstrap(
    (deviceIdentityService) => App(
      config: const StagingConfig(),
      deviceIdentityService: deviceIdentityService,
    ),
  );
}
