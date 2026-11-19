import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import 'user.dart';
import 'users_model.dart';

class NewUserScreen extends StatefulWidget {
  const NewUserScreen({super.key});

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Name must contain at least 2 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.length < 2 || trimmed.contains(' ')) {
      return 'Username must be at least 2 characters without spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    final at = email.indexOf('@');
    final dot = email.indexOf('.', at + 1);
    if (at <= 0 ||
        dot <= at + 1 ||
        dot == email.length - 1 ||
        email.contains(' ') ||
        at != email.lastIndexOf('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String _errorMessage(ApiException error) {
    return switch (error) {
      NoConnectionException() =>
        'No connection. Check your network and try again.',
      ServerException(:final status) => 'Server error ($status). Try again.',
      NotFoundException() => 'Endpoint not found (404).',
      UnauthorizedException() => 'Not authorized (401).',
      BadResponseException() => 'Unexpected server response. Could not save.',
    };
  }

  Future<void> _submit() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);

    final draft = User(
      id: 0,
      name: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      phone: '',
      website: null,
      address: const Address(
        street: '',
        suite: '',
        city: 'Not specified',
        zipcode: '',
        geo: Geo(lat: 0, lng: 0),
      ),
      company: (name: 'Not specified', catchPhrase: ''),
    );

    try {
      final error = await context.read<UsersModel>().createUser(draft);
      if (!mounted) return;
      if (error == null) {
        Navigator.of(context).pop();
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New user')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const ValueKey('new-user-name'),
                controller: _name,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _usernameFocus.requestFocus(),
                onTapOutside: _dismissKeyboard,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('new-user-username'),
                controller: _username,
                focusNode: _usernameFocus,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                onTapOutside: _dismissKeyboard,
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('new-user-email'),
                controller: _email,
                focusNode: _emailFocus,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  unawaited(_submit());
                },
                onTapOutside: _dismissKeyboard,
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('new-user-save'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
