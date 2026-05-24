class VisitorCount {
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int total;
  final int unique;

  VisitorCount({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
    required this.unique,
  });

  factory VisitorCount.fromJson(Map<String, dynamic> json) {
    return VisitorCount(
      today: json['visitors_today'] ?? 0,
      thisWeek: json['visitors_this_week'] ?? 0,
      thisMonth: json['visitors_this_month'] ?? 0,
      total: json['total_visits'] ?? 0,
      unique: json['unique_visitors'] ?? 0,
    );
  }

  factory VisitorCount.initial() {
    return VisitorCount(
      today: 0,
      thisWeek: 0,
      thisMonth: 0,
      total: 0,
      unique: 0,
    );
  }
}