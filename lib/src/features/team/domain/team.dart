import 'package:equatable/equatable.dart';
import 'package:imovio/src/features/authentication/domain/app_user.dart';
import 'package:imovio/src/utils/format.dart';

typedef TeamID = String;

/// Documento `teams/{id}`. O [code] é o que se envia a quem quer entrar.
class Team extends Equatable {
  const Team({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerUid,
  });

  final TeamID id;
  final String name;
  final String code;
  final UserID ownerUid;

  factory Team.fromMap(Map<String, dynamic> data, String id) => Team(
    id: id,
    name: emptyToNull(data['name']?.toString()) ?? 'Equipa',
    code: data['code']?.toString() ?? '',
    ownerUid: data['ownerUid']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'ownerUid': ownerUid,
  };

  @override
  List<Object?> get props => [id, name, code, ownerUid];
}

/// Documento `teams/{teamId}/members/{uid}`. O [sponsorUid] é o padrinho:
/// quem trouxe esta pessoa e ganha uma % da parte dela em cada venda.
class TeamMember extends Equatable {
  const TeamMember({
    required this.uid,
    required this.name,
    this.sponsorUid,
    this.joinedAt,
  });

  final UserID uid;
  final String name;
  final UserID? sponsorUid;
  final int? joinedAt;

  factory TeamMember.fromMap(Map<String, dynamic> data, String uid) =>
      TeamMember(
        uid: uid,
        name: emptyToNull(data['name']?.toString()) ?? 'Sem nome',
        sponsorUid: emptyToNull(data['sponsorUid']?.toString()),
        joinedAt: parseMillis(data['joinedAt']),
      );

  @override
  List<Object?> get props => [uid, name, sponsorUid, joinedAt];
}

/// Documento privado `users/{uid}/team/membership`: a equipa a que o
/// utilizador pertence e os imóveis que escolheu não partilhar.
class Membership extends Equatable {
  const Membership({this.teamId, this.hiddenListings = const []});

  final TeamID? teamId;
  final List<String> hiddenListings;

  bool get inTeam => teamId != null;

  factory Membership.fromMap(Map<String, dynamic>? data) {
    final hidden = data?['hiddenListings'];
    return Membership(
      teamId: emptyToNull(data?['teamId']?.toString()),
      hiddenListings: hidden is List
          ? hidden.map((e) => e.toString()).toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [teamId, hiddenListings];
}
