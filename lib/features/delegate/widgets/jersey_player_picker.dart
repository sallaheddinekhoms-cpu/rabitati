import 'package:flutter/material.dart';

class FootballJerseyWidget extends StatelessWidget {
  final String number;
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final bool isSelected;
  final String? statusBadge; // e.g., 'أساسي', 'احتياطي'
  final VoidCallback? onTap;

  const FootballJerseyWidget({
    super.key,
    required this.number,
    required this.name,
    this.primaryColor = const Color(0xFF1B7A36),
    this.accentColor = Colors.white,
    this.isSelected = false,
    this.statusBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanNumber = number.trim().isEmpty ? '?' : number.trim();
    final cleanName = name.trim().isEmpty ? 'لاعب' : name.trim();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 92,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── شكل القميص الرياضي ─────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // مجسم القميص
                CustomPaint(
                  size: const Size(64, 68),
                  painter: _JerseyPainter(
                    primaryColor: primaryColor,
                    accentColor: accentColor,
                    isSelected: isSelected,
                  ),
                  child: SizedBox(
                    width: 64,
                    height: 68,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          cleanNumber,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: cleanNumber.length > 2 ? 18 : 22,
                            letterSpacing: -0.5,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // شارة الاختيار (Checkmark)
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),

                // شارة الوضع (أساسي / احتياطي)
                if (statusBadge != null)
                  Positioned(
                    bottom: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: statusBadge == 'أساسي' ? Colors.blue.shade700 : Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        statusBadge!,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // ── اسم اللاعب تحت القميص ─────────────────────
            SizedBox(
              width: 82,
              child: Text(
                cleanName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? primaryColor : Colors.black87,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── رسام شكل القميص الرياضي الاحترافي ─────────────────────────
class _JerseyPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool isSelected;

  _JerseyPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // مسار القميص الرياضي (الأكمام، الرقبة، الجذع)
    final path = Path();
    path.moveTo(w * 0.32, 0); // يسار الياقة
    path.quadraticBezierTo(w * 0.5, h * 0.12, w * 0.68, 0); // فتحة الرقبة V
    path.lineTo(w * 0.88, h * 0.08); // الكتف الأيمن
    path.lineTo(w * 1.0, h * 0.34); // الكم الأيمن
    path.lineTo(w * 0.82, h * 0.44); // تحت الإبط الأيمن
    path.lineTo(w * 0.82, h * 0.94); // الجانب الأيمن
    path.quadraticBezierTo(w * 0.5, h * 0.98, w * 0.18, h * 0.94); // الحاشية السفلية
    path.lineTo(w * 0.18, h * 0.44); // تحت الإبط الأيسر
    path.lineTo(0, h * 0.34); // الكم الأيسر
    path.lineTo(w * 0.12, h * 0.08); // الكتف الأيسر
    path.close();

    // خلفية القميص مع تدرج لوني عميق
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withOpacity(0.95),
          primaryColor,
          Color.lerp(primaryColor, Colors.black, 0.25)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // ظل خفيف للقميص
    canvas.drawShadow(path, Colors.black.withOpacity(0.3), 4, false);
    canvas.drawPath(path, paint);

    // خطوط رياضية طولية أنيقة (Pinstripes)
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.36, h * 0.2), Offset(w * 0.36, h * 0.94), stripePaint);
    canvas.drawLine(Offset(w * 0.64, h * 0.2), Offset(w * 0.64, h * 0.94), stripePaint);

    // حواف الياقة
    final collarPaint = Paint()
      ..color = accentColor.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final collarPath = Path();
    collarPath.moveTo(w * 0.32, 0);
    collarPath.quadraticBezierTo(w * 0.5, h * 0.14, w * 0.68, 0);
    canvas.drawPath(collarPath, collarPaint);

    // حدود خارجية للقميص
    final borderPaint = Paint()
      ..color = isSelected ? Colors.amber.shade600 : Colors.white.withOpacity(0.3)
      ..strokeWidth = isSelected ? 2.0 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _JerseyPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.accentColor != accentColor;
  }
}

// ══════════════════════════════════════════════════════════════
// المكون التفاعلي لاختيار اللاعب عبر القمصان والبحث بالرقم
// ══════════════════════════════════════════════════════════════
class JerseyPlayerPicker extends StatefulWidget {
  final List<Map<String, dynamic>> players;
  final String? selectedPlayerId;
  final ValueChanged<Map<String, dynamic>?> onPlayerSelected;
  final String title;
  final Color primaryColor;
  final Color accentColor;
  final String? subtitle;

  const JerseyPlayerPicker({
    super.key,
    required this.players,
    required this.selectedPlayerId,
    required this.onPlayerSelected,
    required this.title,
    this.primaryColor = const Color(0xFF1B7A36),
    this.accentColor = Colors.white,
    this.subtitle,
  });

  @override
  State<JerseyPlayerPicker> createState() => _JerseyPlayerPickerState();
}

class _JerseyPlayerPickerState extends State<JerseyPlayerPicker> {
  final TextEditingController _numberCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filterType = 'all'; // 'all', 'starter', 'sub'

  @override
  void initState() {
    super.initState();
    _syncNumberWithSelected();
  }

  @override
  void didUpdateWidget(covariant JerseyPlayerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlayerId != widget.selectedPlayerId || oldWidget.players != widget.players) {
      _syncNumberWithSelected();
    }
  }

  void _syncNumberWithSelected() {
    if (widget.selectedPlayerId != null && widget.players.isNotEmpty) {
      final found = widget.players.firstWhere(
        (p) => p['id']?.toString() == widget.selectedPlayerId,
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        final numStr = (found['number'] ?? found['jersey_number'] ?? '').toString();
        if (numStr.isNotEmpty && _numberCtrl.text != numStr) {
          _numberCtrl.text = numStr;
        }
      }
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // تحويل الأرقام العربية المشرقية (٠١٢٣٤٥٦٧٨٩) إلى أرقام قياسية (0123456789)
  String _normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';
    String result = input;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result.trim();
  }

  void _onNumberChanged(String val) {
    final clean = _normalizeDigits(val);
    if (clean.isEmpty) return;

    // بحث عن اللاعب المطابق لرقم القميص
    final index = widget.players.indexWhere((p) {
      final num1 = _normalizeDigits((p['number'] ?? '').toString());
      final num2 = _normalizeDigits((p['jersey_number'] ?? '').toString());
      return num1 == clean || num2 == clean;
    });

    if (index != -1) {
      final matchedPlayer = widget.players[index];
      widget.onPlayerSelected(matchedPlayer);

      // تمرير القائمة أوتوماتيكياً ليصل للقميص المطلوب
      if (_scrollController.hasClients) {
        final targetOffset = (index * 96.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية اللاعبين حسب الحالة إن وجدت (أساسي / احتياطي)
    List<Map<String, dynamic>> displayedPlayers = widget.players;
    if (_filterType == 'starter') {
      displayedPlayers = widget.players.where((p) => p['status'] == 'starter').toList();
    } else if (_filterType == 'sub') {
      displayedPlayers = widget.players.where((p) => p['status'] == 'sub').toList();
    }

    final hasStartersAndSubs = widget.players.any((p) => p['status'] == 'starter') &&
        widget.players.any((p) => p['status'] == 'sub');

    // العثور على اللاعب المحدد حالياً
    Map<String, dynamic>? selectedPlayer;
    if (widget.selectedPlayerId != null) {
      selectedPlayer = widget.players.firstWhere(
        (p) => p['id']?.toString() == widget.selectedPlayerId,
        orElse: () => {},
      );
      if (selectedPlayer.isEmpty) selectedPlayer = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primaryColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── عنوان القسم ومؤشر الحالة ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.checkroom, color: widget.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: widget.primaryColor),
                  ),
                ],
              ),
              if (selectedPlayer != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'قميص رقم ${selectedPlayer['number'] ?? selectedPlayer['jersey_number'] ?? ''}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(widget.subtitle!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],

          const SizedBox(height: 10),

          // ── حقل كتابة رقم القميص للبحث والقفز السريع ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.pin, size: 20, color: widget.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: _onNumberChanged,
                    decoration: InputDecoration(
                      hintText: 'اكتب رقم القميص للقفز المباشر (مثال: 10 أو 7)...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_numberCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                    onPressed: () {
                      _numberCtrl.clear();
                      widget.onPlayerSelected(null);
                    },
                  ),
              ],
            ),
          ),

          // ── أزرار التصفية (أساسي / احتياطي) إن وجدت ───────────
          if (hasStartersAndSubs) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFilterChip('all', 'جميع اللاعبين (${widget.players.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('starter', 'الأساسيون بالميدان'),
                const SizedBox(width: 6),
                _buildFilterChip('sub', 'دكة البدلاء'),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // ── شريط تمرير القمصان الرياضية (Horizontal Carousel) ─
          if (displayedPlayers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                'لا يوجد لاعبون مسجلون في هذه القائمة حالياً.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 128,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayedPlayers.length,
                itemBuilder: (context, index) {
                  final p = displayedPlayers[index];
                  final pId = p['id']?.toString() ?? '';
                  final isSelected = pId == widget.selectedPlayerId;
                  final numStr = (p['number'] ?? p['jersey_number'] ?? '').toString();
                  final nameStr = (p['name'] ?? '').toString();
                  final status = p['status'] == 'starter'
                      ? 'أساسي'
                      : (p['status'] == 'sub' ? 'احتياطي' : null);

                  return FootballJerseyWidget(
                    number: numStr,
                    name: nameStr,
                    primaryColor: widget.primaryColor,
                    accentColor: widget.accentColor,
                    isSelected: isSelected,
                    statusBadge: status,
                    onTap: () {
                      widget.onPlayerSelected(p);
                      _numberCtrl.text = numStr;
                    },
                  );
                },
              ),
            ),

          // ── بطاقة توضيح اللاعب المختار حالياً ─────────────────
          if (selectedPlayer != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'اللاعب المحدد: ${selectedPlayer['name'] ?? ''} (قميص رقم ${selectedPlayer['number'] ?? selectedPlayer['jersey_number'] ?? ''})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isCurrent = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isCurrent ? widget.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? widget.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
