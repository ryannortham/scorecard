// card widget for selecting game date

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// card widget for selecting game date
class DateCard extends StatelessWidget {
  const DateCard({
    required this.dateController,
    required this.formKey,
    required this.onDateSelected,
    super.key,
  });

  final TextEditingController dateController;
  final GlobalKey<FormState> formKey;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game Date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Form(
              key: formKey,
              child: TextFormField(
                readOnly: true,
                controller: dateController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(border: InputBorder.none),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Game Date';
                  }
                  return null;
                },
                onTap: () => _showDatePicker(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
      dateController.text = DateFormat('EEEE dd/MM/yyyy').format(pickedDate);
    }
    formKey.currentState?.validate();
  }
}
