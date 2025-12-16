import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  String _recognizedText = '';
  String? _selectedImagePath;
  static const String _apiKey =
      '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';

  static const String _systemPrompt = '''
You are FarmBot, an intelligent agricultural assistant designed to help Indian farmers. 
You provide advice on:
- Crop selection and rotation
- Pest and disease management
- Fertilizer recommendations
- Irrigation techniques
- Weather-related farming decisions
- Government schemes for farmers
- Market prices and selling strategies
- Organic farming practices

Always be helpful, concise, and provide practical advice suitable for Indian farming conditions.
Respond in a friendly manner and use simple language. If asked in Hindi or other regional languages, respond in the same language.
''';

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeechToText();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            'Namaste! 🙏 I am FarmBot, your agricultural assistant. How can I help you today?\n\nनमस्ते! मैं FarmBot हूं, आपका कृषि सहायक। आज मैं आपकी कैसे मदद कर सकता हूं?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _initializeSpeechToText() async {
    bool available = await _speechToText.initialize(
      onError: (error) {
        print('Speech to text error: $error');
      },
      onStatus: (status) {
        print('Speech to text status: $status');
      },
    );
    if (available) {
      print('Speech to text initialized successfully');
    } else {
      print('Speech to text not available on this device');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final String? currentImagePath = _selectedImagePath;
    final bool isImageMessage = currentImagePath != null;

    if (message.isEmpty && !isImageMessage) return;

    // API Key Check
    if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE' || _apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: OpenAI API Key is missing. Please update _apiKey in bot_screen.dart.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      // Fallback response for missing key
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'I cannot process images or send messages to the AI because the OpenAI API Key is missing or invalid. Please configure the key in the code.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
        _selectedImagePath = null;
      });
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    // Determine the text to show in the bubble
    String messageText = message;
    if (message.isEmpty && isImageMessage) {
      messageText = 'Image attached. Please analyze this.';
    } else if (isImageMessage) {
      // Show user's query and note the image attachment
      messageText =
          'Image attached: ${currentImagePath!.split('/').last}\nQuery: "$message"';
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: messageText,
          isUser: true,
          timestamp: DateTime.now(),
          isImage: isImageMessage,
          imagePath: currentImagePath,
        ),
      );
      _isLoading = true;
      _messageController.clear();
      _selectedImagePath =
          null; // Clear the temporary path after adding to messages
    });

    _scrollToBottom();

    try {
      String response;
      if (isImageMessage && currentImagePath != null) {
        // Send message with image analysis request
        response = await _sendImageToAPI(currentImagePath, message);
      } else {
        // Send text-only message
        response = await _getAIResponse(message);
      }

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Send message error: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I encountered an error. Please try again. Error details: ${e.toString()}\n\nक्षमा करें, कुछ त्रुटि हुई। कृपया पुनः प्रयास करें।',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      if (_recognizedText.isNotEmpty) {
        // If image is attached, append voice to the current text
        if (_selectedImagePath != null) {
          // Append the recognized text to whatever the user has typed
          _messageController.text =
              _messageController.text.trim() + ' ' + _recognizedText;
        } else {
          _messageController.text = _recognizedText;
        }
      }
    } else {
      try {
        // Check and request microphone permission again
        var micStatus = await Permission.microphone.status;
        if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
          micStatus = await Permission.microphone.request();
          if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Microphone permission required. Please enable it in settings.',
                ),
              ),
            );
            return;
          }
        }

        bool available = await _speechToText.initialize(
          onError: (error) {
            print('Speech error: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech to text error: $error')),
            );
          },
          onStatus: (status) {
            print('Speech status: $status');
          },
        );

        if (available && _speechToText.isNotListening) {
          setState(() {
            _isListening = true;
            _recognizedText = '';
            // Do not clear the text field if an image is attached, only clear if starting fresh
            if (_selectedImagePath == null) {
              _messageController.text = '';
            }
          });

          _speechToText.listen(
            onResult: (result) {
              setState(() {
                _recognizedText = result.recognizedWords;
                // Update text field with current recognized speech
                _messageController.text = _recognizedText;
              });
            },
            localeId: 'en_IN',
          );
        } else if (!available) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
            ),
          );
        }
      } catch (e) {
        print('Voice listening error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Voice input error: $e')));
      }
    }
  }

  Future<void> _attachMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            color: const Color(0xFFF8F6F0),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF2D5016),
                  ),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      _handleMediaSelection(image.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: Color(0xFF2D5016)),
                  title: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      _handleMediaSelection(image.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.file_present,
                    color: Color(0xFF2D5016),
                  ),
                  title: const Text('File'),
                  onTap: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File picker feature coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMediaSelection(String filePath) {
    // FIX: Removed pre-filled text. User must type their query.
    setState(() {
      _selectedImagePath = filePath;
      // Clear message controller content, but keep hint text
      _messageController.text = '';
      _recognizedText = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Image selected: ${filePath.split('/').last}. Type your query and press Send.',
        ),
      ),
    );
  }

  Future<String> _sendImageToAPI(String imagePath, String userText) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final fileName = imagePath.split('/').last;

      String imageMediaType = 'image/jpeg';
      if (fileName.endsWith('.png')) imageMediaType = 'image/png';
      if (fileName.endsWith('.webp')) imageMediaType = 'image/webp';

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final List<Map<String, dynamic>> userContent = [
        {
          'type': 'image_url',
          'image_url': {'url': 'data:$imageMediaType;base64,$base64Image'},
        },
      ];

      // Determine the text prompt to send alongside the image
      String apiText = userText.trim();
      if (apiText.isEmpty) {
        apiText =
            'Please analyze this farming-related image and provide advice based on the system prompt.';
      }

      userContent.add({'type': 'text', 'text': apiText});

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userContent},
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        print('Vision API Error: ${response.statusCode} - ${response.body}');

        // Fallback to text model if vision model not available
        return await _getAIResponse(
          'User sent an image with query: $userText. Please ask them to describe what they see in the image and provide farming-related advice.',
        );
      }
    } catch (e) {
      print('Error sending image to API: $e');
      // Fallback: send text message instead
      return await _getAIResponse(
        'User sent an image with query: $userText. Please ask them to describe what they see in the image and provide farming-related advice.',
      );
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Create conversation history for context, excluding image messages to prevent API errors
    final List<Map<String, dynamic>> contextMessages = _messages
        .where((msg) => !msg.isImage)
        .map(
          (msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          },
        )
        .toList();

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...contextMessages,
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
        'max_tokens': 500,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('Failed to get response: ${response.statusCode}');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Lottie.asset(
                  'assets/Green Robot.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FarmBot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Agricultural Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text:
                        'Namaste! 🙏 I am FarmBot, your agricultural assistant. How can I help you today?\n\nनमस्ते! मैं FarmBot हूं, आपका कृषि सहायक। आज मैं आपकी कैसे मदद कर सकता हूं?',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
                _selectedImagePath = null;
                _messageController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Quick Suggestions
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('Best crops for Kharif season?'),
                  _buildSuggestionChip('How to control pests naturally?'),
                  _buildSuggestionChip('Fertilizer for rice crop'),
                  _buildSuggestionChip('Government schemes for farmers'),
                ],
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Plus icon for media attachment
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D5016),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _isLoading ? null : _attachMedia,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6F0),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF2D5016).withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _selectedImagePath != null
                              ? 'Image attached. Type your query...'
                              : 'Ask about farming...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          // Display selected image path visually in the input
                          prefixIcon: _selectedImagePath != null
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Icon(
                                    Icons.photo_library,
                                    color: Color(0xFF2D5016).withOpacity(0.7),
                                  ),
                                )
                              : null,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Microphone icon for voice input
                  Container(
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.red.withOpacity(0.7)
                          : const Color(0xFF2D5016),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _toggleListening,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2D5016),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Lottie.asset(
                    'assets/Green Robot.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFF2D5016)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display image if attached
                    if (message.isImage && message.imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(message.imagePath!),
                            width: 150, // Constrain image size
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Lottie.asset(
                  'assets/Green Robot.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(150),
                  const SizedBox(width: 4),
                  _buildDot(300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016).withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D5016).withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF2D5016),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isImage;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isImage = false,
    this.imagePath,
  });
}
