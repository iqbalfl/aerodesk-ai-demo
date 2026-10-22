> LEGACY: Panduan 3 babak versi lama. Untuk demo coding + PR + approval Telegram + deploy, gunakan `FULL_CYCLE_SETUP_ID.md` dan `DEMO_SCRIPT_FULL_CYCLE_ID.md`.

# Script Live Demo - Presenter (Bahasa Indonesia)

Tujuan: menunjukkan AI Second Brain **mengambil konteks**, **memverifikasi sistem nyata**, dan **menindaklanjuti setelah persetujuan**. Presentasi Google Slides tetap berbahasa Inggris, komunikasi ke OpenClaw berbahasa Indonesia.

## Opening singkat sebelum demo

> Sekarang saya tidak akan minta AI sekadar membuat fungsi. Kita akan lihat apakah AI ini benar-benar bisa menjawab dengan konteks project, mengecek implementasi yang sedang berjalan, lalu membantu membuat tiket yang bisa ditindaklanjuti.

## Act 1 - Recover a decision (sekitar 3 menit)

**Di Telegram / Control UI:**

```text
Kita punya project AeroDesk. Tolong cari keputusan arsitektur tentang database. Kenapa tim memilih PostgreSQL, alternatif apa yang dipertimbangkan, dan apa trade-off-nya? Sebutkan nama dokumen sumbernya. Kalau belum ada bukti, bilang belum ditemukan.
```

**Apa yang ditampilkan:** hasil memory yang merujuk `ADR-007`, buka `openclaw-workspace/memory/ADR-007-postgresql.md`, cocokkan alasan dan trade-off. Tekankan bahwa DB masih *planned* dalam ADR, bukan backend sungguhan.

**Prompt tambahan untuk semantic similarity:**

```text
Kalau kebutuhan utama kita adalah reporting dan banyak relasi data, apa pertimbangan di balik pilihan SQL dibanding NoSQL menurut catatan project?
```

Jelaskan jawaban semantik tetap harus diverifikasi ke sumber.

## Act 2 - Investigate the running API (sekitar 4 menit)

**Buka tab:** `https://demo.example.com` → lihat "Requested 3 / Actual 10".

**Di Telegram / Control UI:**

```text
Tolong cek API customer project AeroDesk di https://demo.example.com/api/customers?page=1&limit=3. Bandingkan parameter limit dengan jumlah data yang dikembalikan. Kalau ada masalah, cek source code repo demo di app/server.js dan jelaskan akar masalahnya. Bedakan hasil yang benar-benar kamu verifikasi dengan asumsi.
```

**Bukti yang harus ada:** response `meta.limit=3`, jumlah `data` 10, dan implementasi `const effectiveLimit = 10` dalam `app/server.js`. Jika agent tidak bisa membuka API atau repo, jangan biarkan ia berpura-pura telah mengecek; tampilkan bukti manual.

**Pertanyaan untuk QA (opsional):**

```text
Berdasarkan bug itu dan dokumen QA-012, buat 5 test scenario yang paling penting agar regresinya tidak terulang.
```

## Act 3 - Draft -> Review -> Create GitHub Issue (sekitar 4 menit)

**Tahap draft saja:**

```text
Berdasarkan bug pagination yang tadi ditemukan, siapkan draft GitHub Issue untuk repository YOUR_GITHUB_USERNAME/aerodesk-ai-demo. Sertakan judul, actual dan expected result, langkah reproduksi, lokasi kode, dan acceptance criteria. JANGAN publish sebelum saya menyetujui draft.
```

**Review bersama audience:** cek apakah judul spesifik, langkah reproduksi nyata, expected/actual akurat, acceptance criteria bermanfaat, repo tujuan benar.

**Tahap create setelah izin benar-benar diberikan:**

```text
Saya sudah review dan setuju dengan draft issue yang kamu tampilkan. Silakan buat sekarang di repository demo YOUR_GITHUB_USERNAME/aerodesk-ai-demo saja. Setelah berhasil, berikan URL issue GitHub yang benar-benar dibuat.
```

Jika host command meminta approval kedua, selesaikan di Control UI hanya setelah membaca command yang akan dijalankan. Bila koneksi/approval gagal, berhenti di draft, lalu tunjukkan GitHub Issues manual tanpa mengklaim agent sudah membuat tiket.

## Closing sesudah demo

> Dari sini kita bisa lihat, nilai tambah AI bukan hanya menjawab satu pertanyaan. Nilainya ketika AI bisa mengambil konteks, membandingkan dengan kondisi nyata, kemudian menyiapkan langkah yang dapat ditinjau dan dikerjakan tim.

## Preflight khusus live demo

- [ ] Script `scripts/smoke-test.sh` PASS.
- [ ] Kedua pertanyaan semantic menemukan ADR-007 dan menyebut sumber.
- [ ] Domain API dapat dibuka dari jaringan audience.
- [ ] Telegram hanya boleh diakses akun sendiri.
- [ ] GitHub repo dapat dibaca dan issue write hanya ke repo demo.
- [ ] Ada fallback: browser app, file ADR, repository tab dan draft issue.

## Contoh draft GitHub Issue yang diharapkan

```markdown
Title: Fix customer API ignoring requested pagination limit

### Problem
GET /api/customers?page=1&limit=3 returns 10 records while meta.limit is 3.

### Steps to reproduce
1. Start AeroDesk demo API.
2. GET /api/customers?page=1&limit=3.
3. Compare data length and meta.limit.

### Expected
3 records; meta.limit=3. Subsequent pages respect limit.

### Actual
10 records; meta.limit=3.

### Evidence
app/server.js uses a fixed effectiveLimit=10 even though requestedLimit is parsed.

### Acceptance criteria
- Respect limit for pages 1 and 2.
- Make meta.limit consistent with effective limit.
- Cover test limits 1, 3, 10, 100, and invalid values.
```
