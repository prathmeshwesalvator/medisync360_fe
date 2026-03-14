import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/model/lab_report_model.dart';
import '../bloc/lab_report_cubit.dart';
import '../bloc/lab_report_state.dart';

class LabReportResultScreen extends StatefulWidget {
  final LabReport report;
  const LabReportResultScreen({super.key, required this.report});

  @override
  State<LabReportResultScreen> createState() => _LabReportResultScreenState();
}

class _LabReportResultScreenState extends State<LabReportResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _questionController = TextEditingController();
  final List<ReportQA> _qaHistory = [];
  bool _askingQuestion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<LabReportCubit>().loadQuestions(widget.report.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _askQuestion() {
    final q = _questionController.text.trim();
    if (q.isEmpty) return;
    setState(() => _askingQuestion = true);
    context.read<LabReportCubit>().askQuestion(widget.report.id, q);
    _questionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.report.aiStructuredResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.report.title.isNotEmpty
              ? widget.report.title
              : 'Lab Report Analysis',
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Parameters'),
            Tab(text: 'Recommendations'),
            Tab(text: 'Ask AI'),
          ],
        ),
      ),
      body: BlocListener<LabReportCubit, LabReportState>(
        listener: (context, state) {
          if (state is LabReportAnswered) {
            setState(() {
              _askingQuestion = false;
              _qaHistory.add(ReportQA(
                id: 0,
                question: state.question,
                answer: state.answer,
                askedAt: '',
              ));
            });
          } else if (state is LabReportQuestionsLoaded) {
            setState(() {
              _qaHistory
                ..clear()
                ..addAll(state.questions);
            });
          } else if (state is LabReportError) {
            setState(() => _askingQuestion = false);
          }
        },
        child: result == null
            ? const Center(child: Text('No analysis available.'))
            : TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(result: result),
                  _ParametersTab(result: result),
                  _RecommendationsTab(result: result),
                  _AskTab(
                    qaHistory: _qaHistory,
                    controller: _questionController,
                    isAsking: _askingQuestion,
                    onAsk: _askQuestion,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final LabAiResult result;
  const _OverviewTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '🧬 Summary',
            child: Text(result.summary, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),

          if (result.criticalAlerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: '🚨 Critical Alerts',
              color: Colors.red.shade50,
              borderColor: Colors.red,
              child: Column(
                children: result.criticalAlerts
                    .map((a) => _BulletItem(text: a, color: Colors.red))
                    .toList(),
              ),
            ),
          ],

          if (result.abnormalFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: '⚠️ Abnormal Values',
              color: Colors.orange.shade50,
              borderColor: Colors.orange,
              child: Wrap(
                spacing: 8,
                children: result.abnormalFlags
                    .map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.orange.shade100,
                        ))
                    .toList(),
              ),
            ),
          ],

          if (result.positiveFindings.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: '✅ Positive Findings',
              color: Colors.green.shade50,
              borderColor: Colors.green,
              child: Column(
                children: result.positiveFindings
                    .map((f) => _BulletItem(text: f, color: Colors.green))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          _SectionCard(
            title: '🩺 Doctor Visit',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UrgencyChip(urgency: result.doctorConsultUrgency),
                const SizedBox(height: 8),
                Text(result.doctorConsultReason,
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),

          if (result.healthRisks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: '📊 Health Risks',
              child: Column(
                children: result.healthRisks.map((r) => _RiskTile(risk: r)).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          _SectionCard(
            title: '📅 Trend Advice',
            child: Text(result.trendAdvice,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('ℹ️ ${result.disclaimer}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Parameters Tab ────────────────────────────────────────────────────────────

class _ParametersTab extends StatelessWidget {
  final LabAiResult result;
  const _ParametersTab({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.parameters.isEmpty) {
      return const Center(child: Text('No parameters extracted.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: result.parameters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ParameterTile(param: result.parameters[i]),
    );
  }
}

// ── Recommendations Tab ───────────────────────────────────────────────────────

class _RecommendationsTab extends StatelessWidget {
  final LabAiResult result;
  const _RecommendationsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (result.dietaryRecommendations.isNotEmpty)
            _SectionCard(
              title: '🥗 Dietary Recommendations',
              child: Column(
                children: result.dietaryRecommendations
                    .map((r) => _RecommendationTile(rec: r, icon: Icons.restaurant))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          if (result.lifestyleRecommendations.isNotEmpty)
            _SectionCard(
              title: '🏃 Lifestyle Recommendations',
              child: Column(
                children: result.lifestyleRecommendations
                    .map((r) => _RecommendationTile(rec: r, icon: Icons.fitness_center))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          if (result.followUpTests.isNotEmpty)
            _SectionCard(
              title: '🔬 Suggested Follow-up Tests',
              child: Column(
                children: result.followUpTests
                    .map((t) => _BulletItem(text: t, color: Colors.blue))
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Ask AI Tab ────────────────────────────────────────────────────────────────

class _AskTab extends StatelessWidget {
  final List<ReportQA> qaHistory;
  final TextEditingController controller;
  final bool isAsking;
  final VoidCallback onAsk;

  const _AskTab({
    required this.qaHistory,
    required this.controller,
    required this.isAsking,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: qaHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('Ask anything about your report',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: qaHistory.length,
                  itemBuilder: (_, i) {
                    final qa = qaHistory[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChatBubble(text: qa.question, isUser: true),
                        const SizedBox(height: 6),
                        _ChatBubble(text: qa.answer, isUser: false),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
        ),
        if (isAsking)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about your report...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onAsk(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: isAsking ? null : onAsk,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? color;
  final Color? borderColor;

  const _SectionCard({
    required this.title,
    required this.child,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _ParameterTile extends StatelessWidget {
  final LabParameter param;
  const _ParameterTile({required this.param});

  Color get _statusColor {
    switch (param.status) {
      case 'critical_high':
      case 'critical_low':
        return Colors.red;
      case 'high':
      case 'low':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(param.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(param.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${param.value} ${param.unit}',
              style: TextStyle(fontSize: 18, color: _statusColor, fontWeight: FontWeight.w600)),
          Text('Reference: ${param.referenceRange}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(param.interpretation,
              style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final HealthRisk risk;
  const _RiskTile({required this.risk});

  Color get _riskColor {
    switch (risk.riskLevel) {
      case 'high': return Colors.red;
      case 'moderate': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(color: _riskColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.condition,
                    style: TextStyle(fontWeight: FontWeight.w600, color: _riskColor)),
                Text(risk.explanation,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final Recommendation rec;
  final IconData icon;
  const _RecommendationTile({required this.rec, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.recommendation,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(rec.reason,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String urgency;
  const _UrgencyChip({required this.urgency});

  Color get _color {
    switch (urgency) {
      case 'immediate': return Colors.red;
      case 'within_week': return Colors.orange;
      case 'within_month': return Colors.blue;
      default: return Colors.green;
    }
  }

  String get _label {
    switch (urgency) {
      case 'immediate': return '🚨 See a doctor immediately';
      case 'within_week': return '⚠️ Visit within a week';
      case 'within_month': return '📅 Visit within a month';
      default: return '✅ Routine checkup';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: _color,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text,
            style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4)),
      ),
    );
  }
}