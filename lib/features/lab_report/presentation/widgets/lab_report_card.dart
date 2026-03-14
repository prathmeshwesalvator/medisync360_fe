// import 'package:flutter/material.dart';
// import 'package:medisync_app/features/lab_report/data/model/lab_report_model.dart';

// class LabReportCard extends StatelessWidget {
//   final LabReport report;
//   final VoidCallback? onTap;

//   const LabReportCard({super.key, required this.report, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 48, height: 48,
//               decoration: BoxDecoration(
//                 color: report.hasAbnormal
//                     ? const Color(0xFFFEF2F2)
//                     : const Color(0xFFEFF6FF),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 Icons.science_outlined,
//                 color: report.hasAbnormal ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(report.title,
//                     style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF111827))),
//                   const SizedBox(height: 3),
//                   Text(report.reportType,
//                     style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
//                   const SizedBox(height: 6),
//                   Row(children: [
//                     Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
//                     const SizedBox(width: 4),
//                     Text(
//                       '\${report.testDate.day}/\${report.testDate.month}/\${report.testDate.year}',
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                     ),
//                     if (report.hasAbnormal) ...[
//                       const SizedBox(width: 10),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFEF2F2),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: const Text('Abnormal values',
//                           style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
//                       ),
//                     ],
//                   ]),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//               decoration: BoxDecoration(
//                 color: report.statusColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(report.statusLabel,
//                 style: TextStyle(fontSize: 11, color: report.statusColor, fontWeight: FontWeight.w600)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }