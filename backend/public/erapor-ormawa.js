(function () {
    'use strict';

    const INK = '#14203a', ACCENT = '#7a1230', MUTED = '#4b5566', LINE = '#d3d8e0';

    const indicators = [
        { code: 'A', name: 'Kehadiran dan Koordinasi', subs: ['A1', 'A2', 'A3'] },
        { code: 'B', name: 'Laporan, Monitoring, dan Evaluasi', subs: ['B1', 'B2', 'B3'] },
        { code: 'C', name: 'Responsivitas', subs: ['C1', 'C2', 'C3'] },
        { code: 'D', name: 'Komunikasi', subs: ['D1', 'D2', 'D3'] },
        { code: 'E', name: 'Kegiatan Lapangan', subs: ['E1', 'E2', 'E3'] },
        { code: 'F', name: 'Kelengkapan Pendampingan', subs: ['F1', 'F2', 'F3'] }
    ];
    const subIndicatorLabels = {
        'A1': 'A1: Konsistensi Kehadiran Kegiatan', 'A2': 'A2: Kehadiran Rapat & Koordinasi', 'A3': 'A3: Partisipasi Aktif Keputusan',
        'B1': 'B1: Penyusunan/Penyempurnaan Laporan', 'B2': 'B2: Monitoring Pelaksanaan Program', 'B3': 'B3: Evaluasi, Identifikasi & Solusi',
        'C1': 'C1: Kecepatan Respon Masalah', 'C2': 'C2: Kesediaan Membantu Tim', 'C3': 'C3: Solusi & Masukan Konstruktif',
        'D1': 'D1: Intensitas Komunikasi Tim', 'D2': 'D2: Komunikasi Mitra & Stakeholder', 'D3': 'D3: Kejelasan & Keberlanjutan Komunikasi',
        'E1': 'E1: Frekuensi Keterlibatan Lapangan', 'E2': 'E2: Pendampingan Bersama Masyarakat', 'E3': 'E3: Kontribusi Real Kebutuhan Lapangan',
        'F1': 'F1: Keterlibatan Perencanaan & Persiapan', 'F2': 'F2: Keterlibatan Pelaksanaan & Monev', 'F3': 'F3: Keterlibatan Keberlanjutan Program'
    };
    const students = [
        { id: 0, name: 'Indah Kurnia Novitasari', role: 'Gubernur BEM FK UNNES', focus: 'Pengarah Utama & Penanggung Jawab Kelembagaan', avatar: 'IK' },
        { id: 1, name: 'Amelia Dewi Hapsari', role: 'Wakil Gubernur BEM FK', focus: 'Koordinator Internal & Penjamin Mutu Organisasi', avatar: 'AH' },
        { id: 2, name: 'Alfi Nurul Khikmah', role: 'Fungsionaris BEM FK', focus: 'Pendamping Operasional & Koordinasi Program', avatar: 'AK' },
        { id: 3, name: 'Yofinia', role: 'Fungsionaris BEM FK', focus: 'Pendamping Administrasi & Pengambilan Keputusan', avatar: 'YF' },
        { id: 4, name: 'Nada Naila Sifa', role: 'Fungsionaris BEM FK', focus: 'Pendamping Pelaporan, Monev, & Kemitraan UMKM', avatar: 'NS' },
        { id: 5, name: 'Shafynda Aufarrelya F.', role: 'Fungsionaris BEM FK', focus: 'Pendamping Kegiatan Lapangan & Hubungan Media', avatar: 'SF' }
    ];
    const rawData = {
        m0: [
            { A1:1, A2:1, A3:1, B1:1, B2:1, B3:1, C1:1, C2:2, C3:1, D1:2, D2:1, D3:1, E1:1, E2:1, E3:1, F1:2, F2:1, F3:1 },
            { A1:1, A2:1, A3:1, B1:1, B2:1, B3:1, C1:1, C2:1, C3:1, D1:1, D2:1, D3:1, E1:1, E2:1, E3:1, F1:1, F2:1, F3:1 },
            { A1:1, A2:2, A3:1, B1:1, B2:1, B3:1, C1:1, C2:1, C3:1, D1:1, D2:1, D3:1, E1:1, E2:1, E3:1, F1:1, F2:1, F3:1 },
            { A1:1, A2:1, A3:1, B1:1, B2:1, B3:1, C1:2, C2:1, C3:1, D1:1, D2:1, D3:1, E1:1, E2:1, E3:1, F1:1, F2:1, F3:1 },
            { A1:1, A2:1, A3:1, B1:1, B2:1, B3:1, C1:1, C2:1, C3:1, D1:1, D2:2, D3:1, E1:1, E2:1, E3:1, F1:1, F2:1, F3:1 },
            { A1:1, A2:1, A3:1, B1:1, B2:2, B3:1, C1:1, C2:1, C3:1, D1:1, D2:1, D3:1, E1:1, E2:1, E3:1, F1:1, F2:1, F3:1 }
        ],
        m1: [
            { A1:3, A2:3, A3:3, B1:2, B2:3, B3:2, C1:3, C2:3, C3:2, D1:3, D2:3, D3:3, E1:2, E2:2, E3:2, F1:3, F2:2, F3:2 },
            { A1:3, A2:2, A3:3, B1:2, B2:2, B3:2, C1:3, C2:2, C3:2, D1:3, D2:2, D3:2, E1:2, E2:2, E3:2, F1:3, F2:2, F3:2 },
            { A1:2, A2:2, A3:2, B1:2, B2:2, B3:2, C1:2, C2:2, C3:2, D1:2, D2:2, D3:2, E1:2, E2:2, E3:2, F1:2, F2:2, F3:2 },
            { A1:2, A2:3, A3:2, B1:2, B2:2, B3:2, C1:2, C2:2, C3:2, D1:2, D2:2, D3:2, E1:2, E2:2, E3:2, F1:2, F2:2, F3:2 },
            { A1:2, A2:2, A3:2, B1:3, B2:2, B3:2, C1:2, C2:2, C3:2, D1:2, D2:3, D3:2, E1:2, E2:2, E3:2, F1:2, F2:2, F3:2 },
            { A1:2, A2:2, A3:2, B1:2, B2:3, B3:2, C1:2, C2:2, C3:2, D1:2, D2:2, D3:2, E1:3, E2:2, E3:2, F1:2, F2:2, F3:2 }
        ],
        m2: [
            { A1:4, A2:4, A3:4, B1:3, B2:4, B3:3, C1:4, C2:4, C3:4, D1:4, D2:4, D3:4, E1:3, E2:4, E3:3, F1:4, F2:3, F3:3 },
            { A1:4, A2:4, A3:3, B1:3, B2:3, B3:3, C1:4, C2:3, C3:3, D1:4, D2:4, D3:3, E1:3, E2:3, E3:3, F1:4, F2:3, F3:3 },
            { A1:3, A2:3, A3:3, B1:3, B2:3, B3:3, C1:3, C2:3, C3:3, D1:3, D2:3, D3:3, E1:3, E2:3, E3:3, F1:3, F2:3, F3:3 },
            { A1:3, A2:4, A3:3, B1:3, B2:3, B3:3, C1:3, C2:3, C3:3, D1:3, D2:3, D3:3, E1:3, E2:3, E3:3, F1:3, F2:3, F3:3 },
            { A1:3, A2:3, A3:3, B1:4, B2:3, B3:3, C1:3, C2:3, C3:3, D1:3, D2:4, D3:3, E1:3, E2:3, E3:3, F1:3, F2:3, F3:3 },
            { A1:3, A2:3, A3:3, B1:3, B2:4, B3:3, C1:3, C2:3, C3:3, D1:3, D2:3, D3:3, E1:4, E2:3, E3:3, F1:3, F2:3, F3:3 }
        ],
        m3: [
            { A1:5, A2:5, A3:5, B1:5, B2:5, B3:4, C1:5, C2:5, C3:5, D1:5, D2:5, D3:5, E1:5, E2:5, E3:4, F1:5, F2:5, F3:5 },
            { A1:5, A2:5, A3:5, B1:4, B2:4, B3:4, C1:5, C2:4, C3:5, D1:5, D2:5, D3:4, E1:4, E2:4, E3:4, F1:5, F2:4, F3:4 },
            { A1:4, A2:4, A3:4, B1:4, B2:4, B3:4, C1:4, C2:4, C3:4, D1:4, D2:4, D3:4, E1:4, E2:4, E3:4, F1:4, F2:4, F3:4 },
            { A1:4, A2:5, A3:4, B1:4, B2:4, B3:4, C1:4, C2:4, C3:4, D1:4, D2:4, D3:4, E1:4, E2:4, E3:4, F1:4, F2:4, F3:4 },
            { A1:4, A2:4, A3:4, B1:5, B2:4, B3:4, C1:4, C2:4, C3:4, D1:4, D2:5, D3:4, E1:4, E2:4, E3:4, F1:4, F2:4, F3:4 },
            { A1:4, A2:4, A3:4, B1:4, B2:5, B3:4, C1:4, C2:4, C3:4, D1:4, D2:4, D3:4, E1:5, E2:4, E3:4, F1:4, F2:4, F3:4 }
        ]
    };
    const cumulativeScores = {
        m0: { A: 1.06, B: 1.06, C: 1.11, D: 1.11, E: 1.00, F: 1.06, overall: 1.06, category: 'Range 1 (Baseline)' },
        m1: { A: 2.33, B: 2.17, C: 2.17, D: 2.28, E: 2.06, F: 2.11, overall: 2.19, category: 'Range 2 (Inisiasi)' },
        m2: { A: 3.33, B: 3.17, C: 3.22, D: 3.33, E: 3.11, F: 3.11, overall: 3.21, category: 'Range 3 (Implementasi)' },
        m3: { A: 4.39, B: 4.22, C: 4.28, D: 4.33, E: 4.17, F: 4.22, overall: 4.27, category: 'Range 4 (Unggul / Berdampak)' }
    };
    const studentAverages = {
        m0: [1.17, 1.00, 1.06, 1.06, 1.06, 1.06],
        m1: [2.56, 2.28, 2.00, 2.06, 2.11, 2.11],
        m2: [3.67, 3.33, 3.00, 3.06, 3.11, 3.11],
        m3: [4.89, 4.44, 4.00, 4.06, 4.11, 4.11]
    };
    const periodNarratives = {
        m0: {
            title: "Analisis Evaluasi Bulan Ke-0 (Mei 2026) - Baseline Pra-Program",
            text: `<p>Evaluasi Bulan Ke-0 mengukur profil nilai dasar (<em>baseline</em>) pendampingan BEM FK UNNES sebelum kegiatan fisik di Kelurahan Sumurrejo dimulai. Skor kumulatif Ormawa sebesar <strong>1.06 (Range 1)</strong> merefleksikan bahwa fungsi pendampingan masih berada pada titik awal kesiapan internal.</p>
<p>Domain E (Kegiatan Lapangan) mencatatkan nilai terendah 1.00 karena belum ada mobilisasi fisik. Namun, Domain C (Responsivitas = 1.11) dan Domain D (Komunikasi = 1.11) sedikit lebih tinggi, pendorongnya adalah Gubernur BEM (Indah Kurnia N., 1.17) yang proaktif merespons instruksi pendampingan serta menyusun struktur pendampingan awal.</p>`
        },
        m1: {
            title: "Analisis Evaluasi Bulan Ke-1 (Juni – Juli 2026) - Inisiasi Lapangan",
            text: `<p>Memasuki fase inisiasi lapangan, skor rata-rata kumulatif Ormawa mengalami kenaikan terukur menjadi <strong>2.19 (Range 2)</strong>. Puncak skor dicapai pada Domain A (Kehadiran & Koordinasi = 2.33) dan Domain D (Komunikasi = 2.28).</p>
<p>Peningkatan ini ditopang oleh kehadiran pimpinan BEM dalam pembukaan resmi di Balai Kelurahan Sumurrejo bersama Lurah (Ibu Dwi Asih) dan tokoh masyarakat. Indah Kurnia N. (2.56) dan Amelia Dewi H. (2.28) memimpin koordinasi awal, sementara Nada Naila S. (2.11) dan Shafynda Aufarrelya F. (2.11) memfasilitasi komunikasi kemitraan dan monitoring awal.</p>`
        },
        m2: {
            title: "Analisis Evaluasi Bulan Ke-2 (Juli – Agustus 2026) - Implementasi Inti",
            text: `<p>Bulan Ke-2 merupakan puncak fase eksekusi program: tim meluncurkan <em>Dapur Sehat Nutrasi</em> bersama 24 ibu PKK, memformulasikan <em>Hylogurt</em> bersama UMKM, dan mengoperasikan <em>Pojok Skrining Diabetes</em>. Skor kumulatif Ormawa melonjak signifikan ke <strong>3.21 (Range 3, Good Capacity)</strong>.</p>
<p>Domain A (3.33) dan Domain D (3.33) tetap menjadi yang tertinggi. Indah Kurnia N. (3.67) secara proaktif turun mendampingi kendala logistik skrining (C1-C3 = 4), sedangkan Nada Naila S. (3.11) mendampingi sertifikasi/pengolahan Hylogurt UMKM dan Shafynda (3.11) memimpin liputan publikasi media.</p>`
        },
        m3: {
            title: "Analisis Evaluasi Bulan Ke-3 (Agustus – September 2026) - Pemantapan & Keberlanjutan",
            text: `<p>Fase pemantapan dan evaluasi dampak mencatatkan performa terbaik dengan skor kumulatif mencapai <strong>4.27 (Range 4, Unggul / Ormawa Berdampak)</strong>. Seluruh 6 fungsionaris berhasil menembus Range 4 (4.00 – 5.00).</p>
<p>Domain A Kehadiran & Koordinasi (4.39) dan Domain D Komunikasi (4.33) menjadi nilai tertinggi. Gubernur Indah Kurnia N. meraih skor mendekati sempurna (4.89) berkat kepemimpinan transformatif dalam advokasi kebijakan keberlanjutan Pojok Skrining ke Puskesmas, disusul Wagub Amelia (4.44) yang menjamin kerapian penjaminan mutu logbook digital.</p>`
        },
        all: {
            title: "Analisis Longitudinal Transformatif (Bulan Ke-0 Hingga Ke-3)",
            text: `<p>Analisis komparatif longitudinal memperlihatkan kurva pertumbuhan kapasitas organisasi yang sangat konsisten, dengan total delta kenaikan sebesar <strong>+3.21 poin</strong> (dari 1.06 ke 4.27).</p>
<p>Eskalasi bertahap dari Range 1 (Baseline) menuju Range 2 (Inisiasi), Range 3 (Implementasi), dan Range 4 (Pemantapan) membuktikan efektivitas bimbingan pendampingan Dosen Pendamping. Seluruh domain berkembang secara seimbang, menegaskan bahwa BEM FK UNNES layak menjadi percontohan <em>Ormawa Berdampak</em> pada Anugerah Abdidaya 2026.</p>`
        }
    };
    const rtlData = [
        { id: 1, title: 'Institusionalisasi Pojok Skrining', desc: 'Fasilitasi SK Lurah Sumurrejo untuk mengintegrasikan Pojok Skrining Diabetes secara permanen ke Posbindu PTM.', target: 'Oktober 2026', lead: 'Indah Kurnia & Ketua Tim' },
        { id: 2, title: 'Legalitas & UMKM Hylogurt', desc: 'Pengawalan pendaftaran P-IRT dan Sertifikasi Halal bagi kelompok UMKM Wanita Sumurrejo untuk komersialisasi.', target: 'Okt – Nov 2026', lead: 'Nada Naila Sifa & Sub-Team' },
        { id: 3, title: 'Serah Terima Modul & Kit Health', desc: 'Handover Modul Dapur Sehat, Panduan Skrining, dan Alat Kit Kesehatan kepada Tim Kader Kesehatan Sumurrejo.', target: 'Minggu I Okt 2026', lead: 'Shafynda & Amelia' },
        { id: 4, title: 'Standard Mentoring Kit', desc: 'Penyusunan Standard Ormawa Mentoring Kit sebagai basis data transfer pengetahuan kepengurusan BEM FK selanjutnya.', target: 'November 2026', lead: 'Alfi Nurul & Yofinia' },
        { id: 5, title: 'Simulasi Monev & Abdidaya 2026', desc: 'Finalisasi Laporan Akhir, Pameran Poster, Video Pemberdayaan, & Simulasi Presentasi Visitasi Abdidaya 2026.', target: 'Okt – Nov 2026', lead: 'Gubernur, Dosen & Tim' }
    ];

    let barChartInstance = null, radarChartInstance = null, studentRadarInstance = null;

    function calculateStudentMainAvg(studentIdx, monthKey, indCode) {
        const indObj = indicators.find(i => i.code === indCode);
        let sum = 0;
        indObj.subs.forEach(sub => { sum += rawData[monthKey][studentIdx][sub]; });
        return (sum / indObj.subs.length).toFixed(2);
    }

    function getPeriodLabel(mKey) {
        switch (mKey) {
            case 'm0': return 'Bulan Ke-0 (Mei 2026) - Baseline Pra-Program';
            case 'm1': return 'Bulan Ke-1 (Juni – Juli 2026) - Inisiasi Lapangan';
            case 'm2': return 'Bulan Ke-2 (Juli – Agustus 2026) - Implementasi Inti';
            case 'm3': return 'Bulan Ke-3 (Agustus – September 2026) - Pemantapan Dampak';
            default: return 'Bulan Ke-0 Hingga Ke-3 (Longitudinal)';
        }
    }

    function switchMonth(mKey) {
        document.querySelectorAll('.month-tab').forEach(tab => tab.classList.toggle('is-active', tab.dataset.month === mKey));

        const banner = document.getElementById('period-banner');
        if (mKey === 'all') {
            banner.innerHTML = `
                <div>
                    <strong>Evaluasi Longitudinal (Bulan Ke-0 hingga Ke-3)</strong>
                    <p>Membandingkan eskalasi kinerja dari Mei 2026 hingga September 2026.</p>
                </div>
                <span class="tag tag--outline">Eskalasi Total: +3.21 poin</span>
            `;
        } else {
            const cData = cumulativeScores[mKey];
            banner.innerHTML = `
                <div>
                    <strong>Periode Evaluasi: ${getPeriodLabel(mKey)}</strong>
                    <p>Skor Kumulatif Ormawa: <strong style="color:var(--ink);">${cData.overall}</strong> &middot; ${cData.category}</p>
                </div>
                <span class="tag tag--outline">${cData.category}</span>
            `;
        }

        document.getElementById('narrative-title').textContent = periodNarratives[mKey].title;
        document.getElementById('narrative-content').innerHTML = periodNarratives[mKey].text;
        updateCharts(mKey);
    }

    function updateCharts(mKey) {
        const ctxBar = document.getElementById('barChartCanvas').getContext('2d');
        const ctxRadar = document.getElementById('radarChartCanvas').getContext('2d');
        if (barChartInstance) barChartInstance.destroy();
        if (radarChartInstance) radarChartInstance.destroy();
        const indLabels = indicators.map(i => `Domain ${i.code}`);

        if (mKey === 'all') {
            document.getElementById('bar-chart-title').textContent = 'Diagram Batang Komparatif Longitudinal (M0–M3)';
            document.getElementById('bar-chart-subtitle').textContent = 'Perbandingan rata-rata kumulatif 6 domain dari Bulan 0 hingga Bulan 3.';
            barChartInstance = new Chart(ctxBar, {
                type: 'bar',
                data: {
                    labels: indLabels,
                    datasets: [
                        { label: 'M0', data: [1.06, 1.06, 1.11, 1.11, 1.00, 1.06], backgroundColor: '#c7ccd4' },
                        { label: 'M1', data: [2.33, 2.17, 2.17, 2.28, 2.06, 2.11], backgroundColor: '#8f97a3' },
                        { label: 'M2', data: [3.33, 3.17, 3.22, 3.33, 3.11, 3.11], backgroundColor: '#586275' },
                        { label: 'M3', data: [4.39, 4.22, 4.28, 4.33, 4.17, 4.22], backgroundColor: ACCENT }
                    ]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    scales: { y: { min: 0, max: 5, ticks: { stepSize: 1, color: MUTED }, grid: { color: LINE } }, x: { ticks: { color: MUTED }, grid: { display: false } } },
                    plugins: { legend: { labels: { color: INK, font: { size: 11 } } }, tooltip: { mode: 'index', intersect: false } }
                }
            });

            document.getElementById('radar-chart-title').textContent = 'Spider Chart Multilapis (M0–M3)';
            document.getElementById('radar-chart-subtitle').textContent = 'Pemekaran jaring kualifikasi dari skala 1 menuju skala 5.';
            radarChartInstance = new Chart(ctxRadar, {
                type: 'radar',
                data: {
                    labels: ['A. Kehadiran', 'B. Monev', 'C. Respon', 'D. Komunikasi', 'E. Lapangan', 'F. Kelengkapan'],
                    datasets: [
                        { label: 'M0', data: [1.06, 1.06, 1.11, 1.11, 1.00, 1.06], borderColor: '#9aa1ac', backgroundColor: 'rgba(154,161,172,0.08)', borderWidth: 1.5 },
                        { label: 'M1', data: [2.33, 2.17, 2.17, 2.28, 2.06, 2.11], borderColor: '#727c8c', backgroundColor: 'rgba(114,124,140,0.10)', borderWidth: 1.5 },
                        { label: 'M2', data: [3.33, 3.17, 3.22, 3.33, 3.11, 3.11], borderColor: '#454f61', backgroundColor: 'rgba(69,79,97,0.10)', borderWidth: 1.5 },
                        { label: 'M3', data: [4.39, 4.22, 4.28, 4.33, 4.17, 4.22], borderColor: ACCENT, backgroundColor: 'rgba(122,18,48,0.18)', borderWidth: 2.5 }
                    ]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    scales: { r: { min: 0, max: 5, ticks: { stepSize: 1, display: false }, pointLabels: { color: INK, font: { size: 10 } }, grid: { color: LINE }, angleLines: { color: LINE } } },
                    plugins: { legend: { position: 'bottom', labels: { color: INK, font: { size: 10 } } } }
                }
            });
        } else {
            const c = cumulativeScores[mKey];
            const scoresArr = [c.A, c.B, c.C, c.D, c.E, c.F];
            document.getElementById('bar-chart-title').textContent = `Diagram Batang Kumulatif (${mKey.toUpperCase()})`;
            document.getElementById('bar-chart-subtitle').textContent = `Skor rata-rata kumulatif per domain pada ${getPeriodLabel(mKey)}.`;
            barChartInstance = new Chart(ctxBar, {
                type: 'bar',
                data: { labels: indLabels, datasets: [{ label: 'Skor Kumulatif', data: scoresArr, backgroundColor: INK, borderRadius: 2 }] },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    scales: { y: { min: 0, max: 5, ticks: { stepSize: 1, color: MUTED }, grid: { color: LINE } }, x: { ticks: { color: MUTED }, grid: { display: false } } },
                    plugins: { legend: { display: false } }
                }
            });

            document.getElementById('radar-chart-title').textContent = `Spider Chart (${mKey.toUpperCase()})`;
            document.getElementById('radar-chart-subtitle').textContent = 'Profil jaring radar kekuatan domain pendampingan.';
            radarChartInstance = new Chart(ctxRadar, {
                type: 'radar',
                data: {
                    labels: ['A. Kehadiran', 'B. Monev', 'C. Respon', 'D. Komunikasi', 'E. Lapangan', 'F. Kelengkapan'],
                    datasets: [{ label: `Profil ${mKey.toUpperCase()}`, data: scoresArr, borderColor: ACCENT, backgroundColor: 'rgba(122,18,48,0.16)', borderWidth: 2, pointBackgroundColor: ACCENT }]
                },
                options: {
                    responsive: true, maintainAspectRatio: false,
                    scales: { r: { min: 0, max: 5, ticks: { stepSize: 1, display: false }, pointLabels: { color: INK, font: { size: 10 } }, grid: { color: LINE }, angleLines: { color: LINE } } },
                    plugins: { legend: { display: false } }
                }
            });
        }
    }

    function renderMatrixTable(mKey) {
        document.querySelectorAll('.matrix-filter-btn').forEach(btn => btn.classList.toggle('is-active', btn.dataset.matrix === mKey));

        const table = document.getElementById('score-matrix-table');
        if (mKey === 'all') {
            let html = `
                <thead><tr>
                    <th>Kode</th><th>Domain Utama</th>
                    <th class="num">M0</th><th class="num">M1</th><th class="num">M2</th><th class="num">M3</th>
                    <th class="num">&Delta; Total</th><th>Kategori Tren</th>
                </tr></thead><tbody>`;
            const longData = [
                { code: 'A', name: 'Kehadiran dan Koordinasi', m0: '1.06', m1: '2.33', m2: '3.33', m3: '4.39', delta: '+3.33', trend: 'Linear Positif Maksimal' },
                { code: 'B', name: 'Laporan, Monitoring, dan Evaluasi', m0: '1.06', m1: '2.17', m2: '3.17', m3: '4.22', delta: '+3.16', trend: 'Linear Positif Tinggi' },
                { code: 'C', name: 'Responsivitas', m0: '1.11', m1: '2.17', m2: '3.22', m3: '4.28', delta: '+3.17', trend: 'Linear Positif Tinggi' },
                { code: 'D', name: 'Komunikasi', m0: '1.11', m1: '2.28', m2: '3.33', m3: '4.33', delta: '+3.22', trend: 'Linear Positif Maksimal' },
                { code: 'E', name: 'Kegiatan Lapangan', m0: '1.00', m1: '2.06', m2: '3.11', m3: '4.17', delta: '+3.17', trend: 'Linear Positif Tinggi' },
                { code: 'F', name: 'Kelengkapan Pendampingan', m0: '1.06', m1: '2.11', m2: '3.11', m3: '4.22', delta: '+3.16', trend: 'Linear Positif Tinggi' }
            ];
            longData.forEach(row => {
                html += `
                    <tr>
                        <td class="accent strong">${row.code}</td>
                        <td class="strong">${row.name}</td>
                        <td class="num muted">${row.m0}</td>
                        <td class="num muted">${row.m1}</td>
                        <td class="num muted">${row.m2}</td>
                        <td class="num strong">${row.m3}</td>
                        <td class="num accent">${row.delta}</td>
                        <td><span class="tag tag--ok">${row.trend}</span></td>
                    </tr>`;
            });
            html += `
                <tr class="totals">
                    <td colspan="2">RATA-RATA KUMULATIF PROGRAM (ORMAWA)</td>
                    <td class="num muted">1.06</td><td class="num muted">2.19</td><td class="num muted">3.21</td>
                    <td class="num">4.27</td><td class="num accent">+3.21</td>
                    <td><span class="tag tag--solid">Eskalasi Transformatif</span></td>
                </tr>
                </tbody>`;
            table.innerHTML = html;
        } else {
            let html = `
                <thead><tr>
                    <th>Kode</th><th>Sub-Indikator (${mKey.toUpperCase()})</th>
                    ${students.map(s => `<th class="num">${s.name.split(' ')[0]}</th>`).join('')}
                    <th class="num" style="background:var(--paper);">Rata-Rata</th>
                </tr></thead><tbody>`;
            indicators.forEach(ind => {
                ind.subs.forEach(subCode => {
                    let rowSum = 0;
                    let studentCells = '';
                    students.forEach((s, sIdx) => {
                        const val = rawData[mKey][sIdx][subCode];
                        rowSum += val;
                        const badgeClass = val >= 5 ? 'score-badge--ok' : (val >= 4 ? 'score-badge--good' : (val >= 3 ? 'score-badge--warn' : 'score-badge--low'));
                        studentCells += `<td class="num"><span class="score-badge ${badgeClass}">${val}</span></td>`;
                    });
                    const subAvg = (rowSum / students.length).toFixed(2);
                    html += `
                        <tr>
                            <td class="muted strong">${subCode}</td>
                            <td>${subIndicatorLabels[subCode]}</td>
                            ${studentCells}
                            <td class="num strong" style="background:var(--paper);">${subAvg}</td>
                        </tr>`;
                });
            });
            const averages = studentAverages[mKey];
            const overallAvg = (averages.reduce((a, b) => a + b, 0) / averages.length).toFixed(2);
            html += `
                <tr class="totals">
                    <td colspan="2">RATA-RATA INDIVIDU (${mKey.toUpperCase()})</td>
                    ${averages.map(avg => `<td class="num accent">${avg.toFixed(2)}</td>`).join('')}
                    <td class="num" style="background:var(--paper);">${overallAvg}</td>
                </tr>
                </tbody>`;
            table.innerHTML = html;
        }
    }

    function renderStudentSelectorGroup() {
        const container = document.getElementById('student-selector-group');
        container.innerHTML = students.map(s => `
            <button type="button" class="selector-btn student-select-btn" data-student="${s.id}">
                <div class="selector-btn__row">
                    <div class="avatar">${s.avatar}</div>
                    <span class="selector-btn__name">${s.name.split(' ')[0]}</span>
                </div>
                <p class="selector-btn__role">${s.role.split(' ')[0]} ${s.role.split(' ')[1] || ''}</p>
            </button>
        `).join('');
        container.querySelectorAll('.student-select-btn').forEach(btn => {
            btn.addEventListener('click', () => selectStudent(Number(btn.dataset.student)));
        });
    }

    function selectStudent(sId) {
        const s = students[sId];
        document.querySelectorAll('.student-select-btn').forEach(btn => {
            btn.classList.toggle('is-active', Number(btn.dataset.student) === sId);
        });

        const m0Avg = studentAverages.m0[sId];
        const m3Avg = studentAverages.m3[sId];
        const delta = (m3Avg - m0Avg).toFixed(2);
        const panel = document.getElementById('student-detail-panel');
        panel.innerHTML = `
            <div class="stack-sm">
                <div class="detail-head">
                    <div class="avatar avatar--lg">${s.avatar}</div>
                    <div>
                        <h4 class="detail-name">${s.name}</h4>
                        <span class="role-tag">${s.role}</span>
                    </div>
                </div>
                <div class="mini-card">
                    <span>Peran Utama Pendampingan</span>
                    <p>${s.focus}</p>
                </div>
                <div class="metric-grid">
                    <div class="metric"><span class="label">Skor Awal (M0)</span><span class="value">${m0Avg.toFixed(2)}</span></div>
                    <div class="metric"><span class="label">Skor Akhir (M3)</span><span class="value accent">${m3Avg.toFixed(2)}</span></div>
                    <div class="metric span2"><span class="label" style="font-size:12px; color:var(--muted); font-weight:500;">Eskalasi Total</span><span class="value">+${delta} poin</span></div>
                </div>
            </div>
            <div class="chart-box">
                <h5>Spider Chart Domain (Bulan Ke-3)</h5>
                <div class="chart-container" style="height:240px;"><canvas id="studentRadarCanvas"></canvas></div>
            </div>
            <div class="domain-score-list">
                <h5 style="font-size:0.75rem; font-weight:600;">Skor 6 Domain Utama (M3)</h5>
                ${indicators.map(ind => {
                    const indAvg = calculateStudentMainAvg(sId, 'm3', ind.code);
                    return `<div class="domain-score-row"><span>Domain ${ind.code}. ${ind.name}</span><span class="pill${indAvg >= 4.5 ? ' ok' : ''}">${indAvg}</span></div>`;
                }).join('')}
            </div>
        `;

        const ctxStudentRadar = document.getElementById('studentRadarCanvas').getContext('2d');
        if (studentRadarInstance) studentRadarInstance.destroy();
        const studentM3Scores = indicators.map(ind => calculateStudentMainAvg(sId, 'm3', ind.code));
        studentRadarInstance = new Chart(ctxStudentRadar, {
            type: 'radar',
            data: {
                labels: ['A. Kehadiran', 'B. Monev', 'C. Respon', 'D. Komunikasi', 'E. Lapangan', 'F. Kelengkapan'],
                datasets: [{ label: `Capaian M3: ${s.name.split(' ')[0]}`, data: studentM3Scores, borderColor: ACCENT, backgroundColor: 'rgba(122,18,48,0.16)', borderWidth: 2, pointBackgroundColor: ACCENT }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                scales: { r: { min: 0, max: 5, ticks: { stepSize: 1, display: false }, pointLabels: { color: INK, font: { size: 10 } }, grid: { color: LINE }, angleLines: { color: LINE } } },
                plugins: { legend: { display: false } }
            }
        });
    }

    function renderRtlCards() {
        const container = document.getElementById('rtl-cards-container');
        container.innerHTML = rtlData.map(item => `
            <div class="rtl-card">
                <div class="rtl-card__top">
                    <div class="rtl-card__meta">
                        <span class="rtl-id">${item.id}</span>
                        <span class="tag tag--accent-outline">${item.target}</span>
                    </div>
                    <h5>${item.title}</h5>
                    <p>${item.desc}</p>
                </div>
                <div class="rtl-card__foot"><span>PJ Utama</span><strong>${item.lead}</strong></div>
            </div>
        `).join('');
    }

    document.addEventListener('DOMContentLoaded', () => {
        renderStudentSelectorGroup();
        renderRtlCards();
        switchMonth('m3');
        renderMatrixTable('m3');
        selectStudent(0);

        document.querySelectorAll('.month-tab').forEach(btn => {
            btn.addEventListener('click', () => switchMonth(btn.dataset.month));
        });
        document.querySelectorAll('.matrix-filter-btn').forEach(btn => {
            btn.addEventListener('click', () => renderMatrixTable(btn.dataset.matrix));
        });
    });
})();
