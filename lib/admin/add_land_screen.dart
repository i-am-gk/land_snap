import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/land_repository.dart';

class AddLandScreen extends StatefulWidget {
  final User user;
  const AddLandScreen({required this.user, super.key});

  @override
  _AddLandScreenState createState() => _AddLandScreenState();
}

class _AddLandScreenState extends State<AddLandScreen> {
  final _formKey = GlobalKey<FormState>();
  final LandRepository _landRepo = LandRepository();

  String _khasraNumber = '';
  String _ownerName = '';
  String _areaDetail = '';
  String _areaType = '';
  String _khataNumber = '';

  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (mounted) setState(() => _loading = true);

    try {
      final khasraId = _khasraNumber.trim();
      final docSnapshot = await FirebaseFirestore.instance.collection('lands').doc(khasraId).get();
      
      if (docSnapshot.exists) {
        if (!mounted) return;
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Duplicate Khasra Detected'),
            content: const Text('A land record with this Khasra Number already exists.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Update Existing Record'),
              ),
            ],
          ),
        );

        if (shouldUpdate != true) {
          if (mounted) setState(() => _loading = false);
          return;
        }
      }

      if (!mounted) return;
      if (mounted) setState(() => _loading = true);

      await _landRepo.saveLandRecord(
        khasraId: khasraId,
        metadata: {
          'ownerName': _ownerName.trim(),
          'areaDetail': _areaDetail.trim(),
          'areaType': _areaType.trim(),
          'khataNumber': _khataNumber.trim(),
          'addedBy': widget.user.email,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Land record added successfully!')),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      debugPrint('Error saving land record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add land record')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Land Record'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Land Record',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin: ${widget.user.email}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Form Fields
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Khasra Number',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Khasra Number required'
                              : null,
                  onSaved: (v) => _khasraNumber = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Owner Name required'
                              : null,
                  onSaved: (v) => _ownerName = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Area Detail (e.g., 5 Marla)',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Area Detail required'
                              : null,
                  onSaved: (v) => _areaDetail = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Area Type (e.g., Qabristan)',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Area Type required'
                              : null,
                  onSaved: (v) => _areaType = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Khata Number',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Khata Number required'
                              : null,
                  onSaved: (v) => _khataNumber = v ?? '',
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon:
                        _loading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Icon(Icons.add),
                    label: const Text('Add Land Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
