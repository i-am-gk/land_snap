// MODIFIED FILE: lib/admin/view_land_screen.dart
// ---------------------------------------------------------
// MODULE: Admin View Land Records
// PURPOSE: Displays all land records from Firestore.
//          Allows editing metadata, deleting records, and
//          managing polygon boundaries.
// ---------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/land_repository.dart';
import '../models/map_polygon_feature.dart';
import 'edit_polygon_screen.dart';

class ViewLandScreen extends StatefulWidget {
  final User user;
  const ViewLandScreen({required this.user, super.key});

  @override
  _ViewLandScreenState createState() => _ViewLandScreenState();
}

class _ViewLandScreenState extends State<ViewLandScreen> {
  final LandRepository _landRepo = LandRepository();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('View Land Records', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                .collection('lands')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No land records found.'));
          }

          final landDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: landDocs.length,
            itemBuilder: (context, index) {
              final doc = landDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final feature = MapPolygonFeature.fromFirestore(doc) ?? 
                             MapPolygonFeature(khasraId: doc.id, points: []);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Khasra: ${data['khasraNumber']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryColor)),
                          _buildStatusChip(data['hasGeometry'] == true),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Owner', data['ownerName'] ?? 'N/A'),
                          _buildInfoRow('Area', data['areaDetail'] ?? 'N/A'),
                          _buildInfoRow('Category', data['areaType'] ?? 'N/A'),
                          _buildInfoRow('Khata', data['khataNumber'] ?? 'N/A'),
                          const Divider(height: 24),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit_location_alt),
                                label: Text(data['hasGeometry'] == true ? "Edit Boundary" : "Add Boundary"),
                                onPressed: () => Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (ctx) => EditPolygonScreen(feature: feature))
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.edit, color: primaryColor),
                                onPressed: () => _editLandRecord(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(doc.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete land record $docId?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _landRepo.deleteLandRecord(docId);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _editLandRecord(String docId, Map<String, dynamic> data) {
    final _formKey = GlobalKey<FormState>();
    String owner = data['ownerName'] ?? '';
    String area = data['areaDetail'] ?? '';
    String category = data['areaType'] ?? '';
    String khata = data['khataNumber'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Land Record'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Owner Name', owner, (v) => owner = v ?? ''),
                const SizedBox(height: 12),
                _buildTextField('Area Detail', area, (v) => area = v ?? ''),
                const SizedBox(height: 12),
                _buildTextField('Area Type', category, (v) => category = v ?? ''),
                const SizedBox(height: 12),
                _buildTextField('Khata Number', khata, (v) => khata = v ?? ''),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                _formKey.currentState!.save();
                await _landRepo.updateMetadata(docId, {
                  'ownerName': owner,
                  'areaDetail': area,
                  'areaType': category,
                  'khataNumber': khata,
                });
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record updated')));
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String?) onSaved) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onSaved: onSaved,
    );
  }

  Widget _buildStatusChip(bool isMapped) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMapped ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMapped ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMapped ? Icons.check_circle : Icons.help_outline,
            size: 14,
            color: isMapped ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            isMapped ? "Mapped" : "Text Only",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMapped ? Colors.green[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
