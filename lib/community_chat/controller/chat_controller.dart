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
import 'package:record/record.dart'; 

class ChatController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  String? _selectedImagePath;
  String? _selectedFilePath;
  String? _simulatedVoicePath; // Private field for simulated recording

  final TextEditingController messageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _debugStatus = ''; // For UI feedback on hang location
  
  // Timer for duration update
  Timer? _recordingTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get debugStatus => _debugStatus; // Getter for UI
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

  // Removed _writeSilenceWav as we now record real audio
  
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

    print('DEBUG: Starting upload for $fileType...');
    _isLoading = true;
    _debugStatus = 'Starting upload for $fileType...';
    notifyListeners();
    
    String? downloadUrl;
    try {
      debugPrint('DEBUG: putting file to storage: $fileName');
      _debugStatus = 'Uploading to Storage (putFile)...';
      notifyListeners();
      
      // Added timeout
      await storageRef.putFile(file).timeout(const Duration(seconds: 15)); 
      
      debugPrint('DEBUG: Upload complete. Getting download URL...');
      _debugStatus = 'Getting Download URL...';
      notifyListeners();
      
      downloadUrl = await storageRef.getDownloadURL().timeout(const Duration(seconds: 15));
      debugPrint('DEBUG: Download URL: $downloadUrl');
      
      clearAllAttachments();
      
      await _sendMessage(imageUrl: downloadUrl, isVoice: fileType == 'voice');
    } on TimeoutException catch (_) {
      _errorMessage = 'Upload timed out. Check internet connection.';
      _debugStatus = 'Timeout Error';
      debugPrint('DEBUG: Upload Timeout');
    } on FirebaseException catch (e) {
      debugPrint('Firebase Upload Error: ${e.code} - ${e.message}');
      _errorMessage = 'Upload failed: ${e.message} (${e.code})';
      _debugStatus = 'Upload Failed!';
    } catch (e) {
      debugPrint('General Upload Error: $e');
      _errorMessage = 'An unexpected error occurred during $fileType upload.';
      _debugStatus = 'Error: $e';
    } finally {
      debugPrint('DEBUG: Upload finally block reached. resetting isLoading.');
      _isLoading = false;
      _debugStatus = '';
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
    _debugStatus = 'Preparing message...';
    notifyListeners();

    try {
      final displayName = user.displayName ?? 'Anonymous';
      print('DEBUG: Preparing message to send...');
      
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

      debugPrint('DEBUG: Adding message to Firestore collection...');
      _debugStatus = 'Saving to Firestore...';
      notifyListeners();
      
      // Added timeout
      await _firestore.collection('community_chat').add(message.toMap()).timeout(const Duration(seconds: 15));
      debugPrint('DEBUG: Message added to Firestore!');
      _debugStatus = 'Sent!';
      
      messageController.clear();
      clearAllAttachments();
    } on TimeoutException catch (_) {
       _errorMessage = 'Sending timed out. Check internet connection.';
       _debugStatus = 'Timeout Error';
       debugPrint('DEBUG: Firestore Timeout');
    } catch (e) {
      debugPrint('DEBUG: Error sending message: $e');
      _errorMessage = 'Failed to send message: $e';
      _debugStatus = 'Send Failed: $e';
    } finally {
      debugPrint('DEBUG: sendMessage finally block. Loading = false');
      _isLoading = false;
      _debugStatus = '';
      notifyListeners();
    }
  }

  Future<void> sendMessage() async {
    debugPrint('DEBUG: sendMessage called. Checking attachments...');
    debugPrint('DEBUG: Attachments state -> Voice: $_simulatedVoicePath, Image: $_selectedImagePath, File: $_selectedFilePath'); // Trace state
    
    if (_simulatedVoicePath != null) {
      debugPrint('DEBUG: Sending simulated voice: $_simulatedVoicePath');
      await _uploadMedia(_simulatedVoicePath!, 'voice');
    } else if (_selectedImagePath != null) {
       debugPrint('DEBUG: Sending image: $_selectedImagePath');
      await _uploadMedia(_selectedImagePath!, 'image');
    } else if (_selectedFilePath != null) {
      debugPrint('DEBUG: Sending file: $_selectedFilePath');
      await _uploadMedia(_selectedFilePath!, 'file');
    } else {
      debugPrint('DEBUG: Sending text message...');
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
      // --- STOP RECORDING ---
      try {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        _recordingTimer?.cancel();

        if (path != null) {
          _simulatedVoicePath = path;
          
          final durationText = recordingDuration ?? '00:00';
          _errorMessage = 'Recording stopped ($durationText). Press SEND to upload!';
          
          // Clear other attachments logic
          _selectedImagePath = null;
          _selectedFilePath = null;
          messageController.text = ''; 
          notifyListeners();
        }
      } catch (e) {
        _errorMessage = 'Failed to stop recording: $e';
        _isRecording = false;
        notifyListeners();
      }
    } else {
      // --- START RECORDING ---
      try {
        print('DEBUG: Attempting to start recording...');
        
        final hasPermission = await _audioRecorder.hasPermission();
        print('DEBUG: Permission check result: $hasPermission');

        if (hasPermission) {
          // Reset attachments
          clearAllAttachments();

          final tempDir = await getTemporaryDirectory();
          final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          print('DEBUG: Recording path: $path');

          // Start recording (v5 API)
          await _audioRecorder.start(const RecordConfig(), path: path);
          print('DEBUG: Recording started successfully via plugin');
          
          _isRecording = true;
          _recordingStartTime = DateTime.now();
          
          // Timer for UI duration
          _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
             if (isRecording) {
               final dur = recordingDuration ?? '00:00';
               messageController.text = 'Recording $dur';
               print('DEBUG: Recording tick: $dur');
               notifyListeners(); 
             } else {
               timer.cancel();
             }
          });

          messageController.text = 'Recording 00:00';
          _errorMessage = 'Recording started... Tap again to stop.';
          notifyListeners();
        } else {
          print('DEBUG: Microphone permission denied by plugin/system');
          _errorMessage = 'Microphone permission required.';
          notifyListeners();
        }
      } catch (e, stack) {
        print('DEBUG: EXCEPTION in start recording: $e');
        print('DEBUG: Stack trace: $stack');
        _errorMessage = 'Failed to start recording: $e';
        _isRecording = false;
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
    _audioRecorder.dispose();
    messageController.dispose();
    super.dispose();
  }
}