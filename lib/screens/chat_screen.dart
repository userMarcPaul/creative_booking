// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart'; // Import your ApiService

class ChatScreen extends StatefulWidget {
  final int bookingId;
  final String providerName; // This represents the "Other Person" (Client or Provider)

  const ChatScreen({
    super.key, 
    required this.bookingId, 
    required this.providerName
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer; // Timer for auto-refreshing messages

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Poll for new messages every 3 seconds (Simulates real-time connection)
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(isPolling: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // STOP the timer when screen closes to prevent memory leaks
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch messages from API
  Future<void> _loadMessages({bool isPolling = false}) async {
    // This calls the static method we added to ApiService
    final newMessages = await ApiService.fetchChatMessages(widget.bookingId);
    
    if (mounted) {
      setState(() {
        _messages = newMessages;
        if (!isPolling) _isLoading = false;
      });

      // If it's the first load (or specifically if new messages arrived), scroll to bottom
      // Logic: If not polling (initial load) OR if polling and list length grew
      if (!isPolling && newMessages.isNotEmpty) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    // Small delay to ensure the list has rendered the new items before scrolling
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

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final textToSend = _controller.text;
    _controller.clear();

    // 1. Optimistic Update: Add to UI immediately so it feels instant
    setState(() {
      _messages.add({"text": textToSend, "isMe": true});
    });
    _scrollToBottom();

    // 2. Send to Backend
    final success = await ApiService.sendChatMessage(widget.bookingId, textToSend);

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message. Check connection.")),
        );
      }
    } else {
      // If success, refresh to get the real timestamp/data from server
      _loadMessages(isPolling: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4F46E5),
              child: Text(
                widget.providerName.isNotEmpty ? widget.providerName[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName, 
                  style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                Text(
                  "Online", 
                  style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12)
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text("Say hi to ${widget.providerName}!", style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['isMe'] ?? false;
                          
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? "",
                                style: GoogleFonts.plusJakartaSans(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF4F46E5),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}