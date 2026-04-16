// xray_analyzer_page.dart
// ─────────────────────────────────────────────────────────────────────────────
// UI: Full X-Ray Analyzer feature screen
// Dark medical aesthetic — deep navy + electric cyan + warning amber
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medisync_app/features/x-ray_analyzer/analyzer_bloc.dart';
import 'package:medisync_app/features/x-ray_analyzer/analyzer_datasource.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

const _bg = Color(0xFF050D1A);
const _surface = Color(0xFF0C1829);
const _card = Color(0xFF0F2035);
const _cardBorder = Color(0xFF1A3A5C);
const _cyan = Color(0xFF00D4FF);
const _cyanDim = Color(0xFF00A8CC);
const _amber = Color(0xFFFFB830);
const _red = Color(0xFFFF4C4C);
const _green = Color(0xFF00E676);
const _textPrimary = Color(0xFFE8F4FF);
const _textSecondary = Color(0xFF7A9DBF);
const _textDim = Color(0xFF3A5E80);

// ═════════════════════════════════════════════════════════════════════════════
// ENTRY POINT — provide bloc
// ═════════════════════════════════════════════════════════════════════════════

class XRayAnalyzerPage extends StatelessWidget {
  const XRayAnalyzerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => XRayAnalyzerBloc(),
      child: const _XRayAnalyzerView(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN VIEW
// ═════════════════════════════════════════════════════════════════════════════

class _XRayAnalyzerView extends StatelessWidget {
  const _XRayAnalyzerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: BlocBuilder<XRayAnalyzerBloc, XRayAnalyzerState>(
        builder: (context, state) => switch (state) {
          XRayInitial() => const _UploadScreen(),
          XRayImageReady() => _ImageReadyScreen(state: state),
          XRayGuardChecking() => _LoadingScreen(
              imageFile: state.imageFile,
              label: 'Verifying image type…',
              sublabel: 'Checking if this is a chest X-ray',
            ),
          XRayGuardRejected() => _GuardRejectedScreen(state: state),
          XRayAnalyzing() => _LoadingScreen(
              imageFile: state.imageFile,
              label: 'Analyzing X-ray…',
              sublabel: 'AI radiologist is reviewing your image',
              showPulse: true,
            ),
          XRayAnalysisSuccess() => _ResultsScreen(state: state),
          XRayAnalysisError() => _ErrorScreen(state: state),
          _ => const _UploadScreen(),
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: BlocBuilder<XRayAnalyzerBloc, XRayAnalyzerState>(
        builder: (context, state) {
          if (state is XRayInitial) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textSecondary, size: 18),
            onPressed: () =>
                context.read<XRayAnalyzerBloc>().add(const XRayAnalyzerReset()),
          );
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cyan.withOpacity(0.3)),
            ),
            child: const Icon(Icons.biotech_rounded, color: _cyan, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'X-Ray Analyzer',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _cardBorder),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UPLOAD SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _UploadScreen extends StatelessWidget {
  const _UploadScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Hero scan graphic
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _cyan.withOpacity(0.15), width: 1),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _cyan.withOpacity(0.25), width: 1),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _card,
                        border: Border.all(
                            color: _cyan.withOpacity(0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.biotech_rounded,
                          size: 52, color: _cyan),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'AI Chest X-Ray Analysis',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a chest X-ray for instant AI-powered radiological analysis, disease detection, and interactive Q&A.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Feature chips
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(icon: Icons.shield_outlined, label: 'Guard Check'),
                _FeatureChip(icon: Icons.search, label: 'Disease Detection'),
                _FeatureChip(
                    icon: Icons.chat_bubble_outline, label: 'X-Ray Q&A'),
                _FeatureChip(
                    icon: Icons.summarize_outlined, label: 'Full Report'),
              ],
            ),
            const Spacer(),
            // Upload buttons
            _CyanButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _OutlineButton(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            const SizedBox(height: 16),
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _amber.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _amber, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For educational use only. Not a substitute for professional medical diagnosis.',
                      style: TextStyle(
                        color: _amber.withOpacity(0.8),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1400,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    context.read<XRayAnalyzerBloc>().add(XRayImageSelected(File(picked.path)));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// IMAGE READY SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _ImageReadyScreen extends StatelessWidget {
  final XRayImageReady state;
  const _ImageReadyScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                  color: _card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(state.imageFile, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ready to analyze',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'The AI will first verify this is a chest X-ray, then provide a full radiological report.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _CyanButton(
              icon: Icons.auto_fix_high_rounded,
              label: 'Analyze X-Ray',
              onTap: () => context
                  .read<XRayAnalyzerBloc>()
                  .add(const XRayAnalyzeRequested()),
            ),
            const SizedBox(height: 10),
            _OutlineButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Change Image',
              onTap: () => context
                  .read<XRayAnalyzerBloc>()
                  .add(const XRayAnalyzerReset()),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _LoadingScreen extends StatelessWidget {
  final File imageFile;
  final String label;
  final String sublabel;
  final bool showPulse;

  const _LoadingScreen({
    required this.imageFile,
    required this.label,
    required this.sublabel,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                  color: _card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.contain),
                    // Scan line overlay
                    const _ScanLineOverlay(),
                    // Dim overlay
                    Container(color: _bg.withOpacity(0.55)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(
                              color: _cyan,
                              strokeWidth: 2.5,
                              backgroundColor: _cyan.withOpacity(0.15),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            label,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sublabel,
                            style: const TextStyle(
                                color: _textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GUARD REJECTED SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _GuardRejectedScreen extends StatelessWidget {
  final XRayGuardRejected state;
  const _GuardRejectedScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _red.withOpacity(0.4)),
                  color: _card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Colors.grey, BlendMode.saturation),
                      child: Image.file(state.imageFile, fit: BoxFit.contain),
                    ),
                    Container(color: _red.withOpacity(0.12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: _red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Not a Chest X-Ray',
                        style: TextStyle(
                          color: _red,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.reason,
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CyanButton(
              icon: Icons.upload_file_outlined,
              label: 'Upload a Chest X-Ray',
              onTap: () => context
                  .read<XRayAnalyzerBloc>()
                  .add(const XRayAnalyzerReset()),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ERROR SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorScreen extends StatelessWidget {
  final XRayAnalysisError state;
  const _ErrorScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline_rounded, color: _red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Analysis Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            if (state.imageFile != null) ...[
              _CyanButton(
                icon: Icons.refresh_rounded,
                label: 'Try Again',
                onTap: () => context
                    .read<XRayAnalyzerBloc>()
                    .add(const XRayAnalyzeRequested()),
              ),
              const SizedBox(height: 10),
            ],
            _OutlineButton(
              icon: Icons.home_outlined,
              label: 'Start Over',
              onTap: () => context
                  .read<XRayAnalyzerBloc>()
                  .add(const XRayAnalyzerReset()),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESULTS SCREEN — tabbed
// ═════════════════════════════════════════════════════════════════════════════

class _ResultsScreen extends StatefulWidget {
  final XRayAnalysisSuccess state;
  const _ResultsScreen({required this.state});

  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<XRayAnalyzerBloc, XRayAnalyzerState>(
      builder: (context, state) {
        if (state is! XRayAnalysisSuccess) return const SizedBox.shrink();
        return Column(
          children: [
            // Thumbnail + tab bar header
            _buildHeader(state),
            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: _cyan,
              indicatorWeight: 2,
              labelColor: _cyan,
              unselectedLabelColor: _textDim,
              labelStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              dividerColor: _cardBorder,
              tabs: const [
                Tab(text: 'REPORT'),
                Tab(text: 'CONDITIONS'),
                Tab(text: 'Q & A'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ReportTab(result: state.result),
                  _ConditionsTab(result: state.result),
                  _ChatTab(state: state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(XRayAnalysisSuccess state) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.file(state.imageFile, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: _green, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Chest X-Ray Verified',
                            style: TextStyle(
                                color: _green,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  state.result.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _textSecondary, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Report ────────────────────────────────────────────────────────────

class _ReportTab extends StatelessWidget {
  final XRayAnalysisResult result;
  const _ReportTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Impression
        _SectionCard(
          icon: Icons.description_outlined,
          title: 'Clinical Impression',
          child: Text(
            result.impression,
            style: const TextStyle(
                color: _textSecondary, fontSize: 13.5, height: 1.6),
          ),
        ),
        const SizedBox(height: 12),

        // Findings
        _SectionCard(
          icon: Icons.search_rounded,
          title: 'Radiological Findings',
          child: Column(
            children:
                result.findings.map((f) => _FindingRow(finding: f)).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Recommendation
        _SectionCard(
          icon: Icons.medical_services_outlined,
          title: 'Recommendation',
          child: Text(
            result.recommendation,
            style: const TextStyle(
                color: _textSecondary, fontSize: 13.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _amber.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _amber.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: _amber, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.disclaimer,
                  style: TextStyle(
                      color: _amber.withOpacity(0.7),
                      fontSize: 11,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Tab 2: Conditions ────────────────────────────────────────────────────────

class _ConditionsTab extends StatelessWidget {
  final XRayAnalysisResult result;
  const _ConditionsTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'POSSIBLE CONDITIONS',
          style: TextStyle(
            color: _textDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...result.possibleConditions.map((c) => _ConditionCard(condition: c)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final PossibleCondition condition;
  const _ConditionCard({required this.condition});

  @override
  Widget build(BuildContext context) {
    final confColor = switch (condition.confidence) {
      ConfidenceLevel.high => _red,
      ConfidenceLevel.moderate => _amber,
      ConfidenceLevel.low => _green,
    };
    final confLabel = switch (condition.confidence) {
      ConfidenceLevel.high => 'High likelihood',
      ConfidenceLevel.moderate => 'Moderate likelihood',
      ConfidenceLevel.low => 'Low likelihood',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  condition.name,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: confColor.withOpacity(0.35)),
                ),
                child: Text(
                  confLabel,
                  style: TextStyle(
                      color: confColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            condition.description,
            style: const TextStyle(
                color: _textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.search, color: _cyan, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    condition.evidenceBasis,
                    style: const TextStyle(
                        color: _cyanDim, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Chat ──────────────────────────────────────────────────────────────

class _ChatTab extends StatefulWidget {
  final XRayAnalysisSuccess state;
  const _ChatTab({required this.state});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<XRayAnalyzerBloc, XRayAnalyzerState>(
      listener: (context, state) {
        if (state is XRayAnalysisSuccess) _scrollToBottom();
      },
      builder: (context, state) {
        if (state is! XRayAnalysisSuccess) return const SizedBox.shrink();

        return Column(
          children: [
            Expanded(
              child: state.chatHistory.isEmpty
                  ? _buildEmptyChat()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.chatHistory.length +
                          (state.isChatLoading ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == state.chatHistory.length) {
                          return const _TypingIndicator();
                        }
                        return _ChatBubble(message: state.chatHistory[i]);
                      },
                    ),
            ),
            _buildInputBar(context, state.isChatLoading),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Ask about this X-ray',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'The AI can answer questions about the findings in your uploaded X-ray.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Text(
            'SUGGESTED QUESTIONS',
            style: TextStyle(
              color: _textDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestedQuestions.map((q) => _SuggestedQuestionChip(
                question: q,
                onTap: () => _send(context, q),
              )),
        ],
      ),
    );
  }

  static const _suggestedQuestions = [
    'What are the most concerning findings in this X-ray?',
    'Are the lung fields clear or are there any opacities?',
    'What does the cardiac silhouette look like?',
    'Are there any signs of pleural effusion?',
    'What follow-up tests would you recommend?',
    'How does this compare to a normal chest X-ray?',
  ];

  Widget _buildInputBar(BuildContext context, bool isLoading) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cardBorder),
              ),
              child: TextField(
                controller: _controller,
                enabled: !isLoading,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Ask about this X-ray…',
                  hintStyle: TextStyle(color: _textDim, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (v) => _send(context, v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : () => _send(context, _controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLoading ? _textDim : _cyan,
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: _bg,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: _bg, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.clear();
    context.read<XRayAnalyzerBloc>().add(XRayChatMessageSent(trimmed));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  final XRayFinding finding;
  const _FindingRow({required this.finding});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (finding.severity) {
      Severity.normal => _green,
      Severity.mild => _amber,
      Severity.moderate => const Color(0xFFFF8A00),
      Severity.severe => _red,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.region,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  finding.observation,
                  style: const TextStyle(
                      color: _textSecondary, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withOpacity(0.15),
                border: Border.all(color: _cyan.withOpacity(0.3)),
              ),
              child: const Icon(Icons.biotech_rounded, color: _cyan, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _cyan.withOpacity(0.15) : _card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? _cyan.withOpacity(0.25) : _cardBorder,
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                    color: _textPrimary, fontSize: 13.5, height: 1.5),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyan.withOpacity(0.15),
            ),
            child: const Icon(Icons.biotech_rounded, color: _cyan, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _BouncingDot(delay: Duration(milliseconds: i * 150)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final Duration delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.0, end: -6.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: _cyanDim),
        ),
      ),
    );
  }
}

class _SuggestedQuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback onTap;
  const _SuggestedQuestionChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: _cyan, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _textDim, size: 12),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _cyan, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: _textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CyanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CyanButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _cyan,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _bg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _bg,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scan line animation overlay ─────────────────────────────────────────────

class _ScanLineOverlay extends StatefulWidget {
  const _ScanLineOverlay();

  @override
  State<_ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<_ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _anim = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return CustomPaint(
          painter: _ScanLinePainter(_anim.value),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00D4FF).withOpacity(0),
          const Color(0xFF00D4FF).withOpacity(0.6),
          const Color(0xFF00D4FF).withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));

    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
