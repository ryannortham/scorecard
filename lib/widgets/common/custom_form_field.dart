import 'package:flutter/material.dart';

/// A reusable text field widget for form inputs
class CustomFormField extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String labelText;
  final String emptyValueError;
  final Future<String?> Function() onTap;
  final bool readOnly;
  final Widget? suffixIcon;

  const CustomFormField({
    super.key,
    required this.formKey,
    required this.controller,
    required this.labelText,
    required this.emptyValueError,
    required this.onTap,
    this.readOnly = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        readOnly: readOnly,
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return emptyValueError;
          }
          return null;
        },
        onTap: onTap,
      ),
    );
  }
}
