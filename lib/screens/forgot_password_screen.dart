import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pet_owner_app/db/database_helper.dart';
import 'package:pet_owner_app/services/email_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _generatedCode;
  bool _codeSent = false;
  bool _isLoading = false;

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final userExists = await DatabaseHelper.instance.getOwnerByEmail(email);

    if (userExists == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun compte trouvé pour cet e-mail.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    _generatedCode = (100000 + Random().nextInt(900000)).toString();

    try {
      await EmailService.sendPasswordResetEmail(email, _generatedCode!);
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un code a été envoyé à votre adresse e-mail.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'e-mail: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_codeController.text.trim() != _generatedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code de vérification incorrect.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await DatabaseHelper.instance.updateOwnerPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe réinitialisé avec succès !')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                validator: (value) => value!.isEmpty ? 'Veuillez entrer votre e-mail' : null,
                enabled: !_codeSent,
              ),
              const SizedBox(height: 16),
              if (_codeSent)
                ...[
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: 'Code de vérification'),
                    validator: (value) => value!.isEmpty ? 'Veuillez entrer le code' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Veuillez entrer un mot de passe' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Veuillez confirmer votre mot de passe' : null,
                  ),
                ],
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _codeSent ? _resetPassword : _sendResetCode,
                  child: Text(_codeSent ? 'Réinitialiser' : 'Envoyer le code'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
