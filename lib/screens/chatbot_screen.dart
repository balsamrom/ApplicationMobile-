import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/models/owner.dart';
import 'package:pet_owner_app/models/pet.dart';

class ChatbotScreen extends StatefulWidget {
  final Owner owner;
  const ChatbotScreen({super.key, required this.owner});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _gemini = Gemini.instance;
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  Pet? _selectedPet;
  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    _pets = await DatabaseHelper.instance.getPetsByOwner(widget.owner.id!);
    if (_pets.length == 1) {
      setState(() {
        _selectedPet = _pets.first;
        _addBotMessage('Bonjour ! Je suis prêt à répondre à vos questions sur ${_selectedPet!.name}.');
      });
    } else if (_pets.isNotEmpty) {
      _addBotMessage('Bonjour ! Pour quel animal souhaitez-vous des informations ?');
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _chatHistory.add({'role': 'model', 'text': text});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: const Text(
          'Assistant PetCare',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_pets.isNotEmpty && _selectedPet == null)
            _buildPetSelection(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildPetSelection() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(pet.name),
              selected: _selectedPet == pet,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPet = pet;
                    _addBotMessage('J\'ai sélectionné ${pet.name}. Que puis-je pour vous ?');
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Posez une question...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }

  Future<String> _getPetDataSummary(Pet pet) async {
    final nutritionLogs = await DatabaseHelper.instance.getNutritionLogsForPet(pet.id!);
    final activityLogs = await DatabaseHelper.instance.getActivityLogsForPet(pet.id!);

    final nutritionSummary = nutritionLogs.isNotEmpty
        ? 'Dernier repas: ${nutritionLogs.first.foodType} (${nutritionLogs.first.quantity} ${nutritionLogs.first.unit}).'
        : 'Aucune donnée de nutrition.';

    final activitySummary = activityLogs.isNotEmpty
        ? 'Dernière activité: ${activityLogs.first.activityType} (${activityLogs.first.durationInMinutes} min).'
        : 'Aucune donnée d\'activité.';

    return 'Voici un résumé pour ${pet.name}:\n- $nutritionSummary\n- $activitySummary';
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _controller.clear();

    String contextText = '';
    if (_selectedPet != null) {
      if (text.toLowerCase().contains('nutrition') || text.toLowerCase().contains('activité')) {
        contextText = await _getPetDataSummary(_selectedPet!);
        _addBotMessage(contextText);
        setState(() => _isLoading = false);
        return;
      }
    }

    _gemini.streamGenerateContent(text).listen(
      (response) {
        final modelResponse = response.output ?? 'Désolé, je n\'ai pas pu répondre.';
        _addBotMessage(modelResponse);
        setState(() => _isLoading = false);
      },
      onError: (error) {
        _addBotMessage('Erreur: $error');
        setState(() => _isLoading = false);
      },
    );
  }
}
