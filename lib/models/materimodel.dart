// lib/models/materimodel.dart
class Materi {
  final int id;
  final String judul;
  final String konten;
  final String kategori;

  Materi({required this.id, required this.judul, required this.konten, required this.kategori});

  factory Materi.fromJson(Map<String, dynamic> json) {
    return Materi(
      id: json['id'],
      judul: json['judul'],
      konten: json['konten'],
      kategori: json['kategori'],
    );
  }
}
