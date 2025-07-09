import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Dashboard/Dashboard.dart';

class NutritionsGuide extends StatefulWidget {
  const NutritionsGuide({super.key});

  @override
  State<NutritionsGuide> createState() => _NutritionsGuideState();
}

class _NutritionsGuideState extends State<NutritionsGuide> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _deficiencyController = TextEditingController();
  final TextEditingController _educationalTipController = TextEditingController();
  final TextEditingController _referenceLinkController = TextEditingController();

  // Age group controllers
  final Map<String, TextEditingController> _intakeControllers = {
    '0-6 months': TextEditingController(),
    '7-12 months': TextEditingController(),
    '1-3 years': TextEditingController(),
    '4-8 years': TextEditingController(),
    '9-10 years': TextEditingController(),
  };

  final Map<String, TextEditingController> _mealSuggestionControllers = {
    '0-6 months': TextEditingController(),
    '7-12 months': TextEditingController(),
    '1-3 years': TextEditingController(),
    '4-8 years': TextEditingController(),
    '9-10 years': TextEditingController(),
  };

  final TextEditingController _foodsController = TextEditingController();
  List<String> _recommendedFoods = [];

  @override
  void dispose() {
    _questionController.dispose();
    _deficiencyController.dispose();
    _educationalTipController.dispose();
    _referenceLinkController.dispose();
    _foodsController.dispose();
    for (var controller in _intakeControllers.values) {
      controller.dispose();
    }
    for (var controller in _mealSuggestionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Deficiency Manager',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFF3E0)]),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Section
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add New Deficiency',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildSectionHeader('Basic Information'),
                                _buildTextField(
                                  controller: _questionController,
                                  label: 'Question',
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                                  maxLines: 2,
                                ),
                                _buildTextField(
                                  controller: _deficiencyController,
                                  label: 'Deficiency Name',
                                  validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                                ),
                                _buildTextField(
                                  controller: _educationalTipController,
                                  label: 'Educational Tip',
                                  maxLines: 3,
                                ),
                                _buildTextField(
                                  controller: _referenceLinkController,
                                  label: 'Reference Link',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Recommended Daily Intake'),
                                ..._intakeControllers.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildTextField(
                                    controller: entry.value,
                                    label: 'For ${entry.key}',
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Meal Suggestions'),
                                ..._mealSuggestionControllers.entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildTextField(
                                    controller: entry.value,
                                    label: 'For ${entry.key}',
                                    maxLines: 2,
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Recommended Foods'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _foodsController,
                                        decoration: InputDecoration(
                                          labelText: 'Add food (comma separated)',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: _addFoods,
                                          ),
                                        ),
                                        onFieldSubmitted: (value) => _addFoods(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_recommendedFoods.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _recommendedFoods.map((food) => Chip(
                                        label: Text(food),
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        onDeleted: () => _removeFood(food),
                                        backgroundColor: Colors.blue.withOpacity(0.1),
                                        labelStyle: const TextStyle(color: Colors.blue),
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(240, 56),
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Save Deficiency',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Existing Deficiencies Section
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Existing Deficiencies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('deficiencies')
                            //.orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading data\n${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            );
                          }

                          if (snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No deficiencies found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildDeficiencyCard(doc.id, data);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
        maxLines: maxLines ?? 1,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDeficiencyCard(String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _loadDeficiencyForEdit(docId, data),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['deficiency'] ?? 'Untitled Deficiency',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDeficiency(docId),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['question'] ?? 'No question provided',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[900],
                ),
              ),
              if (data['educationalTip'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  data['educationalTip'],
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatDate(data['createdAt']?.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _addFoods() {
    if (_foodsController.text.isNotEmpty) {
      setState(() {
        _recommendedFoods.addAll(
            _foodsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        );
        _foodsController.clear();
      });
    }
  }

  void _removeFood(String food) {
    setState(() {
      _recommendedFoods.remove(food);
    });
  }

  void _loadDeficiencyForEdit(String docId, Map<String, dynamic> data) {
    // Clear existing data
    _formKey.currentState?.reset();
    setState(() {
      _recommendedFoods = [];
    });

    // Load data into form
    _questionController.text = data['question'] ?? '';
    _deficiencyController.text = data['deficiency'] ?? '';
    _educationalTipController.text = data['educationalTip'] ?? '';
    _referenceLinkController.text = data['referenceLink'] ?? '';

    // Load recommended foods
    if (data['recommendedFoods'] != null) {
      setState(() {
        _recommendedFoods = List<String>.from(data['recommendedFoods']);
      });
    }

    // Load intake recommendations
    final intake = data['recommendedIntake'] as Map<String, dynamic>? ?? {};
    for (var entry in _intakeControllers.entries) {
      entry.value.text = intake[entry.key] ?? '';
    }

    // Load meal suggestions
    final meals = data['mealSuggestions'] as Map<String, dynamic>? ?? {};
    for (var entry in _mealSuggestionControllers.entries) {
      entry.value.text = meals[entry.key] ?? '';
    }

    // Scroll to top
    Scrollable.ensureVisible(
      _formKey.currentContext!,
      duration: const Duration(milliseconds: 300),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deficiency loaded for editing')),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Prepare the data structure
        final deficiencyData = {
          'question': _questionController.text,
          'deficiency': _deficiencyController.text,
          'educationalTip': _educationalTipController.text,
          'referenceLink': _referenceLinkController.text,
          'recommendedIntake': {
            for (var entry in _intakeControllers.entries)
              entry.key: entry.value.text,
          },
          'mealSuggestions': {
            for (var entry in _mealSuggestionControllers.entries)
              entry.key: entry.value.text,
          },
          'recommendedFoods': _recommendedFoods,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Save to Firestore
        await _firestore.collection('deficiencies').add(deficiencyData);

        // Clear the form
        _formKey.currentState!.reset();
        setState(() {
          _recommendedFoods = [];
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deficiency saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving deficiency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDeficiency(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this deficiency?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('deficiencies').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deficiency deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting deficiency: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}