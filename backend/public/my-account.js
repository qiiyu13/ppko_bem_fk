(async () => {
  const token = new URLSearchParams(location.search).get('t');
  const content = document.getElementById('content');
  if (!token) { content.innerHTML = '<p class="error">Tautan tidak valid.</p>'; return; }

  try {
    const res = await fetch(`/api/v1/public/profile-qr/${encodeURIComponent(token)}`);
    const body = await res.json();
    if (!res.ok || !body.success) throw new Error(body.error?.message || 'Gagal memuat akun');
    const d = body.data;

    content.innerHTML = `
      <div class="card">
        <img src="${d.qrDataUrl}" alt="QR akun">
        <p class="note" style="margin-top:.75rem">Tunjukkan QR ini ke petugas saat skrining kesehatan.</p>
      </div>
      <div class="card">
        <div class="row"><div class="k">Nama</div><div class="v">${escapeHtml(d.name)}</div></div>
        ${d.kkNumber ? `<div class="row"><div class="k">No. KK</div><div class="v">${escapeHtml(d.kkNumber)}</div></div>` : ''}
        ${d.username ? `<div class="row"><div class="k">Username</div><div class="v">${escapeHtml(d.username)}</div></div>` : ''}
        ${d.password
          ? `<div class="row"><div class="k">Password</div><div class="v">${escapeHtml(d.password)}</div></div>
             <p class="note" style="color:#7a5c00">Simpan password ini sekarang &mdash; halaman ini tidak akan menampilkannya lagi.</p>`
          : `<p class="note">Sudah punya password? Gunakan No. KK/Username di atas untuk masuk ke aplikasi MEDIKU. Lupa password? Minta bantuan petugas.</p>`}
      </div>
      <p class="note">Instal aplikasi MEDIKU kapan saja, lalu masuk memakai No. KK/Username dan password di atas.</p>
    `;
  } catch (e) {
    content.innerHTML = `<p class="error">${escapeHtml(e.message)}</p>`;
  }
})();

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
