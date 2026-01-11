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
      // 1. Tenta realizar o login no Firebase
      await Provider.of<AuthService>(context, listen: false).login(
        _emailController.text.trim(),
        _senhaController.text.trim(),
      );

      // 2. Se o login for bem-sucedido, fechamos esta tela.
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),
              
              // Logo da Manga com Fundo Roxo
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: AppColors.roxoClaro,
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scale: 1.2,
                    child: Image.asset(
                      'assets/imagem_logo_manga.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Text(
                "Login", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),

              // Campos de Entrada
              _buildTextField("E-mail", _emailController, keyboardType: TextInputType.emailAddress),
              _buildTextField("Senha", _senhaController, obscure: true),

              // Esqueci a Senha
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
                    style: TextStyle(
                      color: AppColors.verdeEscuro, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Botão Entrar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _estaCarregando ? null : _fazerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeEscuro,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                    ),
                    elevation: 0,
                  ),
                  child: _estaCarregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Entrar",
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // Link para Cadastro
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "Não tem uma conta? Cadastre-se",
                  style: TextStyle(
                    color: AppColors.roxoEscuro, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir os TextFields mantendo o padrão visual
  Widget _buildTextField(
    String hint, 
    TextEditingController controller, 
    {bool obscure = false, TextInputType keyboardType = TextInputType.text}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.cinzaClaro,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
            borderSide: BorderSide.none
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}