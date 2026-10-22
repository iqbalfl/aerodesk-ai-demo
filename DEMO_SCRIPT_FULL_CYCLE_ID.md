# Script presenter - AI Second Brain: dari Bug hingga Deploy

> Narasi singkat, prompt Telegram bahasa Indonesia, bukti yang perlu ditunjukkan. Siapkan sekitar 18-25 menit untuk versi penuh, tergantung waktu agent/CI.

## Opening demo
"Barusan kita melihat bagaimana AI bisa menemukan konteks dan memeriksa aplikasi. Sekarang saya ingin tunjukkan apakah AI bisa menindaklanjuti pekerjaan itu sampai perbaikannya benar-benar terpasang di server. Saya sengaja menyisipkan bug kecil pada pagination agar hasilnya mudah diverifikasi."

## Tahap 1 - Memory dan investigasi (2-3 menit)

Prompt Telegram:
"Kenapa kita memilih PostgreSQL pada rencana arsitektur? Tunjukkan ADR-nya. Setelah itu cek endpoint customer pagination: `GET /api/customers?page=1&limit=3`. Apakah hasilnya sesuai? Buktikan dari API dan source code, jangan menebak."

Tunjukkan ADR dan `https://demo.example.com/api/customers?page=1&limit=3` yang masih mengembalikan 10 record.

## Tahap 2 - Ticket (1-2 menit)

Prompt:
"Buat draft GitHub Issue untuk bug ini, dengan reproduction steps, expected versus actual, evidence, dan acceptance criteria. Jangan publish sebelum saya setujui."

Setelah ditinjau: "Oke, buat Issue itu di GitHub repo demo dan berikan link aslinya."

## Tahap 3 - Coding agent mengerjakan ticket (4-8 menit)

Prompt:
"Tolong implementasikan perbaikan untuk Issue #N di repo demo. Gunakan branch `fix/N-pagination`, ubah kode seperlunya, jalankan regression test hingga lulus, commit dan push, lalu buat PR menuju main. Jangan mengubah workflow CI/CD dan jangan merge dulu. Kirim link PR dan SHA terakhirnya."

Bukti: branch baru, file `app/server.js` berubah, test hijau di PR, PR punya referensi "Fixes #N".

## Tahap 4 - Telegram approval (1-3 menit)

Prompt:
"Tunjukkan ringkasan perubahan PR #P, SHA commit, status `Test & Build`, dan URL PR. Saya akan review dulu. Jika aman, minta approval native Telegram untuk menjalankan script merge terkontrol, jangan merge lewat jalur lain."

Presenter buka `Files changed` + CI. Setelah itu berikan approval **pada prompt native Telegram yang memuat command merge dengan SHA**. Jangan memberikan approval hanya dengan chat "ya, deploy".

Bukti: PR berubah menjadi merged. Jika approval tidak muncul, hentikan langkah merge dan tampilkan PR sebagai hasil kerja agent.

## Tahap 5 - GitHub Actions -> SSH VPS -> Verify (3-5 menit)

Buka tab GitHub Actions `Build and Deploy Demo` dan lihat job `Test and Publish Image` serta `Deploy VPS over SSH`. Proses dapat memerlukan waktu berbeda; jangan mengumumkan sukses sebelum selesai.

Tunjukkan URL aplikasi dan hasil API sekarang mengembalikan hanya tiga record (page 1), IDs 4-6 untuk page 2. Jika memungkinkan lihat `/health.revision` untuk mencocokkan commit.

Narasi penutup:
"Di titik ini AI bukan hanya memberi saran. Dia membaca konteks, menemukan bug, membuat pekerjaan, mengubah source code, dan membuka PR. Tapi ada garis yang tetap kita pegang: test dan approval manusia. Deployment dilakukan oleh pipeline yang bisa diaudit, bukan agent bebas menjalankan SSH ke production."

## Fallback jujur

- Coding agent terhenti: tampilkan branch, test logs, atau PR draft yang berhasil dibuat; jangan mengklaim PR created.
- Approval Telegram gagal: tampilkan status pending dan jelaskan batasan; **jangan** diam-diam merge manual.
- Deploy belum sukses: tunjukkan Actions run dan bug masih pada versi lama; jangan mengarang hasil. Gunakan video rekaman latihan jika tersedia dan jelaskan itu rekaman.
