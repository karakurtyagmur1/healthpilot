import 'package:healthpilot/features/food/screens/meal_detail_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:healthpilot/features/chat/screens/chat_screen.dart';
import 'package:healthpilot/features/food/widgets/add_food_bottom_sheet.dart';
import 'package:healthpilot/services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _fs = FirestoreService();
  String? _userId;

  // Seçili gün (date-only)
  late DateTime _selectedDate;
  String get _selectedDateKey => _fs.dateKey(_selectedDate);

  DateTime get _todayOnly {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayOnly;
    _initUser();
  }

  Future<void> _initUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;
    setState(() => _userId = user.uid);
  }

  void _goPrevDay() {
    setState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
              .subtract(const Duration(days: 1));
    });
  }

  void _goNextDay() {
    setState(() {
      final next =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
              .add(const Duration(days: 1));
      if (next.isAfter(_todayOnly)) return;
      _selectedDate = next;
    });
  }

  void _goToday() {
    setState(() => _selectedDate = _todayOnly);
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: _todayOnly,
      locale: const Locale('tr', 'TR'),
    );
    if (picked == null) return;
    setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day));
  }

  void _openAddFood(String mealType) {
    if (_userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFoodBottomSheet(
        userId: _userId!,
        mealType: mealType,
        dateKey: _selectedDateKey,
      ),
    );
  }

  // ---------- Helpers ----------

  double _ratio(double consumed, double target) {
    if (target <= 0) return 0;
    return (consumed / target).clamp(0.0, 1.0);
  }

  double _num(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  // Profile doc içinden hedefleri çek (hem eski hem yeni format destek)
  Map<String, double> _extractTargets(Map<String, dynamic>? data) {
    if (data == null) {
      return {'kcal': 0, 'protein': 0, 'carb': 0, 'fat': 0};
    }

    // Yeni format: macroPlan
    final macroPlan = data['macroPlan'] as Map<String, dynamic>?;
    if (macroPlan != null) {
      return {
        'kcal': _num(macroPlan['targetCalories']),
        'protein': _num(macroPlan['proteinG']),
        'carb': _num(macroPlan['carbG']),
        'fat': _num(macroPlan['fatG']),
      };
    }

    // Eski format (geriye uyumluluk)
    return {
      'kcal': _num(data['kcalTarget']),
      'protein': _num(data['proteinTarget']),
      'carb': _num(data['carbTarget']),
      'fat': _num(data['fatTarget']),
    };
  }

  int _weekOfYear(DateTime dt) {
    // Intl ile haftayı alıyoruz (01..53)
    final w = int.tryParse(DateFormat('w').format(dt));
    return w ?? 0;
  }

  Widget _pillIcon(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _bigKcalRing({
    required double consumedKcal,
    required double targetKcal,
    required double burnedKcal,
  }) {
    final cs = Theme.of(context).colorScheme;

    final remaining = (targetKcal - consumedKcal);
    final remainingClamped = remaining.isFinite ? remaining : 0.0;
    final remainingShown =
        (targetKcal <= 0) ? 0.0 : remainingClamped.clamp(0.0, targetKcal);

    final ringRatio = _ratio(consumedKcal, targetKcal);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                consumedKcal.toStringAsFixed(0),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Alınan',
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  valueColor:
                      AlwaysStoppedAnimation(cs.surfaceContainerHighest),
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: ringRatio,
                  strokeWidth: 12,
                  valueColor: AlwaysStoppedAnimation(cs.secondary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingShown.toStringAsFixed(0),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 28),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kalan',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                burnedKcal.toStringAsFixed(0),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Yakılan',
                style: TextStyle(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _macroBar({
    required String title,
    required double consumed,
    required double target,
  }) {
    final cs = Theme.of(context).colorScheme;
    final r = _ratio(consumed, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: r,
            minHeight: 7,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(cs.primary), // ✅ mavi
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _dateRowHeader() {
    final cs = Theme.of(context).colorScheme;
    final isToday = _selectedDateKey == _fs.dateKey(_todayOnly);

    return Row(
      children: [
        IconButton(
          onPressed: _goPrevDay,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Önceki gün',
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openDatePicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    DateFormat('d MMMM, EEEE', 'tr_TR').format(_selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDateKey,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _goNextDay,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Sonraki gün',
        ),
        const SizedBox(width: 6),
        FilledButton.tonal(
          onPressed: isToday ? null : _goToday,
          child: const Text('Bugün'),
        ),
      ],
    );
  }

  Widget _mealRow({
    required String title,
    required String mealType,
    required String dateKey,
    required IconData icon,
    required double targetKcal,
  }) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          _fs.streamFoodsByMealAndDate(_userId!, mealType, dateKey: dateKey),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        double mealKcal = 0;
        final names = <String>[];

        for (final d in docs) {
          final data = d.data();
          mealKcal += _num(data['kcal']);
          final n = (data['name'] ?? '').toString().trim();
          if (n.isNotEmpty) names.add(n);
        }

        final preview = names.isEmpty
            ? 'Henüz öğe eklenmedi'
            : names.take(3).join(', ') + (names.length > 3 ? '…' : '');

        // Referans görüntüde her öğünün kendi hedefi var.
        // Şimdilik basit bir dağıtım: günlük hedef / 4.
        final mealTarget = (targetKcal <= 0) ? 0.0 : (targetKcal / 4.0);
        final ringRatio = _ratio(mealKcal, mealTarget);

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealDetailScreen(
                  userId: _userId!,
                  mealType: mealType,
                  dateKey: dateKey,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // mini ring + icon
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: ringRatio,
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(
                              cs.primary), // ✅ mavi mini halka
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(icon, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // text area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mealKcal.toStringAsFixed(0)} / ${mealTarget.toStringAsFixed(0)} kcal',
                        style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // plus button
                InkWell(
                  onTap: () => _openAddFood(mealType),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(Icons.add, color: cs.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- 7 gün / chart (kalsın) ----

  List<DateTime> _last7Days() {
    final end = _todayOnly;
    final start = end.subtract(const Duration(days: 6));
    return List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  Map<String, double> _sumDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double kcal = 0, p = 0, c = 0, f = 0;
    for (final doc in docs) {
      final d = doc.data();
      kcal += _num(d['kcal']);
      p += _num(d['protein']);
      c += _num(d['carb']);
      f += _num(d['fat']);
    }
    return {'kcal': kcal, 'protein': p, 'carb': c, 'fat': f};
  }

  Widget _weeklyKcalChart({
    required List<Map<String, dynamic>> days,
    required double maxY,
  }) {
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < days.length; i++) {
      final kcal = (days[i]['kcal'] as double);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: kcal,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barGroups: barGroups,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  final dt = days[i]['date'] as DateTime;
                  final label = DateFormat('E', 'tr_TR').format(dt);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dt = days[group.x]['date'] as DateTime;
                final dayLabel = DateFormat('d MMM', 'tr_TR').format(dt);
                return BarTooltipItem(
                  '$dayLabel\n${rod.toY.toStringAsFixed(0)} kcal',
                  const TextStyle(fontWeight: FontWeight.w600),
                );
              },
            ),
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions) return;
              final spot = response?.spot;
              if (spot == null) return;

              final idx = spot.touchedBarGroupIndex;
              if (idx < 0 || idx >= days.length) return;

              final dt = days[idx]['date'] as DateTime;
              setState(
                  () => _selectedDate = DateTime(dt.year, dt.month, dt.day));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final start7 = _todayOnly.subtract(const Duration(days: 6));
    final start7Key = _fs.dateKey(start7);
    final end7Key = _fs.dateKey(_todayOnly);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _fs.streamUserProfile(_userId!),
      builder: (context, profileSnap) {
        if (profileSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ hedefleri burada çıkarıyoruz
        final targets = _extractTargets(profileSnap.data);
        final targetKcal = (targets['kcal'] ?? 0);
        final targetProtein = (targets['protein'] ?? 0);
        final targetCarb = (targets['carb'] ?? 0);
        final targetFat = (targets['fat'] ?? 0);

        final week = _weekOfYear(_selectedDate);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 12,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/healthpilot_logo.png',
                  height:
                      76, // büyütmek için burayı artırabilirsin (örn: 56, 64)
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported),
                ),
                const SizedBox(width: 10),
                const Text('Bugün'),
              ],
            ),
            centerTitle: false,

            // ✅ Title sağdaki ikonlar tarafından ezilmesin diye
            actions: [
              _pillIcon(Icons.diamond_outlined, '0'),
              const SizedBox(width: 8),
              _pillIcon(Icons.local_fire_department_outlined, '0'),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Grafik',
                icon: const Icon(Icons.show_chart),
                onPressed: () {},
              ),
              IconButton(
                tooltip: 'Takvim',
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: _openDatePicker,
              ),
              IconButton(
                tooltip: 'Chat',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        userId: _userId!,
                        selectedDateKey: _selectedDateKey,
                        targets: {
                          'kcal': targetKcal,
                          'protein': targetProtein,
                          'carb': targetCarb,
                          'fat': targetFat,
                        },
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Profil',
                icon: const Icon(Icons.person_outline),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              Text(
                'Bugün',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hafta $week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),

              // Date row (gün seçimi)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.6),
                  ),
                ),
                child: _dateRowHeader(),
              ),

              const SizedBox(height: 16),

              // ÖZET KARTI
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _fs.streamAllFoodsByDate(
                  _userId!,
                  dateKey: _selectedDateKey,
                ),
                builder: (context, snapshot) {
                  double totalKcal = 0, totalP = 0, totalC = 0, totalF = 0;

                  final docs = snapshot.data?.docs ?? [];
                  for (final doc in docs) {
                    final d = doc.data();
                    totalKcal += _num(d['kcal']);
                    totalP += _num(d['protein']);
                    totalC += _num(d['carb']);
                    totalF += _num(d['fat']);
                  }

                  final cs = Theme.of(context).colorScheme;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Özet',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Detaylar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _bigKcalRing(
                          consumedKcal: totalKcal,
                          targetKcal: targetKcal,
                          burnedKcal: 0,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _macroBar(
                                title: 'Karbonhidrat',
                                consumed: totalC,
                                target: targetCarb,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _macroBar(
                                title: 'Protein',
                                consumed: totalP,
                                target: targetProtein,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _macroBar(
                                title: 'Yağ',
                                consumed: totalF,
                                target: targetFat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // BESLENME
              Row(
                children: [
                  const Text(
                    'Beslenme',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('Fazlası')),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _mealRow(
                      title: 'Kahvaltı',
                      mealType: 'breakfast',
                      dateKey: _selectedDateKey,
                      icon: Icons.local_cafe_outlined,
                      targetKcal: targetKcal,
                    ),
                    _mealRow(
                      title: 'Öğle Yemeği',
                      mealType: 'lunch',
                      dateKey: _selectedDateKey,
                      icon: Icons.lunch_dining_outlined,
                      targetKcal: targetKcal,
                    ),
                    _mealRow(
                      title: 'Akşam Yemeği',
                      mealType: 'dinner',
                      dateKey: _selectedDateKey,
                      icon: Icons.dinner_dining_outlined,
                      targetKcal: targetKcal,
                    ),
                    _mealRow(
                      title: 'Atıştırmalık',
                      mealType: 'snack',
                      dateKey: _selectedDateKey,
                      icon: Icons.apple_outlined,
                      targetKcal: targetKcal,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SON 7 GÜN
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _fs.streamFoodsInDateRange(
                  _userId!,
                  startDateKey: start7Key,
                  endDateKey: end7Key,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final Map<String,
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>>
                      byDay = {};

                  for (final d in docs) {
                    final key = (d.data()['date'] ?? '').toString();
                    if (key.isEmpty) continue;
                    byDay.putIfAbsent(key, () => []).add(d);
                  }

                  final last7 = _last7Days();
                  final days = last7.map((day) {
                    final key = _fs.dateKey(day);
                    final sums = _sumDocs(byDay[key] ?? []);
                    return {'date': day, 'dateKey': key, ...sums};
                  }).toList();

                  double wkKcal = 0, wkP = 0, wkC = 0, wkF = 0;
                  double maxDayKcal = 0;

                  for (final d in days) {
                    final k = (d['kcal'] as double);
                    wkKcal += k;
                    wkP += (d['protein'] as double);
                    wkC += (d['carb'] as double);
                    wkF += (d['fat'] as double);
                    if (k > maxDayKcal) maxDayKcal = k;
                  }

                  final double maxY =
                      (maxDayKcal <= 0) ? 100.0 : (maxDayKcal * 1.2);
                  final cs = Theme.of(context).colorScheme;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Son 7 Gün (Kalori)',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text('Toplam: ${wkKcal.toStringAsFixed(0)} kcal'),
                        Text('Protein: ${wkP.toStringAsFixed(0)} g'),
                        Text('Karbonhidrat: ${wkC.toStringAsFixed(0)} g'),
                        Text('Yağ: ${wkF.toStringAsFixed(0)} g'),
                        const SizedBox(height: 12),
                        _weeklyKcalChart(days: days, maxY: maxY),
                        const SizedBox(height: 6),
                        Text(
                          'İpucu: Bir bara dokunarak o güne geçebilirsin.',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
