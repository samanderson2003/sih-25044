import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controller/chat_controller.dart';
import '../model/chat_message.dart';
import '../../widgets/translated_text.dart'; // Assuming this widget exists

class CommunityChatScreen extends StatelessWidget {
  const CommunityChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: const _CommunityChatView(),
    );
  }
  
}

class _CommunityChatView extends StatelessWidget {
  const _CommunityChatView();

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const TranslatedText(
          'Community Chat',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatController>(
              builder: (context, controller, _) {
                if (controller.errorMessage != null) { 
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(controller.errorMessage!)),
                    );
                    controller.clearErrorMessage(); 
                  });
                }
                
                return StreamBuilder<List<ChatMessage>>(
                  stream: controller.messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading messages: ${snapshot.error}',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            TranslatedText(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TranslatedText(
                              'Be the first to say hello! 👋',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = controller.isMyMessage(message.senderId);

                        return _MessageBubble(
                          message: message, 
                          isMe: isMe,
                          onSenderTap: () => _showUserInfo(context, message.senderId),
                          onLongPress: isMe 
                              ? () => _showDeleteDialog(context, controller, message)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          const _MessageInputField(),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatController controller, ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message for everyone? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteMessage(message);
            },
            child: const Text('DELETE FOR EVERYONE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: primaryColor),
            SizedBox(width: 8),
            TranslatedText('Community Guidelines'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            TranslatedText('• Be respectful to all farmers'),
            SizedBox(height: 8),
            TranslatedText('• Share helpful farming tips'),
            SizedBox(height: 8),
            TranslatedText('• Ask questions freely'),
            SizedBox(height: 8),
            TranslatedText('• No spam or promotional content'),
            SizedBox(height: 8),
            TranslatedText('• Keep discussions agriculture-related'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText(
              'Got it',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showUserInfo(BuildContext context, String senderId) {
    final controller = Provider.of<ChatController>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.person, color: primaryColor),
            SizedBox(width: 8),
            TranslatedText('Farmer Profile'),
          ],
        ),
        content: FutureBuilder<Map<String, String>>(
          future: controller.fetchUserInfo(senderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryColor));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const TranslatedText('Could not load user info.');
            }
            
            final info = snapshot.data!;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 30,
                  child: Icon(Icons.person_2, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                ...info.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                )).toList(),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText(
              'Close',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback onSenderTap;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message, 
    required this.isMe,
    required this.onSenderTap,
    this.onLongPress,
  });

  static const primaryColor = Color(0xFF2D5016);

  @override
  Widget build(BuildContext context) {
    final formattedTime = message.timestamp != null
        ? DateFormat('h:mm a').format(message.timestamp!)
        : '';
        
    final bool isMediaMessage = message.imageUrl != null && message.imageUrl!.isNotEmpty;
    final bool isVoiceMessage = message.text == 'Voice Message 🎤' && isMediaMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isMe ? primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onSenderTap,
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              
              // Media Display
              if (isMediaMessage)
                Padding(
                  padding: EdgeInsets.only(bottom: message.text.isNotEmpty && !isVoiceMessage ? 8.0 : 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                      child: isVoiceMessage
                        ? _VoiceMessagePlayer(
                            audioUrl: message.imageUrl!,
                            isMe: isMe,
                          )
                        : GestureDetector(
                            onTap: () => _showMediaOptions(context, message, isVoiceMessage, isMe),
                            child: CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 150, height: 150, 
                                color: primaryColor.withOpacity(0.1),
                                child: const Center(child: CircularProgressIndicator(color: primaryColor)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 150, height: 150,
                                color: Colors.red.withOpacity(0.1),
                                child: const Icon(Icons.broken_image, color: Colors.red),
                              ),
                            ),
                          ),
                  ),
                ),
                
              // Text Content
              if (message.text.isNotEmpty && !isVoiceMessage) 
                TranslatedText(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white60 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isImageUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final ext = path.split('.').last.toLowerCase();
      const imageExt = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'];
      return imageExt.contains(ext);
    } catch (_) {
      return false;
    }
  }

  Future<void> _showMediaOptions(BuildContext context, ChatMessage message, bool isVoice, bool isMe) async {
    if (message.imageUrl == null || message.imageUrl!.isEmpty) return;
    final url = message.imageUrl!;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVoice) ...[
                ListTile(
                  leading: Icon(Icons.play_arrow, color: primaryColor),
                  title: const Text('Play'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: _VoiceMessagePlayer(audioUrl: url, isMe: isMe),
                      ),
                    );
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.remove_red_eye, color: primaryColor),
                  title: const Text('View'),
                  onTap: () async {
                    Navigator.pop(context);
                    final isImage = _isImageUrl(url);
                    if (isImage) {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Try to open document in external browser/viewer
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        try {
                          await launchUrl(uri);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to open document: $e')));
                        }
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download, color: primaryColor),
                  title: const Text('Download'),
                  onTap: () async {
                    Navigator.pop(context);
                    final suggested = Uri.parse(url).path.split('/').last;
                    await _downloadFile(context, url, suggested);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadFile(BuildContext context, String url, String suggestedName) async {
    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting download...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 1. Request Storage Permission
      if (Platform.isAndroid) {
         // Check Android version indirectly via permission status or just try
         // On Android 13 (SDK 33+), READ_EXTERNAL_STORAGE/WRITE_EXTERNAL_STORAGE are deprecated.
         // We usually don't need runtime permission to write to public Downloads on modern Android.
         
         var status = await Permission.storage.status;
         
         // If denied/restricted, and we are on an older permission model, request it.
         // If we are on Android 13+, this might return denied even if we can write.
         // A simple heuristic: if it's explicitly denied, try to request.
         if (!status.isGranted) {
            final result = await Permission.storage.request();
            if (!result.isGranted) {
               // Only block if we truly believe we need it. 
               // For now, we will try to proceed to the write step even if denied,
               // catching the permission exception there if it actually fails.
               // This works around Android 13 returning 'denied' for a permission that doesn't exist.
            }
         }
      }

      final uri = Uri.parse(url);
      final resp = await http.get(uri);
      
      if (resp.statusCode != 200) {
        throw Exception('Server returned ${resp.statusCode}');
      }

      // 2. Determine Public Download Path
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // Direct path to public Downloads folder
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        // iOS/Fallback
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!downloadsDir.existsSync()) {
        downloadsDir = await getExternalStorageDirectory(); // Fallback to app specific
      }
      
      // 3. Save File
      // Sanitize filename to avoid path traversal
      final safeName = suggestedName.replaceAll(RegExp(r'[^\w\s\.-]'), '');
      String savePath = '${downloadsDir!.path}/$safeName';
      
      // Handle duplicate names
      int counter = 1;
      while (await File(savePath).exists()) {
        final dotIndex = safeName.lastIndexOf('.');
        if (dotIndex != -1) {
             final name = safeName.substring(0, dotIndex);
             final ext = safeName.substring(dotIndex);
             savePath = '${downloadsDir.path}/${name}_$counter$ext';
        } else {
             savePath = '${downloadsDir.path}/${safeName}_$counter';
        }
        counter++;
      }

      final file = File(savePath);
      await file.writeAsBytes(resp.bodyBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to Downloads: ${file.path.split('/').last}'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () {
                 // Try to open the file
              },
            ),
            duration: const Duration(seconds: 4),
          )
        );
      }
      
    } catch (e) {
      print('Download error: $e');
      if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ${e.toString()}')));
      }
      
      // Attempt fallback to browser
      try {
         await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

  }
}

class _VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const _VoiceMessagePlayer({
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoadingAudio = true;

  static const primaryColor = Color(0xFF2D5016);

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      if (mounted) setState(() => _isLoadingAudio = false);
      
      _audioPlayer.durationStream.listen((d) {
        if(mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _audioPlayer.positionStream.listen((p) {
        if(mounted) setState(() => _position = p);
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          if(mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        } 
        else if (playerState.playing != _isPlaying) {
          if(mounted) setState(() => _isPlaying = playerState.playing);
        }
      });
    } catch (e) {
      print('Error loading audio: $e');
      if(mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _togglePlayPause() async {
    if (_isLoadingAudio) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position >= _duration) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAudio) {
      return Container(
        width: 150, height: 48,
        decoration: BoxDecoration(
          color: widget.isMe ? primaryColor.withOpacity(0.8) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minWidth: 150),
      decoration: BoxDecoration(
        color: widget.isMe ? primaryColor.withOpacity(0.8) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: widget.isMe ? Colors.white : primaryColor,
              size: 36,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voice Message',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                    activeColor: widget.isMe ? Colors.white : primaryColor,
                    inactiveColor: widget.isMe ? Colors.white30 : Colors.grey[400],
                    onChanged: (value) {
                      final newPosition = Duration(milliseconds: value.toInt());
                      _audioPlayer.seek(newPosition);
                    },
                  ),
                ),
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _MessageInputField extends StatelessWidget {
  const _MessageInputField();

  static const primaryColor = Color(0xFF2D5016);
  static const backgroundColor = Color(0xFFF8F6F0);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final isImageAttached = controller.selectedImagePath != null;
        final isFileAttached = controller.selectedFilePath != null;
        // FIX: Use the public getter here
        final isVoiceAttached = controller.simulatedVoicePath != null; 
        final isMediaAttached = isImageAttached || isFileAttached || isVoiceAttached;
        
        String? recordingDuration = controller.recordingDuration;
        
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Plus/Attachment Icon
                Container(
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    // Disable if recording or if voice is attached
                    onPressed: controller.isLoading || controller.isRecording || isVoiceAttached ? null : () => _showAttachmentModal(context, controller),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller.messageController,
                      decoration: InputDecoration(
                        hintText: isVoiceAttached
                            ? 'Voice attached. Type your caption or send...'
                            : isImageAttached 
                                ? 'Image attached. Type your caption or send...'
                                : isFileAttached
                                    ? 'File attached. Type your description or send...'
                                    : controller.isRecording 
                                        ? 'Recording $recordingDuration'
                                        : 'Type a message...',
                        hintStyle: TextStyle(
                          color: controller.isRecording ? Colors.red.withOpacity(0.7) : Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        prefixIcon: isMediaAttached
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVoiceAttached ? Icons.mic : (isImageAttached ? Icons.photo : Icons.insert_drive_file), 
                                      color: primaryColor.withOpacity(0.7)
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        isVoiceAttached ? 'Voice Message' : (isImageAttached ? controller.selectedImagePath! : controller.selectedFilePath!)
                                          .split('/')
                                          .last,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: primaryColor.withOpacity(0.7)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                      onPressed: controller.clearAllAttachments,
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => controller.sendMessage(),
                      textInputAction: TextInputAction.send,
                      // Read-only if recording OR if voice is attached and we expect a caption
                      readOnly: controller.isRecording, 
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Microphone icon for voice input (Recording)
                Container(
                  decoration: BoxDecoration(
                    color: controller.isRecording
                        ? Colors.red.withOpacity(0.7)
                        : primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      controller.isRecording ? Icons.stop : Icons.mic_none,
                      color: Colors.white,
                    ),
                    // Pressing this button now manages the recording state and prepares the file
                    onPressed: controller.isLoading || isVoiceAttached ? null : controller.toggleRecording,
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                Container(
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: controller.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: controller.isLoading
                        ? null
                        : () {
                            controller.sendMessage();
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentModal(BuildContext context, ChatController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickMedia(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: primaryColor),
                  title: const Text('Gallery (Photo/Video)'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickMedia(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: primaryColor),
                  title: const Text('Document/File'),
                  onTap: () async {
                    Navigator.pop(context);
                    await controller.pickFile();
                    if (controller.selectedFilePath != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File selected: ${controller.selectedFilePath!.split('/').last}. Type your description and press Send.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}