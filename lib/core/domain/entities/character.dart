class Character {
  final String name;
  final String nameCn; // Chinese name/alias if available
  final String imageUrl;
  final String role; // e.g. 主角, 配角
  final String cv; // Cast name

  const Character({
    required this.name,
    this.nameCn = '',
    required this.imageUrl,
    required this.role,
    this.cv = '',
  });

  factory Character.empty() {
    return const Character(
      name: '',
      imageUrl: '',
      role: '',
    );
  }
}
