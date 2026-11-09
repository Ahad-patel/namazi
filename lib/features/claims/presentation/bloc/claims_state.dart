part of 'claims_bloc.dart';

enum AccessStatus { initial, loading, loaded, error }

/// idle = form open (empty), submitting = loading, success, failure = error.
enum ClaimSubmitStatus { idle, submitting, success, failure }

class ClaimsState extends Equatable {
  const ClaimsState({
    this.status = AccessStatus.initial,
    this.access = MasjidAccess.none,
    this.failure,
    this.submitStatus = ClaimSubmitStatus.idle,
    this.submitFailure,
  });

  final AccessStatus status;
  final MasjidAccess access;
  final Failure? failure;
  final ClaimSubmitStatus submitStatus;
  final Failure? submitFailure;

  ClaimsState copyWith({
    AccessStatus? status,
    MasjidAccess? access,
    Failure? failure,
    ClaimSubmitStatus? submitStatus,
    Failure? submitFailure,
  }) => ClaimsState(
    status: status ?? this.status,
    access: access ?? this.access,
    failure: failure ?? this.failure,
    submitStatus: submitStatus ?? this.submitStatus,
    submitFailure: submitFailure ?? this.submitFailure,
  );

  @override
  List<Object?> get props => [
    status,
    access,
    failure,
    submitStatus,
    submitFailure,
  ];
}
