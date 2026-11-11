import '../models/finance_setup.dart';
import '../models/financial_insight.dart';
import '../utils/rupiah.dart';

/// TITIK SAMBUNG MODEL KLASIFIKASI.
///
/// Saat ini isinya aturan sederhana agar UI bisa berjalan tanpa backend.
/// Kalau model ML sudah siap, buat implementasi baru yang memakai fitur yang
/// sama (pemasukan, tempat tinggal, tagihan, cicilan, tanggungan),
/// lalu ganti satu baris di layar:
///
///   FinancialClassifier.instance = ModelFinancialClassifier();
///
/// Hasil kelas tidak ditampilkan ke pengguna. Yang ditampilkan hanya
/// [FinancialInsight] berupa ringkasan dan saran.
abstract class FinancialClassifier {
  const FinancialClassifier();

  static FinancialClassifier instance = const RuleBasedFinancialClassifier();

  FinancialInsight assess(FinanceSetup setup);
}

class RuleBasedFinancialClassifier extends FinancialClassifier {
  const RuleBasedFinancialClassifier();

  @override
  FinancialInsight assess(FinanceSetup setup) {
    final income = setup.gaji;
    final fixedCost = setup.pengeluaranTetap;
    final remaining = setup.sisa;
    final debtRatio = income > 0 ? setup.cicilan / income : 0.0;
    final fixedRatio = income > 0 ? fixedCost / income : 1.0;
    final billRatio = income > 0 ? setup.tagihanLain / income : 0.0;

    final condition = _condition(
      income: income,
      fixedRatio: fixedRatio,
      remaining: remaining,
      debtRatio: debtRatio,
    );

    final actions = <String>[
      switch (condition) {
        FinancialCondition.aman => 'Pertahankan pola ini, lalu lanjutkan target tabungan dan rencana jangka panjang.',
        FinancialCondition.cukup => 'Pertahankan kebutuhan primer, lalu kurangi porsi Sekunder dan Tersier bulan ini.',
        FinancialCondition.kritis => 'Fokus kebutuhan primer dulu. Tunda belanja Sekunder dan Tersier sampai ada sisa yang aman.',
        FinancialCondition.overleveraged => 'Fokus kebutuhan primer dan tunda komitmen baru sampai pengeluaran tetap lebih kecil dari pemasukan.',
      },
    ];

    if (income <= 0) {
      actions.add(
        'Isi pemasukan atau uang saku bulan ini agar batas belanja bisa dihitung.',
      );
    }

    if (remaining < 0) {
      actions.add(
        'Pengeluaran tetap melebihi pemasukan ${formatRupiah(-remaining)}. '
        'Kurangi atau negosiasi tagihan tetap terlebih dahulu.',
      );
    }

    if (debtRatio > 0.3) {
      actions.add(
        'Cicilan ${_percent(debtRatio)} dari pemasukan. '
        'Targetkan total cicilan di bawah 30%.',
      );
    }

    if (billRatio > 0.15) {
      actions.add(
        'Tagihan rutin ${_percent(billRatio)} dari pemasukan. '
        'Audit langganan dan tagihan yang bisa ditunda.',
      );
    }

    if (setup.housing == HousingStatus.sewa) {
      actions.add(
        'Karena tempat tinggal masih sewa/kontrak, sisihkan dana darurat '
        'minimal 3-6 bulan biaya tetap.',
      );
    } else if (setup.housing == HousingStatus.menumpang) {
      actions.add(
        'Manfaatkan biaya tempat tinggal yang rendah untuk memperkuat '
        'tabungan dan dana darurat.',
      );
    }

    if (setup.tanggungan > 0) {
      actions.add(
        'Dengan ${setup.tanggungan} tanggungan, prioritaskan kebutuhan primer '
        'dan siapkan dana darurat keluarga.',
      );
    }

    return FinancialInsight(
      condition: condition,
      headline: switch (condition) {
        FinancialCondition.aman => 'Keuanganmu cukup sehat',
        FinancialCondition.cukup => 'Rapikan porsi belanja bulan ini',
        FinancialCondition.kritis => 'Fokus kebutuhan primer dulu',
        FinancialCondition.overleveraged =>
          'Beban tetap perlu segera dikurangi',
      },
      summary: income <= 0
          ? 'Belum ada pemasukan yang bisa dihitung. Isi pemasukan atau uang saku bulan ini.'
          : 'Pemasukan ${formatRupiah(income)} · biaya tetap ${formatRupiah(fixedCost)} · sisa ${formatRupiah(remaining)}.',
      actions: actions,
      income: income,
      fixedCost: fixedCost,
      remaining: remaining,
    );
  }

  FinancialCondition _condition({
    required int income,
    required double fixedRatio,
    required int remaining,
    required double debtRatio,
  }) {
    if (income <= 0) return FinancialCondition.kritis;
    if (remaining < 0 || debtRatio > 0.4) {
      return FinancialCondition.overleveraged;
    }
    if (fixedRatio >= 0.9) return FinancialCondition.kritis;
    if (fixedRatio >= 0.7) {
      return FinancialCondition.cukup;
    }
    return FinancialCondition.aman;
  }

  String _percent(double ratio) => '${(ratio * 100).round()}%';
}
