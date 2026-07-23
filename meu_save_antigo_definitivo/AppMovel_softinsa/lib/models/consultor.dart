class Consultor {
  final int id;
  final String nome;
  final String email;
  final String telefone;
  final String area;
  final String learningPath;
  final int badgesObtidos;
  final int totalBadges;

  Consultor({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.area,
    required this.learningPath,
    required this.badgesObtidos,
    required this.totalBadges,
  });

  // Converte de Map (BD/API) para Objeto
  factory Consultor.fromMap(Map<String, dynamic> map) {
    return Consultor(
      id: map['id'] ?? 0,
      nome: map['nome'] ?? 'Desconhecido',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      area: map['area_nome'] ?? 'N/A', // Mapeado para a coluna 'area_nome' da BD
      learningPath: map['learning_path_nome'] ?? 'N/A', // Mapeado para 'learning_path_nome'
      badgesObtidos: map['badgesObtidos'] ?? 12, // Temporário: O ideal seria ler isto com um COUNT na DB
      totalBadges: map['totalBadges'] ?? 20,
    );
  }
}
