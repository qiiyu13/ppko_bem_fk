import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<({String q, String a})> _faqs = [
    (
      q: 'Bagaimana cara mendaftar akun?',
      a: 'Buka layar awal lalu pilih "Daftar". Masukkan nomor KK, nama, nomor telepon, kata sandi, lalu pilih wilayah RW/RT Anda.',
    ),
    (
      q: 'Saya lupa kata sandi, apa yang harus dilakukan?',
      a: 'Hubungi admin wilayah Anda untuk reset kata sandi. Fitur reset mandiri akan tersedia pada pembaruan berikutnya.',
    ),
    (
      q: 'Bagaimana cara melakukan skrining kesehatan?',
      a: 'Pada layar utama pilih menu Skrining. Ikuti instruksi pengukuran tekanan darah, gula darah, dan kuesioner kesehatan.',
    ),
    (
      q: 'Bagaimana cara membuat janji temu?',
      a: 'Pilih tab Janji Temu, pilih jadwal yang tersedia, lalu konfirmasi. Anda akan menerima notifikasi pengingat.',
    ),
    (
      q: 'Data saya aman?',
      a: 'Semua data terenkripsi dan disimpan di server tertutup. Hanya tim medis berwenang yang dapat mengakses rekam medis Anda.',
    ),
    (
      q: 'Bagaimana cara mengubah profil keluarga?',
      a: 'Buka tab Profil, pilih anggota keluarga, lalu tekan ikon edit di kanan atas.',
    ),
    (
      q: 'Notifikasi tidak muncul, kenapa?',
      a: 'Pastikan notifikasi diaktifkan di Pengaturan > Notifikasi dan izin notifikasi diberikan untuk aplikasi di pengaturan ponsel Anda.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan',
          style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Pertanyaan yang Sering Diajukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ..._faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textSecondary,
                    title: Text(
                      f.q,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          f.a,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
