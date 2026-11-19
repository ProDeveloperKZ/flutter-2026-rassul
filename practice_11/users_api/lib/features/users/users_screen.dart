import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import 'new_user_screen.dart';
import 'user.dart';
import 'user_detail_screen.dart';
import 'users_model.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<UsersModel>();

    final Widget body;
    if (m.loading) {
      body = const LoadingView();
    } else {
      body = switch (m.error) {
        null => UserList(users: m.items, onRefresh: m.load),
        NoConnectionException() => OfflineView(onRetry: m.load),
        NotFoundException() => const RequestErrorView(
          title: 'Not found',
          message: 'The requested users could not be found (404).',
        ),
        UnauthorizedException() => const RequestErrorView(
          title: 'Unauthorized',
          message: 'You are not authorized to view users (401).',
        ),
        ServerException(:final status) => ServerErrorView(
          status: status,
          onRetry: m.load,
        ),
        BadResponseException() => const GenericErrorView(),
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-user-fab'),
        onPressed: () {
          unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NewUserScreen()),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('New user'),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading users...'),
        ],
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({required this.users, required this.onRefresh, super.key});

  final List<User> users;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${user.id}')),
            title: Text(user.name),
            subtitle: Text('${user.email}\n${user.address.city}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => UserDetailScreen(user: user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OfflineView extends StatelessWidget {
  const OfflineView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 56),
            const SizedBox(height: 16),
            Text(
              'No connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Could not reach the server. Check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('retry-button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class ServerErrorView extends StatelessWidget {
  const ServerErrorView({
    required this.status,
    required this.onRetry,
    super.key,
  });

  final int status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56),
            const SizedBox(height: 16),
            Text(
              'Server error ($status)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The server ran into a problem. Please try again shortly.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('retry-button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestErrorView extends StatelessWidget {
  const RequestErrorView({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class GenericErrorView extends StatelessWidget {
  const GenericErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.report_problem_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Unexpected response',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The server returned data in an unexpected format. Please report this issue.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
