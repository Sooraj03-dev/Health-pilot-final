import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_pilot/core/constants.dart';

// ────────────────────────────────────────────────────────────────────────────
// Animated Profile Progress Bar
// ────────────────────────────────────────────────────────────────────────────
class AnimatedProfileProgress extends StatefulWidget {
  final double value; // 0.0 – 1.0
  const AnimatedProfileProgress({super.key, required this.value});

  @override
  State<AnimatedProfileProgress> createState() => _AnimatedProfileProgressState();
}

class _AnimatedProfileProgressState extends State<AnimatedProfileProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProfileProgress old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: old.value, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _color {
    if (widget.value < 0.4) return Colors.redAccent;
    if (widget.value < 0.7) return Colors.orange;
    return AppColors.primaryDark;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_color.withAlpha(20), _color.withAlpha(8)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _color.withAlpha(60)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Profile Completeness',
                style: TextStyle(fontWeight: FontWeight.w700, color: _color, fontSize: 14)),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Text(
                '${(_anim.value * 100).toInt()}%',
                style: TextStyle(fontWeight: FontWeight.w800, color: _color, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _anim.value,
              minHeight: 10,
              backgroundColor: _color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
        if (widget.value < 1.0) ...[
          const SizedBox(height: 8),
          Text(
            widget.value < 0.4
                ? 'Complete your profile for personalised care.'
                : widget.value < 0.7
                    ? 'Almost there! Fill in a few more details.'
                    : 'Great progress! Just a couple more fields.',
            style: TextStyle(fontSize: 12, color: _color.withAlpha(180)),
          ),
        ],
      ],
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Profile Section Card (Expandable)
// ────────────────────────────────────────────────────────────────────────────
class ProfileSectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final VoidCallback? onSave;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.onSave,
  });

  @override
  State<ProfileSectionCard> createState() => _ProfileSectionCardState();
}

class _ProfileSectionCardState extends State<ProfileSectionCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    shadowColor: AppColors.primaryDark.withAlpha(30),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: AppColors.primaryDark, size: 20),
        ),
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                ...widget.children,
                if (widget.onSave != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onSave,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Chip Multi-Select
// ────────────────────────────────────────────────────────────────────────────
class ChipMultiSelect extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool hasOther;

  const ChipMultiSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.hasOther = true,
  });

  @override
  State<ChipMultiSelect> createState() => _ChipMultiSelectState();
}

class _ChipMultiSelectState extends State<ChipMultiSelect> {
  final _otherCtrl = TextEditingController();
  bool _showOther = false;
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
    // Restore any "Other:" values
    final otherItem = _selected.where((e) => e.startsWith('Other:')).firstOrNull;
    if (otherItem != null) {
      _showOther = true;
      _otherCtrl.text = otherItem.replaceFirst('Other:', '').trim();
    }
  }

  @override
  void dispose() { _otherCtrl.dispose(); super.dispose(); }

  void _toggle(String option) {
    setState(() {
      if (option == 'Other') {
        _showOther = !_showOther;
        if (!_showOther) _selected.removeWhere((e) => e.startsWith('Other:'));
      } else {
        _selected.contains(option) ? _selected.remove(option) : _selected.add(option);
      }
    });
    widget.onChanged(_selected);
  }

  void _saveOther(String val) {
    _selected.removeWhere((e) => e.startsWith('Other:'));
    if (val.trim().isNotEmpty) _selected.add('Other: ${val.trim()}');
    widget.onChanged(_selected);
  }

  bool get _otherSelected => _showOther;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ...widget.options.map((o) {
            final sel = _selected.contains(o);
            return FilterChip(
              label: Text(o, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textPrimary)),
              selected: sel,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.primaryDark,
              backgroundColor: AppColors.primaryDark.withAlpha(12),
              side: BorderSide(color: sel ? AppColors.primaryDark : AppColors.primaryDark.withAlpha(60)),
              onSelected: (_) => _toggle(o),
            );
          }),
          if (widget.hasOther)
            FilterChip(
              label: Text('Other', style: TextStyle(fontSize: 12, color: _otherSelected ? Colors.white : AppColors.textPrimary)),
              selected: _otherSelected,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.primaryLight,
              backgroundColor: AppColors.primaryLight.withAlpha(12),
              side: BorderSide(color: _otherSelected ? AppColors.primaryLight : AppColors.primaryLight.withAlpha(60)),
              onSelected: (_) => _toggle('Other'),
            ),
        ],
      ),
      if (_showOther) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _otherCtrl,
          decoration: InputDecoration(
            labelText: 'Specify other ${widget.label.toLowerCase()}',
            suffixIcon: IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.primaryDark),
              onPressed: () => _saveOther(_otherCtrl.text),
            ),
          ),
          onFieldSubmitted: _saveOther,
          textInputAction: TextInputAction.done,
        ),
      ],
    ],
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Searchable Dropdown (Autocomplete)
// ────────────────────────────────────────────────────────────────────────────
class SearchableDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final String? hint;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
    initialValue: TextEditingValue(text: value ?? ''),
    optionsBuilder: (tv) {
      if (tv.text.isEmpty) return options;
      return options.where((o) => o.toLowerCase().contains(tv.text.toLowerCase()));
    },
    onSelected: onSelected,
    fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) => TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryDark),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    ),
    optionsViewBuilder: (ctx, onSel, opts) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            children: opts.map((o) => ListTile(
              dense: true,
              title: Text(o, style: const TextStyle(fontSize: 14)),
              onTap: () => onSel(o),
            )).toList(),
          ),
        ),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Styled Dropdown Form Field
// ────────────────────────────────────────────────────────────────────────────
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool required;
  final IconData? icon;

  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.required = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryDark) : null,
    ),
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
    onChanged: onChanged,
    validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Unit Number Field (height / weight)
// ────────────────────────────────────────────────────────────────────────────
class UnitNumberField extends StatelessWidget {
  final String label;
  final String unit;
  final double? value;
  final ValueChanged<double?> onChanged;
  final IconData? icon;

  const UnitNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value != null ? value.toString() : '',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primaryDark) : null,
      suffixText: unit,
      suffixStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
    ),
    onChanged: (v) => onChanged(double.tryParse(v)),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Days Multi-Select (Mon–Sun)
// ────────────────────────────────────────────────────────────────────────────
class DayMultiSelect extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const DayMultiSelect({super.key, required this.selected, required this.onChanged});

  @override
  State<DayMultiSelect> createState() => _DayMultiSelectState();
}

class _DayMultiSelectState extends State<DayMultiSelect> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<String> _selected;

  @override
  void initState() { super.initState(); _selected = List.from(widget.selected); }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children: _days.map((d) {
      final sel = _selected.contains(d);
      return ChoiceChip(
        label: Text(d, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
        selected: sel,
        selectedColor: AppColors.primaryDark,
        backgroundColor: AppColors.primaryDark.withAlpha(10),
        side: BorderSide(color: sel ? AppColors.primaryDark : AppColors.primaryDark.withAlpha(40)),
        onSelected: (_) {
          setState(() => sel ? _selected.remove(d) : _selected.add(d));
          widget.onChanged(_selected);
        },
      );
    }).toList(),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Incomplete Field Prompt Chips (shown below progress bar)
// ────────────────────────────────────────────────────────────────────────────
class IncompletionPrompts extends StatelessWidget {
  final List<String> prompts;
  const IncompletionPrompts({super.key, required this.prompts});

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Suggested additions:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: prompts.map((p) => Chip(
            avatar: const Icon(Icons.info_outline, size: 14, color: Colors.orange),
            label: Text(p, style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
            backgroundColor: Colors.orange.shade50,
            side: const BorderSide(color: Colors.orange, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
      ],
    );
  }
}
