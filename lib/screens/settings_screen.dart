import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/ai_extraction_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _aiService = AIExtractionService();
  final _db = DatabaseService();
  final _apiKeyCtrl = TextEditingController();
  bool _obscureKey = true;
  bool _keyLoaded = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final key = await _aiService.getApiKey();
    final stats = await _db.getStats();
    setState(() {
      _apiKeyCtrl.text = key ?? '';
      _keyLoaded = true;
      _stats = stats;
    });
  }

  Future<void> _saveApiKey() async {
    await _aiService.saveApiKey(_apiKeyCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('API key saved!'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _exportData() async {
    final entries = await _db.getEntriesWithMileage();
    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No data to export'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Odometer (km),Liters,Amount (₹),Rate (₹/L),Mileage (km/L),Notes');
    for (final entry in entries) {
      buffer.writeln(
          '${DateFormat('dd/MM/yyyy').format(entry.date)},'
          '${entry.odometerReading},'
          '${entry.litersFilled},'
          '${entry.amountPaid},'
          '${entry.pricePerLiter},'
          '${entry.mileage?.toStringAsFixed(2) ?? ""},'
          '"${entry.notes ?? ""}"');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('CSV copied to clipboard! Paste into Google Sheets.'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildApiKeySection(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 20),
            _buildExportSection(),
            const SizedBox(height: 20),
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Claude API Key',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Required for AI image extraction',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: AppTheme.accent, size: 16),
                    SizedBox(width: 6),
                    Text('How to get a free API key:',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '1. Go to console.anthropic.com\n'
                  '2. Sign up for a free account\n'
                  '3. Create an API key\n'
                  '4. Paste it here\n\n'
                  'Free tier includes \$5 credit — plenty for hundreds of extractions!',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_keyLoaded)
            TextFormField(
              controller: _apiKeyCtrl,
              obscureText: _obscureKey,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-ant-api03-...',
                prefixIcon: const Icon(Icons.vpn_key_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveApiKey,
              child: const Text('Save API Key'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.accent),
              SizedBox(width: 10),
              Text('Summary',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Fill-ups', '${_stats['totalEntries'] ?? 0}'),
          _summaryRow('Total Distance',
              '${((_stats['totalDistance'] ?? 0.0) as double).toStringAsFixed(0)} km'),
          _summaryRow('Total Fuel Used',
              '${((_stats['totalLiters'] ?? 0.0) as double).toStringAsFixed(1)} L'),
          _summaryRow('Total Spent',
              currencyFormat.format(_stats['totalAmount'] ?? 0.0)),
          _summaryRow(
              'Average Mileage',
              '${((_stats['averageMileage'] ?? 0.0) as double).toStringAsFixed(1)} km/L',
              highlight: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color:
                      highlight ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight:
                      highlight ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_rounded, color: AppTheme.success),
              SizedBox(width: 10),
              Text('Export Data',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Copy your data as CSV and paste into Google Sheets.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportData,
              icon: const Icon(Icons.content_copy_rounded),
              label: const Text('Copy CSV to Clipboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.success,
                side: const BorderSide(color: AppTheme.success),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: AppTheme.warning),
              SizedBox(width: 10),
              Text('How It Works',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'Capture speedometer photo — AI reads the odometer km',
            'Capture fuel machine photo — AI reads liters, rupees, rate',
            'Review the extracted values and correct if needed',
            'Save entry — mileage calculated automatically',
            'Dashboard shows your average mileage and trends',
          ].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
