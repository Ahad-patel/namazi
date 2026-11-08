import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/location/data/datasources/location_ds.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/location/domain/usecases/location_usecases.dart';
import '../../features/masjids/data/datasources/masjid_remote_ds.dart';
import '../../features/masjids/data/repositories/masjid_repository_impl.dart';
import '../../features/masjids/domain/repositories/masjid_repository.dart';
import '../../features/masjids/domain/usecases/masjid_usecases.dart';
import '../../features/masjids/presentation/bloc/masjid_detail_bloc.dart';
import '../../features/masjids/presentation/bloc/nearby_bloc.dart';
import '../network/network_info.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

/// Client, data sources and repositories are lazy singletons; use cases and
/// blocs are factories.
Future<void> configureDependencies() async {
  // ---- external ----
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<http.Client>(http.Client.new);
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Connectivity()));
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => ThemeCubit(prefs));

  // ---- location ----
  sl.registerLazySingleton(DeviceLocationDataSource.new);
  sl.registerLazySingleton(() => GeocodingRemoteDataSource(sl()));
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl(), sl()),
  );
  sl.registerFactory(() => GetCurrentLocation(sl()));
  sl.registerFactory(() => SearchArea(sl()));

  // ---- masjids ----
  sl.registerLazySingleton(() => MasjidRemoteDataSource(sl()));
  sl.registerLazySingleton<MasjidRepository>(() => MasjidRepositoryImpl(sl()));
  sl.registerFactory(() => GetNearbyMasjids(sl()));
  sl.registerFactory(() => GetNextJamatNearby(sl()));
  sl.registerFactory(() => GetMasjidBySlug(sl()));
  sl.registerFactory(() => GetMasjidTimes(sl()));
  sl.registerFactory(
    () => NearbyBloc(
      getCurrentLocation: sl(),
      searchArea: sl(),
      getNearby: sl(),
      getNextJamat: sl(),
    ),
  );
  sl.registerFactory(() => MasjidDetailBloc(getBySlug: sl(), getTimes: sl()));
}
