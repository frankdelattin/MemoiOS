import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapp_app/objectbox.g.dart';

class ObjectBoxInitializer {
  static const String storeName = "memojo-objectbox-v1";

  Future<Store> get instance async {
    final docsDir = await getApplicationDocumentsDirectory();
    var storePath = p.join(docsDir.path, storeName);
    while (true) {
      try {
        if (Store.isOpen(storePath)) {
          return Store.attach(getObjectBoxModel(), storePath);
        }
        return await openStore(directory: storePath);
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
