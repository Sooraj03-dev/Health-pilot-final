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
const _qualifications = ['MBBS', 'MD', 'MS', 'DM', 'Fellowship', 'Diploma', 'PhD', 'Other'];
const _specializations = [
  'Cardiology', 'Dermatology', 'Emergency Medicine', 'ENT', 'Gastroenterology',
  'General Medicine', 'General Surgery', 'Gynaecology', 'Nephrology', 'Neurology',
  'Neurosurgery', 'Obstetrics', 'Oncology', 'Ophthalmology', 'Orthopaedics',
  'Paediatrics', 'Pathology', 'Psychiatry', 'Pulmonology', 'Radiology',
  'Rheumatology', 'Urology', 'Other',
];
const _experienceOptions = ['< 1 year', '1–3 years', '3–5 years', '5–10 years', '> 10 years'];
const _councils = ['MCI', 'NMC', 'State Medical Council', 'Other'];

final doctorProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = ref.watch(authProvider).userId;
  if (userId == null) return null;
  return ProfileService().fetchProfile(userId);
});

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  File? _localPhoto;
  bool _isUploadingPhoto = false;

  // ── Professional section ───────────────────────
  String? _qualification;
  String? _specialization;
  String? _experience;
  String? _council;
  bool _savingProfessional = false;

  // ── Practice section ───────────────────────────
  final _clinicNameCtrl = TextEditingController();
  final _clinicAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _savingPractice = false;

  // ── Licenses ───────────────────────────────────
  List<String> _licenseUrls = [];
  bool _uploadingLicense = false;

  UserProfile? _profile;

  @override
  void dispose() {
    _clinicNameCtrl.dispose();
    _clinicAddressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _loadProfile(UserProfile p) {
    if (_profile?.id == p.id) return;
    _profile = p;
    _qualification = p.highestQualification;
    _specialization = p.specialization;
    _experience = p.experience;
    _council = p.registrationCouncil;
    _clinicNameCtrl.text = p.clinicName ?? p.clinicDetails ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _licenseUrls = List.from(p.licenseUrls);
    // Parse clinic timings JSON if present
    // Format stored: "Mon,Tue|09:00|17:00"
    if (p.clinicTimings != null && p.clinicTimings!.isNotEmpty) {
      final parts = p.clinicTimings!.split('|');
      if (parts.length == 3) {
        _selectedDays = parts[0].split(',');
        final st = parts[1].split(':');
        final et = parts[2].split(':');
        if (st.length == 2) _startTime = TimeOfDay(hour: int.tryParse(st[0]) ?? 9, minute: int.tryParse(st[1]) ?? 0);
        if (et.length == 2) _endTime = TimeOfDay(hour: int.tryParse(et[0]) ?? 17, minute: int.tryParse(et[1]) ?? 0);
      }
    }
  }

  String? _formatTime(TimeOfDay? t) => t != null ? '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}' : null;

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
      ref.invalidate(doctorProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      setState(() => _localPhoto = null);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfessional(String userId) async {
    setState(() => _savingProfessional = true);
    try {
      await ProfileService().updateProfile(
        userId: userId,
        highestQualification: _qualification,
        specialization: _specialization,
        experience: _experience,
        registrationCouncil: _council,
      );
      ref.invalidate(doctorProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Professional info saved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingProfessional = false);
    }
  }

  Future<void> _savePractice(String userId) async {
    setState(() => _savingPractice = true);
    try {
      String? timings;
      if (_selectedDays.isNotEmpty && _startTime != null && _endTime != null) {
        timings = '${_selectedDays.join(',')}|${_formatTime(_startTime)}|${_formatTime(_endTime)}';
      }
      await ProfileService().updateProfile(
        userId: userId,
        clinicName: _clinicNameCtrl.text.trim().isNotEmpty ? _clinicNameCtrl.text.trim() : null,
        clinicDetails: _clinicAddressCtrl.text.trim().isNotEmpty ? _clinicAddressCtrl.text.trim() : null,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        clinicTimings: timings,
      );
      ref.invalidate(doctorProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Practice info saved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _savingPractice = false);
    }
  }

  Future<void> _uploadLicense(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    setState(() => _uploadingLicense = true);
    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final ext = result.files.single.extension ?? 'pdf';
      final fileName = '${userId}_license_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('medical-docs').uploadBinary(
        'licenses/$fileName', bytes,
        fileOptions: FileOptions(upsert: false, contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext'),
      );
      final url = supabase.storage.from('medical-docs').getPublicUrl('licenses/$fileName');
      setState(() => _licenseUrls.add(url));
      await ProfileService().updateProfile(userId: userId, licenseUrls: _licenseUrls);
      ref.invalidate(doctorProfileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License uploaded!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploadingLicense = false);
    }
  }

  List<String> _buildPrompts(UserProfile p) {
    final prompts = <String>[];
    if (p.experience == null) prompts.add('Add experience');
    if (p.registrationCouncil == null) prompts.add('Add council');
    if (p.clinicName == null) prompts.add('Add clinic name');
    if (p.clinicTimings == null) prompts.add('Add clinic timings');
    if (p.licenseUrls.isEmpty) prompts.add('Upload certificates');
    return prompts;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(doctorProfileProvider);

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
              onRefresh: () async => ref.refresh(doctorProfileProvider.future),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Avatar
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
                    Text(
                      profile.fullName != null && profile.fullName!.isNotEmpty ? 'Dr. ${profile.fullName}' : 'Doctor',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(profile.specialization ?? 'General Physician', style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    const SizedBox(height: 20),

                    // Progress bar
                    AnimatedProfileProgress(value: profile.completeness),
                    IncompletionPrompts(prompts: _buildPrompts(profile)),
                    const SizedBox(height: 24),

                    // ── Professional Info ───────────────────────
                    ProfileSectionCard(
                      title: 'Professional Information',
                      icon: Icons.school_outlined,
                      initiallyExpanded: true,
                      onSave: _savingProfessional ? null : () => _saveProfessional(profile.id),
                      children: [
                        AppDropdown(
                          label: 'Highest Qualification',
                          value: _qualification,
                          items: _qualifications,
                          icon: Icons.school_outlined,
                          onChanged: (v) => setState(() => _qualification = v),
                        ),
                        const SizedBox(height: 14),
                        SearchableDropdown(
                          label: 'Specialization',
                          options: _specializations,
                          value: _specialization,
                          hint: 'Search specialization...',
                          onSelected: (v) => setState(() => _specialization = v),
                        ),
                        const SizedBox(height: 14),
                        AppDropdown(
                          label: 'Years of Experience',
                          value: _experience,
                          items: _experienceOptions,
                          icon: Icons.work_outline,
                          onChanged: (v) => setState(() => _experience = v),
                        ),
                        const SizedBox(height: 14),
                        AppDropdown(
                          label: 'Medical Registration Council',
                          value: _council,
                          items: _councils,
                          icon: Icons.verified_outlined,
                          onChanged: (v) => setState(() => _council = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Practice Info ───────────────────────────
                    ProfileSectionCard(
                      title: 'Practice Information',
                      icon: Icons.local_hospital_outlined,
                      onSave: _savingPractice ? null : () => _savePractice(profile.id),
                      children: [
                        TextFormField(
                          controller: _clinicNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Clinic / Hospital Name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _clinicAddressCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Clinic Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Clinic Days', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DayMultiSelect(
                          selected: _selectedDays,
                          onChanged: (v) => setState(() => _selectedDays = v),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0));
                                if (t != null) setState(() => _startTime = t);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Opens at',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.access_time, color: AppColors.primaryDark),
                                ),
                                child: Text(_startTime != null ? _startTime!.format(context) : 'Select',
                                    style: TextStyle(color: _startTime != null ? AppColors.textPrimary : Colors.grey)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0));
                                if (t != null) setState(() => _endTime = t);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Closes at',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.access_time_filled, color: AppColors.primaryDark),
                                ),
                                child: Text(_endTime != null ? _endTime!.format(context) : 'Select',
                                    style: TextStyle(color: _endTime != null ? AppColors.textPrimary : Colors.grey)),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Certificates ────────────────────────────
                    ProfileSectionCard(
                      title: 'Certificates & Licenses',
                      icon: Icons.workspace_premium_outlined,
                      children: [
                        if (_licenseUrls.isEmpty)
                          const Text('No certificates uploaded yet.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _licenseUrls.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.description_outlined, color: AppColors.primaryDark),
                              title: Text('Certificate ${i + 1}', style: const TextStyle(fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.primaryLight),
                                onPressed: () {}, // open link
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            icon: _uploadingLicense
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file_outlined),
                            label: Text(_uploadingLicense ? 'Uploading…' : 'Upload Certificate / License'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              side: const BorderSide(color: AppColors.primaryDark),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _uploadingLicense ? null : () => _uploadLicense(profile.id),
                          ),
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
