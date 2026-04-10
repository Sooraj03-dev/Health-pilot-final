import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/providers/auth_provider.dart';
import 'package:health_pilot/services/profile_service.dart';
import 'package:health_pilot/models/user_model.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/widgets/profile_form_widgets.dart';

// ── Constants ────────────────────────────────────────────────────────────────
const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
const _countryCodes = ['+91', '+1', '+44', '+61', '+971', '+65', '+60', '+81'];

const _commonAllergies = [
  'Penicillin', 'Aspirin', 'Ibuprofen', 'Sulfa drugs', 'Latex',
  'Peanuts', 'Tree nuts', 'Shellfish', 'Eggs', 'Dairy', 'Wheat/Gluten',
  'Bee stings', 'Dust mites', 'Pet dander', 'Pollen',
];
const _commonMedications = [
  'Metformin', 'Atorvastatin', 'Amlodipine', 'Losartan', 'Lisinopril',
  'Omeprazole', 'Pantoprazole', 'Levothyroxine', 'Aspirin',
  'Paracetamol', 'Vitamin D', 'Vitamin B12', 'Iron supplements', 'Calcium',
];
const _commonIllnesses = [
  'Diabetes', 'Hypertension', 'Asthma', 'COPD', 'Heart disease',
  'Kidney disease', 'Liver disease', 'Thyroid disorder', 'Cancer',
  'Stroke', 'Epilepsy', 'Arthritis', 'Depression', 'Anxiety',
  'Appendectomy', 'Cholecystectomy', 'Hernia repair', 'Cataract surgery',
];

final patientProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) return null;
  return ProfileService().fetchProfile(userId);
});

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  File? _localPhoto;
  bool _isUploadingPhoto = false;

  // ── Personal section state ─────────────────────
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _gender;
  String? _bloodGroup;
  DateTime? _dob;
  String _countryCode = '+91';
  bool _savingPersonal = false;

  // ── Medical section state ──────────────────────
  List<String> _allergies = [];
  List<String> _medications = [];
  List<String> _illnesses = [];
  bool _savingMedical = false;

  UserProfile? _profile;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile p) {
    if (_profile?.id == p.id) return; // already loaded
    _profile = p;
    _phoneCtrl.text = p.phone ?? '';
    _emergencyCtrl.text = p.emergencyContact ?? '';
    _heightCtrl.text = p.heightCm != null ? p.heightCm.toString() : '';
    _weightCtrl.text = p.weightKg != null ? p.weightKg.toString() : '';
    _gender = p.gender;
    _bloodGroup = p.bloodGroup;
    _dob = p.dob;
    _allergies = List.from(p.allergies);
    _medications = p.medications?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
    _illnesses = p.pastIllnesses?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [];
  }

  Future<void> _pickAndUploadPhoto(String userId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    setState(() { _localPhoto = File(result.files.single.path!); _isUploadingPhoto = true; });
    try {
      final bytes = await _localPhoto!.readAsBytes();
      final ext = result.files.single.extension ?? 'jpg';
      await supabase.storage.from('medical-docs').uploadBinary(
        'photos/$userId.$ext', bytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );
      final url = supabase.storage.from('medical-docs').getPublicUrl('photos/$userId.$ext');
      await ProfileService().updateProfile(userId: userId, avatarUrl: url);
      ref.invalidate(patientProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      setState(() => _localPhoto = null);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _savePersonal(String userId) async {
    setState(() => _savingPersonal = true);
    try {
      await ProfileService().updateProfile(
        userId: userId,
        phone: _phoneCtrl.text.trim().isNotEmpty ? '$_countryCode ${_phoneCtrl.text.trim()}' : null,
        dob: _dob,
        gender: _gender,
        bloodGroup: _bloodGroup,
        heightCm: double.tryParse(_heightCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
        emergencyContact: _emergencyCtrl.text.trim().isNotEmpty ? _emergencyCtrl.text.trim() : null,
      );
      ref.invalidate(patientProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal info saved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  Future<void> _saveMedical(String userId) async {
    setState(() => _savingMedical = true);
    try {
      await ProfileService().updateProfile(
        userId: userId,
        allergies: _allergies,
        medications: _medications.join(','),
        pastIllnesses: _illnesses.join(','),
      );
      ref.invalidate(patientProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical info saved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingMedical = false);
    }
  }

  List<String> _buildPrompts(UserProfile p) {
    final prompts = <String>[];
    if (p.allergies.isEmpty) prompts.add('Add allergies');
    if (p.medications == null || p.medications!.isEmpty) prompts.add('Add medications');
    if (p.heightCm == null) prompts.add('Add height');
    if (p.weightKg == null) prompts.add('Add weight');
    if (p.bloodGroup == null) prompts.add('Add blood group');
    if (p.emergencyContact == null) prompts.add('Add emergency contact');
    return prompts;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) return const Center(child: Text('Profile not found'));
            _loadProfile(profile);

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(patientProfileProvider.future),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Avatar ──────────────────────────────────
                    GestureDetector(
                      onTap: () => _pickAndUploadPhoto(profile.id),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primaryDark.withAlpha(40),
                            backgroundImage: _localPhoto != null
                                ? FileImage(_localPhoto!) as ImageProvider
                                : (profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null),
                            child: (_localPhoto == null && profile.avatarUrl == null)
                                ? const Icon(Icons.person, size: 54, color: AppColors.primaryDark)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                            child: _isUploadingPhoto
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(profile.fullName ?? 'Patient',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Text('Patient', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    const SizedBox(height: 20),

                    // ── Progress bar ────────────────────────────
                    AnimatedProfileProgress(value: profile.completeness),
                    IncompletionPrompts(prompts: _buildPrompts(profile)),
                    const SizedBox(height: 24),

                    // ── Personal Info ───────────────────────────
                    ProfileSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      initiallyExpanded: true,
                      onSave: _savingPersonal ? null : () => _savePersonal(profile.id),
                      children: [
                        // DOB
                        GestureDetector(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                              firstDate: DateTime(1900), lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryDark)),
                                child: child!,
                              ),
                            );
                            if (d != null) setState(() => _dob = d);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primaryDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select date of birth',
                              style: TextStyle(color: _dob != null ? AppColors.textPrimary : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Gender
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gender', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8, runSpacing: 6,
                              children: _genders.map((g) {
                                final sel = _gender == g;
                                return ChoiceChip(
                                  label: Text(g, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textPrimary)),
                                  selected: sel,
                                  selectedColor: AppColors.primaryDark,
                                  onSelected: (_) => setState(() => _gender = g),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Blood Group
                        AppDropdown(label: 'Blood Group', value: _bloodGroup, items: _bloodGroups,
                            icon: Icons.bloodtype_outlined, onChanged: (v) => setState(() => _bloodGroup = v)),
                        const SizedBox(height: 14),
                        // Height + Weight
                        Row(children: [
                          Expanded(child: TextFormField(
                            controller: _heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm', prefixIcon: Icon(Icons.height)),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(
                            controller: _weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                          )),
                        ]),
                        const SizedBox(height: 14),
                        // Phone
                        Row(children: [
                          DropdownButton<String>(
                            value: _countryCode,
                            underline: const SizedBox(),
                            items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: (v) => setState(() => _countryCode = v!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                          )),
                        ]),
                        const SizedBox(height: 14),
                        // Emergency Contact
                        TextFormField(
                          controller: _emergencyCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Emergency Contact',
                            prefixIcon: Icon(Icons.emergency_outlined, color: Colors.red),
                            hintText: 'Name & phone number',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Medical Info ────────────────────────────
                    ProfileSectionCard(
                      title: 'Medical Information',
                      icon: Icons.medical_information_outlined,
                      onSave: _savingMedical ? null : () => _saveMedical(profile.id),
                      children: [
                        ChipMultiSelect(
                          label: 'Allergies',
                          options: _commonAllergies,
                          selected: _allergies,
                          onChanged: (v) => setState(() => _allergies = v),
                        ),
                        const SizedBox(height: 16),
                        ChipMultiSelect(
                          label: 'Ongoing Medications / Conditions',
                          options: _commonMedications,
                          selected: _medications,
                          onChanged: (v) => setState(() => _medications = v),
                        ),
                        const SizedBox(height: 16),
                        ChipMultiSelect(
                          label: 'Past Illnesses / Surgeries',
                          options: _commonIllnesses,
                          selected: _illnesses,
                          onChanged: (v) => setState(() => _illnesses = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
