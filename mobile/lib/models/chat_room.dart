import '../utils/json_field.dart';

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    this.roomType,
    this.unreadCount = 0,
    this.createdBy,
    this.peerUserId,
    this.peerDisplayName,
    this.levelId,
    this.slug,
    this.description,
  });

  final int id;
  final String name;
  final String? roomType;
  final int unreadCount;
  final int? createdBy;
  final int? peerUserId;
  final String? peerDisplayName;
  final int? levelId;
  final String? slug;
  final String? description;

  bool get isDirect {
    final t = (roomType ?? '').toLowerCase();
    return t == 'private' || t == 'direct';
  }

  bool get isGroup => !isDirect;

  String get displayTitle {
    if (isDirect) {
      final peer = peerDisplayName?.trim();
      if (peer != null && peer.isNotEmpty) return peer;
      if (name.startsWith('Direct:')) return name.replaceFirst('Direct:', '').trim();
    }
    return name;
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final peer = json['peerUser'] ?? json['PeerUser'];
    int? peerId;
    String? peerName;
    if (peer is Map<String, dynamic>) {
      peerId = jsonInt(peer, 'id');
      peerName = jsonStr(peer, 'displayName') ?? jsonStr(peer, 'username');
    }
    return ChatRoom(
      id: jsonInt(json, 'id') ?? jsonInt(json, 'roomId') ?? 0,
      name: jsonStr(json, 'name') ?? jsonStr(json, 'title') ?? 'Phòng chat',
      roomType: jsonStr(json, 'roomType') ?? jsonStr(json, 'type'),
      unreadCount: jsonInt(json, 'unreadCount') ?? 0,
      createdBy: jsonInt(json, 'createdBy'),
      peerUserId: peerId,
      peerDisplayName: peerName,
      levelId: jsonInt(json, 'levelId'),
      slug: jsonStr(json, 'slug'),
      description: jsonStr(json, 'description'),
    );
  }
}
