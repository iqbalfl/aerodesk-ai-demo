> SETUP DASAR: Dokumen ini menjelaskan instalasi awal OpenClaw/VPS. Untuk lanjutan CI/CD, coding agent, approval Telegram, dan deploy, baca `FULL_CYCLE_SETUP_ID.md`.

# Panduan Lengkap Setup Live Demo AI Second Brain (OpenClaw)

**Edisi:** 22 Oktober 2026  
**Audiens:** presenter Fullstack Developer, lintas role (PM, QA, Data Science, department head)  
**Target:** OpenClaw native di VPS Ubuntu 2 vCPU / 4 GB RAM + ChatGPT/Codex OAuth + SQLite/Gemini embeddings + Telegram + Control UI via Cloudflare Access + aplikasi Express di Docker + GitHub Issues.  
**Status:** instruksi sudah direview terhadap dokumentasi resmi, tetapi **belum dieksekusi di VPS milik kamu**. Jangan menganggap domain, bot, maupun GitHub sudah terhubung sebelum tes berhasil.

## 0. Skenario demo

1. **Retrieve:** Agent menjawab mengapa tim memilih PostgreSQL berdasarkan ADR-007 dari memory, bukan dari tebakan.
2. **Investigate:** Agent mengecek aplikasi nyata: `GET /api/customers?page=1&limit=3` mengembalikan **10** records, lalu menelusuri implementasinya.
3. **Act with approval:** Agent membuat **draft** GitHub Issue dan kamu menyetujuinya sebelum issue dibuat pada repository demo.

Catatan: ADR menyatakan keputusan PostgreSQL **untuk arsitektur yang direncanakan**. Aplikasi demo tetap memakai data in-memory. Jangan mengklaim PostgreSQL sudah digunakan. Semua chat OpenClaw dilakukan **dalam bahasa Indonesia** (file `AGENTS.md` sudah disiapkan).

## 1. Arsitektur dan domain

```text
Presenter (Mac / Telegram)
   ├── https://ai.CONTOHDOMAIN.com  ─ Cloudflare Access (restricted email)
   │                                      │
   │                                      └─ Cloudflare Tunnel → 127.0.0.1:18789
   │                                                                  │
   ├── Telegram Bot (DM allowlist) ────────────────────────────────────┤
   │                                                                  ▼
   │                                                    OpenClaw Gateway - native
   │                                                      /     |      |      \
   │                                              ChatGPT OAuth | Gemini | GitHub CLI
   │                                                           SQLite   | repo + Issues
   │
   └── https://demo.CONTOHDOMAIN.com ─ Cloudflare Tunnel → 127.0.0.1:3000
                                                          │
                                                          ▼
                                                   Docker Express API
```

- **OpenClaw bukan container** pada setup ini. Gunakan satu instalasi normal/utama `~/.openclaw` tanpa profile demo terpisah.
- **Aplikasi demo di Docker** dengan port host `127.0.0.1:3000` saja.
- **Control UI punya alamat publik** tetapi wajib lolos Cloudflare Access. Port 18789 tetap hanya di loopback VPS. **Jangan** membuka port 18789/3000 pada security group/UFW.
- Server kecil ini bukan tempat untuk menjalankan LLM atau embedding model besar lokal; kedua komputasi tersebut diakses melalui layanan cloud.

## 2. Persiapan akun dan data yang dibutuhkan

Siapkan: VPS Ubuntu modern dengan SSH dan user non-root `ubuntu`/user milikmu; domain sudah masuk Cloudflare; akun ChatGPT subscription yang memenuhi syarat akses Codex; Google AI Studio API key; bot Telegram dari [@BotFather](https://t.me/BotFather); repository GitHub khusus demo; dan (untuk actual issue write) fine-grained GitHub token khusus repository itu.

Contoh hostname (ganti sendiri, **jangan pakai literal placeholder**):

```text
ai.example.com     - Control UI protected by Cloudflare Access
demo.example.com   - UI dan REST API demo (publik, hanya data fiktif)
YOUR_GITHUB_USERNAME/aerodesk-ai-demo
```

### Catatan biaya

- ChatGPT subscription (Codex OAuth) menggunakan kuota langganan, **bukan** kredit API OpenAI umum.
- `GEMINI_API_KEY` adalah **API key terpisah** untuk embeddings. Tier gratis Google memiliki kuota, rate limit, dan kebijakan penggunaan data sendiri. Gunakan data contoh/fiktif, bukan informasi internal sensitif.
- VPS, domain, dan layanan pihak ketiga bisa menimbulkan biaya yang berbeda. Periksa limit aktual sebelum live demo.

## 3. Persiapkan VPS Ubuntu

SSH dari Mac:

```bash
ssh ubuntu@IP_PUBLIK_VPS
```

Di VPS sebagai user non-root dengan `sudo`:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ca-certificates unzip jq python3 ufw
uname -a
free -h
```

Amankan SSH key dan firewall. **Pastikan aturan SSH sudah benar sebelum mengaktifkan UFW**, atau kamu bisa terkunci dari server. Untuk server baru dengan SSH port 22:

```bash
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status verbose
```

Jika memakai port SSH custom atau firewall provider, sesuaikan. Tidak perlu membuka 3000/18789 di firewall.

## 4. Instal Docker untuk aplikasi demo

Ikuti instalasi resmi **Docker Engine + Compose plugin** untuk Ubuntu: https://docs.docker.com/engine/install/ubuntu/ . Jangan memakai script Docker acak. Setelah terpasang:

```bash
docker version
docker compose version
```

Jika user belum masuk grup docker, gunakan `sudo docker compose` atau konfigurasi sesuai kebutuhan. Menambahkan user ke grup `docker` memberikan akses setara root secara praktis; lakukan hanya pada akun admin yang tepercaya.

## 5. Siapkan repository di GitHub

Di Mac atau laptop lokal, ekstrak ZIP kit ini. Di direktori root yang berisi `compose.yaml`:

```bash
git init -b main
git add .
git commit -m "Initial AeroDesk AI Second Brain demo"
```

Buat repository **baru** bernama `aerodesk-ai-demo` di GitHub (boleh public karena semua data fiktif). Sambungkan dan push:

```bash
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/aerodesk-ai-demo.git
git push -u origin main
```

> Jangan push token, file `.env` asli, file config OpenClaw yang berisi kredensial, backup server, atau data perusahaan. `.gitignore` sudah disediakan.

Di VPS, clone repositori:

```bash
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/YOUR_GITHUB_USERNAME/aerodesk-ai-demo.git
cd aerodesk-ai-demo
```

Pastikan repository **Settings → General → Features → Issues** sudah enabled.

## 6. Deploy aplikasi real dengan Docker

Dari direktori repository di VPS:

```bash
docker compose up -d --build
docker compose ps
docker compose logs --tail 40
curl -fsS http://127.0.0.1:3000/health
bash scripts/smoke-test.sh
```

**Hasil yang diharapkan:** health `status: ok`; smoke test menyatakan `limit=3` tetapi `returned 10`. Endpoint yang tersedia:

```text
/                          -> UI visual untuk audience
/health                    -> status aplikasi
/api/decisions             -> ADR ringkasan (mock)
/api/issues                -> issue data fiktif, BUKAN live GitHub
/api/customers?page=1&limit=3 -> bug pagination yang disengaja
```

Kalau mengubah source pada repo setelah live demo, `docker compose up -d --build` untuk rebuild. **Jangan memperbaiki bug pagination sebelum sesi**, karena dipakai untuk Act 2 dan Act 3.

## 7. Instal OpenClaw native (tanpa profile isolated)

Gunakan dokumentasi instalasi resmi: https://docs.openclaw.ai/start/getting-started . Install script resmi:

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
openclaw --version
```

Jika installer sudah menjalankan onboarding, ikuti langkahnya. Untuk wizard classic yang sekaligus memasang service bila onboarding belum dijalankan:

```bash
openclaw onboard --install-daemon
```

**Catatan:** Jika Gateway sudah terpasang dari langkah installer, jangan menjalankan onboarding berulang hanya untuk memasang service. Alternatifnya `openclaw gateway install` setelah wizard.

Onboarding biasanya akan mengatur `~/.openclaw/openclaw.json` dan workspace `~/.openclaw/workspace/`. Gunakan **satu agent utama** untuk Control UI dan Telegram.

Service berjalan sebagai systemd user unit. Untuk VPS selalu hidup:

```bash
sudo loginctl enable-linger "$USER"
openclaw gateway status
openclaw doctor
```

Versi OpenClaw dapat berubah; bila ada field berbeda, dahulukan `openclaw config schema` dan docs untuk **versi terpasang**, jangan memaksa patch yang gagal validasi.

## 8. Hubungkan ChatGPT subscription / Codex OAuth

Di VPS tanpa browser lokal gunakan device-code login:

```bash
openclaw models auth login --provider openai --method device-code
```

Buka URL yang ditampilkan di Mac, lalu otorisasi menggunakan akun ChatGPT kamu. Jangan membagikan kode login kepada orang lain.

```bash
openclaw models list --provider openai
openclaw models status
```

Untuk model default, pilih **persis salah satu model yang benar-benar muncul** di daftar. Contoh yang disebut dalam dokumentasi saat guide dibuat (akses akun bisa berbeda):

```bash
openclaw config set agents.defaults.model.primary openai/gpt-6-astra
```

Jika tidak tersedia, gunakan nama model yang memang terdaftar di akunmu. **Jangan** membuat `OPENAI_API_KEY` dengan asumsi token ChatGPT sama dengan kredit OpenAI API.

## 9. Konfigurasi SQLite + Gemini cloud embeddings

Backend memory default OpenClaw menggunakan SQLite. API Gemini menyediakan embedding sehingga komputasi embedding tidak dijalankan di VPS.

Buat API key di https://aistudio.google.com/apikey . Simpan pada lingkungan milik Gateway (bukan repository GitHub):

```bash
mkdir -p ~/.openclaw
chmod 700 ~/.openclaw
nano ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
```

Tambahkan satu baris baru tanpa menghapus env lain:

```dotenv
GEMINI_API_KEY=PASTE_KEY_DI_VPS_SAJA
```

Konfigurasikan provider memory yang benar untuk rilis OpenClaw saat ini:

```bash
openclaw config set memory.search.provider gemini
openclaw config set memory.search.model gemini-embedding-001
openclaw config validate --json
openclaw gateway restart
```

Model `gemini-embedding-001` direkomendasikan untuk knowledge teks, dengan default dimensi mengikuti provider. Jangan mengganti model/dimensi tanpa reindex.

**Catatan penting:** bila Gemini API Free Tier tidak dapat memproses request (kuota/izin/region), index semantic tidak otomatis dianggap berhasil. Periksa `memory status --deep`; untuk fallback yang disengaja, gunakan `openclaw config set memory.search.provider none` (keyword/FTS saja), lalu kembali ke Gemini saat siap. `provider: none` bukan semantic similarity.

## 10. Pasang demo memory dan index

**Hanya lakukan pada fresh OpenClaw yang memang didedikasikan untuk sesi ini.** Script akan membuat backup untuk file memory yang namanya sama sebelum menyalin, tetapi tetap mengubah workspace default.

```bash
cd ~/projects/aerodesk-ai-demo
bash scripts/install-workspace.sh
```

Jika default workspace kamu tidak berada pada `~/.openclaw/workspace`, cek:

```bash
openclaw config get agents.defaults.workspace
```

Bila custom, jalankan dengan override eksplisit `OPENCLAW_WORKSPACE=/path/yang/benar bash scripts/install-workspace.sh`.

Index dan verifikasi:

```bash
openclaw memory index --force
openclaw memory status --deep
openclaw memory search 'Kenapa kita memilih database relational untuk reporting?'
```

**Hasil yang diharapkan:** ada temuan ADR-007. Tes ulang pertanyaan dengan kata berbeda, misalnya "Apa alasan tidak memilih NoSQL untuk data customer?" agar nilai semantic similarity terlihat.

## 11. Setup Telegram (chat bahasa Indonesia)

1. Buka https://t.me/BotFather, jalankan `/newbot`, simpan bot token.
2. Simpan token di **file regular** (bukan symlink):

```bash
mkdir -p ~/.config/openclaw
chmod 700 ~/.config/openclaw
nano ~/.config/openclaw/telegram.token
chmod 600 ~/.config/openclaw/telegram.token
```

3. Untuk pertama kali, set token path dan gunakan pairing:

```bash
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.tokenFile "$HOME/.config/openclaw/telegram.token"
openclaw config set channels.telegram.dmPolicy pairing
openclaw config set channels.telegram.groupPolicy disabled
openclaw gateway restart
openclaw channels status --probe
```

4. Kirim pesan langsung dari Telegram kamu ke bot. Lihat pairing code, lalu:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram KODE_PAIRING
```

5. Ambil **Telegram user ID numerik** dari pairing reply atau log (`openclaw logs --follow`). Ganti pairing dengan allowlist permanen:

```bash
openclaw config set channels.telegram.allowFrom '["YOUR_TELEGRAM_NUMERIC_ID"]' --strict-json
openclaw config set channels.telegram.dmPolicy allowlist
openclaw gateway restart
```

6. Tes chat bahasa Indonesia: "Tolong jelaskan apa yang kamu tahu tentang project AeroDesk."

**Penting:** `allowFrom` harus numeric user ID, bukan nama pengguna Telegram, chat/group ID atau nomor telepon. `groupPolicy disabled` menolak bot digunakan dari grup. Long polling default tidak memerlukan webhook atau port inbound.

## 12. Cloudflare Tunnel: app publik + Control UI terproteksi

Gunakan satu Cloudflare Tunnel dengan **dua hostname** yang route-nya berbeda. Install `cloudflared` di VPS melalui instruksi yang diberikan dashboard resmi Cloudflare. Panduan: https://developers.cloudflare.com/tunnel/get-started/.

### Route 1: aplikasi publik

Cloudflare Dashboard → **Networking → Tunnels** → Create Tunnel → install `cloudflared` (salin token servis dari dashboard). Buat published application route:

```text
Hostname: demo.example.com
Service URL: http://127.0.0.1:3000
```

Pastikan DNS record otomatis dibuat atau disesuaikan dalam Cloudflare. Setelah itu buka `https://demo.example.com` dari HP/komputer lain. Halaman UI akan menampilkan mismatch pagination secara visual.

### Route 2: OpenClaw Control UI dengan Cloudflare Access

**Siapkan autentikasi sebelum membuka route Control UI.** Cloudflare → Zero Trust → Access controls → Applications → Add self-hosted application untuk `ai.example.com` → policy **Allow hanya email presenter**. Aktifkan autentikasi yang sesuai (One-time PIN atau identity provider). Di pengaturan Tunnel yang tersedia, gunakan **Protect with Access** sehingga permintaan disaring di sisi connector juga, bukan hanya mengandalkan keberadaan header yang bisa dipalsukan secara lokal.

Tambahkan route:

```text
Hostname: ai.example.com
Service URL: http://127.0.0.1:18789
```

### Konfigurasi trusted proxy di OpenClaw

Backup dulu; jangan hapus session/token sebelum SSH tersedia untuk memulihkan konfigurasi:

```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.before-cloudflare.bak
chmod 600 ~/.openclaw/openclaw.json.before-cloudflare.bak
```

File `config/openclaw.patch.example.json5` dalam paket memperlihatkan bentuk yang disarankan. Isi domain, email, Linux username, dan Telegram user ID yang benar, **lalu hanya patch setelah review**. Contoh field yang dibutuhkan:

```json5
{
  gateway: {
    bind: "loopback",
    publicOrigin: "https://ai.example.com",
    trustedProxies: ["127.0.0.1", "::1"],
    controlUi: { allowedOrigins: ["https://ai.example.com"] },
    auth: {
      mode: "trusted-proxy",
      trustedProxy: {
        userHeader: "cf-access-authenticated-user-email",
        requiredHeaders: ["cf-access-jwt-assertion"],
        allowLoopback: true,
        allowUsers: ["email-presenter@example.com"]
      }
    }
  }
}
```

**CRITICAL:** default onboarding biasanya membuat `gateway.auth.token`, sedangkan mode `trusted-proxy` tidak kompatibel dengan token tersebut. Perlu dihapus dari config **saat** transisi, bukan sebelum route Access siap:

```bash
openclaw config unset gateway.auth.token --dry-run
openclaw config unset gateway.auth.token
# Setelah menyesuaikan isi patch file:
openclaw config patch --file config/openclaw.patch.example.json5 --dry-run
openclaw config patch --file config/openclaw.patch.example.json5
openclaw config validate --json
openclaw gateway restart
openclaw security audit
```

Jika file patch masih berisi placeholder, **JANGAN JALANKAN** perintah patch. `allowLoopback` adalah kepercayaan pada proxy lokal; proses lain dengan akses lokal dapat mencoba spoofing header. Karena itu server harus single-admin trusted host, Gateway bind loopback, cloudflared route satu-satunya jalur eksternal, dan **Protect with Access** wajib diterapkan. Jangan mempublikasikan Control UI dengan `gateway.auth.mode none` atau `dangerouslyAllowHostHeaderOriginFallback`.

Jika menemui masalah trusted-proxy, restore backup dari SSH dan kembali ke konfigurasi token semula. Browser/device baru mungkin membutuhkan approval tersendiri. Tes URL `https://ai.example.com` dalam browser private/incognito untuk memastikan email lain ditolak.

## 13. Integrasi GitHub Issues nyata

**Repository target:** hanya `YOUR_GITHUB_USERNAME/aerodesk-ai-demo`.

Install GitHub CLI di VPS sebagai user OpenClaw (bila belum ada):

```bash
sudo apt install -y gh
gh --version
```

Untuk demo, buat **fine-grained PAT GitHub** dengan Repository access = **Only select repositories** → pilih `aerodesk-ai-demo`, dan permissions minimum yang diperlukan: **Metadata read**, **Contents read**, **Issues read/write**. Jangan memberi hak ke repository lain, organisasi internal, Actions atau Secrets jika tidak dibutuhkan. Atur expiration pendek dan revoke setelah presentasi.

Masukkan PAT ke lingkungan Gateway pada `~/.openclaw/.env` sebagai `GH_TOKEN`, bersama `GEMINI_API_KEY`, izin file 0600. Jangan mengirim PAT di Telegram, prompt agent, `.env` repo, screenshot, atau Presenter View. Pada CLI yang tidak mewarisi env Gateway, verifikasi dengan membaca GH_TOKEN dari tempat aman secara interaktif, bukan mencetak nilainya.

Tes repo secara manual dari VPS:

```bash
gh repo view YOUR_GITHUB_USERNAME/aerodesk-ai-demo
gh issue list -R YOUR_GITHUB_USERNAME/aerodesk-ai-demo --limit 10
```

Untuk membaca source code, git clone sudah tersedia di VPS. Jika agent menggunakan shell tool, **pastikan path repo dan tool permission telah dibatasi**. Jangan berikan akses ke root shell. `gh` harus melihat `GH_TOKEN` di environment Gateway untuk menulis issue.

### Kebijakan approval command

Instalasi OpenClaw native **tanpa sandbox** bisa menjalankan command langsung pada host. Ini sengaja berbeda dari demo profile terisolasi, tetapi berisiko: karena itu kita **tidak** mengizinkan mode `full` tanpa konfirmasi.

```bash
openclaw config set tools.exec.mode ask
openclaw approvals get
openclaw exec-policy show
openclaw gateway restart
```

Mode `ask` membuat bentuk command baru memerlukan approval manusia; ini **berbeda** dari perintah dalam `AGENTS.md` yang hanya bersifat instruksi model. Rute approval via Control UI/Telegram bisa memiliki keterbatasan sehingga **uji terlebih dahulu**. Jika approval belum berhasil, gunakan read-only demonstration dan buat issue secara manual dari terminal setelah kamu menyetujui draft. Jangan mengubah kebijakan menjadi `full` hanya agar demo lancar.

### Bukti issue benar-benar terbuat

Setelah membaca draft issue dan approve, agent boleh membuat issue *hanya* di repo demo. Periksa URL issue yang dikembalikan, klik di browser, dan pastikan status `Open`. Jangan menyebut issue sudah dibuat sebelum link valid.

## 14. Cara menjalankan demo (ringkas)

Gunakan `DEMO_SCRIPT_ID.md` untuk prompt lengkap.

- **Act 1 - Memory:** Tanya alasan PostgreSQL; tampilkan ADR-007. Validasi bahwa ini rencana, bukan implementasi DB nyata.
- **Act 2 - Investigation:** Perlihatkan mismatch di `demo.example.com` dan API `limit=3`, minta agent menunjuk kode penyebab.
- **Act 3 - Action:** Minta draft GitHub Issue, review isi, approve, lalu buka link issue hasil create.

Tunjukkan dialog pada Telegram dan jika perlu switch ke Control UI; jangan menjanjikan chat history antar-channel selalu identik karena sesi dapat berbeda menurut konfigurasi.

## 15. Checklist sebelum sharing session

- [ ] VPS dapat SSH dengan akun non-root dan tidak memiliki port 18789/3000 yang terekspos internet.
- [ ] `docker compose ps` = healthy; `bash scripts/smoke-test.sh` = PASS.
- [ ] `https://demo.example.com` bisa dibuka tanpa login dan menampilkan 3 vs 10.
- [ ] `https://ai.example.com` bisa dibuka **hanya** oleh email presenter melalui Cloudflare Access.
- [ ] `openclaw models status` menunjukkan model inference siap; chat satu prompt sukses.
- [ ] `openclaw memory status --deep` menunjukkan embedding/index siap; dua pertanyaan serupa menemukan ADR-007.
- [ ] Telegram bot merespons akun sendiri; akun lain tidak memiliki akses.
- [ ] Repo GitHub dapat dibaca dan issue list bekerja; token dibatasi ke repo demo.
- [ ] Draft issue mengandung steps, expected/actual, evidence, acceptance criteria.
- [ ] Jalur approval command sudah diuji atau fallback manual sudah siap.
- [ ] Matikan notifikasi pop-up saat screen sharing; jangan tampilkan token atau file konfigurasi sensitif.

## 16. Troubleshooting

| Kendala | Pemeriksaan / langkah |
|---|---|
| `openclaw` tidak ditemukan | Reopen SSH session, cek installer PATH, `openclaw --version` |
| Gateway berhenti setelah logout | `sudo loginctl enable-linger "$USER"`, `openclaw gateway status` |
| OAuth gagal | `openclaw models auth login --provider openai --method device-code`, cek model list dan limit |
| `memory search` kosong | Verifikasi workspace, `openclaw memory index --force`, `openclaw memory status --deep` |
| Gemini embedding 401/429 | Periksa key, akses model, free quota/rate limit; jangan mengklaim semantic berhasil jika gagal |
| Telegram silent | `openclaw channels status --probe`; cek pairing / ID numerik allowlist / tokenFile |
| Cloudflare AI 403 | Periksa Access email policy, Tunnel route, Protect with Access dan JWT headers |
| WebSocket `1008` / origin | Periksa `gateway.publicOrigin`, `gateway.controlUi.allowedOrigins`, trusted proxy policy; jangan membuka auth tanpa kontrol |
| UI app 502 | `docker compose ps`, `docker compose logs`, `curl 127.0.0.1:3000/health` |
| `gh issue create` ditolak | Periksa fine-grained PAT, repo target, Issues write permission, dan approval host; fallback draft/manual |
| VPS kehabisan RAM | `free -h`, `docker stats --no-stream`, hentikan proses tak perlu; inference tetap di cloud |
| Perubahan config tidak valid | Pulihkan backup dan jalankan `openclaw config validate` sebelum restart |

## 17. Rencana cadangan demo

1. Telegram error → presentasikan dari Control UI yang sudah login.
2. Memory semantic gagal → tunjukkan file ADR secara langsung dan jelaskan fallback FTS secara terbuka.
3. Repo/API tak terjangkau agent → gunakan UI API publik + inspect kode di GitHub untuk verifikasi manual.
4. Create issue tidak diizinkan → tampilkan **draft issue** di layar, lalu jika perlu buat tiket manual setelah persetujuan. Jangan berpura-pura agent telah berhasil.

## Dokumentasi utama

- OpenClaw getting started: https://docs.openclaw.ai/start/getting-started
- OpenAI Codex subscription setup: https://docs.openclaw.ai/providers/openai/setup
- OpenClaw memory search: https://docs.openclaw.ai/concepts/memory-search
- Memory config: https://docs.openclaw.ai/reference/memory-config
- Telegram access: https://docs.openclaw.ai/channels/telegram/access-control
- Cloudflare Access guide: https://docs.openclaw.ai/gateway/cloudflare-access
- Permission modes: https://docs.openclaw.ai/tools/permission-modes
- Cloudflare Tunnel: https://developers.cloudflare.com/tunnel/get-started/
- Google Gemini pricing: https://ai.google.dev/gemini-api/docs/pricing
- Docker Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- GitHub CLI: https://cli.github.com/manual/gh_auth_login
