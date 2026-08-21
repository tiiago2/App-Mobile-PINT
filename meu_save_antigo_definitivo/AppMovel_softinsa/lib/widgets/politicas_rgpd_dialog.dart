import 'package:flutter/material.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';

class PoliticasRgpdDialog extends StatelessWidget {
  const PoliticasRgpdDialog({super.key});

  static void mostrar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PoliticasRgpdDialog(),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: AppCores.fontes,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              color: AppCores.fontes,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorders.padrao),
          topRight: Radius.circular(AppBorders.padrao),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            width: 40.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: AppCores.outline,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n?.politicasRgpd ?? 'Políticas RGPD',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
                color: AppCores.fontes,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(color: AppCores.outline, height: 1.0),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('1. Responsável pelo Tratamento', 'A Softinsa, S.A., com sede em Tomar, Portugal, é a entidade responsável pelo tratamento dos seus dados pessoais no âmbito da plataforma de gestão de competências e badges.'),
                  _buildSection('2. Dados Pessoais Recolhidos', 'Nome completo, endereço de email profissional, número de telefone, área funcional, cargo/função, fotografia de perfil, histórico de badges e certificações obtidas, progresso em learning paths e objetivos pessoais.'),
                  _buildSection('3. Finalidade do Tratamento', 'Os dados são tratados para gestão interna de competências e certificações dos consultores, atribuição e acompanhamento de badges de competência, definição de objetivos profissionais e acompanhamento de progresso, geração de rankings e estatísticas de desempenho, e comunicações internas relacionadas com a plataforma.'),
                  _buildSection('4. Base Legal', 'O tratamento é realizado com base no consentimento do titular (artigo 6.º, n.º 1, alínea a) do RGPD) e na execução do contrato de trabalho (artigo 6.º, n.º 1, alínea b) do RGPD).'),
                  _buildSection('5. Conservação dos Dados', 'Os dados pessoais são conservados durante o período de vigência da relação laboral e pelo prazo legalmente exigido após a sua cessação.'),
                  _buildSection('6. Direitos do Titular', 'O utilizador tem o direito de aceder, retificar, apagar, limitar o tratamento, portabilidade e oposição ao tratamento dos seus dados pessoais. Para exercer estes direitos, contacte: rgpd@softinsa.pt'),
                  _buildSection('7. Segurança', 'A Softinsa implementa medidas técnicas e organizativas adequadas para proteger os dados pessoais contra acessos não autorizados, alteração, divulgação ou destruição.'),
                ],
              ),
            ),
          ),
          // Close Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCores.azulFundo,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorders.padrao),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: AppCores.branco,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
