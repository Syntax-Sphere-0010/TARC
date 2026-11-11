import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_state.dart';
import '../services/event_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class SupabaseStatusSheet extends StatefulWidget {
  final AppState appState;

  const SupabaseStatusSheet({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SupabaseStatusSheet(appState: appState),
    );
  }

  @override
  State<SupabaseStatusSheet> createState() => _SupabaseStatusSheetState();
}

class _SupabaseStatusSheetState extends State<SupabaseStatusSheet> {
  final SupabaseService _supabase = SupabaseService.instance;
  bool _isTestingConnection = false;
  bool _isSyncingData = false;
  Map<String, dynamic>? _testResult;

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    final result = await _supabase.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testResult = result;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _runSync() async {
    setState(() => _isSyncingData = true);
    HapticFeedback.lightImpact();

    try {
      await EventService.instance.syncWithSupabase();
      await widget.appState.syncGoalsWithSupabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedules and Goals synced with Supabase successfully!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync note: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final primaryColor = AppTheme.primaryOrange;
    final isConnected = _supabase.isInitialized;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: Color(0xFF3ECF8E), // Supabase Green
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supabase Cloud Database',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time Schedule & Goal Cloud Sync',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSub(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: AppTheme.textSub(isDark)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF241F1A) : const Color(0xFFFFF9F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isConnected
                    ? const Color(0xFF3ECF8E).withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFF3ECF8E) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Service Ready & Active' : 'Disconnected',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isConnected ? const Color(0xFF3ECF8E) : Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Project: helwfjurt...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSub(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Endpoint: https://helwfjurtvgzfnfvbwlr.supabase.co',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Auth: ${_supabase.currentUser?.email ?? "Guest Mode (Local & Cloud Sync Active)"}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSub(isDark),
                  ),
                ),
              ],
            ),
          ),

          // Test Result Card if available
          if (_testResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_testResult!['success'] == true)
                    ? (isDark ? const Color(0xFF1B3520) : const Color(0xFFE8F5E9))
                    : (isDark ? const Color(0xFF3C1F1F) : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    (_testResult!['success'] == true)
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: (_testResult!['success'] == true)
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _testResult!['message']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (_testResult!['success'] == true)
                                ? (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20))
                                : (isDark ? const Color(0xFFEF9A9A) : const Color(0xFFB71C1C)),
                          ),
                        ),
                        if (_testResult!['latencyMs'] != null &&
                            (_testResult!['latencyMs'] as int) > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Latency: ${_testResult!['latencyMs']} ms',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: Test Connection & Sync Now
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingConnection ? null : _runConnectionTest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF5A4D40) : const Color(0xFFD7CCC8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isTestingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.speed_rounded, size: 18),
                  label: Text(
                    _isTestingConnection ? 'Testing...' : 'Test Connection',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSyncingData ? null : _runSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSyncingData
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    _isSyncingData ? 'Syncing...' : 'Sync Now',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Note about SQL schema
          Center(
            child: Text(
              'Schema script saved to supabase_schema.sql in project root',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSub(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
