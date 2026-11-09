import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_ds.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/sign_in_bloc.dart';
import '../../features/location/data/datasources/location_ds.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/location/domain/usecases/location_usecases.dart';
import '../../features/masjids/data/datasources/masjid_remote_ds.dart';
import '../../features/masjids/data/repositories/masjid_repository_impl.dart';
import '../../features/masjids/domain/repositories/masjid_repository.dart';
import '../../features/masjids/domain/usecases/masjid_usecases.dart';
import '../../features/masjids/presentation/bloc/add_masjid_bloc.dart';
import '../../features/masjids/presentation/bloc/masjid_detail_bloc.dart';
import '../../features/masjids/presentation/bloc/nearby_bloc.dart';
import '../../features/suggestions/data/datasources/suggestion_remote_ds.dart';
import '../../features/suggestions/data/repositories/suggestion_repository_impl.dart';
import '../../features/suggestions/domain/repositories/suggestion_repository.dart';
import '../../features/suggestions/domain/usecases/suggestion_usecases.dart';
import '../../features/suggestions/presentation/bloc/suggestions_bloc.dart';
import '../network/network_info.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

/// Client, data sources and repositories are lazy singletons; use cases and
/// blocs are factories, except AuthBloc (one app-wide session).
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
  sl.registerFactory(() => AddMasjid(sl()));
  sl.registerFactory(() => AddMasjidBloc(add: sl()));

  // ---- auth ----
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory(() => GetCurrentUser(sl()));
  sl.registerFactory(() => SignInWithGoogle(sl()));
  sl.registerFactory(() => SendEmailCode(sl()));
  sl.registerFactory(() => VerifyEmailCode(sl()));
  sl.registerFactory(() => SignOut(sl()));
  sl.registerFactory(() => AcceptTerms(sl()));
  sl.registerLazySingleton(
    () => AuthBloc(
      repository: sl(),
      getCurrentUser: sl(),
      signOut: sl(),
      acceptTerms: sl(),
    ),
  );
  sl.registerFactory(
    () => SignInBloc(google: sl(), sendCode: sl(), verifyCode: sl()),
  );

  // ---- suggestions ----
  sl.registerLazySingleton(() => SuggestionRemoteDataSource(sl()));
  sl.registerLazySingleton<SuggestionRepository>(
    () => SuggestionRepositoryImpl(sl()),
  );
  sl.registerFactory(() => GetSuggestions(sl()));
  sl.registerFactory(() => SubmitSuggestion(sl()));
  sl.registerFactory(() => VoteOnSuggestion(sl()));
  sl.registerFactory(
    () => SuggestionsBloc(getSuggestions: sl(), submit: sl(), vote: sl()),
  );
}
