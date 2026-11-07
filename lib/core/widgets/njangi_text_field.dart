import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

/// Custom rounded text field styled according to the NjangiSave design system.
class NjangiTextField extends StatelessWidget {
  const NjangiTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.label,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.textStyle,
  });

  final String hintText;
  final TextEditingController? controller;
  final String? label;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      style:
          textStyle ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.darkNavy,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon:
            prefixWidget ??
            (prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      prefixIcon,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                  )
                : null),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 0),
        suffixIcon: suffixWidget,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        field,
      ],
    );
  }
}
