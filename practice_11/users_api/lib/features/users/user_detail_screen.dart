import 'package:flutter/material.dart';

import 'user.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final website = user.website;
    final phoneDigits = user.phoneDigits;

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, child: Text('${user.id}')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Contact', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('detail-phone-tile'),
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: Text(
                    user.phone.isEmpty
                        ? 'Not provided'
                        : '${user.phone}\nNormalized: $phoneDigits',
                  ),
                  isThreeLine: user.phone.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('detail-website-tile'),
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Website'),
                  subtitle: Text(website ?? 'Not provided'),
                  trailing: website != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: website != null ? () {} : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Address', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    [
                          user.address.street,
                          user.address.suite,
                        ].where((part) => part.isNotEmpty).join(', ').isEmpty
                        ? 'Street not provided'
                        : [
                            user.address.street,
                            user.address.suite,
                          ].where((part) => part.isNotEmpty).join(', '),
                  ),
                  subtitle: Text(
                    [
                      user.address.city,
                      user.address.zipcode,
                    ].where((part) => part.isNotEmpty).join(', '),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public_outlined),
                  title: const Text('Coordinates'),
                  subtitle: Text(
                    'lat ${user.address.geo.lat}, lng ${user.address.geo.lng}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Company', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(
                user.company.name.isEmpty ? 'Not provided' : user.company.name,
              ),
              subtitle: user.company.catchPhrase.isEmpty
                  ? null
                  : Text(user.company.catchPhrase),
            ),
          ),
        ],
      ),
    );
  }
}
