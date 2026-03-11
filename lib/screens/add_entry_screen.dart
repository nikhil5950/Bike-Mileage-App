import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/fuel_entry.dart';
import '../services/ai_extraction_service.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/image_capture_card.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aiService = AIExtractionService();
  final _db = DatabaseService();
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  final _odometerCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _speedometerImagePath;
  String? _machineImagePath;
  bool _extractingSpeedometer = false;
  bool _extractingMachine = false;
  bool _saving = false;
  String? _speedometerError;
  String? _machineError;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _odometerCtrl.dispose();
    _litersCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureSpeedometer() async {
    final choice = await _showImageSourceDialog('Speedometer');
    if (choice == null) return;
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await _imagePicker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1024);
    if (picked == null) return;

    setState(() {
      _speedometerImagePath = picked.path;
      _extractingSpeedometer = true;
      _speedometerError = null;
    });

    final result = await _aiService.extractSpeedometerData(picked.path);
    if (!mounted) return;

    setState(() {
      _extractingSpeedometer = false;
      if (result.success && result.odometerReading != null) {
        _odometerCtrl.text = result.odometerReading!.toStringAsFixed(0);
        _showSnack('Odometer reading extracted!', AppTheme.success);
      } else {
        _speedometerError = result.errorMessage;
        _showSnack(result.errorMessage ?? 'Extraction failed', AppTheme.warning);
      }
    });
  }

  Future<void> _captureMachine() async {
    final choice = await _showImageSourceDialog('Fuel Machine');
    if (choice == null) return;
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await _imagePicker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1024);
    if (picked == null) return;

    setState(() {
      _machineImagePath = picked.path;
      _extractingMachine = true;
      _machineError = null;
    });

    final result = await _aiService.extractMachineData(picked.path);
    if (!mounted) return;

    setState(() {
      _extractingMachine = false;
      bool any = false;
      if (result.litersFilled != null) {
        _litersCtrl.text = result.litersFilled!.toStringAsFixed(2);
        any = true;
      }
      if (result.amountPaid != null) {
        _amountCtrl.text = result.amountPaid!.toStringAsFixed(2);
        any = true;
      }
      if (result.pricePerLiter != null) {
        _rateCtrl.text = result.pricePerLiter!.toStringAsFixed(2);
        any = true;
      }
      if (any) {
        _showSnack('Machine data extracted!', AppTheme.success);
      } else {
        _machineError = result.errorMessage;
        _showSnack(result.errorMessage ?? 'Extraction failed', AppTheme.warning);
      }
    });
  }

  Future<String?> _showImageSourceDialog(String type) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textHint,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Capture $type',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _sourceBtn(Icons.camera_alt_rounded, 'Camera',
                        AppTheme.primary, () => Navigator.pop(context, 'camera'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _sourceBtn(Icons.photo_library_rounded, 'Gallery',
                        AppTheme.accent, () => Navigator.pop(context, 'gallery'))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sourceBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final entry = FuelEntry(
      id: _uuid.v4(),
      date: _selectedDate,
      odometerReading: double.parse(_odometerCtrl.text),
      litersFilled: double.parse(_litersCtrl.text),
      amountPaid: double.parse(_amountCtrl.text),
      pricePerLiter: double.parse(_rateCtrl.text),
      speedometerImagePath: _speedometerImagePath,
      machineImagePath: _machineImagePath,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    await _db.insertEntry(entry);
    setState(() => _saving = false);
    _showSnack('Entry saved successfully!', AppTheme.success);
    _clearForm();
  }

  void _clearForm() {
    _odometerCtrl.clear();
    _litersCtrl.clear();
    _amountCtrl.clear();
    _rateCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _speedometerImagePath = null;
      _machineImagePath = null;
      _selectedDate = DateTime.now();
      _speedometerError = null;
      _machineError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Add Fill-up'),
        actions: [
          TextButton(
            onPressed: _clearForm,
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(),
              const SizedBox(height: 20),
              _sectionHeader('📸 Capture Photos', 'AI will extract data automatically'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ImageCaptureCard(
                      title: 'Speedometer',
                      subtitle: 'Odometer reading',
                      icon: Icons.speed_rounded,
                      imagePath: _speedometerImagePath,
                      isLoading: _extractingSpeedometer,
                      error: _speedometerError,
                      onTap: _captureSpeedometer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ImageCaptureCard(
                      title: 'Fuel Machine',
                      subtitle: 'Amount, liters, rate',
                      icon: Icons.local_gas_station_rounded,
                      imagePath: _machineImagePath,
                      isLoading: _extractingMachine,
                      error: _machineError,
                      onTap: _captureMachine,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionHeader('✏️ Fill-up Data', 'Review and edit extracted values'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _odometerCtrl,
                label: 'Odometer Reading',
                hint: 'e.g. 12500',
                icon: Icons.speed_rounded,
                suffix: 'km',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _litersCtrl,
                      label: 'Liters Filled',
                      hint: '0.00',
                      icon: Icons.opacity_rounded,
                      suffix: 'L',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _amountCtrl,
                      label: 'Amount Paid',
                      hint: '0.00',
                      icon: Icons.currency_rupee_rounded,
                      suffix: '₹',
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _rateCtrl,
                label: 'Rate per Liter',
                hint: '0.00',
                icon: Icons.price_change_rounded,
                suffix: '₹/L',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Any remarks...',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveEntry,
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 8),
                            Text('Save Entry',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppTheme.textSecondary),
      ),
      validator: validator,
    );
  }
}
