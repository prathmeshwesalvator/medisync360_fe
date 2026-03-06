import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_cubit.dart';
import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_state.dart';
import 'package:medisync_app/global/widgets/app_textfield.dart';


class UploadLabReportScreen extends StatefulWidget {
  const UploadLabReportScreen({super.key});

  @override
  State<UploadLabReportScreen> createState() => _UploadLabReportScreenState();
}

class _UploadLabReportScreenState extends State<UploadLabReportScreen> {
  final _titleCtrl   = TextEditingController();
  final _fileUrlCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _selectedType = '';
  DateTime _testDate   = DateTime.now();
  bool _loading        = false;

  final List<String> _types = [
    'CBC', 'LFT', 'KFT', 'Lipid Profile',
    'Thyroid', 'Blood Sugar', 'Urine', 'Urine Culture',
    'Stool', 'HbA1c', 'Other',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fileUrlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _testDate = picked);
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a report title');
      return;
    }
    if (_selectedType.isEmpty) {
      _snack('Please select a report type');
      return;
    }
    if (_fileUrlCtrl.text.trim().isEmpty) {
      _snack('Please enter the file URL');
      return;
    }

    final date =
        '${_testDate.year}-${_testDate.month.toString().padLeft(2, '0')}'
        '-${_testDate.day.toString().padLeft(2, '0')}';

    context.read<LabReportCubit>().uploadReport(
          title:      _titleCtrl.text.trim(),
          reportType: _selectedType,
          fileUrl:    _fileUrlCtrl.text.trim(),
          testDate:   date,
          notes:      _notesCtrl.text.trim(),
        );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return BlocListener<LabReportCubit, LabReportState>(
      listener: (context, state) {
        if (state is LabReportLoading) {
          setState(() => _loading = true);
        } else {
          setState(() => _loading = false);
        }
        if (state is LabReportUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report uploaded successfully'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context);
        }
        if (state is LabReportError) {
          _snack(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Upload Lab Report',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              AppTextField(
                controller: _titleCtrl,
                label: 'Report Title',
                hint: 'e.g. Complete Blood Count',
              ),
              const SizedBox(height: 20),

              // Type chips
              const Text('Report Type',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final selected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // File URL
              AppTextField(
                controller: _fileUrlCtrl,
                label: 'File URL',
                hint: 'https://  (paste link to uploaded report)',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),

              // Date picker
              const Text('Test Date',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(
                      '${_testDate.day}/${_testDate.month}/${_testDate.year}',
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF374151)),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_outlined,
                        size: 16, color: Colors.grey.shade400),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              AppTextField(
                controller: _notesCtrl,
                label: 'Notes (optional)',
                hint: 'Any additional notes...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Upload Report',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}