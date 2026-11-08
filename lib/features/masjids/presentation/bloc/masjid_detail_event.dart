part of 'masjid_detail_bloc.dart';

sealed class MasjidDetailEvent extends Equatable {
  const MasjidDetailEvent();
  @override
  List<Object?> get props => const [];
}

final class MasjidDetailRequested extends MasjidDetailEvent {
  const MasjidDetailRequested(this.slug, {this.known});
  final String slug;
  final Masjid? known;
  @override
  List<Object?> get props => [slug, known];
}

/// Retry, or the highlighted jamat just passed.
final class MasjidDetailRefreshed extends MasjidDetailEvent {
  const MasjidDetailRefreshed();
}
