import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Kolom input dengan label di atas, dipakai semua form.
/// [prefix] menampilkan teks tetap di kiri (mis. "Rp").
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscure = false,
    this.prefix,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.onTap,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final String? prefix;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPrefix = widget.prefix != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.obscure ? 1 : widget.minLines,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          inputFormatters: widget.inputFormatters,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          validator: widget.validator,
          style: const TextStyle(fontSize: 15, color: AppColors.ink),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.hint,
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(hasPrefix ? 0 : 20, 15, 20, 15),
            prefixIcon: hasPrefix
                ? Padding(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    child: Text(
                      widget.prefix!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.body,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    tooltip:
                        _hidden ? 'Tampilkan password' : 'Sembunyikan password',
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  )
                : null,
            enabledBorder: _border(AppColors.fieldBorder, 1.4),
            focusedBorder: _border(AppColors.primary, 1.8),
            errorBorder: _border(AppColors.dangerDeep, 1.6),
            focusedErrorBorder: _border(AppColors.dangerDeep, 1.8),
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.dangerDeep,
            ),
          ),
        ),
      ],
    );
  }
}
