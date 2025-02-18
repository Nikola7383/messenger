import 'package:flutter/material.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MessageInput extends StatefulWidget {
  final Conversation conversation;
  final Function(Map<String, dynamic>, MessageType) onSendMessage;

  const MessageInput({
    super.key,
    required this.conversation,
    required this.onSendMessage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _record = Record();
  String? _recordingPath;
  bool _isRecording = false;
  bool _showAttachMenu = false;

  @override
  void dispose() {
    _textController.dispose();
    _record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showAttachMenu)
              _buildAttachMenu(),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachMenu
                      ? Icons.close
                      : Icons.add,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachMenu = !_showAttachMenu;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Unesite poruku...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                if (_textController.text.isEmpty)
                  IconButton(
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    onPressed: _handleVoiceRecord,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendTextMessage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachButton(
            icon: Icons.image,
            label: 'Slika',
            onTap: _pickImage,
          ),
          _buildAttachButton(
            icon: Icons.camera_alt,
            label: 'Kamera',
            onTap: _takePhoto,
          ),
          _buildAttachButton(
            icon: Icons.attach_file,
            label: 'Fajl',
            onTap: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Implementiraj upload slike
      widget.onSendMessage(
        {
          'url': 'https://example.com/image.jpg', // TODO: Upload image
          'caption': null,
        },
        MessageType.image,
      );
    }
    setState(() {
      _showAttachMenu = false;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // TODO: Implementiraj upload slike
      widget.onSendMessage(
        {
          'url': 'https://example.com/photo.jpg', // TODO: Upload photo
          'caption': null,
        },
        MessageType.image,
      );
    }
    setState(() {
      _showAttachMenu = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // TODO: Implementiraj upload fajla
      widget.onSendMessage(
        {
          'url': 'https://example.com/file.pdf', // TODO: Upload file
          'name': result.files.single.name,
          'size': result.files.single.size,
        },
        MessageType.file,
      );
    }
    setState(() {
      _showAttachMenu = false;
    });
  }

  Future<void> _handleVoiceRecord() async {
    if (!_isRecording) {
      // Počni snimanje
      if (await _record.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordingPath = '${dir.path}/audio_message.m4a';
        
        await _record.start(
          path: _recordingPath!,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      // Zaustavi snimanje
      final path = await _record.stop();
      setState(() {
        _isRecording = false;
      });
      
      if (path != null) {
        // TODO: Implementiraj upload audio fajla
        widget.onSendMessage(
          {
            'url': 'https://example.com/audio.m4a', // TODO: Upload audio
            'duration': 0, // TODO: Get duration
          },
          MessageType.audio,
        );
        
        // Obriši privremeni fajl
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(
        {'text': text},
        MessageType.text,
      );
      _textController.clear();
    }
  }
} 