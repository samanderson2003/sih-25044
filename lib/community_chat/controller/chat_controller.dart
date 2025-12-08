import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../model/chat_message.dart';
import 'package:path_provider/path_provider.dart'; 

class ChatController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  String? _selectedImagePath;
  String? _selectedFilePath;
  String? _simulatedVoicePath; // Private field for simulated recording

  final TextEditingController messageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  
  // Timer for duration update
  Timer? _recordingTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isRecording => _isRecording; 
  
  String? get selectedImagePath => _selectedImagePath;
  String? get selectedFilePath => _selectedFilePath;
  
  // FIX: Public getter for the private simulated voice path field
  String? get simulatedVoicePath => _simulatedVoicePath;
  
  String? get recordingDuration {
    if (_isRecording && _recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!);
      return '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return null;
  }

  Future<void> _writeSilenceWav(String path, int seconds,
      {int sampleRate = 16000, int bitsPerSample = 16, int channels = 1}) async {
    final numSamples = sampleRate * seconds;
    final bytesPerSample = (bitsPerSample / 8).toInt();
    final dataByteLength = numSamples * channels * bytesPerSample;

    final header = BytesBuilder();

    void writeString(String s) => header.add(s.codeUnits);
    void writeIntLE(int value, int byteCount) {
      final b = List<int>.generate(byteCount, (i) => (value >> (8 * i)) & 0xFF);
      header.add(b);
    }

    // RIFF header
    writeString('RIFF');
    writeIntLE(36 + dataByteLength, 4); // file size - 8
    writeString('WAVE');

    // fmt chunk
    writeString('fmt ');
    writeIntLE(16, 4); // PCM
    writeIntLE(1, 2); // audio format = 1 (PCM)
    writeIntLE(channels, 2);
    writeIntLE(sampleRate, 4);
    final byteRate = sampleRate * channels * bytesPerSample;
    writeIntLE(byteRate, 4);
    final blockAlign = channels * bytesPerSample;
    writeIntLE(blockAlign, 2);
    writeIntLE(bitsPerSample, 2);

    // data chunk
    writeString('data');
    writeIntLE(dataByteLength, 4);

    // PCM data (silence)
    final data = Uint8List(dataByteLength);
    // For 16-bit PCM, silence is 0x00 0x00 per sample; data already zeroed.

    final fileBytes = <int>[];
    fileBytes.addAll(header.toBytes());
    fileBytes.addAll(data);

    final f = File(path);
    await f.writeAsBytes(fileBytes, flush: true);
  }
  
  ChatController() {
    // Initialize controller
  }

  // --- Utility Methods for Error and Media ---

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImagePath = null;
    notifyListeners();
  }
  
  void clearSelectedFile() {
    _selectedFilePath = null;
    notifyListeners();
  }
  
  void clearAllAttachments() {
    _selectedImagePath = null;
    _selectedFilePath = null;
    _simulatedVoicePath = null;
    messageController.clear();
    notifyListeners();
  }

  // Stream of messages from Firestore
  Stream<List<ChatMessage>> get messagesStream {
    return _firestore
        .collection('community_chat')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }
  
  Future<void> _uploadMedia(String filePath, String fileType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final file = File(filePath);
    if (!await file.exists()) {
        _errorMessage = 'File not found at path: $filePath';
        notifyListeners();
        clearAllAttachments();
        return;
    }

    final storageDir = fileType == 'image' ? 'chat_images' : (fileType == 'voice' ? 'chat_voices' : 'chat_files');
    final fileExtension = filePath.split('.').last;
    final fileName = '$storageDir/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${fileType}.${fileExtension}';
    final storageRef = _storage.ref().child(fileName);

    _isLoading = true;
    notifyListeners();
    
    String? downloadUrl;
    try {
      await storageRef.putFile(file); 
      downloadUrl = await storageRef.getDownloadURL();
      
      clearAllAttachments();
      
      await _sendMessage(imageUrl: downloadUrl, isVoice: fileType == 'voice');
    } on FirebaseException catch (e) {
      print('Firebase Upload Error: ${e.code} - ${e.message}');
      _errorMessage = 'Failed to upload $fileType: Please check storage rules or try again.';
    } catch (e) {
      print('General Upload Error: $e');
      _errorMessage = 'An unexpected error occurred during $fileType upload.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendMessage({String? imageUrl, String? fileUrl, bool isVoice = false}) async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty && imageUrl == null && fileUrl == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to chat.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final displayName = user.displayName ?? 'Anonymous';
      
      String textContent = messageText;
      if (isVoice) {
        textContent = messageText.isEmpty ? 'Voice Message 🎤' : messageText;
      }

      final message = ChatMessage(
        id: '', 
        text: textContent,
        senderId: user.uid,
        senderName: displayName,
        timestamp: DateTime.now(),
        imageUrl: imageUrl ?? fileUrl,
      );

      await _firestore.collection('community_chat').add(message.toMap());
      messageController.clear();
      clearAllAttachments();
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage() async {
    if (_simulatedVoicePath != null) {
      await _uploadMedia(_simulatedVoicePath!, 'voice');
    } else if (_selectedImagePath != null) {
      await _uploadMedia(_selectedImagePath!, 'image');
    } else if (_selectedFilePath != null) {
      await _uploadMedia(_selectedFilePath!, 'file');
    } else {
      await _sendMessage();
    }
  }

  Future<void> deleteMessage(ChatMessage message) async {
    if (message.senderId != currentUserId) {
      _errorMessage = 'You can only delete your own messages.';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
        final storageRef = _storage.refFromURL(message.imageUrl!);
        await storageRef.delete().catchError((e) {
            print('Warning: Failed to delete file from storage: $e');
        });
      }
      
      await _firestore.collection('community_chat').doc(message.id).delete();
      
      _errorMessage = 'Message deleted for everyone.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Media Attachment Logic ---

  Future<void> pickMedia(ImageSource source) async {
    final XFile? media = await _picker.pickImage(source: source);
    if (media != null) {
      clearAllAttachments();
      _selectedImagePath = media.path;
      notifyListeners();
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        clearAllAttachments();
        _selectedFilePath = result.files.single.path;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error picking file: $e';
      notifyListeners();
    }
  }
  
  // --- Voice Recording Logic (Integrated Stop/Send) ---
  
  Future<void> toggleRecording() async {
    if (_isRecording) {
      // --- STOP RECORDING / SAVE FILE (Simulated) ---
      _isRecording = false;
      _recordingTimer?.cancel();
      
      // Simulate saving an audio file (e.g., .m4a)
      final tempDir = await getTemporaryDirectory();
      final durationSecs = DateTime.now().difference(_recordingStartTime!).inSeconds;
      final safeDuration = durationSecs > 0 ? durationSecs : 1;
      _simulatedVoicePath = '${tempDir.path}/recorded_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Create a small silent WAV file matching the recorded duration so players can play it.
      await _writeSilenceWav(_simulatedVoicePath!, safeDuration);
      
      final durationText = recordingDuration ?? '00:00';
      _errorMessage = 'Recording stopped ($durationText). Press SEND to upload!';
      
      // Clear other attachments but keep the simulated voice path
      _selectedImagePath = null;
      _selectedFilePath = null;
      
      messageController.text = ''; // Clear input text for a clean send
      
      notifyListeners();

    } else {
      // --- START RECORDING ---
      try {
        final micStatus = await Permission.microphone.request();
        if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
          _errorMessage = 'Microphone permission denied.';
          notifyListeners();
          return;
        }

        // Reset all attachments
        clearAllAttachments(); 

        // Start recording state and timer
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
           if (isRecording) {
             // Update the visible recording text each second so UI shows live seconds
             final dur = recordingDuration ?? '00:00';
             messageController.text = 'Recording $dur';
             notifyListeners(); // Force UI update for duration
           } else {
             timer.cancel();
           }
        });

        messageController.text = 'Recording 00:00';
        _errorMessage = 'Recording started... Tap again to stop.';
        notifyListeners();

        // Optional: Auto-stop simulation after a long time
        await Future.delayed(const Duration(minutes: 5)); 
        if (_isRecording) {
           await toggleRecording(); // Automatically stop
        }

      } catch (e) {
        _errorMessage = 'Failed to start recording: $e';
        _isRecording = false;
        _recordingTimer?.cancel();
        notifyListeners();
      }
    }
  }

  bool isMyMessage(String senderId) {
    return senderId == currentUserId;
  }
  
  Future<Map<String, String>> fetchUserInfo(String userId) async {
    if (userId == currentUserId) {
      return {
        'Name': currentUser?.displayName ?? 'You (My Profile)',
        'Role': 'Farmer',
        'Location': 'Unknown (Click to set)',
      };
    } else {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
           return {
            'Name': doc.data()?['displayName'] ?? 'Another Farmer',
            'Role': doc.data()?['role'] ?? 'Farmer',
            'Location': doc.data()?['location'] ?? 'India',
          };
        }
      } catch (_) {
        // Fallback
      }
      
      return {
        'Name': 'Another Farmer',
        'Role': 'Farmer',
        'Location': 'India',
      };
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    messageController.dispose();
    super.dispose();
  }
}