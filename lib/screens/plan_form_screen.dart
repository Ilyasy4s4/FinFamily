import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/session.dart';
import '../data/plan_repository.dart';
import '../models/plan.dart';
import '../services/budget_service.dart';
import '../services/saving_suggestion_service.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';
import '../utils/validators.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';

/// Tambah rencana: pilih tujuan, isi nama, target dana, dan target waktu (PLN_009, PLN_018).
/// Menutup diri dengan `true` jika rencana tersimpan.
class PlanFormScreen extends StatefulWidget {
  const PlanFormScreen({super.key, this.prefill});

  /// Isian awal dari saran menabung (opsional).
  final PlanPrefill? prefill;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _years = TextEditingController();
  final _formatter = RupiahInputFormatter();

  PlanGoal _goal = PlanGoal.pendidikan;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null) {
      _goal = prefill.goal;
      _name.text = prefill.name;
      _target.text = formatNumber(prefill.targetAmount);
      _years.text = '${prefill.years}';
    }
    _target.addListener(_refresh);
    _years.addListener(_refresh);
  }

  @override
  void dispose() {
    _target.removeListener(_refresh);
    _years.removeListener(_refresh);
    _name.dispose();
    _target.dispose();
    _years.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String get _email => Session.spaceId;

  /// Rencana sementara dari isian saat ini (null jika belum valid).
  Plan? get _draft {
    final target = parseRupiah(_target.text);
    final years = int.tryParse(_years.text);
    if (target == null ||
        target <= 0 ||
        years == null ||
        years < 1 ||
        years > 50) {
      return null;
    }
    return Plan(
      id: 'draft',
      goal: _goal,
      name: _name.text,
      targetAmount: target,
      years: years,
      startDate: DateTime.now(),
    );
  }

  String? _validateTarget(String? value) {
    if (value == null || value.trim().isEmpty) return 'Target dana wajib diisi';
    final parsed = parseRupiah(value);
    if (parsed == null || parsed <= 0) return 'Target dana harus lebih dari 0';
    return null;
  }

  String? _validateYears(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Target waktu wajib diisi';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1 || parsed > 50) {
      return 'Target waktu tidak valid';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _draft;
    if (draft == null) return;

    final available = BudgetService.availableForPlan(_email);
    if (!PlanAssessment(plan: draft, sisa: available).sufficient) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Uang belum cukup'),
          content: Text(
            'Rencana ini perlu ${formatRupiah(draft.monthlyNeed(DateTime.now()))} per bulan, '
            'sedangkan uang yang belum dialokasikan ${formatRupiah(available)}. '
            'Jika disimpan, batas belanja akan turun sampai Rp0.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Ubah rencana'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tetap simpan'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    PlanRepository.instance.add(
      _email,
      Plan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        goal: _goal,
        name: _name.text.trim(),
        targetAmount: draft.targetAmount,
        years: draft.years,
        startDate: DateTime.now(),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sisa = BudgetService.availableForPlan(_email);
    final draft = _draft;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Kembali',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tambah Rencana',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih tujuan, lalu isi target dana dan waktunya.',
                        style: TextStyle(fontSize: 15, color: AppColors.body),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tujuan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final goal in PlanGoal.values)
                            _GoalChip(
                              label: goal.label,
                              selected: goal == _goal,
                              onTap: () => setState(() => _goal = goal),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Nama rencana',
                              hint: 'Contoh: Dana Kuliah Anak',
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.required(
                                value,
                                'Nama rencana wajib diisi',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: AppTextField(
                                    label: 'Target dana',
                                    hint: '0',
                                    prefix: 'Rp',
                                    controller: _target,
                                    inputFormatters: [_formatter],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          signed: true,
                                        ),
                                    textInputAction: TextInputAction.next,
                                    validator: _validateTarget,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    label: 'Target waktu (tahun)',
                                    hint: '10',
                                    controller: _years,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    validator: _validateYears,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSavingCard(draft, sisa),
                      const SizedBox(height: 22),
                      GradientButton(
                        label: 'Simpan',
                        isLoading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingCard(Plan? draft, int sisa) {
    final assessment = draft == null
        ? null
        : PlanAssessment(plan: draft, sisa: sisa);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFAE5C), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tabungan per bulan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          if (assessment == null)
            const Text(
              'Isi target dana dan target waktu untuk melihat tabungan per bulan.',
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(assessment.needed),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    assessment.sufficient ? 'Rencana layak' : 'Belum cukup',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: assessment.sufficient
                          ? const Color(0xFF166534)
                          : AppColors.dangerDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Dibanding uang bulanan yang belum dialokasikan ${formatRupiah(sisa)}',
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.softFill : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.accentDeep : AppColors.ink,
          ),
        ),
      ),
    );
  }
}