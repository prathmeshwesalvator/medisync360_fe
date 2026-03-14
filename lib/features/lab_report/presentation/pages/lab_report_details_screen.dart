// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
// import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
// import 'package:medisync_app/features/lab_report/data/model/lab_report_model.dart';
// import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_cubit.dart';
// import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_state.dart';


// class LabReportDetailScreen extends StatefulWidget {
//   final int reportId;
//   const LabReportDetailScreen({super.key, required this.reportId});

//   @override
//   State<LabReportDetailScreen> createState() => _LabReportDetailScreenState();
// }

// class _LabReportDetailScreenState extends State<LabReportDetailScreen> {
//   @override
//   void initState() {
//     super.initState();
//     context.read<LabReportCubit>().loadReport(widget.reportId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         title: const Text('Report Details',
//             style: TextStyle(fontWeight: FontWeight.w700)),
//         backgroundColor: Colors.white,
//         foregroundColor: const Color(0xFF111827),
//         elevation: 0,
//       ),
//       body: BlocBuilder<LabReportCubit, LabReportState>(
//         builder: (context, state) {
//           if (state is LabReportLoading) return const LoadingWidget();
//           if (state is LabReportDetail) return _Body(report: state.report);
//           return const EmptyStateWidget(
//             icon: Icons.science_outlined,
//             title: 'Report not found',
//             subtitle: 'This report could not be loaded',
//           );
//         },
//       ),
//     );
//   }
// }

// class _Body extends StatelessWidget {
//   final LabReport report;
//   const _Body({required this.report});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Header card ───────────────────────────────────────────────
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(children: [
//                   Expanded(
//                     child: Text(report.title,
//                         style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF111827))),
//                   ),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: report.statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(report.statusLabel,
//                         style: TextStyle(
//                             color: report.statusColor,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 13)),
//                   ),
//                 ]),
//                 const SizedBox(height: 14),
//                 _InfoRow(
//                     Icons.biotech_outlined, 'Test Type', report.reportType),
//                 _InfoRow(
//                     Icons.calendar_today_outlined,
//                     'Date',
//                     '${report.testDate.day}/'
//                         '${report.testDate.month}/'
//                         '${report.testDate.year}'),
//                 _InfoRow(
//                     Icons.person_outline, 'Uploaded by', report.uploadedByName),
//                 if (report.notes.isNotEmpty)
//                   _InfoRow(Icons.notes_outlined, 'Notes', report.notes),
//                 // Abnormal banner
//                 if (report.hasAbnormal) ...[
//                   const SizedBox(height: 14),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFEF2F2),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: const Row(children: [
//                       Icon(Icons.warning_amber_rounded,
//                           color: Color(0xFFDC2626), size: 18),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'This report contains abnormal values. '
//                           'Please consult your doctor.',
//                           style:
//                               TextStyle(color: Color(0xFFDC2626), fontSize: 13),
//                         ),
//                       ),
//                     ]),
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           // ── Test results ──────────────────────────────────────────────
//           if (report.results.isNotEmpty) ...[
//             const SizedBox(height: 20),
//             const Text('Test Results',
//                 style: TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF111827))),
//             const SizedBox(height: 12),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withOpacity(0.05), blurRadius: 8)
//                 ],
//               ),
//               child: Column(
//                 children: List.generate(report.results.length, (i) {
//                   final r = report.results[i];
//                   final isLast = i == report.results.length - 1;
//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 14),
//                     decoration: BoxDecoration(
//                       border: isLast
//                           ? null
//                           : Border(
//                               bottom: BorderSide(color: Colors.grey.shade100)),
//                     ),
//                     child: Row(children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(r.testName,
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 14,
//                                     color: Color(0xFF111827))),
//                             if (r.normalRange.isNotEmpty)
//                               Text('Normal: ${r.normalRange}',
//                                   style: TextStyle(
//                                       fontSize: 12,
//                                       color: Colors.grey.shade500)),
//                           ],
//                         ),
//                       ),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             '${r.value} ${r.unit}'.trim(),
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w700,
//                               color: r.isAbnormal
//                                   ? const Color(0xFFDC2626)
//                                   : const Color(0xFF111827),
//                             ),
//                           ),
//                           if (r.isAbnormal)
//                             const Text('Abnormal',
//                                 style: TextStyle(
//                                     fontSize: 11, color: Color(0xFFDC2626))),
//                         ],
//                       ),
//                     ]),
//                   );
//                 }),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   const _InfoRow(this.icon, this.label, this.value);

//   @override
//   Widget build(BuildContext context) => Padding(
//         padding: const EdgeInsets.only(top: 8),
//         child: Row(children: [
//           Icon(icon, size: 16, color: Colors.grey.shade400),
//           const SizedBox(width: 8),
//           Text('$label: ',
//               style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
//           Expanded(
//             child: Text(value,
//                 style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF111827))),
//           ),
//         ]),
//       );
// }
