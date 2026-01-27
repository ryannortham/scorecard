// displays when a team has no address information available

import 'package:flutter/material.dart';
import 'package:scorecard/theme/colors.dart';

/// displays when a team has no address information available
class TeamNoAddressSection extends StatelessWidget {
  const TeamNoAddressSection({
    required this.hasPlayHQId,
    required this.isFetching,
    required this.onFetchAddress,
    super.key,
  });

  final bool hasPlayHQId;
  final bool isFetching;
  final VoidCallback? onFetchAddress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: context.colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'No address information available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (hasPlayHQId) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isFetching ? null : onFetchAddress,
                  icon:
                      isFetching
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.location_searching),
                  label: Text(
                    isFetching
                        ? 'Fetching Address...'
                        : 'Fetch Address from PlayHQ',
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'This team was added manually. Address information is only '
                'available for teams imported from PlayHQ.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
