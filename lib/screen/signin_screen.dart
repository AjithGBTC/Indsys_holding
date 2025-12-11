import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/common.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        ClipPath(clipper: BlueClipper(), child: Container(height: 250, color: const Color(0xff0AA2E8), child: const Center(child: Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))))),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: ListView(children: [
          const SizedBox(height: 10),
          const Text('Full Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(controller: nameCtrl, decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade200, hintText: 'Enter full name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(controller: emailCtrl, decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade200, hintText: 'Enter email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(controller: passCtrl, obscureText: _obscure, decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade200, hintText: 'Enter password', suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          const Text('Confirm Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(controller: confirmCtrl, obscureText: _obscureConfirm, decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade200, hintText: 'Confirm password', suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: auth.isLoading ? null : () async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final pass = passCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();
            if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
              return;
            }
            if (pass != confirm) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
              return;
            }
            final res = await auth.signup(context, email: email, password: pass);
            if (res == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created')));
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
            }
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0AA2E8), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)))), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Already have an account? '), GestureDetector(onTap: () => Navigator.pop(context), child: Text('Login', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)))]), const SizedBox(height: 25), ]))),
      ]),
    );
  }
}
