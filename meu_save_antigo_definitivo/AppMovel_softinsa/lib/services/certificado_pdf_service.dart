import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dados necessários para gerar o certificado de badge em PDF.
class CertificadoBadgeData {
  final String nomeBadge;
  final String descricaoBadge;
  final String? imagemBadgeUrl;
  final int pontos;
  final int validadeDias;
  final String nivel;
  final String area;
  final String serviceLine;
  final String learningPath;
  final bool especial;

  final String nomeConsultor;
  final String emailConsultor;

  final int idRegisto;
  final DateTime? dataObtencao;
  final DateTime? dataExpiracao;

  final String urlPublica;

  const CertificadoBadgeData({
    required this.nomeBadge,
    required this.descricaoBadge,
    this.imagemBadgeUrl,
    required this.pontos,
    required this.validadeDias,
    required this.nivel,
    required this.area,
    this.serviceLine = '',
    this.learningPath = '',
    this.especial = false,
    required this.nomeConsultor,
    required this.emailConsultor,
    required this.idRegisto,
    this.dataObtencao,
    this.dataExpiracao,
    required this.urlPublica,
  });
}

/// Serviço para gerar o PDF do certificado de badge.
class CertificadoPdfService {
  CertificadoPdfService._();

  // ── Cores ──────────────────────────────────────────────────────────────────

  static const _corFundo = PdfColor.fromInt(0xFFF5F9FF);
  static const _corBordaAzul = PdfColor.fromInt(0xFF0056B9);
  static const _corTextoTitulo = PdfColor.fromInt(0xFF0056B9);
  static const _corTextoEscuro = PdfColor.fromInt(0xFF222222);
  static const _corTextoCinza = PdfColor.fromInt(0xFF555555);
  static const _corBadgeFallbackBg = PdfColor.fromInt(0xFFDDE8F5);
  static const _corBadgeFallbackTxt = PdfColor.fromInt(0xFF0056B9);

  // ── Margens e medidas ──────────────────────────────────────────────────────

  static const double _margemBorda = 26;
  static const double _espessuraBorda = 3;
  static const double _logoW = 132;
  static const double _logoH = 50;
  static const double _badgeImgSize = 116;

  // ── Ponto de entrada ───────────────────────────────────────────────────────

  /// Gera o PDF e devolve o caminho do ficheiro guardado no dispositivo.
  static Future<String> gerarCertificadoBadgePdf(CertificadoBadgeData data) async {
    // 1. Carregar imagens em memória (assíncrono)
    final logoBytes = await _carregarAssetImage('assets/images/logotipo_softinsa.png');
    final badgeBytes = await _carregarImagemRemota(data.imagemBadgeUrl);

    // 2. Construir o documento PDF
    final pdf = pw.Document(
      title: 'Certificado - ${data.nomeBadge}',
      author: 'Plataforma de Badges Softinsa',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return _buildPagina(context, data, logoBytes, badgeBytes);
        },
      ),
    );

    // 3. Guardar o ficheiro
    final dir = await getApplicationDocumentsDirectory();
    final nomeSeguro = data.nomeBadge.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filePath = '${dir.path}/Certificado_$nomeSeguro.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    debugPrint('✅ [CertificadoPdf] PDF gerado em: $filePath');
    return filePath;
  }

  // ── Página Principal ───────────────────────────────────────────────────────

  static pw.Widget _buildPagina(
    pw.Context context,
    CertificadoBadgeData data,
    Uint8List? logoBytes,
    Uint8List? badgeBytes,
  ) {
    final pageW = PdfPageFormat.a4.landscape.width;
    final pageH = PdfPageFormat.a4.landscape.height;

    return pw.Container(
      width: pageW,
      height: pageH,
      color: _corFundo,
      child: pw.Stack(
        children: [
          // ── Borda azul ─────────────────────────────────────────────────
          pw.Positioned(
            left: _margemBorda,
            top: _margemBorda,
            child: pw.Container(
              width: pageW - _margemBorda * 2,
              height: pageH - _margemBorda * 2,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: _corBordaAzul,
                  width: _espessuraBorda,
                ),
              ),
            ),
          ),

          // ── Logótipo Softinsa ──────────────────────────────────────────
          if (logoBytes != null)
            pw.Positioned(
              left: 52,
              top: 44,
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                width: _logoW,
                height: _logoH,
                fit: pw.BoxFit.contain,
              ),
            ),

          // ── Conteúdo central ────────────────────────────────────────────
          pw.Positioned(
            left: _margemBorda + 20,
            right: _margemBorda + 20,
            top: 44,
            bottom: _margemBorda + 20,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Espaço para o logo
                pw.SizedBox(height: 10),

                // Título do certificado
                pw.Text(
                  'Certificado de Conquista de Badge',
                  style: pw.TextStyle(
                    color: _corTextoTitulo,
                    fontSize: 25,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 18),

                // "Certifica-se que"
                pw.Text(
                  'Certifica-se que',
                  style: pw.TextStyle(
                    color: _corTextoEscuro,
                    fontSize: 14,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 10),

                // Nome do consultor
                pw.Text(
                  data.nomeConsultor,
                  style: pw.TextStyle(
                    color: _corTextoEscuro,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 10),

                // "conquistou o badge"
                pw.Text(
                  'conquistou o badge',
                  style: pw.TextStyle(
                    color: _corTextoEscuro,
                    fontSize: 14,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 10),

                // Nome do badge
                pw.Text(
                  data.nomeBadge,
                  style: pw.TextStyle(
                    color: _corTextoTitulo,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),

                pw.SizedBox(height: 14),

                // Imagem do badge
                _buildBadgeImage(badgeBytes),

                pw.Spacer(),

                // Secção de detalhes (metadados)
                _buildDetalhes(data),

                pw.SizedBox(height: 8),

                // Rodapé técnico
                _buildRodape(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Imagem do Badge ────────────────────────────────────────────────────────

  static pw.Widget _buildBadgeImage(Uint8List? badgeBytes) {
    if (badgeBytes != null) {
      return pw.Center(
        child: pw.ClipOval(
          child: pw.Image(
            pw.MemoryImage(badgeBytes),
            width: _badgeImgSize,
            height: _badgeImgSize,
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }

    // Fallback: retângulo arredondado com "B"
    return pw.Center(
      child: pw.Container(
        width: _badgeImgSize,
        height: _badgeImgSize,
        decoration: pw.BoxDecoration(
          color: _corBadgeFallbackBg,
          borderRadius: pw.BorderRadius.circular(16),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'B',
          style: pw.TextStyle(
            color: _corBadgeFallbackTxt,
            fontSize: 52,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Secção de Detalhes (Rodapé de Metadados) ──────────────────────────────

  static pw.Widget _buildDetalhes(CertificadoBadgeData data) {
    final estiloLabel = pw.TextStyle(
      color: _corTextoCinza,
      fontSize: 10,
    );

    final dataObtStr = data.dataObtencao != null
        ? _formatarData(data.dataObtencao!)
        : '—';
    final dataExpStr = data.dataExpiracao != null
        ? _formatarData(data.dataExpiracao!)
        : 'Sem expiração';
    final validadeStr = data.validadeDias > 0
        ? '${data.validadeDias} dias'
        : 'Sem expiração';
    final tipoStr = data.especial ? 'Especial' : 'Normal';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Descrição (com quebra de linha)
        pw.Text(
          'Descrição: ${data.descricaoBadge}',
          style: estiloLabel,
          maxLines: 3,
        ),
        pw.SizedBox(height: 2),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),

        // Duas colunas: esquerda e direita
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Coluna esquerda
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nível: ${data.nivel}', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Área: ${data.area}', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  if (data.serviceLine.isNotEmpty)
                    pw.Text('Service Line: ${data.serviceLine}', style: estiloLabel),
                  if (data.serviceLine.isNotEmpty)
                    pw.SizedBox(height: 2),
                  if (data.learningPath.isNotEmpty)
                    pw.Text('Learning Path: ${data.learningPath}', style: estiloLabel),
                ],
              ),
            ),

            // Coluna direita
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Pontos: ${data.pontos}', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Tipo: $tipoStr', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Validade: $validadeStr', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Data de obtenção: $dataObtStr', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Data de expiração: $dataExpStr', style: estiloLabel),
                  pw.SizedBox(height: 2),
                  pw.Text('Registo: ${data.idRegisto}', style: estiloLabel),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Rodapé Técnico ─────────────────────────────────────────────────────────

  static pw.Widget _buildRodape(CertificadoBadgeData data) {
    final agora = DateTime.now();
    final emitidoStr = _formatarDataHora(agora);

    final estiloRodape = pw.TextStyle(
      color: _corTextoCinza,
      fontSize: 8,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Emitido em: $emitidoStr', style: estiloRodape),
                  pw.SizedBox(height: 1),
                  pw.Text('Página pública: ${data.urlPublica}', style: estiloRodape),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Plataforma de Badges Softinsa',
            style: pw.TextStyle(
              color: _corTextoCinza,
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ── Utilitários de carregamento de imagens ─────────────────────────────────

  /// Carrega uma imagem de um asset local do Flutter.
  static Future<Uint8List?> _carregarAssetImage(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('⚠️ [CertificadoPdf] Erro ao carregar asset "$assetPath": $e');
      return null;
    }
  }

  /// Carrega uma imagem remota (Cloudinary, etc.) via HTTP.
  static Future<Uint8List?> _carregarImagemRemota(String? url) async {
    if (url == null || url.isEmpty || !url.startsWith('http')) return null;

    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      debugPrint('⚠️ [CertificadoPdf] Erro ao carregar imagem remota "$url": $e');
    }
    return null;
  }

  // ── Formatação de datas ────────────────────────────────────────────────────

  static String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  static String _formatarDataHora(DateTime dt) {
    return '${_formatarData(dt)} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
