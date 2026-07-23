import 'package:flutter/material.dart';

import '../variaveis/variaveis.dart';

class SessionLoadingScreen extends StatelessWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppCores.branco,
      body: Center(
        child: CircularProgressIndicator(
          color: AppCores.azulFundo,
        ),
      ),
    );
  }
}
