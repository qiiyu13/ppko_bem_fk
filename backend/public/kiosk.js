const API = '/api/v1';
const $ = (id) => document.getElementById(id);
let token = sessionStorage.getItem('kiosk_token');
let who = sessionStorage.getItem('kiosk_who');

function showApp() {
  $('login-card').classList.add('hidden');
  $('app').classList.add('ready');
  $('who-name').textContent = who || '';
}

if (token) showApp();

$('login-btn').addEventListener('click', async () => {
  const identifier = $('li-id').value.trim();
  const password = $('li-pw').value;
  $('login-error').style.display = 'none';
  if (!identifier || !password) return;
  $('login-btn').disabled = true;
  try {
    const res = await fetch(`${API}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier, password }),
    });
    const body = await res.json();
    if (!res.ok || !body.success) throw new Error(body.error?.message || 'Login gagal');
    if (!['ADMIN', 'SUPERADMIN'].includes(body.data.user.role)) throw new Error('Akun ini bukan akun petugas');
    token = body.data.token;
    who = body.data.user.responsibleName;
    sessionStorage.setItem('kiosk_token', token);
    sessionStorage.setItem('kiosk_who', who);
    showApp();
  } catch (e) {
    $('login-error').textContent = e.message;
    $('login-error').style.display = 'block';
  } finally {
    $('login-btn').disabled = false;
  }
});

$('logout-btn').addEventListener('click', () => {
  sessionStorage.removeItem('kiosk_token');
  sessionStorage.removeItem('kiosk_who');
  location.reload();
});

$('register-btn').addEventListener('click', async () => {
  const name = $('f-name').value.trim();
  const gender = document.querySelector('input[name=gender]:checked')?.value;
  $('register-error').style.display = 'none';
  if (!name) return showRegError('Nama wajib diisi');
  if (!gender) return showRegError('Jenis kelamin wajib dipilih');

  const payload = {
    name,
    gender,
    nik: $('f-nik').value.trim() || undefined,
    occupation: $('f-occupation').value || undefined,
    income: $('f-income').value || undefined,
    bloodType: $('f-bloodtype').value || undefined,
    address: $('f-address').value.trim() || undefined,
  };

  $('register-btn').disabled = true;
  try {
    const res = await fetch(`${API}/admin/kiosk/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.status === 401) { sessionStorage.clear(); location.reload(); return; }
    if (!res.ok || !body.success) throw new Error(body.error?.message || 'Gagal mendaftarkan pasien');

    $('r-name').textContent = body.data.profile.name;
    $('r-kk').textContent = body.data.kkNumber;
    $('r-username').textContent = body.data.username;
    $('r-password').textContent = body.data.password;
    $('r-view-qr').src = body.data.viewQrDataUrl;

    $('register-card').classList.add('hidden');
    $('result-card').classList.remove('hidden');
  } catch (e) {
    showRegError(e.message);
  } finally {
    $('register-btn').disabled = false;
  }
});

function showRegError(msg) {
  $('register-error').textContent = msg;
  $('register-error').style.display = 'block';
}

$('again-btn').addEventListener('click', () => {
  document.querySelectorAll('#register-card input, #register-card select, #register-card textarea').forEach((el) => {
    if (el.type === 'radio') el.checked = false; else el.value = '';
  });
  $('result-card').classList.add('hidden');
  $('register-card').classList.remove('hidden');
  $('f-name').focus();
});
