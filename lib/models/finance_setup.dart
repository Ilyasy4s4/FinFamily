/// Status tempat tinggal. Dipakai sebagai salah satu fitur klasifikasi
/// kondisi keuangan, bukan untuk ditampilkan sebagai label kelas.
enum HousingStatus { milikSendiri, sewa, menumpang }

extension HousingStatusX on HousingStatus {
  String get label => switch (this) {
    HousingStatus.milikSendiri => 'Rumah sendiri',
    HousingStatus.sewa => 'Kontrak / sewa',
    HousingStatus.menumpang => 'Menumpang',
  };

  String get description => switch (this) {
    HousingStatus.milikSendiri => 'Tidak ada biaya sewa bulanan.',
    HousingStatus.sewa => 'Ada biaya sewa atau kontrak rutin.',
    HousingStatus.menumpang => 'Tinggal bersama keluarga atau kerabat.',
  };

  /// Nilai kategori persis seperti pada dataset/model (kolom `status_rumah`).
  String get modelValue => switch (this) {
    HousingStatus.milikSendiri => 'Milik Sendiri',
    HousingStatus.sewa => 'Sewa/Kontrak',
    HousingStatus.menumpang => 'Menumpang',
  };
}

/// Data keuangan bulanan dari layar Pengaturan Awal.
class FinanceSetup {
  const FinanceSetup({
    required this.gaji,
    required this.kebutuhan,
    required this.cicilan,
    this.tabungan = 0,
    this.tagihanLain = 0,
    this.housing = HousingStatus.milikSendiri,
    this.anggota = 1,
    this.anakSekolah = 0,
  });

  final int gaji;
  final int kebutuhan;
  final int cicilan;

  /// Tidak lagi diisi dari Pengaturan Awal (selalu 0). Menabung dikelola lewat
  /// Plan Masa Depan, yang mengurangi batas belanja. Field dipertahankan agar
  /// bentuk input model tidak berubah.
  final int tabungan;

  /// Tagihan rutin di luar kebutuhan, cicilan, dan tabungan.
  /// Contoh: internet, pulsa, langganan.
  final int tagihanLain;

  /// Status tempat tinggal, dipakai untuk membaca beban biaya tetap.
  final HousingStatus housing;

  /// Jumlah anggota keluarga dalam satu rumah, termasuk pengguna (1-8).
  /// Fitur `jumlah_anggota` pada model.
  final int anggota;

  /// Jumlah anak usia sekolah. Harus lebih kecil dari [anggota].
  /// Fitur `jumlah_anak_sekolah` pada model.
  final int anakSekolah;

  /// Jumlah tanggungan selain pengguna, dipakai untuk menyesuaikan saran.
  int get tanggungan => anggota > 1 ? anggota - 1 : 0;

  int get pengeluaranTetap => kebutuhan + cicilan + tabungan + tagihanLain;

  /// Sisa uang bebas belanja = batas pengeluaran Sekunder + Tersier.
  int get sisa => gaji - pengeluaranTetap;

  /// Kebutuhan pokok versi model. Di dataset, `kebutuhan_pokok` sudah memuat
  /// listrik/air/sekolah/sewa, jadi tagihan rutin ikut dijumlahkan agar
  /// `sisa` di app sama dengan `sisa_uang_bebas_belanja` di model.
  int get kebutuhanPokokModel => kebutuhan + tagihanLain;

  /// Input 8 isian untuk model (nama kunci sama dengan kolom dataset).
  /// [sekunderTersier] adalah perkiraan belanja keinginan; bila belum ada,
  /// pakai nilai default (mis. sisa x porsi sekunder) agar fitur turunan
  /// `saldo_akhir` tetap terhitung.
  Map<String, Object> toModelInput({int? sekunderTersier}) => {
    'jumlah_anggota': anggota,
    'jumlah_anak_sekolah': anakSekolah,
    'status_rumah': housing.modelValue,
    'pendapatan_bulanan': gaji,
    'kebutuhan_pokok': kebutuhanPokokModel,
    'cicilan_utang': cicilan,
    'tabungan': tabungan,
    'sekunder_tersier': sekunderTersier ?? (sisa > 0 ? sisa : 0),
  };

  /// Data layak dikirim ke model (aturan yang sama dengan notebook).
  bool get validForModel =>
      gaji > 0 && sisa >= 0 && anggota >= 1 && anakSekolah < anggota;
}