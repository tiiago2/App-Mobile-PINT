import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uicons/uicons.dart';
import '../variaveis/variaveis.dart';

class AppNavegacao extends StatefulWidget {
  final Widget ecraAtual; // O recheio (ecrã) que as rotas vão injetar aqui

  const AppNavegacao({super.key, required this.ecraAtual});

  @override
  State<AppNavegacao> createState() => _AppNavegacaoState();
}

class _AppNavegacaoState extends State<AppNavegacao> {

  // Descobre qual ícone deve estar "aceso" com base no URL da rota
  int _calcularIndice(String location) {
    if (location.startsWith('/galeria')) return 0;
    if (location.startsWith('/objetivos')) return 1;
    if (location.startsWith('/estatisticas')) return 3;
    if (location.startsWith('/perfil')) return 4;
    return 2; // Por defeito, acende o botão do Início
  }

  // Faz a viagem quando tocas num dos botões
  void _aoTocar(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/galeria');
        break;
      case 1:
        context.go('/objetivos');
        break;
      case 2:
        context.go('/home');
        break;
      case 3:
        context.go('/estatisticas');
        break;
      case 4:
        context.go('/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lê a rota atual onde a app está
    final String location = GoRouterState.of(context).uri.toString();
    final int indiceAtual = _calcularIndice(location);

    // Variável mestre de tamanho retirada da tua Central de Comando
    final double tamanhoIcone = AppTamanhos.iconeNavegacao;

    return Scaffold(
      body: widget.ecraAtual,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppCores.azulFundo, // A tua cor da Central
        type: BottomNavigationBarType.fixed,
        currentIndex: indiceAtual,
        onTap: (index) => _aoTocar(index, context),
        selectedItemColor: AppCores.azulClaro,
        unselectedItemColor: AppCores.branco,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(UIcons.boldRounded.badge, size: tamanhoIcone),
            activeIcon: Icon(UIcons.boldRounded.badge, size: tamanhoIcone),
            label: 'Galeria',
          ),
          BottomNavigationBarItem(
            icon: Icon(UIcons.boldRounded.target, size: tamanhoIcone),
            activeIcon: Icon(UIcons.boldRounded.target, size: tamanhoIcone),
            label: 'Objetivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(UIcons.boldRounded.home, size: tamanhoIcone),
            activeIcon: Icon(UIcons.boldRounded.home, size: tamanhoIcone),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(UIcons.boldRounded.chart_histogram, size: tamanhoIcone),
            activeIcon: Icon(
              UIcons.boldRounded.chart_histogram,
              size: tamanhoIcone,
            ),
            label: 'Pesquisa',
          ),
          BottomNavigationBarItem(
            icon: Icon(UIcons.boldRounded.portrait, size: tamanhoIcone),
            activeIcon: Icon(UIcons.boldRounded.portrait, size: tamanhoIcone),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
