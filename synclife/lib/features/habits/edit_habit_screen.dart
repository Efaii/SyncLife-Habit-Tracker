import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/habit_model.dart';
import 'habit_repository.dart';
import '../home/dashboard_screen.dart'; // For habitsFutureProvider
import '../../utils/ui_helper.dart';
import 'widgets/icon_color_picker.dart';

class EditHabitScreen extends ConsumerStatefulWidget {
  final HabitModel habit;

  const EditHabitScreen({super.key, required this.habit});

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  TimeOfDay? _selectedTime;
  String? _selectedIcon;
  String? _selectedColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit.namaHabit);
    _nameController.addListener(() {
      setState(() {});
    });

    _selectedIcon = widget.habit.ikon;
    _selectedColor = widget.habit.warnaTag;
    
    // Parse targetWaktu (HH:mm or HH:mm:ss)
    final parts = widget.habit.targetWaktu.split(':');
    if (parts.length >= 2) {
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0, 
        minute: int.tryParse(parts[1]) ?? 0
      );
    }

    // Trigger UI refresh to ensure grid re-renders with correct initial DB values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedIcon = widget.habit.ikon;
          _selectedColor = widget.habit.warnaTag;
        });
      }
    });
  }

  bool get hasChanges {
    if (_nameController.text.trim() != widget.habit.namaHabit) return true;
    if (_selectedIcon != widget.habit.ikon) return true;
    if (_selectedColor != widget.habit.warnaTag) return true;

    if (_selectedTime != null) {
      final initialParts = widget.habit.targetWaktu.split(':');
      if (initialParts.length >= 2) {
        final initialHour = int.tryParse(initialParts[0]) ?? 0;
        final initialMinute = int.tryParse(initialParts[1]) ?? 0;
        if (_selectedTime!.hour != initialHour || _selectedTime!.minute != initialMinute) return true;
      } else {
        return true;
      }
    } else {
      if (widget.habit.targetWaktu.isNotEmpty) return true;
    }
    return false;
  }

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
    if (_selectedIcon == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih ikon dan warna terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(habitRepositoryProvider);
      
      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final updatedHabit = HabitModel(
        idHabit: widget.habit.idHabit,
        namaHabit: _nameController.text.trim(),
        ikon: _selectedIcon!,
        targetWaktu: timeString,
        warnaTag: _selectedColor!,
        createdAt: widget.habit.createdAt,
      );

      await repo.updateHabit(updatedHabit);

      // Refresh Dashboard
      ref.invalidate(habitsProvider);

      if (mounted) {
        Navigator.pop(context);
        UIHelper.showSuccessSnackbar(context, 'Kebiasaan berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan pada sistem. Silakan coba lagi.');
      }
    }
  }

  Future<void> _selectTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
    final textColor = theme.colorScheme.onSurface;

    return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Kebiasaan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Kebiasaan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kebiasaan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              
              IconAndColorPicker(
                selectedIcon: _selectedIcon ?? '',
                selectedColor: _selectedColor ?? '',
                onIconSelected: (val) => setState(() => _selectedIcon = val),
                onColorSelected: (val) => setState(() => _selectedColor = val),
              ),
              const SizedBox(height: 28),

              Text('Target Waktu', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime != null 
                            ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Pilih waktu',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _selectedTime != null ? textColor : theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Removed old color selector
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || !hasChanges) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
