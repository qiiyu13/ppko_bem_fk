# 📝 Panduan Tanya Jawab (FAQ) Wawancara - Proyek Mediku

Dokumen ini disusun khusus untuk tim perwakilan yang akan melakukan wawancara/presentasi. Pertanyaan dan jawaban di bawah ini dirancang menggunakan bahasa yang **sederhana, mudah dimengerti, dan tidak terlalu teknis (non-teknis)** agar kalian bisa menjawab pertanyaan juri atau penanya dengan percaya diri dan meyakinkan.

---

### 1. Aplikasi ini sebenarnya tentang apa sih secara garis besar?
**Jawaban (Konsep & Kegunaan):**
"Mediku (Media Informasi dan Diagnostik Kesehatanku) adalah aplikasi kesehatan terpadu yang menjembatani pasien dengan penyedia layanan kesehatan. Fitur andalan kami adalah pencatatan rekam medis (seperti tekanan darah dan gula darah), pengelolaan profil kesehatan untuk seluruh anggota keluarga dalam satu akun, Asisten Kesehatan Pintar (AI), dan fitur edukasi pengobatan tradisional melalui artikel Tanaman Toga."

### 2. Bagaimana dengan biaya operasional atau *maintenance cost* aplikasi ini? Apakah mahal?
**Jawaban (Biaya & Efisiensi):**
"Sama sekali tidak mahal, justru sangat efisien. 
- Untuk **biaya Server** (tempat penyimpanan sistem di internet), kami menyewa layanan *cloud* yang sangat terjangkau dan ekonomis untuk menunjang skala operasional kami.
- Untuk **biaya Pengembangan (Developer / Maintenance)**, biayanya bisa ditekan secara maksimal. Aplikasi ini dibangun, dikembangkan, dan dirawat sepenuhnya oleh tim internal kami sendiri secara mandiri, sehingga kami tidak memiliki beban biaya untuk menyewa jasa pihak ketiga atau vendor luar."

### 3. Di aplikasi kesehatan, privasi itu penting. Bagaimana keamanan data pasien di aplikasi ini?
**Jawaban (Keamanan Data):**
"Keamanan dan privasi data pasien adalah prioritas utama kami. Kami menggunakan teknologi pengamanan standar industri. Kata sandi pengguna diacak (*encrypted*) sehingga tidak bisa dibaca oleh siapapun, termasuk kami. Selain itu, kami menerapkan sistem pembagian peran (Pasien, Admin/Tenaga Medis, Superadmin) yang ketat. Pasien hanya bisa melihat datanya sendiri dan keluarganya, sehingga kebocoran atau intip-mengintip data pasien lain tidak mungkin terjadi."

### 4. Apakah aplikasi ini bisa digunakan saat sedang tidak ada kuota atau sinyal internet (offline)?
**Jawaban (Fitur Offline):**
"Bisa! Kami memahami bahwa tidak semua daerah atau pengguna selalu memiliki koneksi internet yang stabil. Oleh karena itu, aplikasi kami dilengkapi dengan fitur penyimpanan lokal di memori HP. Pengguna tetap bisa melihat riwayat kesehatan mereka meski sedang *offline*. Begitu HP kembali mendapatkan sinyal internet, aplikasi akan secara otomatis mengunggah dan menyelaraskan (sinkronisasi) data terbaru ke server pusat."

### 5. Di sini ada fitur AI "Tanya Asisten". Apakah ini berarti aplikasi kalian akan menggantikan peran dokter sungguhan?
**Jawaban (Peran AI):**
"Tentu tidak. Fitur 'Tanya Asisten' dirancang semata-mata untuk memberikan edukasi dasar, tips kesehatan ringan, dan informasi pencegahan awal. Fitur ini **bukan** alat untuk mendiagnosis penyakit secara medis dan **tidak akan pernah menggantikan peran dokter**. Faktanya, AI kami diprogram sedemikian rupa sehingga jika ada pengguna yang mengeluhkan gejala serius, AI tersebut akan langsung mengarahkan pengguna untuk segera berkonsultasi ke fasilitas kesehatan atau dokter."

### 6. Kalau nanti aplikasinya dipakai oleh banyak warga di desa/komunitas, apakah aplikasinya bakal lemot atau servernya *down*?
**Jawaban (Skalabilitas / Kemampuan Menampung Pengguna):**
"Insyaallah tidak akan lemot. Sistem kami di belakang layar (Server & Database) dibangun menggunakan teknologi modern yang biasa dipakai oleh perusahaan teknologi besar, yang memang dirancang untuk menampung banyak pengguna sekaligus. Kalaupun nanti penggunanya membludak melebihi perkiraan, kapasitas server kami bisa ditingkatkan (*di-upgrade*) dengan sangat mudah dan cepat tanpa harus merombak aplikasinya."

### 7. Bagaimana kalau ada kasus di mana dokter (admin) sedang memperbarui data pasien A, tapi di saat bersamaan pasien A juga sedang mengubah datanya sendiri dari HP-nya? Apakah datanya akan error?
**Jawaban (Fitur Deteksi Konflik):**
"Kami sudah mengantisipasi masalah tersebut dengan sebuah sistem pintar yang disebut **Deteksi Konflik**. Jika hal itu terjadi, sistem tidak akan sembarangan menimpa data. Sistem akan memunculkan jendela peringatan kepada orang kedua yang menekan tombol 'simpan', memberitahu bahwa *'Data ini baru saja diperbarui oleh orang lain'*. Kemudian sistem akan meminta orang tersebut untuk mengecek kembali data terbaru sebelum memutuskan untuk menyimpannya. Jadi, data pasien dijamin selalu akurat dan tidak ada yang terhapus tanpa sengaja."

### 8. Bagaimana cara aplikasi ini menentukan status risiko kesehatan pasien?
**Jawaban (Perhitungan Otomatis):**
"Aplikasi kami memiliki sistem perhitungan otomatis yang disebut *Index Risk Diabetes* (IRD). Saat admin memasukkan data skrining kesehatan pasien (seperti tekanan darah, gula darah, berat badan), sistem kami akan langsung menghitung secara matematis dan mengelompokkan risiko pasien ke dalam kategori: Risiko Rendah, Sedang, atau Berat. Ini sangat membantu tenaga medis untuk mengambil tindakan pencegahan dengan lebih cepat."

### 9. Apakah aplikasi ini cuma bisa dipakai di HP Android? Bagaimana kalau ke depannya mau dibuat untuk iPhone (iOS) atau Web?
**Jawaban (Teknologi Lintas Platform):**
"Saat ini kami memang fokus meluncurkan untuk Android dan Web terlebih dahulu. Tapi kabar baiknya, kami membangun aplikasi ini menggunakan teknologi *Flutter*. Teknologi ini memungkinkan kami menggunakan **satu kode sumber (source code) yang sama** untuk membuat aplikasi Android, iPhone (iOS), maupun Website. Jadi, kalau nanti kami ingin merilis versi iPhone, kami tidak perlu repot-repot membuat aplikasinya dari nol lagi. Cukup disesuaikan sedikit dan langsung bisa dirilis."

### 10. Bagaimana cara HP pasien dan komputer Admin bisa saling bertukar data secara langsung?
**Jawaban (API / Jembatan Komunikasi):**
"Aplikasi di HP pasien dan sistem Admin tidak terhubung secara langsung satu sama lain. Kami menggunakan sistem perantara yang disebut **API (Application Programming Interface)** yang berada di Server pusat kami. Ibaratnya, API ini seperti 'pelayan restoran'. Aplikasi HP pasien memesan data (misal: jadwal periksa), lalu API akan mengambilkan data tersebut dari 'dapur' (Database) dan menyajikannya ke HP pasien. Cara ini membuat komunikasi data jadi sangat cepat, tertata, dan aman."

### 11. Terkait AI Asisten, apakah kalian memprogram "otak" AI-nya sendiri dari nol?
**Jawaban (Integrasi AI Pihak Ketiga):**
"Membuat otak AI dari nol membutuhkan waktu bertahun-tahun dan biaya super komputer yang sangat mahal. Oleh karena itu, kami bekerja secara efisien dengan **mengintegrasikan model AI kelas dunia yang sudah ada** (seperti sistem yang dipakai oleh ChatGPT). Namun, kami tidak memakainya mentah-mentah. Kami memberikan instruksi khusus dan batasan yang ketat (*prompt engineering*) pada AI tersebut agar ia hanya menjawab pertanyaan seputar kesehatan, bersikap layaknya asisten medis yang ramah, dan menolak menjawab pertanyaan di luar konteks medis."

### 12. Kalau aplikasi ini dipakai bertahun-tahun, datanya pasti akan menumpuk. Apakah nanti aplikasinya jadi lambat saat mencari nama pasien?
**Jawaban (Database & Indexing):**
"Tidak akan lambat. Kami menggunakan sistem manajemen *Database* profesional (PostgreSQL) yang dirancang untuk menangani jutaan baris data. Sistem kami juga sudah dilengkapi dengan teknik **Indexing**. Cara kerjanya mirip seperti 'Daftar Isi' di bagian depan buku tebal. Saat admin mencari nama 'Budi', sistem tidak akan membaca data satu per satu dari awal sampai akhir, melainkan langsung melihat ke 'Daftar Isi' dan melompat ke halaman tempat data Pak Budi berada. Jadi pencarian data akan selalu instan."

---
*Catatan untuk tim presentasi: Jika ada pertanyaan yang di luar pemahaman kalian saat presentasi, kalian bisa menjawab dengan tenang: "Terima kasih atas pertanyaannya. Untuk hal-hal teknis yang lebih mendalam terkait kode dan server, itu ditangani oleh tim teknis / developer kami. Namun dari sisi operasional, kami memastikan [sebutkan solusi umum yang relevan]." Selamat berjuang!*