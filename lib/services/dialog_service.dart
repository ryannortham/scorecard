import 'package:flutter/material.dart';
import 'package:scorecard/services/color_service.dart';

/// A service for showing Material 3 compliant dialogs throughout the app
/// Provides consistent styling and behavior for all prompts
class DialogService {
  /// Show a confirmation dialog with optional destructive styling
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    bool isDestructive = false,
  }) async {
    // Use confirmText as title if title is empty, otherwise use provided title
    final dialogTitle = title.isEmpty ? confirmText : title;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: icon != null ? Icon(icon) : null,
          title: Text(dialogTitle),
          content: content.isNotEmpty ? Text(content) : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style:
                  isDestructive
                      ? FilledButton.styleFrom(
                        backgroundColor: context.colors.error,
                        foregroundColor: context.colors.onError,
                      )
                      : null,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Show a team name edit dialog with duplicate validation
  static Future<String?> showTeamNameDialog({
    required BuildContext context,
    required String title,
    required String? initialValue,
    required bool Function(String) hasTeamWithName,
    String? currentTeamName,
    String confirmText = 'Save',
    String cancelText = 'Cancel',
    String? description,
    int maxLength = 60,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Validation function
    String? validateTeamName(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a team name';
      }
      final trimmedValue = value.trim();
      // Allow keeping the same name, but prevent using other existing team names
      if (currentTeamName != null && trimmedValue == currentTeamName) {
        return null; // Allow keeping the same name
      }
      if (hasTeamWithName(trimmedValue)) {
        return 'Team name already exists';
      }
      return null;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Check if current value is valid
            final currentValue = controller.text;
            final isValid = validateTeamName(currentValue) == null;

            // Trigger initial validation after first build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (formKey.currentState != null) {
                formKey.currentState!.validate();
              }
            });

            return AlertDialog(
              title: Text(title),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null) ...[
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        hintText: 'Enter team name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      maxLength: maxLength,
                      onChanged: (value) {
                        // Trigger validation and rebuild to update button state
                        formKey.currentState?.validate();
                        setState(() {});
                      },
                      validator: validateTeamName,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(cancelText),
                ),
                FilledButton(
                  onPressed:
                      isValid
                          ? () {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop(controller.text.trim());
                            }
                          }
                          : null, // Disable button when invalid
                  child: Text(confirmText),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }
}
