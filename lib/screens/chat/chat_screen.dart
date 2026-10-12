import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/message_bubble.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botanical_background.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

class ChatScreen extends StatefulWidget {
  final bool autoListen;
  const ChatScreen({super.key, this.autoListen = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> messages = [];

  bool isTyping = false;
  final ChatService chatService = ChatService();
  
  // Voice and Speech
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speech = stt.SpeechToText();
    _initTts();
    
    // Use addPostFrameCallback to access context safely for initial message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = Provider.of<LanguageService>(context, listen: false);
      setState(() {
        messages.add(
          Message(
            text: lang.translate('welcome_bot'),
            isUser: false,
            time: DateTime.now(),
          ),
        );
      });
    });

    if (widget.autoListen) {
      Future.delayed(const Duration(milliseconds: 1000), () => _listen());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update welcome message if it's the only message when language changes
    if (messages.length == 1 && !messages[0].isUser) {
      final lang = Provider.of<LanguageService>(context);
      messages[0] = Message(
        text: lang.translate('welcome_bot'),
        isUser: false,
        time: messages[0].time,
      );
    }
  }

  void _initTts() async {
    try {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );
      _isTtsInitialized = true;
    } catch (e) {
      print("TTS Init Error: $e");
    }
  }

  Future<void> _speak(String text) async {
    final langService = Provider.of<LanguageService>(context, listen: false);

    String cleanText = text.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    String languageCode = 'en-US';
    if (langService.currentLanguage == AppLanguage.urdu) {
      languageCode = 'ur-PK';
    } else if (langService.currentLanguage == AppLanguage.punjabi) {
      languageCode = 'ur-PK';
    }

    try {
      await _flutterTts.stop();

      await _flutterTts.setLanguage(languageCode);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);

      // Wait until each sentence finishes before speaking the next
      await _flutterTts.awaitSpeakCompletion(true);

      // Split long text into sentences
      List<String> sentences =
      cleanText.split(RegExp(r'(?<=[.!?])\s+'));

      for (String sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          print("Speaking: $sentence");
          await _flutterTts.speak(sentence.trim());
        }
      }
    } catch (e) {
      print("TTS Error: $e");
    }
  }
  void _listen() async {
    if (!_isListening) {
      final langService = Provider.of<LanguageService>(context, listen: false);

      String localeId = 'en-US';

      if (langService.currentLanguage == AppLanguage.urdu) {
        localeId = 'ur-PK';
      } else if (langService.currentLanguage == AppLanguage.punjabi) {
        localeId = 'ur-PK'; // Use Urdu recognition
      }

      try {
        bool available = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (val) {
            setState(() => _isListening = false);
            print("Speech Init Error: ${val.errorMsg}");
          },
        );
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            localeId: localeId, // This forces the phone to use the correct script
            onResult: (val) => setState(() {
              _controller.text = val.recognizedWords;
            }),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mic not available - Check permissions")),
            );
          }
        }
      } catch (e) {
        print("Speech Exception: $e");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flutterTts.stop();
      _speech.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(
        Message(
          text: text,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      isTyping = true;
    });

    _controller.clear();
    scrollToBottom();

    try {
      final langService = Provider.of<LanguageService>(context, listen: false);

      String langCode = 'en';

      if (langService.currentLanguage == AppLanguage.urdu) {
        langCode = 'ur';
      } else if (langService.currentLanguage == AppLanguage.punjabi) {
        langCode = 'pa';
      }

      String reply = await chatService.sendMessage(text, langCode);
      setState(() {
        messages.add(
          Message(
            text: reply,
            isUser: false,
            time: DateTime.now(),
          ),
        );
        isTyping = false;
      });
    } catch (e) {
      setState(() {
        messages.add(
          Message(
            text: "Failed to connect to the assistant. Please try again.",
            isUser: false,
            time: DateTime.now(),
          ),
        );
        isTyping = false;
      });
    }

    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBotanicalGreen : theme.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.secondary,
              child: Icon(Icons.eco, color: theme.colorScheme.onSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Wheat AI",
                  style: TextStyle(fontSize: 18, color: isDark ? AppTheme.goldAccent : Colors.white),
                ),
                Text(
                  isTyping ? "Typing..." : "Online",
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.sageGreen : Colors.white70),
                )
              ],
            )
          ],
        ),
      ),
      body: BotanicalBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(
                    message: messages[index],
                    onSpeak: () => _speak(messages[index].text),
                  );
                },
              ),
            ),
            if (isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text("Assistant is thinking...", style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            _buildInputSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final langService = Provider.of<LanguageService>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBotanicalGreen.withOpacity(0.95) : theme.cardColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language Quick Toggle Row
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _langChip("EN", AppLanguage.english, langService),
                const SizedBox(width: 8),
                _langChip("اردو", AppLanguage.urdu, langService),
                const SizedBox(width: 8),
                _langChip(langService.translate('lang_punjabi'), AppLanguage.punjabi, langService),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _listen,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent : (isDark ? AppTheme.cardColor : theme.scaffoldBackgroundColor),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: langService.translate('ask_about_wheat'),
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? AppTheme.cardColor : theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, AppLanguage lang, LanguageService service) {
    final theme = Theme.of(context);
    bool isSelected = service.currentLanguage == lang;
    return GestureDetector(
      onTap: () => service.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : (theme.dividerColor)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodySmall?.color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
