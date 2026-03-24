import 'package:rackup/app/app.dart';
import 'package:rackup/bootstrap.dart';
import 'package:rackup/core/config/staging_config.dart';

Future<void> main() async {
  await bootstrap(() => const App(config: StagingConfig()));
}
