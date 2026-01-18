import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardStats {
  final int totalCustomers;
  final int activeJobs;
  final double todayIncome;
  final DateTime? lastUpdated;

  DashboardStats({
    this.totalCustomers = 0,
    this.activeJobs = 0,
    this.todayIncome = 0.0,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalCustomers': totalCustomers,
      'activeJobs': activeJobs,
      'todayIncome': todayIncome,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCustomers: json['totalCustomers'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      todayIncome: (json['todayIncome'] ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardStats> {
  @override
  Future<DashboardStats> build() async {
    return _loadStats();
  }

  Future<DashboardStats> _loadStats() async {
    final firestore = FirebaseFirestore.instance;
    final prefs = await SharedPreferences.getInstance();

    // 1. Try to load from cache first (if we are loading for the first time)
    // In build(), we want to return something fast.
    // But AsyncNotifier build() must return the Future<Data>.
    // If we return cached data, the state becomes AsyncData(cached).
    // Then we can trigger a refresh in the background?
    // A better pattern for "cache first, then network" in AsyncNotifier:

    DashboardStats? cachedStats;
    try {
      final cachedString = prefs.getString('dashboard_stats');
      if (cachedString != null) {
        cachedStats = DashboardStats.fromJson(jsonDecode(cachedString));
      }
    } catch (e) {
      // Silently ignore cache errors
    }

    // If we have cache, we can return it partially?
    // But we want to try fetching fresh data.
    // If we return cachedStats here, the UI shows it.

    // Strategy:
    // If we have cached stats, we accept them as the "current" truth for now?
    // But we want to auto-refresh if it's stale.
    // Standard AsyncNotifier logic: return the fresh data.

    // To support "show cache then update", we might need to update state manually.
    // But let's try to fetch fresh data.

    int totalCustomers = 0;
    int activeJobs = 0;
    double todayIncome = 0.0;
    bool fetchFailed = false;
    String? errorMessage;

    try {
      // Total Customers
      try {
        final countQuery = await firestore
            .collection('customers')
            .count()
            .get()
            .timeout(const Duration(seconds: 5));
        totalCustomers = countQuery.count ?? 0;
      } catch (e) {
        final snap = await firestore
            .collection('customers')
            .get()
            .timeout(const Duration(seconds: 5));
        totalCustomers = snap.docs.length;
      }

      // Active Jobs
      try {
        final jobsQuery = await firestore
            .collection('job_cards')
            .where(
              'status',
              whereIn: ['Received', 'Inspection', 'InProgress', 'Completed'],
            )
            .count()
            .get()
            .timeout(const Duration(seconds: 5));
        activeJobs = jobsQuery.count ?? 0;
      } catch (e) {
        final snap = await firestore
            .collection('job_cards')
            .get()
            .timeout(const Duration(seconds: 5));
        activeJobs = snap.docs.where((doc) {
          final s = doc.data()['status'] as String?;
          return s != null &&
              ['Received', 'Inspection', 'InProgress', 'Completed'].contains(s);
        }).length;
      }

      // Today Income
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final invoicesQuery = await firestore
          .collection('invoices')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get()
          .timeout(const Duration(seconds: 5));

      for (var doc in invoicesQuery.docs) {
        todayIncome += (doc.data()['total'] ?? 0).toDouble();
      }
    } catch (e) {
      fetchFailed = true;
      errorMessage = e.toString();
    }

    if (!fetchFailed) {
      final newStats = DashboardStats(
        totalCustomers: totalCustomers,
        activeJobs: activeJobs,
        todayIncome: todayIncome,
        lastUpdated: DateTime.now(),
      );

      // Cache it
      try {
        await prefs.setString('dashboard_stats', jsonEncode(newStats.toJson()));
      } catch (e) {
        // Silently ignore cache write errors
      }
      return newStats;
    } else {
      // If fetch failed, return cached stats if available
      if (cachedStats != null) {
        return cachedStats; // Return old data
      }
      throw Exception(errorMessage ?? 'Failed to load dashboard stats.');
    }
  }

  // Method to refresh manually
  Future<void> refresh() async {
    // Invaliding the provider causes a rebuild/refetch
    ref.invalidateSelf();
    await future;
  }
}

final dashboardStatsProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardStats>(() {
      return DashboardNotifier();
    });
