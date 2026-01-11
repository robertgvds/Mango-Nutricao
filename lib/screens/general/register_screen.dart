import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'verification_screen.dart';
import '../../widgets/app_colors.dart';

enum UserType { paciente, nutricionista }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  UserType _selectedUser = UserType.paciente;
  String _generoSelecionado = 'Feminino'; // Valor padrão para o gênero
  bool _estaCarregando = false;

  final _nomeController = TextEditingController();
  final _dataNascController = TextEditingController();
  final _crnController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final maskFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _senhasNaoCoincidem = false;
  bool _formularioCompleto = false;
  String? _erroRequisitoSenha;

  @override
  void initState() {
    super.initState();
    List<TextEditingController> controllers = [
      _nomeController,
      _dataNascController,
      _crnController,
      _emailController,
      _senhaController,
      _confirmarSenhaController,
    ];
    for (var controller in controllers) {
      controller.addListener(_atualizarEstadoFormulario);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascController.dispose();
    _crnController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  String? _validarRequisitosSenha(String senha) {
    if (senha.isEmpty) return null;
    if (senha.length < 8) return "A senha deve ter pelo menos 8 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(senha)) return "Adicione pelo menos uma letra maiúscula";
    if (!RegExp(r'[0-9]').hasMatch(senha)) return "Adicione pelo menos um número";
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(senha)) return "Adicione um caractere especial (ex: @, #, %)";
    return null;
  }

  String? _validarDataNascimento(String data) {
    if (data.isEmpty || data.length < 10) return null;
    try {
      List<String> partes = data.split('/');
      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int ano = int.parse(partes[2]);
      final dataInformada = DateTime(ano, mes, dia);
      final hoje = DateTime.now();
      if (dataInformada.day != dia || dataInformada.month != mes || dataInformada.year != ano) return "Data inválida";
      if (dataInformada.isAfter(hoje)) return "A data não pode ser no futuro";
      if (ano < 1900) return "Ano inválido";
      return null;
    } catch (e) {
      return "Formato de data incorreto";
    }
  }

  void _atualizarEstadoFormulario() {
    final senha = _senhaController.text;
    final confirmar = _confirmarSenhaController.text;
    final erroSenha = _validarRequisitosSenha(senha);
    final erroData = _validarDataNascimento(_dataNascController.text);

    final coincidem = senha.isNotEmpty && confirmar.isNotEmpty && senha != confirmar;

    setState(() {
      _erroRequisitoSenha = erroSenha;
      _senhasNaoCoincidem = coincidem;

      final camposBasicosOk = _nomeController.text.isNotEmpty &&
          _dataNascController.text.length == 10 &&
          _emailController.text.contains('@') &&
          senha.isNotEmpty &&
          confirmar.isNotEmpty;

      final crnOk = (_selectedUser == UserType.paciente) || _crnController.text.isNotEmpty;

      _formularioCompleto = camposBasicosOk && crnOk && erroSenha == null && erroData == null;
    });
  }

  Future<void> _cadastrarNoFirebase() async {
    setState(() => _estaCarregando = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.registrar(
        _emailController.text.trim(),
        _senhaController.text.trim(),
        _nomeController.text.trim(),
        _selectedUser == UserType.paciente ? 'paciente' : 'nutricionista',
        _selectedUser == UserType.nutricionista ? _crnController.text.trim() : null,
        _generoSelecionado, // Passando o gênero selecionado para o serviço
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerificationScreen()),
        );
      }
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

  Widget _buildErrorMessage(String message, {Color color = Colors.red}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool obscure = false, List<MaskTextInputFormatter>? inputFormatters, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        onChanged: (_) => _atualizarEstadoFormulario(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.preto, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(30),
                isSelected: [_selectedUser == UserType.paciente, _selectedUser == UserType.nutricionista],
                onPressed: (index) => setState(() {
                  _selectedUser = index == 0 ? UserType.paciente : UserType.nutricionista;
                  _atualizarEstadoFormulario();
                }),
                fillColor: AppColors.roxoClaro,
                selectedColor: AppColors.preto,
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 45) / 2, minHeight: 45),
                children: const [Text("Paciente"), Text("Nutricionista")],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Dados Pessoais", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField("Insira seu nome completo", _nomeController),
            _buildTextField("Insira sua Data de Nascimento", _dataNascController, inputFormatters: [maskFormatter], keyboardType: TextInputType.number),
            
            if (_dataNascController.text.length == 10 && _validarDataNascimento(_dataNascController.text) != null)
              _buildErrorMessage(_validarDataNascimento(_dataNascController.text)!),

            // CAMPO GÊNERO (Mesmo design do ToggleButtons acima)
            const SizedBox(height: 15),
            const Text("Gênero", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(30),
                isSelected: [_generoSelecionado == 'Feminino', _generoSelecionado == 'Masculino'],
                onPressed: (index) => setState(() {
                  _generoSelecionado = index == 0 ? 'Feminino' : 'Masculino';
                  _atualizarEstadoFormulario();
                }),
                fillColor: AppColors.roxoClaro,
                selectedColor: AppColors.preto,
                constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 45) / 2, minHeight: 45),
                children: const [Text("Feminino"), Text("Masculino")],
              ),
            ),

            if (_selectedUser == UserType.nutricionista) _buildTextField("Insira seu CRN", _crnController),

            const SizedBox(height: 20),
            const Text("Dados de Acesso", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField("E-mail", _emailController, keyboardType: TextInputType.emailAddress),
            _buildTextField("Defina sua senha", _senhaController, obscure: true),
            
            if (_erroRequisitoSenha != null) _buildErrorMessage(_erroRequisitoSenha!, color: Colors.orange),

            _buildTextField("Confirme sua senha", _confirmarSenhaController, obscure: true),
            
            if (_senhasNaoCoincidem) _buildErrorMessage("As senhas não coincidem."),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_formularioCompleto && !_estaCarregando) ? _cadastrarNoFirebase : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roxoEscuro,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _estaCarregando 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Realizar Cadastro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}