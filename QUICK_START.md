> LEGACY: Panduan 3 babak versi lama. Untuk demo coding + PR + approval Telegram + deploy, gunakan `FULL_CYCLE_SETUP_ID.md` dan `DEMO_SCRIPT_FULL_CYCLE_ID.md`.

# Quick Start - Checklist Demo AI Second Brain

> Untuk detail dan keamanan, baca [VPS_SETUP_ID.md](VPS_SETUP_ID.md). Semua chat ke agent berbahasa Indonesia.

## Persiapan (akun)

- [ ] Fresh VPS Ubuntu 2C4G dengan SSH key dan user admin non-root
- [ ] Domain Cloudflare: `ai.example.com`, `demo.example.com`
- [ ] Akun ChatGPT untuk Codex OAuth
- [ ] Google AI Studio key untuk Gemini Embedding API
- [ ] Telegram bot token dari @BotFather
- [ ] Dedicated GitHub repo dan fine-grained PAT hanya untuk repo demo

## Urutan pekerjaan

1. Upload project ke GitHub (`git init` → commit → push).
2. Clone di VPS; install Docker; jalankan `docker compose up -d --build`.
3. Uji: `bash scripts/smoke-test.sh` (harus membuktikan mismatch pagination).
4. Instal OpenClaw native memakai installer resmi dan buat systemd user service.
5. Login `openclaw models auth login --provider openai --method device-code`.
6. Simpan `GEMINI_API_KEY` di `~/.openclaw/.env`; `openclaw config set memory.search.provider gemini`.
7. Jalankan `bash scripts/install-workspace.sh`, `openclaw memory index --force`, `openclaw memory status --deep`.
8. Setup Telegram tokenFile → pairing → ganti allowlist numeric Telegram user ID.
9. Cloudflare Tunnel route: `demo.example.com → 127.0.0.1:3000`; `ai.example.com → 127.0.0.1:18789`.
10. Siapkan Cloudflare Access (email presenter) + Protect with Access, lalu trusted-proxy config OpenClaw.
11. Login GitHub CLI dengan credential khusus demo repository; batasi command access (`tools.exec.mode ask`).
12. Latihan 3 prompt di `DEMO_SCRIPT_ID.md` dan uji fallback.

## URL yang ditampilkan

- Public app: `https://demo.example.com`
- Public API bug: `https://demo.example.com/api/customers?page=1&limit=3`
- Protected Control UI: `https://ai.example.com`
- GitHub Issues: `https://github.com/YOUR_GITHUB_USERNAME/aerodesk-ai-demo/issues`

**Jangan** menaruh token di slide, Telegram chat, atau repo. Jangan buka port 18789/3000 ke internet. Tidak perlu membuat profil OpenClaw terpisah.
