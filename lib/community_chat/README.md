# Community Chat Feature

## Overview
The Community Chat feature enables farmers to communicate with each other in real-time, share experiences, ask questions, and build connections within the agricultural community.

## Architecture

### MVC Structure
```
lib/community_chat/
├── model/
│   └── chat_message.dart        # ChatMessage data model
├── controller/
│   └── chat_controller.dart     # Chat state management & business logic
└── view/
    └── community_chat_screen.dart # UI components
```

## Features

### ✅ Real-time Messaging
- Send and receive messages instantly
- Messages stored in Firebase Firestore
- Auto-scroll to latest messages
- Timestamp for each message

### ✅ User Identification
- Displays sender name from Firebase Auth
- Different bubble styles for own vs. other messages
- Color-coded message bubbles (green for you, white for others)

### ✅ Professional UI
- Clean, modern design matching app theme
- Message bubbles with rounded corners
- Smooth animations and transitions
- Empty state with helpful message
- Loading indicators

### ✅ Smart Features
- Send on keyboard submit
- Character trimming (no empty messages)
- Error handling and user feedback
- Community guidelines dialog

## Components

### 1. Model: ChatMessage
**File**: `model/chat_message.dart`

```dart
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime? timestamp;
  final String? imageUrl;
  final List<String> reactions;
}
```

**Features**:
- Firestore integration with `fromFirestore()` factory
- Conversion to map with `toMap()`
- Copyable with `copyWith()`
- Support for future features (images, reactions)

### 2. Controller: ChatController
**File**: `controller/chat_controller.dart`

**Responsibilities**:
- Message streaming from Firestore
- Sending messages
- User authentication state
- Loading states
- Error handling

**Key Methods**:
- `messagesStream` - Real-time message updates
- `sendMessage()` - Send new message
- `deleteMessage()` - Delete a message (future use)
- `addReaction()` - Add reactions (future use)
- `isMyMessage()` - Check if message is from current user

### 3. View: CommunityChatScreen
**File**: `view/community_chat_screen.dart`

**UI Components**:
- **AppBar**: Title, back button, info button
- **Message List**: StreamBuilder with real-time updates
- **Message Bubbles**: Custom styled containers
- **Input Field**: TextField with send button
- **Empty State**: Friendly message when no chats

## Integration

### Access Points
1. **From AgriConnect Map**:
   - Tap "Community" button in top-left
   - Opens full-screen chat

2. **Future Navigation**:
   - Can be added to bottom nav bar
   - Can be accessed from profile
   - Can be linked from notifications

### Current Implementation
```dart
// In connections_screen.dart
_buildTopNavButton(
  icon: Icons.chat_bubble,
  label: 'Community',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityChatScreen(),
      ),
    );
  },
)
```

## Firebase Setup

### Firestore Collection Structure
```
community_chat/
  └── {messageId}/
      ├── text: string
      ├── senderId: string
      ├── senderName: string
      ├── timestamp: timestamp
      ├── imageUrl: string (optional)
      └── reactions: array (optional)
```

### Security Rules (Recommended)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /community_chat/{messageId} {
      // Anyone can read messages
      allow read: if request.auth != null;
      
      // Only authenticated users can create messages
      allow create: if request.auth != null 
                    && request.resource.data.senderId == request.auth.uid;
      
      // Users can only delete their own messages
      allow delete: if request.auth != null 
                    && resource.data.senderId == request.auth.uid;
      
      // Users can only update their own messages
      allow update: if request.auth != null 
                    && resource.data.senderId == request.auth.uid;
    }
  }
}
```

## Usage

### Sending a Message
1. Type message in input field
2. Press send button or hit enter
3. Message appears instantly for all users

### Viewing Messages
- Messages load automatically in reverse chronological order
- Scroll to view older messages
- Your messages appear on the right (green)
- Other messages appear on the left (white)

### Community Guidelines
- Tap the info icon in top-right
- View chat guidelines and best practices

## Design Specifications

### Colors
- **Primary Green**: `#2D5016`
- **Background Cream**: `#F8F6F0`
- **Your Messages**: Green (`#2D5016`)
- **Other Messages**: White
- **Text**: Black/White (based on background)

### Typography
- **Sender Name**: 12px, bold
- **Message Text**: 16px, regular
- **Timestamp**: 10px, light

### Spacing
- Message padding: 16px horizontal, 10px vertical
- Message margin: 4px vertical
- Input padding: 8px all around

## State Management

Using **Provider** for state management:
- `ChangeNotifierProvider` wraps the screen
- `ChatController` extends `ChangeNotifier`
- `Consumer<ChatController>` for reactive updates
- Automatic UI updates on state changes

## Error Handling

### User Feedback
- Loading indicator while sending
- Error messages via SnackBar
- Empty state when no messages
- Connection error state

### Validation
- Empty message prevention
- Authentication check before sending
- Firestore error catching

## Future Enhancements

### Planned Features
1. **Image Sharing**
   - Upload and share crop photos
   - Disease/pest identification help
   - Farm progress documentation

2. **Reactions**
   - Like messages
   - Emoji reactions
   - Helpful/Not helpful feedback

3. **Sub-communities**
   - District-based groups
   - Crop-specific channels
   - Language preferences

4. **Search & Filter**
   - Search message history
   - Filter by user
   - Date range filtering

5. **Notifications**
   - Push notifications for new messages
   - @mentions support
   - Mute/unmute options

6. **Rich Features**
   - Reply to specific messages
   - Edit sent messages
   - Delete messages
   - Report inappropriate content

7. **Voice Messages**
   - Record and send voice notes
   - Useful for farmers with limited literacy

8. **Translation**
   - Auto-translate messages
   - Multi-language support

## Testing

### Manual Testing Checklist
- [ ] Send message successfully
- [ ] Receive messages in real-time
- [ ] Empty state displays correctly
- [ ] Loading state shows while fetching
- [ ] Error handling works
- [ ] Back button navigation
- [ ] Message ordering (newest first)
- [ ] Timestamp formatting
- [ ] User identification (you vs others)
- [ ] Guidelines dialog opens

### Firebase Testing
- [ ] Messages saved to Firestore
- [ ] Timestamp generated server-side
- [ ] User data correctly associated
- [ ] Real-time updates working
- [ ] Multiple users can chat

## Dependencies

Already included in `pubspec.yaml`:
```yaml
cloud_firestore: ^5.6.0  # Real-time database
firebase_auth: ^5.4.1     # User authentication
provider: ^6.1.2          # State management
intl: ^0.19.0            # Date formatting
```

## Permissions

No additional permissions required beyond existing:
- ✅ INTERNET (already configured)
- ✅ Firebase initialized (already done)

## Troubleshooting

### Messages not appearing?
- Check internet connection
- Verify Firebase configuration
- Check Firestore security rules
- Ensure user is authenticated

### Can't send messages?
- Verify user is logged in
- Check Firestore write permissions
- Look for console errors
- Verify Firebase project setup

### Timestamp not showing?
- Check device time settings
- Verify Firestore timestamp field
- Check date formatting code

## Best Practices

### For Users
- Be respectful and helpful
- Share relevant farming information
- Ask clear questions
- Provide constructive feedback

### For Developers
- Always check authentication state
- Handle Firestore errors gracefully
- Validate input before sending
- Use proper state management
- Follow MVC architecture
- Keep UI responsive

## Performance

### Optimization
- Messages query limited to recent items (can add pagination)
- Reverse chronological order (newest first)
- Efficient StreamBuilder usage
- Minimal rebuilds with Consumer

### Scalability
- Can handle thousands of messages
- Firestore auto-scaling
- Efficient indexing
- Can add pagination for older messages
