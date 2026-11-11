import 'package:flutter/material.dart';

import '../data/feedback_repository.dart';
import '../data/session.dart';
import '../services/sentiment_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/app_background.dart';
import '../widgets/app_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/info_card.dart';

/// Umpan Balik: rating bintang (opsional) dan saran/ulasan. Dipakai semua peran.
/// Teks dianalisis layanan sentimen; hasilnya hanya dilihat tim pengembang
/// sebagai ringkasan, tidak ditampilkan kepada pengguna.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.showBack = false});

  /// true jika dibuka sebagai halaman terpisah (ada tombol kembali).
  final bool showBack;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();

  int _rating = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return; // cegah kirim ganda
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);
    final text = _text.text.trim();
    // Jika layanan sentimen gagal, umpan balik tetap disimpan tanpa label.
    final sentiment = await analyzeSafely(SentimentService.instance, text);
    if (!mounted) return;

    FeedbackRepository.instance.add(
      FeedbackEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        authorEmail: Session.email,
        text: text,
        rating: _rating == 0 ? null : _rating,
        sentiment: sentiment,
        createdAt: DateTime.now(),
      ),
    );

    _text.clear();
    setState(() {
      _rating = 0;
      _sending = false;
    });
    _formKey.currentState?.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Terima kasih! Umpan balikmu sudah kami terima.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final length = _text.text.length;
    final tooLong = length > Validators.maxFeedbackLength;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: AppBackground()),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, widget.showBack ? 8 : 22, 22, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showBack)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Kembali',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Umpan Balik',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ceritakan pengalamanmu memakai FinFamily. Saran dan ulasanmu membantu kami berkembang.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.body),
                    ),
                    const SizedBox(height: 18),
                    _buildRatingCard(),
                    const SizedBox(height: 14),
                    _buildTextCard(length, tooLong),
                    const SizedBox(height: 14),
                    const InfoCard(
                      icon: Icons.info_outline,
                      child: Text(
                        'Umpan balikmu dianalisis untuk mengetahui kesan pengguna. Tim pengembang hanya melihat ringkasannya.',
                        style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Kirim Umpan Balik',
                      isLoading: _sending,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (!widget.showBack) return content;
    return Scaffold(backgroundColor: AppColors.background, body: content);
  }

  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Rating',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                TextSpan(
                  text: ' (opsional)',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  // Menekan bintang yang sama sekali lagi menghapus rating.
                  onPressed: () => setState(() => _rating = _rating == i ? 0 : i),
                  tooltip: 'Beri $i bintang',
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: i <= _rating ? AppColors.accentDeep : AppColors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(int length, bool tooLong) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Saran atau ulasan',
              hint: 'Tulis pengalaman atau saranmu di sini',
              controller: _text,
              maxLines: 8,
              minLines: 6,
              keyboardType: TextInputType.multiline,
              validator: Validators.feedback,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$length / ${Validators.maxFeedbackLength}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: tooLong ? FontWeight.w700 : FontWeight.w500,
                  color: tooLong ? AppColors.dangerDeep : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
