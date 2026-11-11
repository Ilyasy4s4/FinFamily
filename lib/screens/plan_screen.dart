import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/finance_repository.dart';
import '../data/income_repository.dart';
import '../data/plan_repository.dart';
import '../data/transaction_repository.dart';
import '../models/plan.dart';
import '../models/usage_status.dart';
import '../services/budget_service.dart';
import '../services/saving_suggestion_service.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import 'plan_form_screen.dart';

const _okColor = Color(0xFF166534);
const _okBackground = Color(0xFFDCFCE7);
const _warnBackground = Color(0xFFFFEDD5);

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String _fullDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _percent(double v) => '${(v * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

String _timeLeft(Plan plan) {
  final m = plan.monthsLeft(DateTime.now());
  if (m == 0) return 'Jatuh tempo';
  final y = m ~/ 12;
  final mo = m % 12;
  if (y == 0) return '$mo bulan lagi';
  if (mo == 0) return '$y tahun lagi';
  return '$y tahun $mo bulan lagi';
}

/// Plan Masa Depan: ringkasan tabungan, daftar rencana, setoran, dan detailnya.
/// Catatan: akses khusus Kepala Keluarga dan Pasangan akan dipasang saat fitur peran dibuat.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  String get _email => Session.spaceId;

  Future<void> _addPlan(BuildContext context, {PlanPrefill? prefill}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => PlanFormScreen(prefill: prefill)),
    );
    if (saved == true && context.mounted) {
      _snack(context, 'Rencana tersimpan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PlanRepository.instance,
        IncomeRepository.instance,
        FinanceRepository.instance,
        TransactionRepository.instance,
      ]),
      builder: (context, _) {
        final budget = BudgetService.of(_email);
        final plans = PlanRepository.instance.all(_email);
        final advice = SavingSuggestionService.advise(
          setup: FinanceRepository.instance.of(_email)?.setup,
          budget: budget,
          plans: plans,
          usage: UsageSummary(
            used: TransactionRepository.instance.usedLimitInMonth(
              _email,
              DateTime.now(),
            ),
            limit: budget.limit,
          ),
          now: DateTime.now(),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: AppBackground()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Plan Masa Depan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wujudkan mimpi dan ketahanan finansial keluarga.',
                          style: TextStyle(fontSize: 15, color: AppColors.body),
                        ),
                        const SizedBox(height: 18),
                        _SummaryCard(plans: plans, budget: budget),
                        if (advice != null) ...[
                          const SizedBox(height: 14),
                          _AdviceCard(
                            advice: advice,
                            onAction: () => _onAdvice(context, advice),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GradientButton(
                          label: 'Tambah Rencana',
                          onPressed: () => _addPlan(context),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Daftar Rencana',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (plans.isNotEmpty)
                              const Text(
                                'Tenggat terdekat',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.body,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (plans.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.fieldBorder),
                            ),
                            child: const Text(
                              'Belum ada rencana. Mulai dengan Tambah Rencana.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: AppColors.body,
                              ),
                            ),
                          )
                        else
                          for (final plan in plans) ...[
                            _PlanCard(
                              plan: plan,
                              onTap: () => _showDetail(context, plan.id),
                              onDeposit: () => _showDeposit(context, plan),
                            ),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onAdvice(BuildContext context, SavingAdvice advice) {
    final planId = advice.depositPlanId;
    if (planId != null) {
      final plan = PlanRepository.instance.byId(_email, planId);
      if (plan != null) _showDeposit(context, plan, amount: advice.amount);
      return;
    }
    _addPlan(context, prefill: advice.prefill);
  }

  void _showDetail(BuildContext context, String planId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PlanDetail(planId: planId),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _showDeposit(BuildContext context, Plan plan, {int? amount}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _DepositSheet(plan: plan, initialAmount: amount),
  );
  if (ok == true && context.mounted) {
    _snack(context, 'Setoran tersimpan.');
  }
}

// ---------------------------------------------------------------------------
// Komponen kecil
// ---------------------------------------------------------------------------

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.color,
    this.track = const Color(0xFFFDE6D3),
  });

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 9,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final good = status != PlanStatus.butuhAkselerasi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: good ? _okBackground : _warnBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: good ? _okColor : AppColors.accentDeep,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.plans, required this.budget});

  final List<Plan> plans;
  final BudgetSnapshot budget;

  @override
  Widget build(BuildContext context) {
    final saved = plans.fold<int>(0, (s, p) => s + p.saved);
    final target = plans.fold<int>(0, (s, p) => s + p.targetAmount);
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);
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
          Row(
            children: [
              const Icon(Icons.savings_outlined, color: AppColors.ink),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Total tabungan impian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_percent(progress)} terkumpul',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(saved),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppColors.ink,
            ),
          ),
          Text(
            'dari total sasaran ${formatRupiah(target)} (${plans.length} rencana)',
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          _Bar(value: progress, color: AppColors.ink, track: Colors.white54),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _summaryRow('Sisa uang bulanan', budget.beforePlan),
                const SizedBox(height: 6),
                _summaryRow('Alokasi Plan', -budget.planAllocation),
                const Divider(height: 18),
                _summaryRow('Batas belanja', budget.limit, bold: true),
                if (budget.overAllocated) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Alokasi Plan melebihi sisa uang ${formatRupiah(-budget.unallocated)}. Atur ulang rencana.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dangerDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice, required this.onAction});

  final SavingAdvice advice;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final label = advice.actionLabel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.accentDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  advice.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advice.message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentDeep,
              ),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _summaryRow(String label, int value, {bool bold = false}) {
  final style = TextStyle(
    fontSize: bold ? 15 : 13,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    color: bold ? AppColors.ink : AppColors.body,
  );
  final text = value < 0 ? '- ${formatRupiah(-value)}' : formatRupiah(value);
  return Row(
    children: [
      Expanded(child: Text(label, style: style)),
      Text(text, style: style.copyWith(color: AppColors.ink)),
    ],
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onDeposit,
  });

  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback onDeposit;

  @override
  Widget build(BuildContext context) {
    final status = plan.status(DateTime.now());
    final done = status == PlanStatus.tercapai;
    final barColor = status == PlanStatus.butuhAkselerasi
        ? const Color(0xFFF97316)
        : _okColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${plan.goal.label} · ${_monthYear(plan.deadline)} · ${_timeLeft(plan)}',
              style: const TextStyle(fontSize: 13, color: AppColors.body),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terkumpul',
                        style: TextStyle(fontSize: 12.5, color: AppColors.body),
                      ),
                      Text(
                        formatRupiah(plan.saved),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: done ? _okColor : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(fontSize: 12.5, color: AppColors.body),
                    ),
                    Text(
                      formatRupiah(plan.targetAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Bar(value: plan.progress, color: barColor),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progres: ${_percent(plan.progress)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                  ),
                ),
                Text(
                  'Sisa: ${formatRupiah(plan.remaining)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.body),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.softFill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      done
                          ? 'Target tercapai'
                          : 'Perlu ${formatRupiah(plan.monthlyNeed(DateTime.now()))} /bln',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDeep,
                      ),
                    ),
                  ),
                  if (!done)
                    TextButton.icon(
                      onPressed: onDeposit,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Setor'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentDeep,
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail rencana + riwayat setoran
// ---------------------------------------------------------------------------

class _PlanDetail extends StatelessWidget {
  const _PlanDetail({required this.planId});

  final String planId;

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.body),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  String _advice(PlanAssessment a) {
    final needed = a.yearsNeeded;
    if (needed == null) {
      return 'Saran: kurangi pengeluaran Sekunder dan Tersier agar ada sisa uang bulanan, lalu atur ulang rencana.';
    }
    return 'Saran: kurangi pengeluaran Sekunder atau Tersier sebesar ${formatRupiah(a.shortfall)} per bulan, atau perpanjang waktu menjadi $needed tahun dari sekarang.';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PlanRepository.instance,
        IncomeRepository.instance,
        FinanceRepository.instance,
      ]),
      builder: (context, _) {
        final plan = PlanRepository.instance.byId(Session.spaceId, planId);
        if (plan == null) return const SizedBox.shrink();
        final sisa = BudgetService.availableForPlan(
          Session.spaceId,
          planId: planId,
        );
        final assessment = PlanAssessment(plan: plan, sisa: sisa);
        final ok = assessment.sufficient;
        final status = plan.status(DateTime.now());
        final history = [...plan.deposits]
          ..sort((a, b) => b.date.compareTo(a.date));
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detail rencana',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _row('Nama rencana', plan.name),
                  _row('Tujuan', plan.goal.label),
                  _row('Target dana', formatRupiah(plan.targetAmount)),
                  _row('Terkumpul', formatRupiah(plan.saved)),
                  _row('Kurang', formatRupiah(plan.remaining)),
                  _row('Tenggat', '${_monthYear(plan.deadline)} (${_timeLeft(plan)})'),
                  _row('Perlu disetor per bulan', formatRupiah(assessment.needed)),
                  _row('Uang tersedia untuk rencana ini', formatRupiah(sisa)),
                  const SizedBox(height: 6),
                  _Bar(
                    value: plan.progress,
                    color: status == PlanStatus.butuhAkselerasi
                        ? const Color(0xFFF97316)
                        : _okColor,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ok ? _okBackground : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.remaining == 0
                              ? 'Target tercapai. Rencana ini tidak lagi mengurangi batas belanja.'
                              : ok
                              ? 'Uang tersedia ${formatRupiah(sisa)} mencukupi untuk menyisihkan ${formatRupiah(assessment.needed)} per bulan.'
                              : 'Uang tersedia ${formatRupiah(sisa)} tidak mencukupi untuk menyisihkan ${formatRupiah(assessment.needed)} per bulan.',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: ok ? _okColor : AppColors.dangerDeep,
                          ),
                        ),
                        if (!ok) ...[
                          const SizedBox(height: 8),
                          Text(
                            _advice(assessment),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat setoran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showDeposit(context, plan),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Setor'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentDeep,
                        ),
                      ),
                    ],
                  ),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Belum ada setoran.',
                        style: TextStyle(fontSize: 14, color: AppColors.body),
                      ),
                    )
                  else
                    for (final d in history)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '+ ${formatRupiah(d.amount)}',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: _okColor,
                                    ),
                                  ),
                                  Text(
                                    d.note.isEmpty
                                        ? _fullDate(d.date)
                                        : '${_fullDate(d.date)} · ${d.note}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.body,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus setoran',
                              onPressed: () => PlanRepository.instance
                                  .removeDeposit(Session.spaceId, plan.id, d.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Form setoran
// ---------------------------------------------------------------------------

class _DepositSheet extends StatefulWidget {
  const _DepositSheet({required this.plan, this.initialAmount});

  final Plan plan;

  /// Nominal awal (mis. dari saran menabung). null = kosong.
  final int? initialAmount;

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _formatter = RupiahInputFormatter();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    if (initial != null && initial > 0) _fill(initial);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fill(int value) {
    final raw = TextEditingValue(text: '$value');
    _amount.value = _formatter.formatEditUpdate(TextEditingValue.empty, raw);
  }

  void _fillMonthly() => _fill(widget.plan.monthlyNeed(DateTime.now()));

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nominal wajib diisi';
    final parsed = parseRupiah(value);
    if (parsed == null || parsed <= 0) return 'Nominal harus lebih dari 0';
    return null;
  }

  void _save() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = parseRupiah(_amount.text);
    if (amount == null || amount <= 0) return;
    PlanRepository.instance.addDeposit(
      Session.spaceId,
      widget.plan.id,
      PlanDeposit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        note: _note.text.trim(),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Setor tabungan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.name} · kurang ${formatRupiah(plan.remaining)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.body),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nominal setoran',
                  hint: '0',
                  prefix: 'Rp',
                  controller: _amount,
                  inputFormatters: [_formatter],
                  keyboardType: const TextInputType.numberWithOptions(),
                  textInputAction: TextInputAction.next,
                  validator: _validate,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _fillMonthly,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentDeep,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      'Isi sesuai kebutuhan bulanan (${formatRupiah(plan.monthlyNeed(DateTime.now()))})',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AppTextField(
                  label: 'Catatan (opsional)',
                  hint: 'Contoh: Bonus bulan ini',
                  controller: _note,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                GradientButton(label: 'Simpan setoran', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}