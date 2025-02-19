import 'dart:collection';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';

class MemoryOptimizer {
  // Maksimalan broj poruka u memoriji po konverzaciji
  static const int maxMessagesPerConversation = 100;
  
  // Maksimalan broj konverzacija u memoriji
  static const int maxConversationsInMemory = 20;
  
  // LRU cache za konverzacije
  static final LinkedHashMap<String, List<Message>> _messageCache = 
    LinkedHashMap<String, List<Message>>();
  
  // LRU cache za konverzacije
  static final LinkedHashMap<String, Conversation> _conversationCache = 
    LinkedHashMap<String, Conversation>();

  /// Optimizuje listu poruka za konverzaciju
  static List<Message> optimizeMessageList(
    String conversationId,
    List<Message> messages,
  ) {
    // Sortiraj poruke po vremenu (najnovije prve)
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ograniči broj poruka
    if (sortedMessages.length > maxMessagesPerConversation) {
      sortedMessages.removeRange(
        maxMessagesPerConversation,
        sortedMessages.length,
      );
    }

    // Ažuriraj cache
    _messageCache[conversationId] = sortedMessages;
    
    // Održavaj veličinu cache-a
    if (_messageCache.length > maxConversationsInMemory) {
      _messageCache.remove(_messageCache.keys.first);
    }

    return sortedMessages;
  }

  /// Optimizuje listu konverzacija
  static List<Conversation> optimizeConversationList(
    List<Conversation> conversations,
  ) {
    // Sortiraj konverzacije po poslednjoj aktivnosti
    final sortedConversations = List<Conversation>.from(conversations)
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    // Ograniči broj konverzacija u memoriji
    if (sortedConversations.length > maxConversationsInMemory) {
      sortedConversations.removeRange(
        maxConversationsInMemory,
        sortedConversations.length,
      );
    }

    // Ažuriraj cache
    for (final conversation in sortedConversations) {
      _conversationCache[conversation.id] = conversation;
    }

    // Održavaj veličinu cache-a
    while (_conversationCache.length > maxConversationsInMemory) {
      _conversationCache.remove(_conversationCache.keys.first);
    }

    return sortedConversations;
  }

  /// Optimizuje attachment-e u poruci
  static Message optimizeMessageAttachments(Message message) {
    if (message.type != MessageType.image && 
        message.type != MessageType.file) {
      return message;
    }

    final optimizedContent = Map<String, dynamic>.from(message.content);

    // Optimizuj veličinu slika/fajlova
    if (message.type == MessageType.image) {
      optimizedContent['quality'] = 0.8; // Kompresuj slike na 80% kvaliteta
      optimizedContent['maxWidth'] = 1024; // Ograniči maksimalnu širinu
      optimizedContent['maxHeight'] = 1024; // Ograniči maksimalnu visinu
    }

    // Ograniči veličinu fajlova
    if (message.type == MessageType.file) {
      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if ((optimizedContent['size'] as int) > maxFileSize) {
        throw Exception('Fajl je prevelik. Maksimalna veličina je 5MB.');
      }
    }

    return message.copyWith(content: optimizedContent);
  }

  /// Vraća cached poruke za konverzaciju
  static List<Message>? getCachedMessages(String conversationId) {
    return _messageCache[conversationId];
  }

  /// Vraća cached konverzaciju
  static Conversation? getCachedConversation(String conversationId) {
    return _conversationCache[conversationId];
  }

  /// Invalidira cache za konverzaciju
  static void invalidateConversationCache(String conversationId) {
    _messageCache.remove(conversationId);
    _conversationCache.remove(conversationId);
  }

  /// Čisti sve cache-ove
  static void clearCaches() {
    _messageCache.clear();
    _conversationCache.clear();
  }

  /// Optimizuje korišćenje memorije za velike liste
  static List<T> optimizeLargeList<T>(
    List<T> items,
    int maxItems,
    int Function(T a, T b) compareFunction,
  ) {
    final sortedItems = List<T>.from(items)
      ..sort(compareFunction);

    if (sortedItems.length > maxItems) {
      sortedItems.removeRange(maxItems, sortedItems.length);
    }

    return sortedItems;
  }

  /// Procenjuje veličinu objekta u memoriji
  static int estimateObjectSize(Object obj) {
    if (obj is String) {
      return obj.length * 2; // UTF-16 encoding
    }
    
    if (obj is List) {
      return obj.fold<int>(
        0,
        (sum, item) => sum + estimateObjectSize(item),
      );
    }
    
    if (obj is Map) {
      return obj.entries.fold<int>(
        0,
        (sum, entry) => 
          sum + 
          estimateObjectSize(entry.key) + 
          estimateObjectSize(entry.value),
      );
    }

    // Default size za ostale tipove
    return 8;
  }
} 