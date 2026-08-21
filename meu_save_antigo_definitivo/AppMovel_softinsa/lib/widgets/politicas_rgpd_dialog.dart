import 'package:flutter/material.dart';
import '../variaveis/variaveis.dart';
import '../idiomas/app_localizations.dart';

/// Modal bottom sheet reutilizável que apresenta as Políticas de Privacidade e RGPD.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppCores.branco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            width: 48.0,
            height: 5.0,
            decoration: BoxDecoration(
              color: AppCores.outline,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header com título e botão fechar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.politicasRgpd ?? 'Políticas RGPD',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppCores.fontes,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppCores.fontes),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: AppCores.outline),

          // Conteúdo com scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Responsável pelo Tratamento',
                    'A Softinsa, S.A., com sede em Tomar, Portugal, é a entidade responsável pelo tratamento dos seus dados pessoais no âmbito da plataforma de gestão de competências e badges.',
                  ),
                  _buildSection(
                    '2. Dados Pessoais Recolhidos',
                    'Nome completo, endereço de email profissional, número de telefone, área funcional, cargo/função, fotografia de perfil, histórico de badges e certificações obtidas, progresso em learning paths e objetivos profissionais.',
                  ),
                  _buildSection(
                    '3. Finalidade do Tratamento',
                    'Os dados são tratados exclusivamente para:\n'
                    '• Gestão interna de competências e certificações dos consultores;\n'
                    '• Atribuição e acompanhamento de badges de competência;\n'
                    '• Definição de objetivos profissionais e acompanhamento de progresso;\n'
                    '• Geração de rankings e estatísticas de desempenho;\n'
                    '• Comunicações internas e notificações relacionadas com a plataforma.',
                  ),
                  _buildSection(
                    '4. Base Legal',
                    'O tratamento dos dados é realizado com base no consentimento do titular (artigo 6.º, n.º 1, alínea a) do RGPD) e na execução do contrato de trabalho e cumprimento de obrigações legais (artigo 6.º, n.º 1, alínea b) do RGPD).',
                  ),
                  _buildSection(
                    '5. Conservação dos Dados',
                    'Os dados pessoais são conservados durante o período de vigência da relação laboral e pelos prazos legais subsequentes legalmente exigidos.',
                  ),
                  _buildSection(
                    '6. Direitos do Titular',
                    'Nos termos da legislação aplicável, o utilizador tem o direito de aceder, retificar, apagar, limitar o tratamento, requerer a portabilidade e opor-se ao tratamento dos seus dados pessoais. Para exercer qualquer um destes direitos, contacte o Encarregado de Proteção de Dados através de: rgpd@softinsa.pt',
                  ),
                  _buildSection(
                    '7. Segurança da Informação',
                    'A Softinsa implementa medidas técnicas e organizativas adequadas para assegurar um nível de segurança apropriado ao risco, protegendo os dados pessoais contra perda, alteração, acesso indevido ou divulgação não autorizada.',
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),

          // Botão inferior Fechar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCores.azulFundo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorders.padrao),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Compreendi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSection(String titulo, String conteudo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppCores.fontes,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            conteudo,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0,
              height: 1.45,
              color: AppCores.fontes.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
