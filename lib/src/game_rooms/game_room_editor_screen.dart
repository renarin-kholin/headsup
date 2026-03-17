import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'game_room.dart';
import 'game_rooms.dart';
import '../style/palette.dart';

class GameRoomEditorScreen extends StatefulWidget {
  final String? roomId;

  const GameRoomEditorScreen({super.key, this.roomId});

  @override
  State<GameRoomEditorScreen> createState() => _GameRoomEditorScreenState();
}

class _GameRoomEditorScreenState extends State<GameRoomEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wordController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  final List<WordItem> _items = [];
  bool _isEditing = false;
  String? _currentRoomId;

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _isEditing = true;
      _currentRoomId = widget.roomId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingRoom();
      });
    }
  }

  void _loadExistingRoom() {
    final gameRooms = context.read<GameRooms>();
    final room = gameRooms.getRoomById(widget.roomId!);
    if (room != null) {
      _nameController.text = room.name;
      _items.addAll(room.items);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    final existingIndex =
        _items.indexWhere((i) => i.word.toLowerCase() == word.toLowerCase());
    if (existingIndex >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word already exists')),
      );
      return;
    }

    String? savedImagePath;
    if (_selectedImage != null) {
      final roomId =
          _currentRoomId ?? DateTime.now().millisecondsSinceEpoch.toString();
      savedImagePath = await GameRoom.saveImage(_selectedImage!, roomId);
    }

    setState(() {
      _items.add(WordItem(
        word: word,
        imagePath: savedImagePath,
      ));
      _wordController.clear();
      _selectedImage = null;
    });
  }

  void _removeWord(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _editWord(int index) {
    final item = _items[index];
    _wordController.text = item.word;
    if (item.imagePath != null) {
      _selectedImage = File(item.imagePath!);
    }
    _removeWord(index);
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one word')),
      );
      return;
    }

    final gameRooms = context.read<GameRooms>();
    final roomId =
        _currentRoomId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final room = GameRoom(
      id: roomId,
      name: _nameController.text.trim(),
      items: List.from(_items),
    );

    if (_isEditing) {
      await gameRooms.updateRoom(room);
    } else {
      await gameRooms.addRoom(room);
    }

    if (mounted) {
      context.go('/play');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      backgroundColor: palette.backgroundLevelSelection,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Room' : 'Create Room'),
        backgroundColor: palette.backgroundLevelSelection,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/play'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Word with optional image',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _wordController,
                      decoration: const InputDecoration(
                        labelText: 'Word',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onFieldSubmitted: (_) => _addWord(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text('Add Image',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addWord,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.darkPen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No words added yet.\nAdd words to create your custom game.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              leading: item.hasImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child:
                                          _buildImageThumbnail(item.imagePath),
                                    )
                                  : const Icon(Icons.text_fields,
                                      color: Colors.white),
                              title: Text(
                                item.word,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editWord(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeWord(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saveRoom,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.darkPen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isEditing ? 'Update Room' : 'Create Room',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String? imagePath) {
    if (imagePath == null) {
      return const SizedBox(width: 48, height: 48);
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.broken_image, color: Colors.grey);
  }
}
