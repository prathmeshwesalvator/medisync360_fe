// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
// import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
// import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_cubit.dart';
// import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_state.dart';
// import 'package:medisync_app/features/lab_report/presentation/pages/lab_report_details_screen.dart';
// import '../widgets/lab_report_card.dart';
// import 'upload_lab_report_screen.dart';

// class LabReportListScreen extends StatefulWidget {
//   const LabReportListScreen({super.key});

//   @override
//   State<LabReportListScreen> createState() => _LabReportListScreenState();
// }

// class _LabReportListScreenState extends State<LabReportListScreen> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<LabReportCubit>().loadReports();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: const Text('Lab Reports',
//             style: TextStyle(fontWeight: FontWeight.w700)),
//         backgroundColor: Colors.white,
//         foregroundColor: const Color(0xFF111827),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.upload_file_outlined),
//             tooltip: 'Upload report',
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const UploadLabReportScreen()),
//             ).then((_) => context.read<LabReportCubit>().loadReports()),
//           ),
//         ],
//       ),
//       body: BlocBuilder<LabReportCubit, LabReportState>(
//         builder: (context, state) {
//           if (state is LabReportLoading) return const LoadingWidget();

//           if (state is LabReportError) {
//             return EmptyStateWidget(
//               icon: Icons.science_outlined,
//               title: 'Could not load reports',
//               subtitle: state.message,
//               buttonLabel: 'Retry',
//               onButtonTap: () => context.read<LabReportCubit>().loadReports(),
//             );
//           }

//           if (state is LabReportLoaded) {
//             if (state.reports.isEmpty) {
//               return EmptyStateWidget(
//                 icon: Icons.science_outlined,
//                 title: 'No lab reports yet',
//                 subtitle: 'Upload your reports to keep track of them here',
//                 buttonLabel: 'Upload Report',
//                 onButtonTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (_) => const UploadLabReportScreen()),
//                 ).then((_) => context.read<LabReportCubit>().loadReports()),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: () => context.read<LabReportCubit>().loadReports(),
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 itemCount: state.reports.length,
//                 itemBuilder: (_, i) {
//                   final report = state.reports[i];
//                   return LabReportCard(
//                     report: report,
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             LabReportDetailScreen(reportId: report.id),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           }

//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }
