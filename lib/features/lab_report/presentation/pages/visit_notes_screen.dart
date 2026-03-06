import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/ehr/data/models/ehr_models.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class VisitNotesScreen extends StatefulWidget {
  const VisitNotesScreen({super.key});

  @override
  State<VisitNotesScreen> createState() => _VisitNotesScreenState();
}

class _VisitNotesScreenState extends State<VisitNotesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EHRCubit>().loadVisitNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Notes',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<EHRCubit, EHRState>(
        builder: (context, state) {
          if (state is EHRLoading) return const LoadingWidget();

          if (state is EHRError) {
            return EmptyStateWidget(
              icon: Icons.note_alt_outlined,
              title: 'Could not load notes',
              subtitle: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () => context.read<EHRCubit>().loadVisitNotes(),
            );
          }

          if (state is VisitNotesLoaded) {
            if (state.notes.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.note_alt_outlined,
                title: 'No doctor notes yet',
                subtitle: 'Notes from your doctor visits will appear here',
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<EHRCubit>().loadVisitNotes(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.notes.length,
                itemBuilder: (_, i) => _NoteCard(note: state.notes[i]),
              ),
            );
          }

          return const EmptyStateWidget(
            icon: Icons.note_alt_outlined,
            title: 'No notes found',
            subtitle: 'Please try again',
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final VisitNoteModel note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0891B2).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outlined,
                    color: Color(0xFF0891B2), size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${note.doctorName}',
                        style: AppTextStyles.labelLarge),
                    Text(note.doctorSpecialty, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(note.visitDate,
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w600)),
                if (note.followUpDate != null)
                  Text('Follow-up: ${note.followUpDate}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning)),
              ]),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.chiefComplaint.isNotEmpty) ...[
                  _NoteSection('Chief Complaint', note.chiefComplaint,
                      Icons.help_outline_rounded, AppColors.warning),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (note.diagnosis.isNotEmpty) ...[
                  _NoteSection('Diagnosis', note.diagnosis,
                      Icons.medical_information_outlined, AppColors.error),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (note.treatmentPlan.isNotEmpty) ...[
                  _NoteSection('Treatment Plan', note.treatmentPlan,
                      Icons.healing_outlined, AppColors.accent),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (note.examinationNotes.isNotEmpty)
                  _NoteSection('Examination Notes', note.examinationNotes,
                      Icons.note_outlined, AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSection extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _NoteSection(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      );
}
