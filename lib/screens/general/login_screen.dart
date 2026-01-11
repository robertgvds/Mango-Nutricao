import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _estaCarregando = false;

  Future<void> _fazerLogin() async {
    setState(() => _estaCarregando = true);
    try {
      await Provider.of<AuthService>(context, listen: false).login(
        _emailController.text.trim(),
        _senhaController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _estaCarregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Container(
                width: 150, // Tamanho do círculo mantido
                height: 150,
                decoration: const BoxDecoration(
                  color: AppColors.roxoClaro, 
                  shape: BoxShape.circle,
                ),
                child: Transform.scale(
                  scale: 1.2, // 1.0 é o tamanho normal. 1.2 aumenta em 20%
                  child: Image.asset(
                    'assets/imagem_logo_manga.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
                        const SizedBox(height: 30),
            const Text("Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField("E-mail", _emailController),
            _buildTextField("Senha", _senhaController, obscure: true),
            
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  "Esqueci a minha senha",
                  style: TextStyle(color: AppColors.verdeEscuro, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 10), 
            
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _estaCarregando ? null : _fazerLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeEscuro,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _estaCarregando 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Entrar", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterScreen())),
              child: const Text("Não tem uma conta? Cadastre-se", style: TextStyle(color: AppColors.roxoEscuro, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.cinzaClaro,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}