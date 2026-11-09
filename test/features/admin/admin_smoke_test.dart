import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namazi/core/di/injector.dart';
import 'package:namazi/core/error/failures.dart';
import 'package:namazi/core/widgets/confirm_destructive_dialog.dart';
import 'package:namazi/features/admin/domain/entities/admin_items.dart';
import 'package:namazi/features/admin/domain/entities/admin_queue.dart';
import 'package:namazi/features/admin/domain/usecases/admin_usecases.dart';
import 'package:namazi/features/admin/presentation/bloc/admin_queue_bloc.dart';
import 'package:namazi/features/admin/presentation/pages/masjid_admin_page.dart';
import 'package:namazi/features/admin/presentation/pages/super_admin_page.dart';
import 'package:namazi/features/admin/presentation/widgets/set_time_sheet.dart';
import 'package:namazi/features/claims/presentation/bloc/claims_bloc.dart';
import 'package:namazi/features/claims/presentation/pages/claim_page.dart';
import 'package:namazi/features/masjids/domain/entities/prayer.dart';
import 'package:namazi/features/masjids/presentation/bloc/masjid_detail_bloc.dart';

import '../../helpers/fake_admin_repository.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/pump_app.dart';

class _Claims extends MockBloc<ClaimsEvent, ClaimsState>
    implements ClaimsBloc {}

class _Detail extends MockBloc<MasjidDetailEvent, MasjidDetailState>
    implements MasjidDetailBloc {}

late FakeAdminRepository repo;

B _mock<B extends BlocBase<S>, S>(B bloc, S state) {
  whenListen(bloc, Stream<S>.empty(), initialState: state);
  return bloc;
}

Widget _claim(ClaimsState s) => BlocProvider<ClaimsBloc>.value(
  value: _mock(_Claims(), s),
  child: ClaimView(masjid: masjidUrdu, pickPhoto: () async => null),
);

Widget _masjidAdmin(MasjidDetailState s) => MultiBlocProvider(
  providers: [
    BlocProvider<MasjidDetailBloc>.value(value: _mock(_Detail(), s)),
    BlocProvider<AdminQueueBloc<InboxItem>>(
      create: (_) => AdminQueueBloc<InboxItem>(
        queue: const InboxQueue('m2'),
        load: LoadAdminQueue(repo),
        perform: PerformAdminAction(repo),
      )..add(const AdminQueueRequested()),
    ),
  ],
  child: const MasjidAdminView(slug: 'noor'),
);

Map<String, Widget Function()> _screens() => {
  for (var i = 0; i < 6; i++)
    'SuperAdmin tab $i': () => SuperAdminPage(initialTab: i),
  'SuperAdmin empty': () {
    repo.empty = true;
    return const SuperAdminPage();
  },
  'SuperAdmin error': () {
    repo.failWith = const PermissionFailure('42501');
    return const SuperAdminPage(initialTab: 5);
  },
  'MasjidAdmin loaded': () => _masjidAdmin(
    MasjidDetailState(
      status: MasjidDetailStatus.loaded,
      masjid: masjidUrdu,
      times: fullTimes,
    ),
  ),
  'MasjidAdmin loading': () =>
      _masjidAdmin(const MasjidDetailState(status: MasjidDetailStatus.loading)),
  'MasjidAdmin error': () => _masjidAdmin(
    const MasjidDetailState(
      status: MasjidDetailStatus.error,
      failure: NetworkFailure('x'),
    ),
  ),
  'Claim form': () => _claim(const ClaimsState()),
  'Claim failure': () => _claim(
    const ClaimsState(
      submitStatus: ClaimSubmitStatus.failure,
      submitFailure: PermissionFailure('42501'),
    ),
  ),
  'Claim sent': () =>
      _claim(const ClaimsState(submitStatus: ClaimSubmitStatus.success)),
  'SetTimeSheet': () => const Scaffold(
    body: SetTimeSheet(masjidId: 'm1', prayer: Prayer.maghrib),
  ),
  'ConfirmDestructive': () => const Scaffold(
    body: ConfirmDestructiveDialog(
      title: 'Hide Test Masjid-e-Noor with a long name?',
      body: 'It disappears for everyone. You can restore it from Hidden.',
      confirmText: 'Test Masjid-e-Noor',
      actionLabel: 'Hide',
    ),
  ),
};

void main() {
  setUp(() {
    repo = FakeAdminRepository();
    sl
      ..registerFactory(() => LoadAdminQueue(repo))
      ..registerFactory(() => PerformAdminAction(repo))
      ..registerFactory(() => GetSuggestionAuthor(repo))
      ..registerFactory(() => GetProofUrl(repo));
  });
  tearDown(sl.reset);

  for (final size in smokeSizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 2.0]) {
        final tag =
            '${size.width.toInt()}x${size.height.toInt()} '
            '${mode.name} @${scale}x';
        for (final MapEntry(key: name, value: build) in _screens().entries) {
          testWidgets('$name $tag', (tester) async {
            await tester.pumpApp(
              build(),
              size: size,
              mode: mode,
              textScale: scale,
            );
            await tester.pump();
            await tester.pump();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  testWidgets('typed confirm: button enabled only on an exact match', (
    tester,
  ) async {
    await tester.pumpApp(
      _screens()['ConfirmDestructive']!(),
      size: smokeSizes[1],
    );
    FilledButton hide() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Hide'));
    expect(hide().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Test Masjid');
    await tester.pump();
    expect(hide().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Test Masjid-e-Noor');
    await tester.pump();
    expect(hide().onPressed, isNotNull);
  });

  testWidgets('claim: approve sends one ReviewClaim and reloads', (
    tester,
  ) async {
    await tester.pumpApp(const SuperAdminPage(), size: smokeSizes[3]);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').first);
    await tester.pump();
    await tester.pump();
    expect(repo.performed, [const ReviewClaim('c1', approve: true)]);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('ban author previews the count, then needs the name typed', (
    tester,
  ) async {
    await tester.pumpApp(
      const SuperAdminPage(initialTab: 2),
      size: smokeSizes[3],
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ban author'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This hides 7 open suggestions by Spammer'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Spammer');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ban author'));
    await tester.pumpAndSettle();
    expect(repo.performed, [const BanAuthor('s1')]);
  });

  testWidgets('log shows readable actions, unknown ones raw', (tester) async {
    await tester.pumpApp(
      const SuperAdminPage(initialTab: 5),
      size: smokeSizes[1],
    );
    await tester.pump();
    expect(find.text('Banned a user'), findsOneWidget);
    expect(find.text('something_new'), findsOneWidget);
  });

  testWidgets('inbox accept performs AcceptSuggestion', (tester) async {
    await tester.pumpApp(
      _screens()['MasjidAdmin loaded']!(),
      size: smokeSizes[3],
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pump();
    expect(repo.performed, [const AcceptSuggestion('s2')]);
  });
}
