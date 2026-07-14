import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────
// MIZAN DESIGN TOKENS
// ─────────────────────────────────────────────────────────────

const Color _ivory = Color(0xFFFBF9F6);
const Color _paper = Color(0xFFF9F4ED);
const Color _walnut = Color(0xFF2F241E);
const Color _walnutLight = Color(0xFF3C2F26);
const Color _bronze = Color(0xFF8B6842);
const Color _bronzeDark = Color(0xFF6D4F32);
const Color _bronzeLight = Color(0xFFB38964);
const Color _clay = Color(0xFFE2D0BE);
const Color _clayLight = Color(0xFFE8DCCF);
const Color _clayPale = Color(0xFFF3E9DE);
const Color _mutedOlive = Color(0xFF749B75);
const Color _mutedOliveLight = Color(0xFFD4E0C8);
const Color _stone = Color(0xFF6D5B4D);
const Color _stoneLight = Color(0xFF9A8A7A);
const Color _stonePale = Color(0xFFB8A28E);
const Color _white = Color(0xFFFFFFFF);
const Color _shadow = Color(0x0D000000);
const Color _shadowWarm = Color(0x1A8B6842);

// ─────────────────────────────────────────────────────────────
// QUICK ACTS DATA
// ─────────────────────────────────────────────────────────────

class _QuickAct {
  final String label;
  final IconData icon;
  final bool isFinancial;
  final String subtitle;
  const _QuickAct(this.label, this.icon, this.isFinancial, this.subtitle);
}

const List<_QuickAct> _quickActs = [
  _QuickAct('Money', Icons.attach_money, true, 'Financial sadaqah'),
  _QuickAct('Food', Icons.restaurant_outlined, false, 'Nourishment given'),
  _QuickAct('Kindness', Icons.favorite_outline, false, 'A gentle act'),
  _QuickAct('Time', Icons.schedule_outlined, false, 'Time offered'),
  _QuickAct('Knowledge', Icons.menu_book_outlined, false, 'Teaching or learning'),
  _QuickAct('Prayer', Icons.self_improvement_outlined, false, "Du'a for others"),
  _QuickAct('Volunteer Work', Icons.volunteer_activism_outlined, false, 'Community service'),
  _QuickAct('Support Family', Icons.groups_outlined, false, 'Upholding family ties'),
  _QuickAct('Visit the Sick', Icons.local_hospital_outlined, false, 'Comforting the ill'),
  _QuickAct('Smile', Icons.sentiment_satisfied_alt_outlined, false, 'A simple charity'),
  _QuickAct('Helping Someone', Icons.handshake_outlined, false, 'Physical support'),
  _QuickAct('Other', Icons.add_circle_outline, false, 'Another good deed'),
];

const List<String> _categories = [
  'Sadaqah',
  'Sadaqah Jariyah',
  'Zakat',
  'Kindness',
  'Volunteer',
  'Knowledge',
  'Support',
  'Community',
  'Other',
];

const List<String> _currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'SAR', 'AED', 'MYR', 'IDR', 'Other'];

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class AddActScreen extends StatefulWidget {
  const AddActScreen({super.key});

  @override
  State<AddActScreen> createState() => _AddActScreenState();
}

class _AddActScreenState extends State<AddActScreen> with TickerProviderStateMixin {
  // ── Step tracking ──
  int _step = -1;

  // ── Form data ──
  String _selectedAct = '';
  bool _isFinancial = false;
  String amount = '';
  String _currency = 'USD';
  String _category = '';
  final TextEditingController _niyyahController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  String _privacy = 'private';
  String? _photoPath;
  String? _locationName;

  // ── Animation controllers ──
  late final AnimationController _fadeController;
  late final AnimationController _dropController;
  late final AnimationController _glowController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _dropAnimation;
  late final Animation<double> _glowAnimation;

  // ── Step animation ──
  late final AnimationController _stepSlideController;
  late final Animation<Offset> _stepSlideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dropAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInOutBack),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _stepSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stepSlideAnimation = Tween<Offset>(
      begin: const Offset(0.12, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _stepSlideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _stepSlideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dropController.dispose();
    _glowController.dispose();
    _stepSlideController.dispose();
    _niyyahController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  void _selectAct(String label, bool financial) {
    setState(() {
      _selectedAct = label;
      _isFinancial = financial;
    });
    _advance();
  }

  void _advance() {
    HapticFeedback.lightImpact();
    _stepSlideController.reset();
    setState(() => _step = (_step + 1).clamp(-1, 7));
    _stepSlideController.forward();
    _fadeController.forward(from: 0.0);
  }

  void _goBack() {
    if (_step <= 0) {
      context.pop();
      return;
    }
    HapticFeedback.selectionClick();
    _stepSlideController.reset();
    setState(() => _step -= 1);
    _stepSlideController.forward();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    setState(() {
      _step = 7;
    });
    _dropController.forward(from: 0.0);
    _glowController.forward(from: 0.0);

    // Ceramic sound simulation via haptic pattern
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
    Future.delayed(const Duration(milliseconds: 400), () => HapticFeedback.lightImpact());

    // Auto-return to home
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      context.pop();
    });
  }

  // ───────────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      body: SafeArea(
        child: Stack(
          children: [
            // Background paper texture
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperTexturePainter(),
              ),
            ),

            // Top bar (hidden during save animation)
            if (_step < 7)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

            // Main content
            Positioned.fill(
              top: _step < 7 ? 60 : 0,
              child: AnimatedBuilder(
                animation: _stepSlideAnimation,
                builder: (context, child) => SlideTransition(
                  position: _stepSlideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: child,
                  ),
                ),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // TOP BAR
  // ───────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _TopBarButton(
            icon: Icons.arrow_back_ios_new,
            onTap: _goBack,
          ),

          // Step indicators
          if (_step >= 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (index) {
                final active = _step == index;
                final past = _step > index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(left: 5),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? _bronze
                        : past
                            ? _bronzeLight
                            : _clayLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),

          // Close button
          _TopBarButton(
            icon: Icons.close,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP CONTENT
  // ───────────────────────────────────────────────────────────

  Widget _buildStepContent() {
    switch (_step) {
      case -1:
        return _buildEmptyState();
      case 0:
        return _buildActSelection();
      case 1:
        return _buildDetails();
      case 2:
        return _buildNiyyah();
      case 3:
        return _buildReflection();
      case 4:
        return _buildPhoto();
      case 5:
        return _buildLocation();
      case 6:
        return _buildPrivacy();
      case 7:
        return _buildSaveAnimation();
      default:
        return _buildEmptyState();
    }
  }

  // ───────────────────────────────────────────────────────────
  // STEP -1: EMPTY STATE
  // ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Ceramic jar illustration
          SizedBox(
            width: 200,
            height: 240,
            child: CustomPaint(
              painter: _CeramicJarPainter(empty: true, glow: 0.0),
            ),
          ),

          const SizedBox(height: 28),

          // Warm morning light effect
          Container(
            width: 120,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _bronzeLight.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Every journey begins\nwith a single act.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Your jar is waiting. Each sincere deed,\nno matter how small, fills it with light.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _stone,
              fontFamily: 'Georgia',
            ),
          ),

          const Spacer(flex: 2),

          // Primary button
          _MizanButton(
            label: 'Record Your First Act',
            onTap: () {
              HapticFeedback.lightImpact();
              _advance();
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 0: ACT SELECTION
  // ───────────────────────────────────────────────────────────

  Widget _buildActSelection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Heading
          const Text(
            'What did you do\ntoday?',
            style: TextStyle(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Every sincere act, no matter how small,\ndeserves to be remembered.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: _stone,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 16),

          // Date display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _clay),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _bronze.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, size: 16, color: _bronze),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '14 Ramadan 1445 AH',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _walnut,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Monday, April 1, 2024',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.5,
                        color: _stonePale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Acts grid
          Expanded(
            child: GridView.builder(
              itemCount: _quickActs.length,
              padding: const EdgeInsets.only(bottom: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final act = _quickActs[index];
                return _QuickActCard(
                  act: act,
                  index: index,
                  onTap: () => _selectAct(act.label, act.isFinancial),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 1: DETAILS (Amount or Description)
  // ───────────────────────────────────────────────────────────

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Step label
          _StepLabel(text: 'Details'),

          const SizedBox(height: 6),

          Text(
            _isFinancial ? 'How much did you give?' : 'Would you like to describe\nwhat happened?',
            style: const TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _isFinancial ? 'Optional — only what you remember.' : 'Optional — a few words or a full entry.',
            style: TextStyle(
              fontSize: 12,
              color: _stone,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _isFinancial ? _buildFinancialFields() : _buildDescriptionField(),
          ),

          const SizedBox(height: 12),

          _MizanButton(
            label: 'Continue',
            onTap: _advance,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialFields() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount field
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _clay),
              boxShadow: [
                BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2.2,
                    color: _stonePale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 40,
                          color: _bronzeLight,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => amount = v),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 44,
                          fontFamily: 'Georgia',
                          color: _walnut,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                          hintStyle: TextStyle(color: _clayLight),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Currency selector
          const Text(
            'CURRENCY',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2.2,
              color: _stonePale,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currencies.map((c) {
              final selected = _currency == c;
              return GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _bronze : _paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? _bronze : _clay,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: _bronze.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? _white : _stone,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Category
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 2.2,
              color: _stonePale,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final selected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _bronze : _paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? _bronze : _clay,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: _bronze.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? _white : _stone,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _clay),
        boxShadow: [
          BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 18,
          height: 1.6,
          fontFamily: 'Georgia',
          color: _walnut,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Write a few words about what you did...',
          hintStyle: TextStyle(color: _clayLight, fontFamily: 'Georgia'),
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 2: PRIVATE NIYYAH
  // ───────────────────────────────────────────────────────────

  Widget _buildNiyyah() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _StepLabel(text: 'Private Intention'),

          const SizedBox(height: 6),

          const Text(
            'What was in your\nheart today?',
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          const Row(
            children: [
              Icon(Icons.lock_outline, size: 13, color: _bronzeLight),
              SizedBox(width: 6),
              Text(
                'Only you can see this.',
                style: TextStyle(
                  fontSize: 12,
                  color: _stone,
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Journal-style text area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _clay),
                boxShadow: [
                  BoxShadow(color: _shadowWarm, blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: CustomPaint(
                painter: _JournalLinePainter(),
                child: TextField(
                  controller: _niyyahController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.8,
                    fontFamily: 'Georgia',
                    color: _walnut,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write your niyyah...',
                    hintStyle: TextStyle(
                      color: _clayLight,
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MizanOutlineButton(
                  label: 'Skip',
                  onTap: _advance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _MizanButton(
                  label: 'Continue',
                  onTap: _advance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 3: REFLECTION
  // ───────────────────────────────────────────────────────────

  Widget _buildReflection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _StepLabel(text: 'Reflection'),

          const SizedBox(height: 6),

          const Text(
            'Would you like to\nremember anything\nabout today?',
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Optional — a quiet moment to reflect.',
            style: TextStyle(
              fontSize: 12,
              color: _stone,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),

          // Prompt suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PromptChip(label: 'How did this make you feel?'),
              _PromptChip(label: 'What are you grateful for?'),
              _PromptChip(label: 'What did you learn today?'),
            ],
          ),

          const SizedBox(height: 16),

          // Reflection field
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _clay),
                boxShadow: [
                  BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: _reflectionController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  fontFamily: 'Georgia',
                  color: _walnut,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your reflection...',
                  hintStyle: TextStyle(
                    color: _clayLight,
                    fontFamily: 'Georgia',
                    fontStyle: FontStyle.italic,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MizanOutlineButton(
                  label: 'Skip',
                  onTap: _advance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _MizanButton(
                  label: 'Continue',
                  onTap: _advance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 4: PHOTO
  // ───────────────────────────────────────────────────────────

  Widget _buildPhoto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _StepLabel(text: 'Memory'),

          const SizedBox(height: 6),

          const Text(
            'Add a photo?',
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Optional — capture a moment from today.',
            style: TextStyle(
              fontSize: 12,
              color: _stone,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // In production, use image_picker
                  setState(() {
                    _photoPath = _photoPath == null ? 'placeholder' : null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: _photoPath != null ? _paper : _paper,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _photoPath != null ? _bronzeLight : _clay,
                      width: _photoPath != null ? 1.5 : 1.0,
                    ),
                    boxShadow: _photoPath != null
                        ? [
                            BoxShadow(color: _shadowWarm, blurRadius: 16, offset: const Offset(0, 6)),
                          ]
                        : [
                            BoxShadow(color: _shadow, blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                  ),
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Placeholder for actual image
                              Container(
                                color: _mutedOliveLight.withValues(alpha: 0.3),
                                child: const Center(
                                  child: Icon(Icons.image_outlined, size: 64, color: _mutedOlive),
                                ),
                              ),
                              // Editorial overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        _walnut.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.camera_alt_outlined, size: 14, color: _white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Tap to change',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Remove button
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photoPath = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: _walnut),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _bronze.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, size: 28, color: _bronzeLight),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add a memory',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _walnut,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera or gallery',
                              style: TextStyle(
                                fontSize: 11,
                                color: _stoneLight,
                                fontFamily: 'Georgia',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MizanOutlineButton(
                  label: 'Skip',
                  onTap: _advance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _MizanButton(
                  label: 'Continue',
                  onTap: _advance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 5: LOCATION
  // ───────────────────────────────────────────────────────────

  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _StepLabel(text: 'Location'),

          const SizedBox(height: 6),

          const Text(
            'Where were you?',
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Optional — a place to remember.',
            style: TextStyle(
              fontSize: 12,
              color: _stone,
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 24),

          // Current location option
          _LocationOption(
            icon: Icons.my_location_outlined,
            title: 'Use current location',
            subtitle: 'Automatically detect where you are',
            selected: _locationName == 'current',
            onTap: () {
              setState(() => _locationName = _locationName == 'current' ? null : 'current');
            },
          ),

          const SizedBox(height: 12),

          // Manual location option
          _LocationOption(
            icon: Icons.search_outlined,
            title: 'Choose a place',
            subtitle: 'Search or type a location',
            selected: _locationName != null && _locationName != 'current',
            onTap: () {
              // In production, show a search dialog
              setState(() => _locationName = 'Al-Masjid an-Nabawi');
            },
          ),

          // Place tag if selected
          if (_locationName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _bronzeLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: _bronze),
                  const SizedBox(width: 8),
                  Text(
                    _locationName == 'current' ? 'Current Location' : _locationName!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _walnut,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _locationName = null),
                    child: const Icon(Icons.close, size: 14, color: _stonePale),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: _MizanOutlineButton(
                  label: 'Skip',
                  onTap: _advance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _MizanButton(
                  label: 'Continue',
                  onTap: _advance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 6: PRIVACY
  // ───────────────────────────────────────────────────────────

  Widget _buildPrivacy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          const _StepLabel(text: 'Privacy'),

          const SizedBox(height: 6),

          const Text(
            'Who can see this?',
            style: TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: _walnut,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Choose who may witness this act.',
            style: TextStyle(
              fontSize: 12,
              color: _stone,
              fontFamily: 'Georgia',
            ),
          ),

          const SizedBox(height: 20),

          // Private
          _PrivacyCard(
            icon: Icons.lock_outlined,
            title: 'Private',
            description: 'Only visible to you.\nA personal moment between you and your Creator.',
            selected: _privacy == 'private',
            onTap: () => setState(() => _privacy = 'private'),
          ),

          const SizedBox(height: 12),

          // Family
          _PrivacyCard(
            icon: Icons.groups_outlined,
            title: 'Share with Family',
            description: 'Visible inside your Family Jar.\nInspire your loved ones with your sincerity.',
            selected: _privacy == 'family',
            onTap: () => setState(() => _privacy = 'family'),
          ),

          const SizedBox(height: 12),

          // Anonymous
          _PrivacyCard(
            icon: Icons.visibility_off_outlined,
            title: 'Anonymous',
            description: 'Contributes to your Family Jar\nwithout revealing your identity.',
            selected: _privacy == 'anonymous',
            onTap: () => setState(() => _privacy = 'anonymous'),
          ),

          const Spacer(),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _clay),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _bronze.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.checklist_outlined, size: 20, color: _bronze),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAct.isNotEmpty ? _selectedAct : 'Act of goodness',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _walnut,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _privacy == 'private'
                            ? 'Only you can see this'
                            : _privacy == 'family'
                                ? 'Shared with your Family Jar'
                                : 'Anonymous contribution',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _stoneLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _MizanButton(
            label: 'Add to My Jar',
            onTap: _save,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // STEP 7: SAVE ANIMATION
  // ───────────────────────────────────────────────────────────

  Widget _buildSaveAnimation() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Ceramic jar with glow
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 200,
                  height: 260,
                  child: CustomPaint(
                    painter: _CeramicJarPainter(
                      empty: false,
                      glow: _glowAnimation.value,
                    ),
                  ),
                );
              },
            ),

            // Bronze drop falling
            AnimatedBuilder(
              animation: _dropAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _dropAnimation.value),
                  child: Opacity(
                    opacity: _dropAnimation.value < 0 ? 1.0 : (1.0 - _dropAnimation.value * 0.5).clamp(0.0, 1.0),
                    child: Container(
                      width: 12,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _bronze,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _bronze.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Confirmation text
            const Text(
              'Your act has been added.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: _walnut,
                fontFamily: 'Georgia',
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'May Allah accept it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: _bronze,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            // Ripple rings
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_glowAnimation.value > 0.3)
                        Container(
                          width: 80 * _glowAnimation.value,
                          height: 80 * _glowAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _bronzeLight.withValues(alpha: (1.0 - _glowAnimation.value) * 0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      if (_glowAnimation.value > 0.6)
                        Container(
                          width: 120 * (_glowAnimation.value - 0.3) / 0.7,
                          height: 120 * (_glowAnimation.value - 0.3) / 0.7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _bronzeLight.withValues(alpha: (1.0 - _glowAnimation.value) * 0.2),
                              width: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────────

// ── Top bar button ──
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _clay),
          boxShadow: [
            BoxShadow(color: _shadow, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 16, color: _walnutLight),
      ),
    );
  }
}

// ── Step label ──
class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bronze.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w700,
          color: _bronze,
        ),
      ),
    );
  }
}

// ── Quick Act Card ──
class _QuickActCard extends StatefulWidget {
  final _QuickAct act;
  final int index;
  final VoidCallback onTap;

  const _QuickActCard({
    required this.act,
    required this.index,
    required this.onTap,
  });

  @override
  State<_QuickActCard> createState() => _QuickActCardState();
}

class _QuickActCardState extends State<_QuickActCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_hoverAnimation.value * 3),
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _hoverController.forward(),
          onTapUp: (_) => _hoverController.reverse(),
          onTapCancel: () => _hoverController.reverse(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _clay),
              boxShadow: [
                BoxShadow(
                  color: _shadow,
                  blurRadius: 8 + _hoverAnimation.value * 4,
                  offset: Offset(0, 3 + _hoverAnimation.value * 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _bronze.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.act.icon, size: 20, color: _bronze),
                ),
                const Spacer(),
                Text(
                  widget.act.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _walnut,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.act.subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    color: _stoneLight,
                    fontFamily: 'Georgia',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Prompt Chip ──
class _PromptChip extends StatelessWidget {
  final String label;
  const _PromptChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _clay),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: _stone,
          fontFamily: 'Georgia',
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Location Option ──
class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LocationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _paper : _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _bronzeLight : _clay,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _shadowWarm, blurRadius: 10, offset: const Offset(0, 3))]
              : [BoxShadow(color: _shadow, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? _bronze.withValues(alpha: 0.1) : _clayPale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: selected ? _bronze : _stoneLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? _bronzeDark : _walnut,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: _stoneLight,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _bronze : Colors.transparent,
                border: Border.all(
                  color: selected ? _bronze : _clay,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: _white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Privacy Card ──
class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? _paper : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _bronzeLight : _clay,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _bronze.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(color: _shadow, blurRadius: 6, offset: const Offset(0, 2)),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? _bronze.withValues(alpha: 0.1) : _clayPale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: selected ? _bronze : _stoneLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? _bronzeDark : _walnut,
                          fontFamily: 'Georgia',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? _bronze : Colors.transparent,
                          border: Border.all(
                            color: selected ? _bronze : _clay,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 11, color: _white)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: _stone,
                      fontFamily: 'Georgia',
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
}

// ── Primary Button ──
class _MizanButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _MizanButton({required this.label, required this.onTap});

  @override
  State<_MizanButton> createState() => _MizanButtonState();
}

class _MizanButtonState extends State<_MizanButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final scale = 1.0 - _pressAnimation.value * 0.02;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _bronze,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _bronze.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outline Button ──
class _MizanOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _MizanOutlineButton({required this.label, required this.onTap});

  @override
  State<_MizanOutlineButton> createState() => _MizanOutlineButtonState();
}

class _MizanOutlineButtonState extends State<_MizanOutlineButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressAnimation,
      builder: (context, child) {
        final scale = 1.0 - _pressAnimation.value * 0.02;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _clay),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _stone,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────

// ── Paper Texture ──
class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _ivory
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle paper grain
    final grainPaint = Paint()
      ..color = _walnut.withValues(alpha: 0.015)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = random.nextDouble() * 2 + 0.5;
      final h = random.nextDouble() * 2 + 0.5;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Journal Line Painter ──
class _JournalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _clay.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const double lineHeight = 30.0;
    final double startY = 8.0;

    for (double y = startY; y < size.height; y += lineHeight) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Ceramic Jar Painter ──
class _CeramicJarPainter extends CustomPainter {
  final bool empty;
  final double glow;

  _CeramicJarPainter({required this.empty, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow effect
    if (glow > 0) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _bronzeLight.withValues(alpha: glow * 0.15),
            _bronzeLight.withValues(alpha: glow * 0.05),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy + 20), radius: 120));
      canvas.drawCircle(Offset(cx, cy + 20), 120, glowPaint);
    }

    // Jar body
    final jarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: empty
            ? [
                const Color(0xFFE8D8C7),
                const Color(0xFFD9C4AF),
                const Color(0xFFC9B09A),
              ]
            : [
                const Color(0xFFE8D8C7),
                const Color(0xFFD9C4AF),
                const Color(0xFFC9B09A),
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(cx - 60, cy - 80, 120, 160));

    // Jar path
    final jarPath = Path()
      ..moveTo(cx - 40, cy - 80) // Neck left
      ..quadraticBezierTo(cx - 50, cy - 75, cx - 55, cy - 60) // Neck curve
      ..quadraticBezierTo(cx - 60, cy - 40, cx - 58, cy - 20) // Shoulder
      ..lineTo(cx - 55, cy + 40) // Body left
      ..quadraticBezierTo(cx - 50, cy + 70, cx - 30, cy + 75) // Bottom curve left
      ..lineTo(cx + 30, cy + 75) // Bottom
      ..quadraticBezierTo(cx + 50, cy + 70, cx + 55, cy + 40) // Bottom curve right
      ..lineTo(cx + 58, cy - 20) // Body right
      ..quadraticBezierTo(cx + 60, cy - 40, cx + 55, cy - 60) // Shoulder right
      ..quadraticBezierTo(cx + 50, cy - 75, cx + 40, cy - 80) // Neck right
      ..close();

    canvas.drawPath(jarPath, jarPaint);

    // Jar rim
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFD4BFA8),
          Color(0xFFC4AD94),
          Color(0xFFB89E84),
        ],
      ).createShader(Rect.fromLTWH(cx - 42, cy - 88, 84, 16));

    final rimPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 82), width: 84, height: 14),
        const Radius.circular(7),
      ));
    canvas.drawPath(rimPath, rimPaint);

    // Inner rim (dark opening)
    final innerPaint = Paint()..color = const Color(0xFF8B7A6A);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 82), width: 60, height: 10),
      innerPaint,
    );

    // Content (light inside jar if not empty)
    if (!empty) {
      final contentPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            _bronzeLight.withValues(alpha: 0.3),
            _bronzeLight.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy + 10), radius: 40));

      canvas.drawCircle(Offset(cx, cy + 10), 40, contentPaint);

      // Small light dots inside
      final dotPaint = Paint()..color = _bronzeLight.withValues(alpha: 0.2);
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final r = 12.0 + (i % 3) * 8.0;
        final dx = cx + math.cos(angle) * r;
        final dy = cy + 5 + math.sin(angle) * r * 0.5;
        canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
      }
    }

    // Highlight/shine
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _white.withValues(alpha: 0.15),
          _white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cx - 50, cy - 70, 30, 100));

    final shinePath = Path()
      ..moveTo(cx - 45, cy - 65)
      ..quadraticBezierTo(cx - 40, cy - 30, cx - 42, cy + 10)
      ..quadraticBezierTo(cx - 38, cy + 20, cx - 35, cy + 30)
      ..lineTo(cx - 30, cy + 30)
      ..quadraticBezierTo(cx - 33, cy + 10, cx - 35, cy - 30)
      ..quadraticBezierTo(cx - 38, cy - 60, cx - 45, cy - 65)
      ..close();
    canvas.drawPath(shinePath, shinePaint);

    // Decorative line on jar
    final linePaint = Paint()
      ..color = _bronzeLight.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final linePath = Path()
      ..moveTo(cx - 48, cy - 10)
      ..quadraticBezierTo(cx, cy - 5, cx + 48, cy - 10);
    canvas.drawPath(linePath, linePaint);

    // Bottom decorative line
    final bottomLinePath = Path()
      ..moveTo(cx - 45, cy + 45)
      ..quadraticBezierTo(cx, cy + 50, cx + 45, cy + 45);
    canvas.drawPath(bottomLinePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CeramicJarPainter oldDelegate) {
    return oldDelegate.empty != empty || oldDelegate.glow != glow;
  }
}