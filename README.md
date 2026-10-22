# AI Second Brain - Full Cycle Demo Kit (v2)

AeroDesk project fiktif untuk live sharing session **From AI Assistant to AI Teammate**. Versi ini memperpanjang 3 babak lama menjadi workflow pengembangan software end-to-end yang dapat diuji di GitHub dan VPS.

**[Panduan utama full cycle](FULL_CYCLE_SETUP_ID.md)** | [Naskah demo full cycle](DEMO_SCRIPT_FULL_CYCLE_ID.md) | [Checklist](QUICK_START_FULL_CYCLE.md)

## File baru di versi ini

| File | Fungsi |
| --- | --- |
| `app/test/pagination.test.js` | Regression test yang sengaja merah sebelum bug diperbaiki |
| `.github/workflows/pr-ci.yml` | Test dan Docker build di PR (tanpa deploy) |
| `.github/workflows/deploy.yml` | Test, Docker build, push GHCR, SSH VPS, deploy otomatis pada push `main` |
| `compose.prod.yaml` | Menggunakan image dari GHCR yang dipin ke SHA |
| `deploy/remote-deploy.sh` | Pull image, deploy, health check + rollback best effort |
| `scripts/merge-approved-pr.sh` | Gate sebelum merge: verifikasi PR SHA + CI sukses, dijalankan via approval Telegram |
| `scripts/check-fixed-live.sh` | Verifikasi hasil setelah deploy |
| `FULL_CYCLE_SETUP_ID.md` | Panduan setup VPS/GitHub/Telegram step-by-step |
| `DEMO_SCRIPT_FULL_CYCLE_ID.md` | Prompt presenter berbahasa Indonesia |
| `CODEX_ACP_OPTIONAL.md` | Jika ingin coding worker khusus via OpenClaw ACP |

## Sifat demo

- Bug awal `effectiveLimit=10` **disengaja**, bukan error project.
- Unit/regression test baru **gagal** pada branch baseline. Setelah coding agent memperbaiki bug, test harus hijau.
- Deployment `main` awal melalui Action juga bisa merah sampai bug diperbaiki. Untuk demo kondisi awal jalankan `docker compose up -d --build` di VPS.
- Aplikasi data in-memory, bukan PostgreSQL; ADR keputusan PostgreSQL adalah mock untuk pembahasan knowledge.
- Approval Telegram adalah kontrol eksekusi command native OpenClaw, **bukan** penerapan PR review formal GitHub. Tetap wajib review diff + branch protection.
- Source template ini belum terpasang di akun pengguna dan belum dites dengan koneksi GitHub/VPS/Telegram nyata.

## Static smoke check (tanpa koneksi cloud)

```bash
bash scripts/test-workflow.sh
```

Karena sistem kerja ini memakai npm dependency Express, untuk menjalankan tes HTTP sesungguhnya perlu `npm install --prefix app` di mesin dengan akses registry npm. Contoh:

```bash
npm install --prefix app --no-audit --no-fund
npm test --prefix app              # Expected to fail before agent fixes the bug
```

**Catatan reproducibility:** Paket tidak membawa `node_modules` atau secrets. Saat pertama menginstal dari internet, buat dan commit `app/package-lock.json` untuk lock dependency (lalu pindah `npm install` ke `npm ci` untuk deployment jangka panjang).

### Approval via Telegram

Contoh patch konfigurasi native approvals tersedia di
`config/openclaw.telegram-approvals.patch.example.json5`. **Jangan mengganti seluruh
`openclaw.json` dengan file patch ini**; gabungkan hanya bagian yang relevan.

Tes merge gate tanpa GitHub sungguhan:

```bash
bash scripts/test-merge-guard.sh
```
