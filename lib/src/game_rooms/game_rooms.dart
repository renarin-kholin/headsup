import 'package:flutter/foundation.dart';

import 'game_room.dart';
import 'persistence/game_room_persistence.dart';

class GameRooms extends ChangeNotifier {
  final GameRoomPersistence _persistence;
  List<GameRoom> _rooms = [];
  bool _isLoading = true;

  GameRooms(this._persistence) {
    _loadRooms();
  }

  List<GameRoom> get rooms => _rooms;
  bool get isLoading => _isLoading;

  Future<void> _loadRooms() async {
    _isLoading = true;
    notifyListeners();

    _rooms = await _persistence.getGameRooms();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadRooms();
  }

  Future<void> addRoom(GameRoom room) async {
    _rooms.add(room);
    await _persistence.saveGameRoom(room);
    notifyListeners();
  }

  Future<void> updateRoom(GameRoom room) async {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index >= 0) {
      _rooms[index] = room;
      await _persistence.saveGameRoom(room);
      notifyListeners();
    }
  }

  Future<void> deleteRoom(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    await _persistence.deleteGameRoom(id);
    notifyListeners();
  }

  GameRoom? getRoomById(String id) {
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
