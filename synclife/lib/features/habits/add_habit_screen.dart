
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/habit_model.dart';
import 'habit_repository.dart';
import '../home/dashboard_screen.dart'; // For habitsFutureProvider
import '../../utils/ui_helper.dart';
import 'widgets/icon_color_picker.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  TimeOfDay? _selectedTime;
  String _selectedIcon = Icons.fitness_center.codePoint.toString();
  String _selectedColor = '#673AB7'; // Deep Purple default
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      UIHelper.showErrorSnackbar(context, 'Pilih target waktu terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(habitRepositoryProvider);
      
      // Format time as HH:mm
      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final newHabit = HabitModel(
        namaHabit: _nameController.text.trim(),
        ikon: _selectedIcon,
        targetWaktu: timeString,
        warnaTag: _selectedColor,
        createdAt: DateTime.now(),
      );

      await repo.createHabit(newHabit);

      // Invalidate dashboard provider so it fetches the new list
      ref.invalidate(habitsProvider);

      if (mounted) {
        Navigator.pop(context);
        UIHelper.showSuccessSnackbar(context, 'Kebiasaan baru berhasil ditambahkan!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showErrorSnackbar(context, 'Error: $e');
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }



@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  
  // Variabel warna dinamis
  final backgroundColor = theme.scaffoldBackgroundColor;
  final textColor = theme.textTheme.bodyMedium?.color ?? (isDarkMode ? Colors.white : Colors.black87);
  final inputFillColor = theme.cardColor;
  final borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

  return Scaffold(
    backgroundColor: backgroundColor,
    appBar: AppBar(
      title: Text(
        'Tambah Kebiasaan',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: textColor),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Kebiasaan
            Text('Nama Kebiasaan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Misal: Olahraga Pagi, Minum Air',
                hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2B3A8C), width: 2)),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
            ),
            
            const SizedBox(height: 28),
            IconAndColorPicker(
              selectedIcon: _selectedIcon,
              selectedColor: _selectedColor,
              onIconSelected: (val) => setState(() => _selectedIcon = val),
              onColorSelected: (val) => setState(() => _selectedColor = val),
            ),
            const SizedBox(height: 28),

            // Target Waktu
            Text('Target Waktu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF2B3A8C)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime != null 
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Pilih waktu...',
                      style: GoogleFonts.inter(fontSize: 16, color: _selectedTime != null ? textColor : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            // Removed Old Color section
            const SizedBox(height: 48),

            // Tombol Simpan
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B3A8C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_isLoading ? 'Menyimpan...' : 'Simpan Kebiasaan', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}