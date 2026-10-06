import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(
    text: 'student@example.com',
  );
  final _passwordController = TextEditingController(text: 'student123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // void _fillCredentials(String email, String password) {
  //   setState(() {
  //     _identifierController.text = email;
  //     _passwordController.text = password;
  //   });
  // }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authProvider.notifier)
          .login(_identifierController.text.trim(), _passwordController.text);
    }
  }

  // void _showServerSettingsDialog() {
  //   final storage = ref.read(storageProvider);
  //   final urlController = TextEditingController(text: storage.getBaseUrl());

  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text('Backend Server URL'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Set the backend Express server URL:',
  //             style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
  //           ),
  //           const SizedBox(height: 12),
  //           TextField(
  //             controller: urlController,
  //             decoration: const InputDecoration(
  //               labelText: 'Base URL',
  //               hintText: 'e.g. http://localhost:3000 or http://10.0.2.2:3000',
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           Wrap(
  //             spacing: 6,
  //             runSpacing: 6,
  //             children: [
  //               ActionChip(
  //                 label: const Text(
  //                   'Localhost (3000)',
  //                   style: TextStyle(fontSize: 11),
  //                 ),
  //                 onPressed: () => urlController.text = 'http://localhost:3000',
  //               ),
  //               ActionChip(
  //                 label: const Text(
  //                   'Android (10.0.2.2)',
  //                   style: TextStyle(fontSize: 11),
  //                 ),
  //                 onPressed: () => urlController.text = 'http://10.0.2.2:3000',
  //               ),
  //               ActionChip(
  //                 label: const Text(
  //                   'Render Live',
  //                   style: TextStyle(fontSize: 11),
  //                 ),
  //                 onPressed: () =>
  //                     urlController.text = 'https://itlab-2.onrender.com',
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             final newUrl = urlController.text.trim();
  //             if (newUrl.isNotEmpty) {
  //               await storage.saveBaseUrl(newUrl);
  //               if (mounted) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('Server URL set to: $newUrl')),
  //                 );
  //               }
  //             }
  //             if (ctx.mounted) Navigator.pop(ctx);
  //           },
  //           child: const Text('Save'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    // final storage = ref.watch(storageProvider);

    ref.listen(authProvider, (prev, next) {
      if (next is AsyncError) {
        final errorMsg = next.error
            .toString()
            .replaceAll('Exception:', '')
            .trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       tooltip: 'Server Settings',
      //       icon: const Icon(
      //         Icons.settings_outlined,
      //         color: AppTheme.textSecondary,
      //       ),
      //       onPressed: _showServerSettingsDialog,
      //     ),
      //   ],
      // ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.borderLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Icon Header
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.quiz_rounded,
                            size: 36,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'College MCQ System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access your exams and dashboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email / Username field
                      TextFormField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: 'Email or Username',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email or username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // const Divider(),
                      // const SizedBox(height: 12),

                      // // Quick Fill Presets
                      // const Text(
                      //   'Demo Accounts (In-Memory Backend)',
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w600,
                      //     color: AppTheme.textSecondary,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                      // const SizedBox(height: 10),

                      // Wrap(
                      //   alignment: WrapAlignment.center,
                      //   spacing: 8,
                      //   runSpacing: 8,
                      //   children: [
                      //     ChoiceChip(
                      //       label: const Text('🎓 Student 1'),
                      //       selected: _identifierController.text == 'student@example.com',
                      //       onSelected: (_) =>
                      //           _fillCredentials('student@example.com', 'student123'),
                      //     ),
                      //     ChoiceChip(
                      //       label: const Text('🎓 Student 2'),
                      //       selected: _identifierController.text == 'student2@example.com',
                      //       onSelected: (_) =>
                      //           _fillCredentials('student2@example.com', 'student123'),
                      //     ),
                      //     ChoiceChip(
                      //       label: const Text('👨‍🏫 Examiner'),
                      //       selected: _identifierController.text == 'examiner@example.com',
                      //       onSelected: (_) =>
                      //           _fillCredentials('examiner@example.com', 'examiner123'),
                      //     ),
                      //     ChoiceChip(
                      //       label: const Text('🛡️ Admin'),
                      //       selected: _identifierController.text == 'admin@example.com',
                      //       onSelected: (_) =>
                      //           _fillCredentials('admin@example.com', 'admin123'),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 16),
                      // Center(
                      //   child: InkWell(
                      //     onTap: _showServerSettingsDialog,
                      //     borderRadius: BorderRadius.circular(6),
                      //     child: Padding(
                      //       padding: const EdgeInsets.symmetric(
                      //         horizontal: 8,
                      //         vertical: 4,
                      //       ),
                      //       child: Text(
                      //         'Server: ${storage.getBaseUrl()}',
                      //         style: const TextStyle(
                      //           fontSize: 11,
                      //           color: AppTheme.textSecondary,
                      //           decoration: TextDecoration.underline,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
