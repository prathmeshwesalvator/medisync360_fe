import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/ehr/data/models/ehr_models.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EHRCubit>().loadPrescriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescriptions',
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
              icon: Icons.medication_outlined,
              title: 'Could not load prescriptions',
              subtitle: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<EHRCubit>().loadPrescriptions(),
            );
          }

          if (state is PrescriptionsLoaded) {
            if (state.prescriptions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.medication_outlined,
                title: 'No prescriptions yet',
                subtitle: 'Your doctor prescriptions will appear here',
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<EHRCubit>().loadPrescriptions(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.prescriptions.length,
                itemBuilder: (_, i) =>
                    _PrescriptionCard(rx: state.prescriptions[i]),
              ),
            );
          }

          return const EmptyStateWidget(
            icon: Icons.medication_outlined,
            title: 'Could not load',
            subtitle: 'Please try again',
          );
        },
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _PrescriptionCard extends StatelessWidget {
  final PrescriptionModel rx;
  const _PrescriptionCard({required this.rx});

  Color get _statusColor {
    switch (rx.status) {
      case 'active':   return AppColors.accent;
      case 'expired':  return AppColors.error;
      default:         return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.doctorRole.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_outlined,
                color: AppColors.doctorRole, size: 22),
          ),
          title: Text('Dr. ${rx.doctorName}',
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rx.diagnosis,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Row(children: [
                Text(rx.issuedDate, style: AppTextStyles.caption),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(rx.status.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          children: rx.items.isEmpty
              ? [
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('No medicines listed.',
                        style: AppTextStyles.bodyMedium),
                  )
                ]
              : rx.items.map((m) => _MedicineRow(m: m)).toList(),
        ),
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  final PrescriptionItemModel m;
  const _MedicineRow({required this.m});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
              color: AppColors.doctorRole, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.medicineName}  ${m.dosage}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
              Text('${m.frequency}  ·  ${m.duration}',
                  style: AppTextStyles.caption),
              if (m.instructions.isNotEmpty)
                Text(m.instructions, style: AppTextStyles.caption),
            ],
          ),
        ),
      ]),
    );
  }
}