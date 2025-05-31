import 'package:logging/logging.dart';
import 'package:sane/sane.dart';
import 'package:test/test.dart';

void main() {
  late Sane sane;

  setUp(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  });

  test('can instantiate', () {
    sane = Sane();
  });

  test('same instance on repeated instantiation', () {
    final newSane = Sane();
    expect(sane, equals(newSane));
  });

  test('can exit', () {
    expect(sane.exit, returnsNormally);
  });

  test('throws upon use', () {
    expect(
      () => sane.getDevices(localOnly: true),
      throwsA(isA<SaneNotInitializedError>()),
    );
  });

  test('doesn\'t throw upon use', () {
    expect(sane.init, returnsNormally);
  });
}
