import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData? leadIcon;
  final IconData? trailIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool isPassword;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.leadIcon,
    this.trailIcon,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
    this.isPassword = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.helperText,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            ignoring: widget.onTap != null,
            child: TextFormField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              obscureText: widget.isPassword ? _obscured : false,
              maxLines: widget.isPassword ? 1 : widget.maxLines,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              inputFormatters: widget.inputFormatters,
              style: GoogleFonts.inter(
                color: AppColors.dark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                helperText: widget.helperText,
                helperStyle: GoogleFonts.inter(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: widget.leadIcon != null
                    ? Icon(widget.leadIcon, size: 18, color: AppColors.sub)
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscured ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                          color: AppColors.sub,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : widget.suffixIcon ??
                        (widget.trailIcon != null
                            ? Icon(widget.trailIcon, size: 18, color: AppColors.sub)
                            : null),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
