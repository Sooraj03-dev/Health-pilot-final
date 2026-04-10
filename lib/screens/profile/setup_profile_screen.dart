import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/providers/auth_provider.dart';
import 'package:health_pilot/services/profile_service.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/widgets/profile_form_widgets.dart';

// ── Constants ────────────────────────────────────────────────────────────────
const _qualifications = ['MBBS', 'MD', 'MS', 'DM', 'Fellowship', 'Diploma', 'PhD', 'Other'];
const _specializations = [
  'Cardiology', 'Dermatology', 'Emergency Medicine', 'ENT', 'Gastroenterology',
  'General Medicine', 'General Surgery', 'Gynaecology', 'Nephrology', 'Neurology',
  'Neurosurgery', 'Obstetrics', 'Oncology', 'Ophthalmology', 'Orthopaedics',
  'Paediatrics', 'Pathology', 'Psychiatry', 'Pulmonology', 'Radiology',
  'Rheumatology', 'Urology', 'Other',
];
const _experienceOptions = ['< 1 year', '1–3 years', '3–5 years', '5–10 years', '> 10 years'];
const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();

  // Patient
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;

  // Doctor
  String? _qualification;
  String? _specialization;
  String? _experience;

  File? _photoFile;
  bool _isUploadingPhoto = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(String userId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    setState(() { _photoFile = File(result.files.single.path!); _isUploadingPhoto = true; });
    try {
      final bytes = await _photoFile!.readAsBytes();
      final ext = result.files.single.extension ?? 'jpg';
      final fileName = '${userId}.$ext';
      await supabase.storage.from('medical-docs').uploadBinary(
        'photos/$fileName', bytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );
      final url = supabase.storage.from('medical-docs').getPublicUrl('photos/$fileName');
      await ProfileService().updateProfile(userId: userId, avatarUrl: url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.red));
      setState(() => _photoFile = null);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final role = ref.read(authProvider).role;
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    if (role == 'patient' && _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your Date of Birth'), backgroundColor: Colors.red));
      return;
    }
    if (role == 'doctor' && (_qualification == null || _specialization == null || _experience == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ProfileService().updateProfile(
        userId: userId,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        dob: role == 'patient' ? _dob : null,
        gender: role == 'patient' ? _gender : null,
        bloodGroup: role == 'patient' ? _bloodGroup : null,
        highestQualification: role == 'doctor' ? _qualification : null,
        specialization: role == 'doctor' ? _specialization : null,
        experience: role == 'doctor' ? _experience : null,
        profileSetupDone: true,
      );
      await ref.read(authProvider.notifier).refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role;
    final userId = authState.userId;
    final name = authState.fullName ?? '';
    final isPatient = role == 'patient';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome${name.isNotEmpty ? ', $name' : ''}! 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPatient ? 'A few quick details to personalise your care.' : 'Tell us about your practice.',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // Photo Picker
                Center(
                  child: GestureDetector(
                    onTap: userId != null ? () => _pickAndUploadPhoto(userId) : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: AppColors.primaryDark.withAlpha(40),
                          backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                          child: _isUploadingPhoto
                              ? const CircularProgressIndicator(color: AppColors.primaryDark, strokeWidth: 2.5)
                              : (_photoFile == null ? const Icon(Icons.person, size: 54, color: AppColors.primaryDark) : null),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(child: Text('Tap to add your photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                const SizedBox(height: 24),

                // Phone (shared)
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Patient fields ──────────────────────────────
                if (isPatient) ...[
                  // DOB
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryDark)),
                          child: child!,
                        ),
                      );
                      if (d != null) setState(() => _dob = d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth *',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select your date of birth',
                        style: TextStyle(color: _dob != null ? AppColors.textPrimary : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gender segmented
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gender', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _genders.map((g) {
                          final sel = _gender == g;
                          return ChoiceChip(
                            label: Text(g, style: TextStyle(fontSize: 13, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            selected: sel,
                            selectedColor: AppColors.primaryDark,
                            onSelected: (_) => setState(() => _gender = g),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Blood Group
                  AppDropdown(
                    label: 'Blood Group',
                    value: _bloodGroup,
                    items: _bloodGroups,
                    icon: Icons.bloodtype_outlined,
                    onChanged: (v) => setState(() => _bloodGroup = v),
                  ),
                ],

                // ── Doctor fields ───────────────────────────────
                if (!isPatient) ...[
                  AppDropdown(
                    label: 'Highest Qualification *',
                    value: _qualification,
                    items: _qualifications,
                    icon: Icons.school_outlined,
                    required: true,
                    onChanged: (v) => setState(() => _qualification = v),
                  ),
                  const SizedBox(height: 16),
                  SearchableDropdown(
                    label: 'Specialization *',
                    options: _specializations,
                    value: _specialization,
                    hint: 'Search specialization...',
                    onSelected: (v) => setState(() => _specialization = v),
                  ),
                  const SizedBox(height: 16),
                  AppDropdown(
                    label: 'Years of Experience *',
                    value: _experience,
                    items: _experienceOptions,
                    icon: Icons.work_outline,
                    required: true,
                    onChanged: (v) => setState(() => _experience = v),
                  ),
                ],

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploadingPhoto) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
