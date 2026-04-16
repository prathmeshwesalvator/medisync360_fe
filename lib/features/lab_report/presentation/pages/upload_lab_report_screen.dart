import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import '../bloc/lab_report_cubit.dart';
import '../bloc/lab_report_state.dart';
import 'lab_report_result_screen.dart';

class UploadLabReportScreen extends StatefulWidget {
  const UploadLabReportScreen({super.key});

  @override
  State<UploadLabReportScreen> createState() => _UploadLabReportScreenState();
}

class _UploadLabReportScreenState extends State<UploadLabReportScreen> {
  File? _selectedImage;
  String _reportType = 'other';
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, String>> _reportTypes = [
    {'value': 'cbc', 'label': 'Complete Blood Count'},
    {'value': 'blood_test', 'label': 'Blood Test'},
    {'value': 'lipid_panel', 'label': 'Lipid Panel'},
    {'value': 'liver_function', 'label': 'Liver Function'},
    {'value': 'kidney_function', 'label': 'Kidney Function'},
    {'value': 'thyroid', 'label': 'Thyroid Panel'},
    {'value': 'diabetes', 'label': 'Diabetes Panel'},
    {'value': 'urine_test', 'label': 'Urine Test'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Image Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _upload() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first')));
      return;
    }
    context.read<LabReportCubit>().uploadReport(
          imageFile: _selectedImage!,
          reportType: _reportType,
          title: _titleController.text.trim(),
          notes: _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Lab Report')),
      body: BlocListener<LabReportCubit, LabReportState>(
        listener: (context, state) {
          if (state is LabReportLoaded) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LabReportResultScreen(report: state.report),
              ),
            );
          } else if (state is LabReportError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<LabReportCubit, LabReportState>(
          builder: (context, state) {
            final bool isBusy = state is LabReportUploading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker area
                  GestureDetector(
                    onTap: isBusy ? null : _showImagePicker,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border:
                            Border.all(color: Colors.blue.shade200, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_selectedImage!,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file,
                                    size: 54, color: Colors.blue.shade300),
                                const SizedBox(height: 10),
                                Text('Tap to upload lab report image',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Report type
                  const Text('Report Type',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _reportType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: _reportTypes
                        .map((t) => DropdownMenuItem(
                              value: t['value'],
                              child: Text(t['label']!),
                            ))
                        .toList(),
                    onChanged:
                        isBusy ? null : (v) => setState(() => _reportType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Title (optional)
                  TextField(
                    controller: _titleController,
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: 'Title (optional)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  TextField(
                    controller: _notesController,
                    enabled: !isBusy,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Loading / button
                  if (isBusy) ...[
                    const Center(child: LoadingWidget()),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Uploading...',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _upload,
                        icon: const Icon(Icons.biotech),
                        label: const Text('Analyze Report',
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
