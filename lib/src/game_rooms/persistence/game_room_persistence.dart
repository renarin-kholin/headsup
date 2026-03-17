import '../game_room.dart';

abstract class GameRoomPersistence {
  Future<List<GameRoom>> getGameRooms();
  Future<void> saveGameRoom(GameRoom room);
  Future<void> deleteGameRoom(String id);
  Future<void> saveGameRooms(List<GameRoom> rooms);
}
