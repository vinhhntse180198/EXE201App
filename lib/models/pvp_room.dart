import '../utils/json_field.dart';

class PvpRoom {
  const PvpRoom({
    required this.roomId,
    required this.roomCode,
    required this.status,
    required this.hostUserId,
    required this.hostDisplayName,
    this.guestUserId,
    this.guestDisplayName,
  });

  final int roomId;
  final String roomCode;
  final String status;
  final int hostUserId;
  final String hostDisplayName;
  final int? guestUserId;
  final String? guestDisplayName;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isWaiting => status.toLowerCase() == 'waiting';
  bool get hasGuest => guestUserId != null && guestUserId! > 0;

  factory PvpRoom.fromJson(Map<String, dynamic> json) {
    return PvpRoom(
      roomId: jsonInt(json, 'roomId') ?? jsonInt(json, 'RoomId') ?? 0,
      roomCode: jsonStr(json, 'roomCode') ?? jsonStr(json, 'RoomCode') ?? '',
      status: jsonStr(json, 'status') ?? jsonStr(json, 'Status') ?? 'waiting',
      hostUserId: jsonInt(json, 'hostUserId') ?? jsonInt(json, 'HostUserId') ?? 0,
      hostDisplayName: jsonStr(json, 'hostDisplayName') ?? jsonStr(json, 'HostDisplayName') ?? 'Host',
      guestUserId: jsonInt(json, 'guestUserId') ?? jsonInt(json, 'GuestUserId'),
      guestDisplayName: jsonStr(json, 'guestDisplayName') ?? jsonStr(json, 'GuestDisplayName'),
    );
  }
}
