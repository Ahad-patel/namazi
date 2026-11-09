import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum ClaimRole { imam, mutawalli, committee }

enum ClaimStatus { pending, approved, rejected, revoked }

/// What the caller may do at one masjid (`masjid_access` RPC).
class MasjidAccess extends Equatable {
  const MasjidAccess({required this.canManage, this.claimStatus});

  /// Approved admin of this masjid, or super admin.
  final bool canManage;

  /// The caller's latest claim here, if any.
  final ClaimStatus? claimStatus;

  static const none = MasjidAccess(canManage: false);

  @override
  List<Object?> get props => [canManage, claimStatus];
}

class ClaimDraft extends Equatable {
  const ClaimDraft({
    required this.masjidId,
    required this.role,
    required this.phone,
    this.photo,
  });

  final String masjidId;
  final ClaimRole role;

  /// Digits with an optional leading +, 8–15 digits (server check).
  final String phone;

  /// JPEG, already resized on device (1600 px, quality 80).
  final Uint8List? photo;

  @override
  List<Object?> get props => [masjidId, role, phone, photo?.length];
}
