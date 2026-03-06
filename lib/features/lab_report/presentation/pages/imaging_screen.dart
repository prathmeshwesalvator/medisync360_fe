import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';


class ImagingScreen extends StatefulWidget {
  const ImagingScreen({super.key});

  @override
  State<ImagingScreen> createState() => _ImagingScreenState();
}

class _ImagingScreenState extends State<ImagingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EHRCubit>().loadImaging();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Imaging Records',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: BlocBuilder<EHRCubit, EHRState>(
        builder: (context, state) {
          if (state is EHRLoading) return const LoadingWidget();

          if (state is EHRError) {
            return EmptyStateWidget(
              icon: Icons.image_outlined,
              title: 'Could not load imaging records',
              subtitle: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () => context.read<EHRCubit>().loadImaging(),
            );
          }

          if (state is ImagingLoaded) {
            if (state.records.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.image_outlined,
                title: 'No imaging records',
                subtitle: 'X-Ray, MRI, CT Scan records will appear here',
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.records.length,
              itemBuilder: (_, i) {
                final img = state.records[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail area
                      Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFEFF),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 40, color: Color(0xFF0891B2)),
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              img.imagingTypeDisplay.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0891B2),
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              img.bodyPart,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              img.scanDate,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const EmptyStateWidget(
            icon: Icons.image_outlined,
            title: 'Could not load',
            subtitle: 'Please try again',
          );
        },
      ),
    );
  }
}