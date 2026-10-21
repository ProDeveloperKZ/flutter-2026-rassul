import 'package:flutter/material.dart';

import 'summary_card.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sign up',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    home: const SignUpScreen(),
  );
}

const groups = ['IT-2301', 'IT-2302', 'IT-2303', 'IT-2304', 'IT-2305'];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _birthText = TextEditingController();
  final _emailFocus = FocusNode();
  String? _group;
  DateTime? _birth;
  bool _agreed = false;
  bool _done = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _birthText]) {
      c.dispose();
    }
    _emailFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created')));
      setState(() => _done = true);
    }
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    if (!mounted) return;
    setState(() {
      _birth = date;
      _birthText.text =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.${date.year}';
    });
  }

  void _startOver() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      for (final c in [_name, _email, _password, _confirm, _birthText]) {
        c.clear();
      }
      _group = null;
      _birth = null;
      _agreed = false;
      _done = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign up')),
    body: _done
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SummaryCard(
                  name: _name.text.trim(),
                  email: _email.text.trim(),
                  group: _group ?? '',
                  birthDate: _birthText.text,
                ),
                TextButton(
                  onPressed: _startOver,
                  child: const Text('Start over'),
                ),
              ],
            ),
          )
        : Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    onTapOutside: _dismissKeyboard,
                    validator: (v) => (v ?? '').trim().length < 2
                        ? 'Name must contain at least 2 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@kbtu.kz',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onTapOutside: _dismissKeyboard,
                    validator: (v) {
                      final email = (v ?? '').trim();
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
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('password'),
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      helperText: 'At least 8 characters',
                    ),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    onTapOutside: _dismissKeyboard,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v ?? '').length < 8
                        ? 'Password must contain at least 8 characters'
                        : null,
                  ),
                  Text(
                    '${_password.text.length} of 8',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('confirm'),
                    controller: _confirm,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: _agreed ? (_) => _submit() : null,
                    onTapOutside: _dismissKeyboard,
                    validator: (v) => (v ?? '').isEmpty || v != _password.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('group'),
                    initialValue: _group,
                    decoration: const InputDecoration(labelText: 'Group'),
                    items: [
                      for (final g in groups)
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: (g) => setState(() => _group = g),
                    validator: (g) => g == null ? 'Choose a group' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('birth'),
                    controller: _birthText,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: _pickBirthDate,
                    onTapOutside: _dismissKeyboard,
                    validator: (_) =>
                        _birth == null ? 'Choose your date of birth' : null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const ValueKey('agreed'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I agree to the rules'),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('submit'),
                    onPressed: _agreed ? _submit : null,
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ),
          ),
  );
}
