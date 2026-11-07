import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String league;
  final String team1;
  final String team2;
  final String score1;
  final String score2;
  final String date;
  final String time;
  final String status;
  final String round;
  final String? delegateName;
  final String? delegateEmail;
  final DateTime? timestamp;
  final int? addedTime1;
  final int? addedTime2;
  final String? matchStage;
  final String? timingDisplay;
  final DateTime? firstHalfStartTime;
  final DateTime? secondHalfStartTime;

  MatchModel({
    required this.id,
    required this.league,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    this.date = '',
    required this.time,
    required this.status,
    required this.round,
    this.delegateName,
    this.delegateEmail,
    this.timestamp,
    this.addedTime1,
    this.addedTime2,
    this.matchStage,
    this.timingDisplay,
    this.firstHalfStartTime,
    this.secondHalfStartTime,
  });

  factory MatchModel.fromJson(Map<String, dynamic> data) {
    DateTime? dt;
    if (data['date'] != null && data['time'] != null) {
      dt = DateTime.tryParse('${data['date']} ${data['time']}:00');
    }

    DateTime? fhStart;
    if (data['firstHalfStartTime'] != null) {
      fhStart = DateTime.tryParse(data['firstHalfStartTime'].toString());
    } else if (data['first_half_start_at'] != null) {
      fhStart = DateTime.tryParse(data['first_half_start_at'].toString());
    }

    DateTime? shStart;
    if (data['secondHalfStartTime'] != null) {
      shStart = DateTime.tryParse(data['secondHalfStartTime'].toString());
    } else if (data['second_half_start_at'] != null) {
      shStart = DateTime.tryParse(data['second_half_start_at'].toString());
    }

    final statusStr = data['status']?.toString() ?? 'لم تبدأ';
    final stageStr = data['matchStage']?.toString() ?? data['match_stage']?.toString() ?? '';
    final isLiveOrFinished = statusStr == 'مباشر' ||
        statusStr.contains('الشوط') ||
        statusStr == 'live' ||
        statusStr == 'منتهية' ||
        statusStr == 'انتهت' ||
        statusStr == 'finished' ||
        stageStr == 'first_half' ||
        stageStr == 'second_half' ||
        stageStr == 'half_time' ||
        stageStr == 'finished';

    String s1 = data['score1']?.toString() ?? '';
    String s2 = data['score2']?.toString() ?? '';
    if (isLiveOrFinished) {
      if (s1.isEmpty || s1 == '-') s1 = '0';
      if (s2.isEmpty || s2 == '-') s2 = '0';
    } else {
      if (s1.isEmpty) s1 = '-';
      if (s2.isEmpty) s2 = '-';
    }

    final timing = data['timing_display']?.toString() ?? data['timing_text']?.toString() ?? data['timingDisplay']?.toString();
    final cleanTiming = (timing != null && timing.isNotEmpty && timing != 'null' && timing != 'مبرمجة' && timing != 'scheduled')
        ? timing
        : null;

    return MatchModel(
      id: data['id']?.toString() ?? '',
      league: data['league'] ?? '',
      team1: data['team1'] ?? '',
      team2: data['team2'] ?? '',
      score1: s1,
      score2: s2,
      date: data['date']?.toString() ?? '',
      time: data['time'] ?? '14:30',
      status: statusStr,
      round: data['round'] ?? 'الجولة 1',
      delegateName: data['delegateName'],
      delegateEmail: data['delegateEmail'],
      timestamp: dt,
      addedTime1: (data['addedTime1'] as num?)?.toInt(),
      addedTime2: (data['addedTime2'] as num?)?.toInt(),
      matchStage: stageStr.isNotEmpty ? stageStr : null,
      timingDisplay: cleanTiming,
      firstHalfStartTime: fhStart,
      secondHalfStartTime: shStart,
    );
  }

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? fhStart;
    final st1 = data['firstHalfStartTime'];
    if (st1 is Timestamp) fhStart = st1.toDate();
    else if (st1 is String) fhStart = DateTime.tryParse(st1);

    DateTime? shStart;
    final st2 = data['secondHalfStartTime'];
    if (st2 is Timestamp) shStart = st2.toDate();
    else if (st2 is String) shStart = DateTime.tryParse(st2);

    final timing = data['timingDisplay']?.toString();
    final cleanTiming = (timing != null && timing.isNotEmpty && timing != 'null' && timing != 'مبرمجة' && timing != 'scheduled')
        ? timing
        : null;

    return MatchModel(
      id: doc.id,
      league: data['league'] ?? '',
      team1: data['team1'] ?? '',
      team2: data['team2'] ?? '',
      score1: data['score1']?.toString() ?? '0',
      score2: data['score2']?.toString() ?? '0',
      date: data['date']?.toString() ?? '',
      time: data['time'] ?? '00:00',
      status: data['status'] ?? 'لم تبدأ',
      round: data['round'] ?? 'الجولة 1',
      delegateName: data['delegateName'],
      delegateEmail: data['delegateEmail'] ?? data['delegateId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      addedTime1: (data['addedTime1'] as num?)?.toInt(),
      addedTime2: (data['addedTime2'] as num?)?.toInt(),
      matchStage: data['matchStage']?.toString(),
      timingDisplay: cleanTiming,
      firstHalfStartTime: fhStart,
      secondHalfStartTime: shStart,
    );
  }

  bool get isFinished {
    final s = status.trim().toLowerCase();
    final stg = (matchStage ?? '').trim().toLowerCase();
    return s == 'منتهية' ||
        s == 'انتهت' ||
        s == 'نتيجة' ||
        s == 'finished' ||
        stg == 'finished' ||
        stg == 'منتهية' ||
        stg == 'انتهت' ||
        stg == 'نهاية اللقاء' ||
        stg == 'نهاية المباراة';
  }

  bool get isHalfTime {
    final s = status.trim().toLowerCase();
    final stg = (matchStage ?? '').trim().toLowerCase();
    return s == 'استراحة' ||
        s == 'استراحة بين الشوطين' ||
        s == 'بين الشوطين' ||
        s == 'half_time' ||
        stg == 'half_time' ||
        stg == 'استراحة' ||
        stg == 'استراحة بين الشوطين' ||
        stg == 'بين الشوطين';
  }

  bool get isSecondHalf {
    final s = status.trim().toLowerCase();
    final stg = (matchStage ?? '').trim().toLowerCase();
    return s == 'الشوط الثاني' ||
        stg == 'second_half' ||
        stg == 'الشوط الثاني';
  }

  bool get isLive {
    if (isFinished) return false;
    if (isHalfTime) return true;
    final s = status.trim().toLowerCase();
    final stg = (matchStage ?? '').trim().toLowerCase();
    return s == 'مباشر' ||
        s == 'live' ||
        s == 'الشوط الأول' ||
        s == 'الشوط الثاني' ||
        stg == 'first_half' ||
        stg == 'second_half' ||
        stg == 'الشوط الأول' ||
        stg == 'الشوط الثاني' ||
        stg == 'بين الشوطين' ||
        stg == 'الوقت الإضافي الأول' ||
        stg == 'الوقت الإضافي الثاني' ||
        stg == 'ركلات الترجيح';
  }

  bool get isScheduled => !isLive && !isFinished;

  /// العداد التفاعلي الزمني للمباراة بالدقائق والثواني (Chronomètre MM:SS)
  String get chronometerDisplay {
    if (isFinished) return "انتهت • FT";
    if (isHalfTime) return "استراحة 45:00";

    if (isSecondHalf) {
      DateTime? start = secondHalfStartTime;
      if (start == null && firstHalfStartTime != null) {
        start = firstHalfStartTime!.add(const Duration(minutes: 60));
      }
      if (start != null) {
        final diffSec = DateTime.now().difference(start).inSeconds;
        final clampedDiff = diffSec >= 0 ? diffSec : 0;
        final totalSec = 2700 + clampedDiff; // 45:00 = 2700s
        if (totalSec <= 5400) { // <= 90:00
          final m = (totalSec ~/ 60).toString().padLeft(2, '0');
          final s = (totalSec % 60).toString().padLeft(2, '0');
          return "$m:$s";
        } else {
          final extra = totalSec - 5400;
          final em = (extra ~/ 60).toString().padLeft(2, '0');
          final es = (extra % 60).toString().padLeft(2, '0');
          return "90:00 +$em:$es";
        }
      }
      if (timingDisplay != null && timingDisplay!.contains(':')) {
        return timingDisplay!;
      }
      return "45:00";
    }

    if (isLive) {
      DateTime? start = firstHalfStartTime ?? timestamp;
      if (start != null) {
        final diffSec = DateTime.now().difference(start).inSeconds;
        final clampedDiff = diffSec >= 0 ? diffSec : 0;
        if (clampedDiff <= 2700) { // <= 45:00
          final m = (clampedDiff ~/ 60).toString().padLeft(2, '0');
          final s = (clampedDiff % 60).toString().padLeft(2, '0');
          return "$m:$s";
        } else {
          final extra = clampedDiff - 2700;
          final em = (extra ~/ 60).toString().padLeft(2, '0');
          final es = (extra % 60).toString().padLeft(2, '0');
          return "45:00 +$em:$es";
        }
      }
      if (timingDisplay != null && timingDisplay!.contains(':')) {
        return timingDisplay!;
      }
      return "00:00";
    }

    if (time.isNotEmpty && time != '00:00') return time;
    return status;
  }
}
