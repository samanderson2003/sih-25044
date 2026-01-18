import 'package:flutter/material.dart';
import '../../widgets/translated_text.dart';
import '../controller/cattle_controller.dart';

class AddCattleScreen extends StatefulWidget {
  const AddCattleScreen({super.key});

  @override
  State<AddCattleScreen> createState() => _AddCattleScreenState();
}

class _AddCattleScreenState extends State<AddCattleScreen> {
  final _controller = CattleController();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  String _selectedType = 'cow';
  String _selectedBreed = '';
  final TextEditingController _ageController = TextEditingController();
  bool _isSaving = false;

  final Map<String, List<String>> _breeds = {
    'cow': [
      "Kangayam",
      "Umblachery",
      "Alambadi",
      "Bargur",
      "Pulikulam",
      "Jersey (Cross)", // Common in TN
      "Holstein Friesian (Cross)", // Common in TN
    ],
    'goat': [
      "Kanni Aadu",
      "Kodi Aadu",
      "Salem Black",
      "Tellicherry", // Also common in TN
    ],
    'buffalo': [
      "Toda",
      "Murrah", // Common across India including TN
      "Surti",
    ]
  };

  @override
  void initState() {
    super.initState();
    // Initialize default breed
    _selectedBreed = _breeds['cow']!.first;
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveCattle() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if a breed is selected (though UI should enforce this)
    if (_selectedBreed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a breed')),
        );
        return;
    }


    setState(() => _isSaving = true);

    try {
      await _controller.addCattle(
        type: _selectedType,
        breed: _selectedBreed,
        age: int.parse(_ageController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cattle added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding cattle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Add Cattle'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _buildBreedSelector(),
              const SizedBox(height: 20),
              _buildAgeInput(),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Livestock Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'cow', child: Text('🐄 Cattle')),
                DropdownMenuItem(value: 'goat', child: Text('🐐 Goat')),
                DropdownMenuItem(value: 'buffalo', child: Text('🐃 Buffalo')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _selectedBreed = _breeds[value]!.first;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreedSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Breed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBreed,
              isExpanded: true,
              items: _breeds[_selectedType]!
                  .map((breed) => DropdownMenuItem(
                        value: breed,
                        child: Text(breed),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedBreed = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Age (in years)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter age',
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter age';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveCattle,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007BFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const TranslatedText(
                'Add Cattle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
