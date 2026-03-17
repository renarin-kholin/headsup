import 'package:shared_preferences/shared_preferences.dart';

import '../game_room.dart';
import 'game_room_persistence.dart';

class LocalStorageGameRoomPersistence extends GameRoomPersistence {
  static const _gameRoomsKey = 'custom_game_rooms';
  final Future<SharedPreferences> _instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<List<GameRoom>> getGameRooms() async {
    final prefs = await _instanceFuture;
    final jsonString = prefs.getString(_gameRoomsKey) ?? '';
    return GameRoom.decode(jsonString);
  }

  @override
  Future<void> saveGameRoom(GameRoom room) async {
    final rooms = await getGameRooms();
    final index = rooms.indexWhere((r) => r.id == room.id);
    if (index >= 0) {
      rooms[index] = room;
    } else {
      rooms.add(room);
    }
    await saveGameRooms(rooms);
  }

  @override
  Future<void> deleteGameRoom(String id) async {
    final rooms = await getGameRooms();
    rooms.removeWhere((r) => r.id == id);
    await saveGameRooms(rooms);
  }

  @override
  Future<void> saveGameRooms(List<GameRoom> rooms) async {
    final prefs = await _instanceFuture;
    await prefs.setString(_gameRoomsKey, GameRoom.encode(rooms));
  }
}
