import 'package:beacon_broadcaster_example/models/beacon.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'objectbox.g.dart'; // created by `flutter pub run build_runner build`

class ObjectBox {
  /// The Store of this app.
  late final Store store;
  late final Box<Beacon> beaconBox;

  static ObjectBox? _instance;

  ObjectBox._create(this.store) {
    beaconBox = Box<Beacon>(store);
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store =
        await openStore(directory: p.join(docsDir.path, "objectbox-store"));
    final objectbox = ObjectBox._create(store);
    _instance = objectbox;
    return objectbox;
  }

  static ObjectBox get instance {
    if (_instance == null) {
      throw Exception(
          "ObjectBox not initialized. Call ObjectBox.create() first.");
    }
    return _instance!;
  }
}
