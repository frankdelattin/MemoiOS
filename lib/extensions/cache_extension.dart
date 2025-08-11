import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapp_app/repositories/cache/cache_repository.dart';

extension CacheExtension on GetIt {
  void registerCache() {
    registerSingletonAsync<SharedPreferencesWithCache>(
      () async => SharedPreferencesWithCache.create(
        cacheOptions: SharedPreferencesWithCacheOptions(),
      ),
    );

    registerSingletonAsync<CacheRepository>(
      () async => CacheRepository(sharedPreferences: this()),
      dependsOn: [SharedPreferencesWithCache],
    );
  }
}
