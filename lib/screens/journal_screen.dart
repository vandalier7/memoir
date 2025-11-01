// lib/screens/journal_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class JournalScreen extends StatefulWidget {
  final String imagePath;
  final List<CameraDescription> cameras;
  
  const JournalScreen({
    Key? key, 
    required this.imagePath,
    required this.cameras,
  }) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with TickerProviderStateMixin {
  // Palette
  static const List<Color> palette = [
    Color(0xFFF75270),
    Color.fromARGB(255, 250, 132, 154),
    Color.fromARGB(255, 252, 165, 181),
    Color.fromARGB(255, 245, 200, 157),
    Color.fromARGB(255, 248, 217, 174),
  ];

  bool isMoodOpen = false;
  bool isJournalOpen = false;
  bool isEmojiPickerOpen = false;
  String selectedMood = '';

  // Moods with emojis
  final List<Map<String, String>> moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😡', 'label': 'Angry'},
    {'emoji': '🤢', 'label': 'Disgusted'},
    {'emoji': '😱', 'label': 'Scared'},
    {'emoji': '😌', 'label': 'Chill'},
    {'emoji': '😰', 'label': 'Stressed'},
  ];

  // Available emojis for overlay
  final List<String> availableEmojis = [
    '😊', '😂', '😍', '🥰', '😎', '🤩', '😢', '😭',
    '😡', '🤬', '😱', '🤢', '🤮', '😴', '🤔', '🤯',
    '❤️', '💕', '💖', '✨', '⭐', '🌟', '🔥', '💯',
    '👍', '👎', '👏', '🙌', '🤝', '💪', '🎉', '🎊'
  ];

  final TextEditingController whatsController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController textOverlayController = TextEditingController();
  List<String> tags = [];
  List<_OverlayItem> overlays = [];
  bool isDraggingOverlay = false;

  late final AnimationController _bottomDrawerController;
  late final AnimationController _moodDrawerController;

  @override
  void initState() {
    super.initState();
    _bottomDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _moodDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    whatsController.dispose();
    tagController.dispose();
    textOverlayController.dispose();
    _bottomDrawerController.dispose();
    _moodDrawerController.dispose();
    super.dispose();
  }

  void _toggleMood() {
    setState(() => isMoodOpen = !isMoodOpen);
    isMoodOpen
        ? _moodDrawerController.forward()
        : _moodDrawerController.reverse();
  }

  void _toggleJournal() {
    setState(() => isJournalOpen = !isJournalOpen);
    isJournalOpen
        ? _bottomDrawerController.forward()
        : _bottomDrawerController.reverse();
  }

  void _addTag() {
    final t = tagController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      tags.add(t);
      tagController.clear();
    });
  }

  Future<void> saveToSupabase() async {
    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(const SnackBar(content: Text('Saving...')));
    await Future.delayed(const Duration(seconds: 1));
    snack.hideCurrentSnackBar();
    snack.showSnackBar(
      const SnackBar(content: Text('Saved to Supabase (placeholder)!')),
    );
  }

  void _showTextOverlayDialog() {
    textOverlayController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textOverlayController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textOverlayController.text.trim().isNotEmpty) {
                _addTextOverlay(textOverlayController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTextOverlay(String text) {
    final overlay = _OverlayItem.text(
      text: text,
      dx: 0.4,
      dy: 0.4,
      scale: 1.0,
    );
    setState(() => overlays.add(overlay));
  }

  void _showEmojiPicker() {
    setState(() => isEmojiPickerOpen = true);
  }

  void _addEmojiOverlay(String emoji) {
    final overlay = _OverlayItem.emoji(
      emoji: emoji,
      dx: 0.4,
      dy: 0.4,
      scale: 1.0,
    );
    setState(() {
      overlays.add(overlay);
      isEmojiPickerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (isMoodOpen) {
            setState(() {
              isMoodOpen = false;
              _moodDrawerController.reverse();
            });
          }
          if (isEmojiPickerOpen) {
            setState(() => isEmojiPickerOpen = false);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Positioned.fill(
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),

            // Overlay items
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: overlays.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return _DraggableResizableOverlay(
                        key: ValueKey(item.id),
                        item: item,
                        parentSize:
                            Size(constraints.maxWidth, constraints.maxHeight),
                        onUpdate: (updated) {
                          setState(() => overlays[idx] = updated);
                        },
                        onRemove: () {
                          setState(() => overlays.removeAt(idx));
                        },
                        onDragStart: () {
                          setState(() => isDraggingOverlay = true);
                        },
                        onDragEnd: () {
                          setState(() => isDraggingOverlay = false);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Close button
            Positioned(
              top: 40,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(cameras: widget.cameras),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),

            // Top right action buttons
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.text_fields,
                    onTap: _showTextOverlayDialog,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    icon: Icons.emoji_emotions,
                    onTap: _showEmojiPicker,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    icon: Icons.music_note,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Music feature coming soon!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Emoji Picker
            if (isEmojiPickerOpen) _buildEmojiPicker(),

            // Mood Button
            if (!isDraggingOverlay)
              Positioned(
                left: 20,
                bottom: 140 + bottomSafe,
                child: _buildMoodButton(),
              ),

            // Add to Journal pill
            if (!isDraggingOverlay)
              Positioned(
                bottom: 80 + bottomSafe,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _toggleJournal,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add to Journal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        AnimatedRotation(
                          turns: isJournalOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Journal Drawer
            if (isJournalOpen) _buildBottomJournalDrawer(),

            // Mood Drawer
            if (!isDraggingOverlay) _buildMoodDrawer(),

            // Trash can (shown when dragging overlays)
            if (isDraggingOverlay)
              Positioned(
                bottom: 20 + bottomSafe,
                left: MediaQuery.of(context).size.width / 2 - 35,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),

            // Share Memory button
            if (!isDraggingOverlay)
              Positioned(
                left: 20,
                right: 20,
                bottom: 10 + bottomSafe,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: saveToSupabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette[0].withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Share Memory',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Positioned(
      top: 100,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 280,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: availableEmojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _addEmojiOverlay(availableEmojis[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        availableEmojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton() {
    return GestureDetector(
      onTap: _toggleMood,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mood, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              selectedMood.isEmpty ? 'Mood' : selectedMood,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDrawer() {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 20,
      bottom: 184 + bottomSafe, // Connected to mood button
      child: SizeTransition(
        sizeFactor: _moodDrawerController,
        axisAlignment: -1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: moods.map((m) {
                      final isSelected = selectedMood == m['label'];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Text(m['emoji']!,
                            style: const TextStyle(fontSize: 20)),
                        title: Text(
                          m['label']!,
                          style: TextStyle(
                            color: isSelected ? palette[0] : Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          setState(() => selectedMood = m['label']!);
                          _toggleMood();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Connector line
            Container(
              width: 2,
              height: 4,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomJournalDrawer() {
    final height = MediaQuery.of(context).size.height * 0.46;
    return AnimatedBuilder(
      animation: _bottomDrawerController,
      builder: (context, child) {
        final value = _bottomDrawerController.value;
        return Positioned(
          left: 0,
          right: 0,
          bottom: -height + (height * value) + 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(14),
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Journal Entry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleJournal,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    const Text("What's happening?",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: whatsController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Describe the moment...',
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Tags", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Add a tag',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black26,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map((t) => Chip(
                                label: Text(t),
                                backgroundColor: Colors.white12,
                                labelStyle: const TextStyle(color: Colors.white),
                                onDeleted: () {
                                  setState(() => tags.remove(t));
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverlayItem {
  final String id;
  final bool isText;
  final String text;
  final String emoji;
  final double dx;
  final double dy;
  final double scale;

  _OverlayItem._({
    required this.id,
    required this.isText,
    required this.text,
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.scale,
  });

  factory _OverlayItem.text({
    required String text,
    required double dx,
    required double dy,
    required double scale,
  }) {
    return _OverlayItem._(
      id: UniqueKey().toString(),
      isText: true,
      text: text,
      emoji: '',
      dx: dx,
      dy: dy,
      scale: scale,
    );
  }

  factory _OverlayItem.emoji({
    required String emoji,
    required double dx,
    required double dy,
    required double scale,
  }) {
    return _OverlayItem._(
      id: UniqueKey().toString(),
      isText: false,
      text: '',
      emoji: emoji,
      dx: dx,
      dy: dy,
      scale: scale,
    );
  }

  _OverlayItem copyWith({
    double? dx,
    double? dy,
    double? scale,
    String? text,
    String? emoji,
  }) {
    return _OverlayItem._(
      id: id,
      isText: isText,
      text: text ?? this.text,
      emoji: emoji ?? this.emoji,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scale: scale ?? this.scale,
    );
  }
}

// Draggable and resizable overlay widget
class _DraggableResizableOverlay extends StatefulWidget {
  final _OverlayItem item;
  final Size parentSize;
  final void Function(_OverlayItem) onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _DraggableResizableOverlay({
    Key? key,
    required this.item,
    required this.parentSize,
    required this.onUpdate,
    required this.onRemove,
    required this.onDragStart,
    required this.onDragEnd,
  }) : super(key: key);

  @override
  State<_DraggableResizableOverlay> createState() =>
      _DraggableResizableOverlayState();
}

class _DraggableResizableOverlayState extends State<_DraggableResizableOverlay> {
  late double dx;
  late double dy;
  late double scale;
  double baseScale = 1.0;
  bool isDragging = false;
  bool isResizing = false;

  @override
  void initState() {
    super.initState();
    dx = widget.item.dx;
    dy = widget.item.dy;
    scale = widget.item.scale;
    baseScale = scale;
  }

  bool _isOverTrash() {
    final screenHeight = widget.parentSize.height;
    final screenWidth = widget.parentSize.width;
    final itemY = dy * screenHeight;
    final itemX = dx * screenWidth;
    
    // Trash is at bottom center
    final trashY = screenHeight - 55; // Approximate trash position
    final trashX = screenWidth / 2;
    
    // Check if overlay is near trash (within 80 pixels)
    final distance = ((itemX - trashX).abs() + (itemY - trashY).abs());
    return distance < 80;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: dx * widget.parentSize.width - 30,
      top: dy * widget.parentSize.height - 30,
      child: GestureDetector(
        onScaleStart: (details) {
          baseScale = scale;
          widget.onDragStart();
          setState(() {
            isDragging = true;
            isResizing = false;
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            // Always handle position changes
            dx += details.focalPointDelta.dx / widget.parentSize.width;
            dy += details.focalPointDelta.dy / widget.parentSize.height;
            
            // If scale is changing significantly, we're also resizing
            if ((details.scale - 1.0).abs() > 0.05) {
              isResizing = true;
              scale = baseScale * details.scale;
              scale = scale.clamp(0.5, 3.0);
            }
          });
          widget.onUpdate(widget.item.copyWith(dx: dx, dy: dy, scale: scale));
        },
        onScaleEnd: (details) {
          widget.onDragEnd();
          
          // Check if over trash
          if (_isOverTrash() && isDragging && !isResizing) {
            widget.onRemove();
          }
          
          setState(() {
            isDragging = false;
            isResizing = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDragging
                  ? (_isOverTrash() ? Colors.red : Colors.blue.withOpacity(0.6))
                  : Colors.white.withOpacity(0.3),
              width: isDragging ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Transform.scale(
            scale: scale,
            child: widget.item.isText
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.item.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    widget.item.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
          ),
        ),
      ),
    );
  }
}