(function () {
    'use strict';

    const domainDefinitions = [
        {
            code: 'A',
            title: 'Analisis Situasi Masyarakat',
            desc: 'Kemampuan mahasiswa dalam memetakan profil demografi, beban penyakit diabetes, serta potensi sosial masyarakat secara komprehensif.',
            indicators: [
                { id: 1, text: 'Mampu mengidentifikasi masalah utama kesehatan masyarakat berdasarkan data lapangan' },
                { id: 2, text: 'Mampu mengidentifikasi potensi lokal yang dapat diberdayakan' },
                { id: 3, text: 'Mampu menentukan prioritas masalah bersama masyarakat' }
            ]
        },
        {
            code: 'B',
            title: 'Partisipasi Masyarakat',
            desc: 'Kemampuan menggerakkan partisipasi aktif warga, perwakilan kelompok sasaran, dan elemen masyarakat dari awal hingga keputusan akhir.',
            indicators: [
                { id: 4, text: 'Melibatkan masyarakat sejak tahap perencanaan' },
                { id: 5, text: 'Mendorong masyarakat aktif menyampaikan ide' },
                { id: 6, text: 'Keputusan program dibuat bersama masyarakat' }
            ]
        },
        {
            code: 'C',
            title: 'Pengembangan Kapasitas Masyarakat',
            desc: 'Transfer pengetahuan dan keterampilan klinis dasar, pencatatan PTM, serta digitalisasi pemantauan kesehatan kader.',
            indicators: [
                { id: 7, text: 'Melatih kader melakukan skrining diabetes secara mandiri' },
                { id: 8, text: 'Melatih kader menggunakan aplikasi MEDIKU' },
                { id: 9, text: 'Melatih kader melakukan pencatatan faktor risiko PTM' }
            ]
        },
        {
            code: 'D',
            title: 'Pemberdayaan Berbasis Potensi Lokal',
            desc: 'Pemanfaatan kekayaan hayati lokal (TOGA/tanaman herbal) dan inovasi produk pangan fungsional serbasari rendah indeks glikemik.',
            indicators: [
                { id: 10, text: 'Mengoptimalkan pemanfaatan TOGA lokal' },
                { id: 11, text: 'Mengembangkan produk serbasari bersama masyarakat' },
                { id: 12, text: 'Melibatkan masyarakat dalam inovasi produk pangan fungsional' }
            ]
        },
        {
            code: 'E',
            title: 'Keberlanjutan Program',
            desc: 'Kemandirian kelompok masyarakat dalam mengoperasikan Pojok Skrining, pemutakhiran MEDIKU, dan reproduksi pangan fungsional.',
            indicators: [
                { id: 13, text: 'Masyarakat mampu menjalankan pojok skrining tanpa pendampingan mahasiswa' },
                { id: 14, text: 'Kader mampu menginput data MEDIKU secara mandiri' },
                { id: 15, text: 'Kelompok masyarakat mampu memproduksi produk Glycos secara mandiri' },
                { id: 16, text: 'Terbentuk kader yang menjadi pelatih kader lain' }
            ]
        },
        {
            code: 'F',
            title: 'Kolaborasi',
            desc: 'Strategi membangun jejaring lintas sektor meliputi Kelurahan, Puskesmas Gunungpati, PKK, Posbindu, dan tokoh masyarakat.',
            indicators: [
                { id: 17, text: 'Membangun kerja sama dengan puskesmas' },
                { id: 18, text: 'Membangun kerja sama dengan kelurahan' },
                { id: 19, text: 'Melibatkan PKK, Posbindu, dan tokoh masyarakat' }
            ]
        },
        {
            code: 'G',
            title: 'Kepemimpinan Mahasiswa',
            desc: 'Kompetensi manajerial mahasiswa dalam memfasilitasi dialog, pemecahan masalah/konflik, dan menjaga motivasi kader.',
            indicators: [
                { id: 20, text: 'Mampu memfasilitasi diskusi masyarakat' },
                { id: 21, text: 'Mampu menyelesaikan konflik kelompok' },
                { id: 22, text: 'Mampu memotivasi kader agar aktif' }
            ]
        }
    ];

    const indicatorsList = [
        "Indikator 1: Identifikasi Masalah Kesehatan", "Indikator 2: Identifikasi Potensi Lokal", "Indikator 3: Penetapan Prioritas Masalah",
        "Indikator 4: Pelibatan Perencanaan", "Indikator 5: Mendorong Penyampaian Ide", "Indikator 6: Keputusan Bersama",
        "Indikator 7: Pelatihan Skrining Diabetes", "Indikator 8: Pelatihan Aplikasi MEDIKU", "Indikator 9: Pencatatan Faktor Risiko",
        "Indikator 10: Pemanfaatan TOGA Lokal", "Indikator 11: Pengembangan Produk Serbasari", "Indikator 12: Inovasi Pangan Fungsional",
        "Indikator 13: Kemandirian Pojok Skrining", "Indikator 14: Input Data MEDIKU Mandiri", "Indikator 15: Produksi Mandiri Glycos",
        "Indikator 16: Pembentukan Kader Trainer", "Indikator 17: Kerjasama Puskesmas", "Indikator 18: Kerjasama Kelurahan",
        "Indikator 19: Pelibatan PKK & Posbindu", "Indikator 20: Fasilitasi Diskusi", "Indikator 21: Penyelesaian Konflik",
        "Indikator 22: Motivasi Keaktifan Kader"
    ];

    const monthlyData = {
        0: {
            label: "Bulan Ke-0 (Mei 2026)", targetRange: "Range 1 (1.00 - 1.80)",
            domainScores: [1.38, 1.37, 1.38, 1.40, 1.38, 1.37, 1.39], cumulativeAvg: 1.38,
            indicatorScores: [1.39, 1.37, 1.38, 1.36, 1.37, 1.38, 1.39, 1.38, 1.37, 1.41, 1.40, 1.39, 1.38, 1.37, 1.39, 1.38, 1.37, 1.38, 1.36, 1.40, 1.39, 1.38],
            narrative: "<strong>Evaluasi Baseline (Mei 2026):</strong> Berada pada Range 1 dengan rata-rata kumulatif 1,38. Mahasiswa tim BEM FK UNNES masih berada pada tahap persiapan konseptual sebelum penerjunan lapangan. Pemahaman potensi TOGA lokal (Domain D: 1,40) sedikit memimpin, sedangkan kolaborasi dan partisipasi berada di titik awal karena belum dimulainya interaksi terstruktur dengan pemangku kepentingan desa."
        },
        1: {
            label: "Bulan Ke-1 (Juni - Juli 2026)", targetRange: "Range 2 (2.00 - 2.90)",
            domainScores: [2.47, 2.45, 2.46, 2.44, 2.43, 2.46, 2.47], cumulativeAvg: 2.45,
            indicatorScores: [2.48, 2.47, 2.46, 2.46, 2.44, 2.45, 2.47, 2.46, 2.45, 2.45, 2.44, 2.43, 2.44, 2.42, 2.43, 2.43, 2.47, 2.46, 2.45, 2.48, 2.46, 2.47],
            narrative: "<strong>Evaluasi Inisiasi (Juni - Juli 2026):</strong> Berada pada Range 2 dengan rata-rata 2,45. Menggambarkan keberhasilan sosialisasi awal, pembentukan struktur Pojok Skrining, serta pengenalan modul aplikasi MEDIKU. Kepemimpinan mahasiswa dan analisis situasi (2,47) memimpin berkat komunikasi aktif tim dengan pihak Kelurahan Sumurrejo dan Puskesmas Gunungpati."
        },
        2: {
            label: "Bulan Ke-2 (Juli - Agustus 2026)", targetRange: "Range 3 (3.00 - 3.90)",
            domainScores: [3.45, 3.44, 3.46, 3.43, 3.44, 3.44, 3.44], cumulativeAvg: 3.44,
            indicatorScores: [3.46, 3.45, 3.44, 3.45, 3.44, 3.43, 3.47, 3.46, 3.45, 3.44, 3.43, 3.42, 3.45, 3.43, 3.44, 3.44, 3.45, 3.44, 3.43, 3.45, 3.43, 3.44],
            narrative: "<strong>Evaluasi Akselerasi (Juli - Agustus 2026):</strong> Berada pada Range 3 dengan rata-rata 3,44. Pelatihan praktik skrining glukosa darah mandiri dan simulasi input MEDIKU secara real-time mendorong lonjakan signifikan pada Pengembangan Kapasitas (Domain C: 3,46). Kader PKK juga mulai aktif memformulasi olahan pangan fungsional serbasari."
        },
        3: {
            label: "Bulan Ke-3 (Agustus - September 2026)", targetRange: "Range 4 (4.10 - 4.40)",
            domainScores: [4.26, 4.28, 4.25, 4.25, 4.25, 4.25, 4.23], cumulativeAvg: 4.25,
            indicatorScores: [4.27, 4.26, 4.25, 4.29, 4.28, 4.27, 4.26, 4.25, 4.24, 4.26, 4.25, 4.24, 4.26, 4.25, 4.25, 4.24, 4.26, 4.25, 4.24, 4.24, 4.22, 4.23],
            narrative: "<strong>Evaluasi Kemandirian (Agustus - September 2026):</strong> Mencapai skor puncak <strong>4,25</strong> (Sesuai target Range 4). Kader Posbindu dan PKK telah mampu mengelola Pojok Skrining mandiri, menginput data MEDIKU, serta mereplikasi pengetahuan melalui skema Training of Trainers (ToT). Mahasiswa sukses bertransformasi menjadi pendamping pasif."
        }
    };

    const studentsData = [
        { name: "Oktavia Kurniawati", role: "Ketua Tim Pelaksana", scores: [1.42, 2.50, 3.53, 4.31], class: "Sangat Unggul", domainB3: [4.32, 4.34, 4.31, 4.31, 4.31, 4.31, 4.29] },
        { name: "N. Rania Danisya Adriani", role: "Administrasi & Sekretariat", scores: [1.41, 2.44, 3.47, 4.28], class: "Sangat Unggul", domainB3: [4.29, 4.31, 4.28, 4.28, 4.28, 4.28, 4.26] },
        { name: "Nayara Raya Kanahaya", role: "Keuangan & Anggaran", scores: [1.37, 2.45, 3.46, 4.27], class: "Sangat Unggul", domainB3: [4.28, 4.30, 4.27, 4.27, 4.27, 4.27, 4.25] },
        { name: "Rintis Aulia Maharani", role: "Teknis Skrining Kesehatan", scores: [1.42, 2.49, 3.49, 4.27], class: "Sangat Unggul", domainB3: [4.28, 4.30, 4.27, 4.27, 4.27, 4.27, 4.25] },
        { name: "Aida Maghfiroh", role: "Formulasi Olah Pangan", scores: [1.39, 2.47, 3.44, 4.27], class: "Sangat Unggul", domainB3: [4.28, 4.30, 4.27, 4.27, 4.27, 4.27, 4.25] },
        { name: "Edward Joshua Sibarani", role: "Humas & Kemitraan Eksternal", scores: [1.38, 2.49, 3.43, 4.22], class: "Unggul", domainB3: [4.23, 4.25, 4.22, 4.22, 4.22, 4.22, 4.20] },
        { name: "Diva Ayu Hafsari Dewi", role: "Pengembang Sistem MEDIKU", scores: [1.40, 2.48, 3.47, 4.27], class: "Sangat Unggul", domainB3: [4.28, 4.30, 4.27, 4.27, 4.27, 4.27, 4.25] },
        { name: "Aulia Zaziroturrohmah", role: "Edukasi & Literasi Kesehatan", scores: [1.40, 2.43, 3.44, 4.24], class: "Unggul", domainB3: [4.25, 4.27, 4.24, 4.24, 4.24, 4.24, 4.22] },
        { name: "Fany Fitria Salsabilla", role: "Pemasaran & Bisnis Glycos", scores: [1.37, 2.48, 3.42, 4.27], class: "Sangat Unggul", domainB3: [4.28, 4.30, 4.27, 4.27, 4.27, 4.27, 4.25] },
        { name: "Damar Syahid Nugraha", role: "Logistik & Aset Lapangan", scores: [1.38, 2.43, 3.40, 4.24], class: "Unggul", domainB3: [4.25, 4.27, 4.24, 4.24, 4.24, 4.24, 4.22] },
        { name: "Ivani Ramadhani Putri Permana", role: "Konservasi TOGA Lokal", scores: [1.39, 2.49, 3.45, 4.26], class: "Sangat Unggul", domainB3: [4.27, 4.29, 4.26, 4.26, 4.26, 4.26, 4.24] },
        { name: "Amalina Nayla Putri", role: "Pendampingan Lapangan", scores: [1.36, 2.36, 3.42, 4.22], class: "Unggul", domainB3: [4.23, 4.25, 4.22, 4.22, 4.22, 4.22, 4.20] },
        { name: "Fathurrahman Muhammad", role: "Media & Publikasi Dokumenter", scores: [1.34, 2.41, 3.41, 4.19], class: "Unggul", domainB3: [4.20, 4.22, 4.19, 4.19, 4.19, 4.19, 4.17] },
        { name: "Muhammad Fiqi Firmansyah", role: "Operasional Lapangan", scores: [1.34, 2.44, 3.41, 4.24], class: "Unggul", domainB3: [4.25, 4.27, 4.24, 4.24, 4.24, 4.24, 4.22] },
        { name: "Zoar Lewi Panjaitan", role: "Evaluasi & Pengolahan Data", scores: [1.35, 2.43, 3.43, 4.26], class: "Sangat Unggul", domainB3: [4.27, 4.29, 4.26, 4.26, 4.26, 4.26, 4.24] }
    ];

    const INK = '#14203a', ACCENT = '#7a1230', MUTED = '#4b5566', LINE = '#d3d8e0';

    let longitudinalChartObj = null, spiderChartObj = null, barChartObj = null, studentRadarChartObj = null;

    function filterDomain(code) {
        document.querySelectorAll('.dom-tab-btn').forEach(btn => {
            btn.classList.toggle('is-active', btn.dataset.domain === code);
        });
        renderDomainCards(code);
    }

    function renderDomainCards(codeFilter) {
        const container = document.getElementById('domainGridContainer');
        const listToRender = codeFilter === 'ALL' ? domainDefinitions : domainDefinitions.filter(d => d.code === codeFilter);
        container.innerHTML = listToRender.map(d => `
            <div class="domain-card">
                <div class="domain-card__head">
                    <span class="domain-chip">Domain ${d.code}</span>
                    <span class="domain-card__count">${d.indicators.length} Indikator</span>
                </div>
                <h4 class="domain-card__title">${d.title}</h4>
                <p class="domain-card__desc">${d.desc}</p>
                <div class="indicator-list">
                    ${d.indicators.map(i => `<div class="indicator-item"><span class="indicator-item__code">#${i.id}</span><span>${i.text}</span></div>`).join('')}
                </div>
            </div>
        `).join('');
    }

    function initLongitudinalChart() {
        const ctx = document.getElementById('longitudinalLineChart').getContext('2d');
        longitudinalChartObj = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['Bulan 0', 'Bulan 1', 'Bulan 2', 'Bulan 3'],
                datasets: [
                    { label: 'Rata-Rata Kumulatif Tim', data: [1.38, 2.45, 3.44, 4.25], borderColor: ACCENT, backgroundColor: 'rgba(122,18,48,0.08)', borderWidth: 2.5, fill: true, tension: 0.25, pointRadius: 4, pointBackgroundColor: ACCENT },
                    { label: 'Batas Bawah Target', data: [1.00, 2.00, 3.00, 4.10], borderColor: MUTED, borderDash: [4, 4], borderWidth: 1.5, fill: false, pointRadius: 0 }
                ]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom', labels: { font: { size: 11 }, color: INK } } },
                scales: {
                    y: { min: 1, max: 5, ticks: { stepSize: 1, color: MUTED }, grid: { color: LINE } },
                    x: { ticks: { color: MUTED }, grid: { display: false } }
                }
            }
        });
    }

    function switchMonth(mIndex) {
        document.querySelectorAll('.month-tab').forEach(tab => {
            tab.classList.toggle('is-active', Number(tab.dataset.month) === mIndex);
        });
        renderMonthlyCharts(mIndex);
    }

    function renderMonthlyCharts(mIndex) {
        const data = monthlyData[mIndex];
        document.getElementById('spider-subtitle').textContent = `${data.label} · Target: ${data.targetRange}`;
        document.getElementById('bar-subtitle').textContent = `22 Indikator · ${data.label}`;
        document.getElementById('narrative-title').textContent = 'Narasi Analisis Evaluasi';
        document.getElementById('narrative-content').innerHTML = data.narrative;

        const banner = document.getElementById('period-banner');
        banner.innerHTML = `
            <div>
                <strong>${data.label}</strong>
                <p>Skor Kumulatif Tim: <strong style="color:var(--ink);">${data.cumulativeAvg.toFixed(2)}</strong> &middot; ${data.targetRange}</p>
            </div>
            <span class="tag tag--outline">${data.targetRange.split(' ')[0]} ${data.targetRange.split(' ')[1]}</span>
        `;

        const ctxSpider = document.getElementById('monthlySpiderChart').getContext('2d');
        if (spiderChartObj) spiderChartObj.destroy();
        spiderChartObj = new Chart(ctxSpider, {
            type: 'radar',
            data: {
                labels: ['Domain A', 'Domain B', 'Domain C', 'Domain D', 'Domain E', 'Domain F', 'Domain G'],
                datasets: [{ label: 'Skor Domain', data: data.domainScores, backgroundColor: 'rgba(122,18,48,0.14)', borderColor: ACCENT, pointBackgroundColor: ACCENT, borderWidth: 2 }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                scales: { r: { min: 1, max: 5, ticks: { stepSize: 1, display: false }, pointLabels: { font: { size: 10 }, color: INK }, grid: { color: LINE }, angleLines: { color: LINE } } },
                plugins: { legend: { display: false } }
            }
        });

        const ctxBar = document.getElementById('monthlyBarChart').getContext('2d');
        if (barChartObj) barChartObj.destroy();
        barChartObj = new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: Array.from({ length: 22 }, (_, i) => `I${i + 1}`),
                datasets: [{ label: 'Skor Indikator', data: data.indicatorScores, backgroundColor: INK, borderRadius: 2 }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { callbacks: { title: (items) => indicatorsList[items[0].dataIndex] } } },
                scales: {
                    y: { min: 1, max: 5, ticks: { stepSize: 1, color: MUTED }, grid: { color: LINE } },
                    x: { ticks: { font: { size: 9 }, color: MUTED }, grid: { display: false } }
                }
            }
        });
    }

    function populateStudentSelector() {
        const select = document.getElementById('studentSelect');
        select.innerHTML = studentsData.map((s, idx) => `<option value="${idx}">${idx + 1}. ${s.name}</option>`).join('');
    }

    function updateStudentView() {
        const idx = document.getElementById('studentSelect').value;
        const s = studentsData[idx];

        document.getElementById('student-bio-card').innerHTML = `
            <div>
                <h4 style="font-size:0.875rem; font-weight:600;">${s.name}</h4>
                <p style="font-size:0.75rem; color:var(--accent); font-weight:500;">${s.role}</p>
            </div>
            <div style="border-top:1px solid var(--line); padding-top:8px; margin-top:8px; font-size:0.75rem; color:var(--muted); display:flex; flex-direction:column; gap:4px;">
                <div style="display:flex; justify-content:space-between;"><span>Status Klasifikasi</span><span style="font-weight:600; color:var(--ink);">${s.class}</span></div>
                <div style="display:flex; justify-content:space-between;"><span>Skor Awal (B0)</span><span style="font-weight:600; color:var(--ink);">${s.scores[0]}</span></div>
                <div style="display:flex; justify-content:space-between;"><span>Skor Akhir (B3)</span><span style="font-weight:600; color:var(--accent);">${s.scores[3]}</span></div>
            </div>
        `;

        const delta = (s.scores[3] - s.scores[0]).toFixed(2);
        document.getElementById('student-growth-badge').textContent = `Δ +${delta} poin`;

        document.getElementById('student-detail-summary').innerHTML = `
            <div><span class="m-label">Bulan 0</span><span class="m-value">${s.scores[0]}</span></div>
            <div><span class="m-label">Bulan 1</span><span class="m-value">${s.scores[1]}</span></div>
            <div><span class="m-label">Bulan 2</span><span class="m-value">${s.scores[2]}</span></div>
            <div class="is-final"><span class="m-label">Bulan 3</span><span class="m-value">${s.scores[3]}</span></div>
        `;

        const ctx = document.getElementById('studentRadarChart').getContext('2d');
        if (studentRadarChartObj) studentRadarChartObj.destroy();
        studentRadarChartObj = new Chart(ctx, {
            type: 'radar',
            data: {
                labels: ['Domain A', 'Domain B', 'Domain C', 'Domain D', 'Domain E', 'Domain F', 'Domain G'],
                datasets: [
                    { label: 'Bulan Ke-0', data: Array(7).fill(s.scores[0]), borderColor: MUTED, backgroundColor: 'rgba(75,85,102,0.08)', borderWidth: 1.5 },
                    { label: 'Bulan Ke-3', data: s.domainB3, borderColor: ACCENT, backgroundColor: 'rgba(122,18,48,0.16)', borderWidth: 2 }
                ]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                scales: { r: { min: 1, max: 5, ticks: { stepSize: 1, display: false }, pointLabels: { font: { size: 10 }, color: INK }, grid: { color: LINE }, angleLines: { color: LINE } } },
                plugins: { legend: { position: 'bottom', labels: { font: { size: 10 }, color: INK } } }
            }
        });
    }

    function renderTable() {
        const tbody = document.getElementById('tableBody');
        tbody.innerHTML = studentsData.map((s, idx) => {
            const growth = (s.scores[3] - s.scores[0]).toFixed(2);
            const tagClass = s.class === 'Sangat Unggul' ? 'tag--ok' : 'tag--warn';
            return `
                <tr>
                    <td class="num muted">${idx + 1}</td>
                    <td class="strong">${s.name}</td>
                    <td class="muted">${s.role}</td>
                    <td class="num muted">${s.scores[0]}</td>
                    <td class="num muted">${s.scores[1]}</td>
                    <td class="num muted">${s.scores[2]}</td>
                    <td class="num strong">${s.scores[3]}</td>
                    <td class="num accent">+${growth}</td>
                    <td><span class="tag ${tagClass}">${s.class}</span></td>
                </tr>
            `;
        }).join('');
    }

    function filterTable() {
        const query = document.getElementById('tableSearch').value.toLowerCase();
        document.querySelectorAll('#tableBody tr').forEach(row => {
            row.style.display = row.textContent.toLowerCase().includes(query) ? '' : 'none';
        });
    }

    document.addEventListener('DOMContentLoaded', () => {
        renderDomainCards('ALL');
        initLongitudinalChart();
        renderMonthlyCharts(0);
        populateStudentSelector();
        updateStudentView();
        renderTable();

        document.querySelectorAll('[data-scroll]').forEach(btn => {
            btn.addEventListener('click', () => {
                document.getElementById(btn.dataset.scroll).scrollIntoView({ behavior: 'smooth' });
            });
        });
        document.querySelectorAll('.dom-tab-btn').forEach(btn => {
            btn.addEventListener('click', () => filterDomain(btn.dataset.domain));
        });
        document.querySelectorAll('.month-tab').forEach(btn => {
            btn.addEventListener('click', () => switchMonth(Number(btn.dataset.month)));
        });
        document.getElementById('studentSelect').addEventListener('change', updateStudentView);
        document.getElementById('tableSearch').addEventListener('input', filterTable);
    });
})();
