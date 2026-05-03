import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TanamanArticle {
  final String id;
  final String title;
  final String content;
  final String imagePath;
  final DateTime publishDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isPublished;
  final bool isDraft;
  final bool isDeleted;

  const TanamanArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.imagePath,
    required this.publishDate,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.isPublished = true,
    this.isDraft = false,
    this.isDeleted = false,
  });

  TanamanArticle copyWith({
    String? id,
    String? title,
    String? content,
    String? imagePath,
    DateTime? publishDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPublished,
    bool? isDraft,
    bool? isDeleted,
  }) {
    return TanamanArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      publishDate: publishDate ?? this.publishDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      isDraft: isDraft ?? this.isDraft,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'publishDate': publishDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': jsonEncode(tags),
      'isPublished': isPublished,
      'isDraft': isDraft,
      'isDeleted': isDeleted,
    };
  }

  factory TanamanArticle.fromMap(Map<String, dynamic> map) {
    return TanamanArticle(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imagePath: map['imagePath'] ?? '',
      publishDate: DateTime.parse(map['publishDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      isPublished: map['isPublished'] ?? true,
      isDraft: map['isDraft'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  factory TanamanArticle.fromApi(Map<String, dynamic> map) {
    return TanamanArticle(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imagePath: map['imagePath'] ?? '',
      publishDate: map['publishDate'] != null
          ? DateTime.parse(map['publishDate'])
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now()),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      tags: map['tags'] != null ? List<String>.from(map['tags']) : [],
      isPublished: map['isPublished'] ?? false,
      isDraft: map['isDraft'] ?? true,
    );
  }

  static List<TanamanArticle> getMockArticles() {
    assert(kDebugMode, 'getMockArticles should only be called in debug mode');
    final now = DateTime.now();
    return [
      TanamanArticle(
        id: '1',
        title: 'Jahe untuk Diabetes: Kontrol Gula Darah Alami',
        content: '''Diabetes Melitus adalah penyakit tidak menular yang semakin banyak diderita masyarakat. Nahasnya, banyak penderita yang belum menyadari bahwa jahe bisa membantu mengontrol gula darah!

Jahe mengandung gingerol yang terbukti secara ilmiah membantu:
• Meningkatkan sensitivitas insulin
• Menurunkan kadar gula darah puasa
• Mengurangi peradangan kronis (faktor risiko diabetes)
• Melindungi sel beta pankreas

Penelitian menunjukkan konsumsi jahe 2-4 gram per hari dapat menurunkan HbA1c pada penderita diabetes tipe 2.

Cara konsumsi:
1. Rebus 2-3 iris jahe segar dalam 1 gelas air selama 10 menit
2. Minum sebelum makan 2 kali sehari
3. Konsisten selama minimal 8 minggu untuk hasil optimal

Catatan: Jahe merupakan pendamping terapi, bukan pengganti obat. Konsultasikan dengan dokter terlebih dahulu.''',
        imagePath: 'assets/images/Jahe.jpg',
        publishDate: DateTime(2025, 1, 5),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 5)),
        tags: ['PTM', 'Diabetes', 'Jahe', 'KontrolGulaDarah'],
        isPublished: true,
        isDraft: false,
      ),
      TanamanArticle(
        id: '2',
        title: 'Kunyit untuk Pencegahan Kanker dan Jantung',
        content: '''Penyakit Tidak Menular (PTM) seperti kanker dan penyakit jantung koroner menjadi pembunuh nomor satu di Indonesia. Kabar baiknya, kunyit bisa jadi senjata ampuh untuk mencegahnya!

Kandungan kurkumin dalam kunyit telah terbukti melalui penelitian klinis:
• Menghambat pertumbuhan sel kanker (anti-karsinogenik)
• Mengurangi peradangan kronis yang memicu kanker
• Mencegah penumpukan plak di pembuluh darah
• Menurunkan risiko penyakit jantung koroner
• Melindungi otak dari degenerasi (mencegah stroke)

Fakta menarik: India yang rutin mengonsumsi kunyit memiliki angka kanker kolorektal lebih rendah dibanding negara Barat.

Cara konsumsi optimal:
1. Campurkan 1 sendok teh bubuk kunyit dengan sedikit minyak kelapa (kurkumin larut dalam lemak)
2. Tambahkan lada hitam (piperin meningkatkan penyerapan 2000%)
3. Konsumsi dengan susu kedelai hangat
4. Minum setiap malam sebelum tidur

Ingat: Pencegahan lebih baik daripada pengobatan!''',
        imagePath: 'assets/images/Kunyit.jpg',
        publishDate: DateTime(2025, 1, 3),
        createdAt: now.subtract(const Duration(days: 28)),
        updatedAt: now.subtract(const Duration(days: 3)),
        tags: ['PTM', 'Kanker', 'Jantung', 'Kunyit', 'Kurkumin'],
        isPublished: true,
        isDraft: false,
      ),
      TanamanArticle(
        id: '3',
        title: 'Daun Sirih untuk Pencegahan Diabetes dan Hipertensi',
        content: '''Diabetes dan hipertensi sering muncul bersamaan (sindrom metabolik). Ternyata daun sirih yang ada di pekarangan rumah bisa membantu mencegah kedua penyakit tidak menular ini!

Hasil penelitian modern membuktikan daun sirih mengandung:
• Eugenol: menurunkan tekanan darah dengan merelaksasi pembuluh darah
• Tanin: mengontrol gula darah pasca makan
• Kavikol: antioksidan kuat mencegah komplikasi diabetes

Manfaat spesifik untuk PTM:
• Menurunkan kadar gula darah puasa dan HbA1c
• Menstabilkan tekanan darah pada penderita hipertensi
• Mencegah komplikasi diabetes neuropati
• Melindungi pembuluh darah dari kerusakan

Cara konsumsi terapeutik:
1. Ambil 5-7 lembar daun sirih merah segar
2. Rebus dengan 2 gelas air hingga tersisa 1 gelas
3. Saring dan minum hangat
4. Konsumsi 2 kali sehari (pagi dan malam)

Tips: Gunakan daun sirih merah untuk hasil lebih optimal.''',
        imagePath: 'assets/images/Sirih.jpg',
        publishDate: DateTime(2025, 1, 1),
        createdAt: now.subtract(const Duration(days: 26)),
        updatedAt: now.subtract(const Duration(days: 1)),
        tags: ['PTM', 'Diabetes', 'Hipertensi', 'Sirih', 'SindromMetabolik'],
        isPublished: true,
        isDraft: false,
      ),
      TanamanArticle(
        id: '4',
        title: 'Belimbing Wuluh untuk Hipertensi dan Kolesterol',
        content: '''Hipertensi (tekanan darah tinggi) dan hiperkolesterolemia adalah duo berbahaya penyakit tidak menular yang menjadi pintu gerbang stroke dan serangan jantung. Belimbing wuluh bisa jadi solusi alami!

Penelitian dari Fakultas Kedokteran Universitas Indonesia membuktikan:
• Ekstrak belimbing wuluh menurunkan tekanan sistolik 10-15 mmHg
• Serat pektin mengikat kolesterol jahat (LDL)
• Vitamin C tinggi mencegah pengerasan arteri (aterosklerosis)
• Asam hidroksisitrat membantu metabolisme lemak

Manfaat klinis:
• Menurunkan tekanan darah pada penderita hipertensi grade 1
• Mengurangi kolesterol total hingga 20%
• Mencegah trombosis (penggumpalan darah)
• Melindungi fungsi ginjal dari hipertensi

Resep terapeutis:
1. Ambil 5-6 buah belimbing wuluh segar, cuci bersih
2. Rebus dengan 3 gelas air hingga mendidih
3. Tambahkan 1 sdm madu (hindari gula)
4. Minum selagi hangat 2-3 kali sehari
5. Konsumsi rutin minimal 4 minggu

Peringatan: Penderita hipertensi tetap harus memantau tekanan darah secara rutin dan tidak menghentikan obat tanpa konsultasi dokter.''',
        imagePath: '',
        publishDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        tags: ['PTM', 'Hipertensi', 'Kolesterol', 'Stroke', 'BelimbingWuluh'],
        isPublished: false,
        isDraft: true,
      ),
      TanamanArticle(
        id: '5',
        title: 'Temulawak untuk Pencegahan Fatty Liver dan Diabetes',
        content: '''Non-Alcoholic Fatty Liver Disease (NAFLD) dan diabetes tipe 2 sering berjalan beriringan sebagai bagian dari sindrom metabolik. Temulawak menawarkan perlindungan ganda untuk kedua kondisi PTM ini.

Temulawak mengandung kurkuminoid dan xanthorrhizol yang terbukti:
• Mengurangi peradangan hati (hepatoprotektor)
• Meningkatkan sensitivitas insulin
• Menurunkan resistensi insulin (kunci diabetes tipe 2)
• Mencegah steatosis hati (penumpukan lemak di hati)
• Melindungi sel-sel hati dari kerusakan oksidatif

Data epidemiologi: 70% penderita diabetes memiliki gangguan fungsi hati. Mencegah fatty liver berarti menurunkan risiko diabetes!

Protokol konsumsi untuk PTM:
1. Gunakan temulawak segar (10-15 gram) atau bubuk (1 sdm)
2. Rebus dengan air hangat 200ml
3. Tambahkan lemon untuk penyerapan lebih baik
4. Minum 30 menit sebelum sarapan
5. Rutin selama 12 minggu

Pantau hasilnya dengan pemeriksaan fungsi hati (SGOT, SGPT) dan gula darah secara berkala.

Catatan: Artikel ini masih dalam tahap penyuntingan medis.''',
        imagePath: 'assets/images/Temulawak.jpg',
        publishDate: now,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        tags: ['PTM', 'FattyLiver', 'Diabetes', 'Temulawak', 'SindromMetabolik'],
        isPublished: false,
        isDraft: true,
      ),
    ];
  }

  String get formattedDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${publishDate.day} ${months[publishDate.month - 1]} ${publishDate.year}';
  }

  String get statusLabel {
    if (isDeleted) return 'Dihapus';
    if (isDraft) return 'Draft';
    if (isPublished) return 'Dipublikasikan';
    return 'Tidak Dipublikasikan';
  }

  Color get statusColor {
    if (isDeleted) return Colors.red;
    if (isDraft) return Colors.orange;
    if (isPublished) return Colors.green;
    return Colors.grey;
  }
}
