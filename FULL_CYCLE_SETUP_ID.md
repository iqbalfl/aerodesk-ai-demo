# Panduan Demo End-to-End: AI Coding Agent -> GitHub PR -> Telegram Approval -> GitHub Actions -> VPS

> Untuk sharing session **From AI Assistant to AI Teammate**. Dibuat untuk VPS Ubuntu 2 vCPU/4 GB, OpenClaw native, Express API demo di Docker, GitHub, Telegram, ChatGPT/Codex OAuth, Gemini embeddings, Cloudflare. Semua percakapan dengan agent menggunakan bahasa Indonesia.
>
> **Status:** Starter kit siap dijalankan, tetapi **belum** terhubung ke GitHub, VPS, Telegram, atau layanan milikmu. Konfigurasi harus dilakukan di akun sendiri. Jangan anggap deployment sudah berhasil sebelum semua pengujian live lulus.

## 1. Hasil akhir yang akan dilihat audience

```text
[Telegram / OpenClaw Control UI]
    |
    | "Tolong perbaiki Issue #N"
    v
[OpenClaw orchestrator / coding agent]
    | git checkout -b fix/N-pagination
    | perbaiki app/server.js
    | npm test --prefix app  (mulai dari RED menjadi GREEN)
    | git push origin fix/N-pagination
    | gh pr create --base main
    v
[GitHub Pull Request] --> [PR Validation: Test & Build]
    |
    | Bot mengirim link PR + commit SHA ke Telegram
    | Presenter membuka "Files changed" + CI dan melakukan review
    v
[Telegram exec approval: /approve atau tombol Approve]
    | script scripts/merge-approved-pr.sh <PR> <SHA>
    | validasi target main + fix/* + SHA + CI sukses
    v
[GitHub merge PR] --> [push main]
    v
[GitHub Actions: tests -> Docker build -> GHCR push]
    |
    | SSH via key + verified known_hosts
    v
[VPS: docker pull image:SHA -> compose up -> health check -> smoke test]
    |
    +--> rollback ke image sebelumnya bila deploy/health/regresi gagal
    v
[demo.example.com/api/customers?page=1&limit=3] -> data.length = 3
```

**Approval Telegram** di sini adalah persetujuan **eksekusi command merge pada OpenClaw**, bukan otomatis review formal GitHub. GitHub harus dikonfigurasi dengan branch/ruleset protection dan CI, sementara manusia tetap memeriksa diff. Untuk kontrol produksi yang lebih kuat, gunakan reviewer GitHub independen, bot identity terpisah, dan policy yang tidak bisa diubah oleh coding agent.

## 2. Repository demo dan starting state

1. Buat repo dedicated GitHub, idealnya **public hanya untuk kode/dataset fiktif**; contoh `OWNER/aerodesk-ai-demo`. Jangan gunakan repo kerja internal.
2. Push **seluruh isi folder kit ini** sebagai root repo, termasuk folder `.github/workflows` (jangan hanya meng-upload ZIP sebagai satu file).
3. Pastikan branch default `main` dan Issues diaktifkan.
4. Jangan melakukan "fix" pada `const effectiveLimit = 10;` di `app/server.js` sebelum live demo. Inilah bug yang akan diperbaiki agent.
5. Tes regression dalam `app/test/pagination.test.js` sengaja **gagal pada baseline**. CI deployment pertama di `main` juga dapat gagal sampai perbaikan melalui PR. Itu **disengaja**, bukan bug instalasi. Deployment awal dilakukan manual di VPS.
6. Buat GitHub Issue dari hasil investigasi (bisa dilakukan saat live demo). Gunakan issue tersebut sebagai task coding agent.

Jaga source dari perubahan tanpa sengaja. Review `git status` sebelum setiap langkah dan periksa PR tidak mengubah `.github/workflows`, `deploy/`, `.env`, atau credentials. Untuk demo jangan izinkan coding agent menyentuh workflow CI/CD.

## 3. VPS: demo versi bug masih ada (baseline)

Instal Docker Engine + Compose plugin, Git, Node.js versi yang didukung OpenClaw, dan `curl`. Buat user operator non-root untuk OpenClaw; jangan login sebagai root. OpenClaw tetap native **tanpa sandbox**, tetapi gunakan approval dan permission minimal.

```bash
# Setelah GitHub repo dibuat; boleh pakai SSH atau HTTPS
sudo mkdir -p /opt/aerodesk
sudo chown "$USER":"$USER" /opt/aerodesk
cd /opt/aerodesk
git clone https://github.com/OWNER/aerodesk-ai-demo.git .

docker compose up -d --build
curl http://127.0.0.1:3000/health
bash scripts/smoke-test.sh
```

`smoke-test.sh` **hanya untuk pre-fix**: ia mengharapkan API salah mengembalikan 10 data untuk `limit=3`. Setelah deployment baru, gunakan `scripts/check-fixed-live.sh`.

Set Cloudflare Tunnel `demo.example.com` -> `http://127.0.0.1:3000`. Domain OpenClaw Control UI dipisah di `ai.example.com` -> port loopback 18789 dan wajib Cloudflare Access. Jangan membuka port 3000/18789 publik. Rincian instalasi OpenClaw, ChatGPT/Codex OAuth, Gemini, dan Cloudflare ada di `VPS_SETUP_ID.md` paket ini.

## 4. GitHub Actions dan pemisahan permission

### A. Workflow bawaan

- `.github/workflows/pr-ci.yml`: setiap PR ke `main`, jalankan regression tests dan build Docker, **tanpa deploy**. Job bernama tepat `Test & Build` karena dipakai merge gate.
- `.github/workflows/deploy.yml`: setiap `push` ke `main`, test -> build image `ghcr.io/owner/repo:<commit-sha>` -> push ke GHCR -> SSH VPS -> jalankan `remote-deploy.sh`.
- `compose.prod.yaml`: memakai image dari GHCR, bukan `build: .` di VPS.
- `deploy/remote-deploy.sh`: memverifikasi image tag dengan commit SHA, melakukan pull/deploy, memeriksa `/health` dan pagination, serta mencoba rollback pada kegagalan.

### B. Repository rules (wajib)

Di **GitHub Repository Settings -> Rules/Rulesets** atau Branch protection untuk `main`:

- Require a pull request before merging.
- Require status checks to pass sebelum merge: **`Test & Build`** (bila rule status tersedia untuk jenis akun/repo).
- Block force push dan branch deletion.
- Pertimbangkan require approval by a second GitHub reviewer serta CODEOWNERS untuk `.github/workflows/**` jika ada akun kedua. Reviewer ini terpisah dari approval eksekusi Telegram.
- Jangan berikan bypass branch protection kepada credential agent. Jangan memakai `gh pr merge --admin`.

**Penting:** persyaratan GitHub tersedia berbeda menurut plan/visibility repo. Untuk GitHub Free, gunakan repo publik berisi data fiktif jika hendak memakai environment/protection yang sesuai. Cek tampilan Settings di akun sendiri.

### C. Settings untuk GitHub Action deploy

Buat **environment** bernama `production` di Settings -> Environments. Pada repo publik GitHub Free, environment tersedia. Karena demo sudah memakai approval Telegram untuk merge, kamu bisa tidak menambahkan reviewer environment; untuk kontrol ekstra, tambahkan reviewer juga (berarti ada **approval kedua** di GitHub Actions).

Tambahkan secrets environment **production** (bukan masukkan ke repo):

| Secret | Isi |
| --- | --- |
| `DEPLOY_HOST` | IP publik / hostname SSH VPS |
| `DEPLOY_USER` | User khusus SSH deploy, contoh `deploydemo` |
| `DEPLOY_SSH_KEY` | Private key ed25519 CI; **bukan** SSH key pribadi, dan tidak disimpan di OpenClaw |
| `DEPLOY_KNOWN_HOSTS` | Isi known_hosts yang **telah diverifikasi fingerprint-nya** dari VPS |

`GITHUB_TOKEN` bawaan GitHub Action dipakai untuk push image ke GHCR dengan permission `packages: write`. Tidak perlu menaruh PAT GitHub penulis ke Actions.

### D. Setup SSH deploy di VPS

Buat akun non-root khusus deploy (contoh `deploydemo`) dan beri izin Docker. **Peringatan:** anggota grup `docker` pada dasarnya memiliki kewenangan setingkat root. Gunakan VPS fiktif khusus demo dan simpan deploy key hanya di GitHub Actions.

```bash
sudo adduser deploydemo
sudo usermod -aG docker deploydemo
sudo mkdir -p /opt/aerodesk
sudo chown -R deploydemo:deploydemo /opt/aerodesk
```

Buat key pair baru **di laptop yang dipercaya**, simpan private key sebagai GitHub `DEPLOY_SSH_KEY` dan public key ke `/home/deploydemo/.ssh/authorized_keys`. Setelah itu login ke VPS sebagai `deploydemo` dan letakkan file:

```bash
cp compose.prod.yaml /opt/aerodesk/compose.prod.yaml
cp deploy/remote-deploy.sh /opt/aerodesk/remote-deploy.sh
chmod 700 /opt/aerodesk/remote-deploy.sh
printf 'IMAGE_REPOSITORY=ghcr.io/owner/aerodesk-ai-demo\n' > /opt/aerodesk/deploy.env
chmod 600 /opt/aerodesk/deploy.env
```

Perlu izin tulis ke `/opt/aerodesk` untuk user deploy. Untuk pertama kali, setelah `main` masih broken, tetap gunakan `docker compose up -d --build` (build lokal). Setelah fix merge, Actions otomatis beralih ke image GHCR melalui `compose.prod.yaml`.

Jika GHCR image bersifat privat, lakukan `docker login ghcr.io` **sekali** pada user `deploydemo` dengan kredensial **read:packages** yang minimum. Jika image public, authenticated pull mungkin tidak diperlukan. Jangan menaruh GHCR token pada source atau dokumentasi.

**Fingerprint known_hosts:** jalankan `ssh-keyscan` di workstation tepercaya, lalu cocokkan fingerprint hasil scan dengan `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` dari konsol VPS. Hanya simpan host key yang sudah cocok ke `DEPLOY_KNOWN_HOSTS`. Jangan pakai `StrictHostKeyChecking=no`.

> Workflow menggunakan satu image tag immutable SHA. VPS melakukan `docker pull` dan `docker compose up -d --no-build`. Jika ingin juga `git pull` source ke server, itu **tidak diperlukan** pada containerized deployment dan meningkatkan kebutuhan credential; image pull menggantikan git pull untuk deployment.

## 5. OpenClaw: coding agent dan GitHub CLI

Pasang `git`, GitHub CLI (`gh`), Node.js, lalu autentikasi GitHub CLI menggunakan fine-grained PAT khusus **satu repository** dengan Contents read/write, Issues read/write, Pull Requests read/write (dan metadata). Gunakan user Linux OpenClaw sendiri, **bukan user deploy SSH**.

Repo coding agent sebaiknya berada di direktori operasional yang tidak memuat credentials dan terpisah dari `/opt/aerodesk`:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/OWNER/aerodesk-ai-demo.git
cd aerodesk-ai-demo
npm install --prefix app --no-audit --no-fund
# Baseline regression sengaja gagal:
npm test --prefix app || true
```

**OpenClaw AGENTS.md** dalam `openclaw-workspace/AGENTS.md` diperluas agar agent bisa menganalisis issue, memperbaiki kode, melakukan git commit, push branch `fix/...`, dan mengirim link PR. Pastikan workspace AGENTS.md yang benar sudah diinstal/direload. Model harus punya tool host filesystem dan shell yang memang diizinkan; **prompt saja tidak memberikan tool akses**.

### Approval native Telegram (untuk command merge)

OpenClaw mendukung exec approval pada channel Telegram. Contoh potongan config yang harus digabungkan ke OpenClaw (sesuaikan versi saat instalasi):

```json5
{
  tools: { exec: { mode: 'ask' } },
  channels: { telegram: {
    execApprovals: { enabled: true, approvers: ['123456789'], target: 'dm' },
    capabilities: { inlineButtons: 'dm' }
  } }
}
```

- `123456789` diganti numeric Telegram user ID kamu.
- `channels.telegram.allowFrom` mengatur siapa yang dapat mengobrol; `execApprovals.approvers` secara terpisah mengatur siapa yang dapat menyetujui.
- Native exec approval mengharuskan command benar-benar melewati tool **exec** OpenClaw dengan policy `ask`; balasan chat seperti "ya" bukan mekanisme persetujuan yang setara.
- `tools.exec.mode='ask'` dapat meminta approval untuk banyak command (git, test, dan lainnya); demo ini sengaja mengutamakan keselamatan. Jika nanti ingin meminimalkan prompt, terapkan allowlist host yang diuji, bukan mode `full`.
- Jangan menaruh approval command dan token ke grup Telegram umum.

Jalankan `openclaw config validate --json`, restart Gateway, dan **uji approval native** di Telegram dengan satu command aman lebih dulu. Referensi: https://docs.openclaw.ai/tools/exec-approvals-advanced dan https://docs.openclaw.ai/channels/telegram/rich-messages.

### Script merge terkontrol

Set `DEMO_GITHUB_REPO=OWNER/aerodesk-ai-demo` di environment user yang menjalankan GitHub CLI (jangan ketik `OWNER` literal). Untuk permintaan merge, agent wajib menampilkan **PR URL, nomor, exact head SHA**, lalu menggunakan:

```bash
cd ~/projects/aerodesk-ai-demo
DEMO_GITHUB_REPO=OWNER/aerodesk-ai-demo ./scripts/merge-approved-pr.sh 12 0123456789abcdef0123456789abcdef01234567
```

Ganti nomor dan SHA dengan yang **dibaca dari PR sebenarnya**. Script menolak draft/cross-repo, target selain main, branch tanpa prefix `fix/`, SHA yang berubah, serta check `Test & Build` yang belum pass. Perintah `gh pr merge --match-head-commit` memastikan tidak merge commit berbeda dari yang disetujui. Eksekusi script inilah yang harus **memunculkan native approval Telegram**; jika tidak muncul, batalkan dan periksa konfigurasi - jangan menganggap pesan chat sebagai approval.

Script bukan batas keamanan mutlak jika agent punya token dan exec permission yang bisa melakukan merge dengan cara lain. Untuk production, gunakan identitas terpisah, protected branch dan review GitHub independen.

## 6. Opsi coding agent khusus (Codex via ACP) - tidak wajib

Jika ingin benar-benar mendemokan **agent yang berbeda sebagai coding worker**, OpenClaw saat ini mendukung ACP runtime resmi:

```bash
openclaw plugins install @openclaw/acpx
openclaw config set plugins.entries.acpx.enabled true
```

Siapkan harness Codex dan autentikasi Codex secara terpisah bila diminta, ikuti https://docs.openclaw.ai/tools/acp-agents/quickstart dan jalankan `/acp doctor`. Setelah backend valid, agent utama bisa mengirim tugas kepada Codex melalui `sessions_spawn` dengan `runtime: "acp", agentId: "codex"` atau perintah `/acp spawn codex --mode oneshot --thread off`. **Catatan:** ACP coding harness dapat menjalankan tools dengan permission policy tersendiri; approval OpenClaw exec belum tentu mengawasi setiap command internal ACP. Jangan berikan credential merge/deploy pada ACP worker dan pertahankan langkah merge pada orchestrator terpisah.

Jika ACP belum siap, demo tetap valid: OpenClaw agent utama bisa melakukan investigasi, edit kode, test, branch dan PR menggunakan tools host. Jangan mengatakan sedang menjalankan Codex ACP jika belum diuji.

## 7. Demo live (Bahasa Indonesia)

1. **Memory:** "Kenapa kita memilih PostgreSQL? Tolong tunjukkan ADR dan trade-off." Lihat sumber.
2. **Investigation:** "Cek pagination API customer di domain demo; bandingkan parameter limit 3 dengan data yang kembali. Cek kode GitHub yang relevan." Verifikasi bug memang ada.
3. **Ticket:** "Buat draft Issue untuk bug pagination itu lengkap dengan reproduction, expected/actual, acceptance criteria. Jangan publish dulu." Setelah diperiksa: "Sekarang buat Issue-nya di repo demo, lalu berikan link." Tidak boleh mengklaim created tanpa URL asli.
4. **Coding:** "Tolong kerjakan Issue #N. Buat branch fix/, perbaiki bug, jalankan test sampai lulus, commit dan push, lalu buka PR. Jangan merge." Lihat PR, diff, dan job `Test & Build` di GitHub.
5. **Approval:** "Tampilkan URL PR, SHA terakhir, hasil CI dan command merge terkontrol. Tunggu approval native Telegram." Presenter buka PR/diff dan approve prompt Telegram. Ini mengeksekusi script `merge-approved-pr.sh`, bukan menyetujui tanpa tinjauan.
6. **Deploy:** GitHub Actions pada `push main` menjalankan test, Docker build, GHCR push, SSH VPS, `docker pull`, `compose up`. Lihat log Actions untuk status aktual.
7. **Verify:** refresh `https://demo.example.com` dan `.../api/customers?page=1&limit=3`. Data harus 3, kemudian coba `page=2&limit=3`. Jalankan `scripts/check-fixed-live.sh`.

## 8. Troubleshooting dan rollback

| Gejala | Pemeriksaan | Tindakan |
| --- | --- | --- |
| CI merah saat initial main | Kode masih mengandung seeded pagination bug | Wajar sebelum PR fix; app baseline berjalan via Docker lokal |
| PR CI masih merah | Test pagination atau Docker build gagal | Agent revisi branch; jangan merge |
| Telegram approval tidak muncul | Approvers numeric ID, exec mode, inline buttons, owner & session | Uji `/approve`; jangan bypass dengan command langsung |
| GHCR pull gagal | Package visibility / `read:packages` user VPS | Siapkan login ghcr pada deploy user |
| SSH gagal | VPS firewall port 22, key, known_hosts, user | Periksa fingerprint, jangan matikan host verification |
| Deployed image tidak berubah | Lihat tag image SHA & `/health.revision` | Bandingkan commit deploy dengan response health |
| Health/regression gagal | `docker compose ps`, Actions logs | Script mencoba rollback ke previous image; cek kondisi manual |
| Cloudflare masih menampilkan halaman lama | Tunnel target dan cache | Pastikan target `127.0.0.1:3000` dan bypass caching API |

### Batasan yang perlu dijelaskan ke audience

- Script rollback adalah **best effort**, bukan zero-downtime deployment; app satu replica bisa sempat restart.
- Proses deploy memperbarui **Docker image**, bukan `git pull` source; image bersifat immutable sesuai commit SHA.
- Keberhasilan CI, approval, dan deploy **harus terlihat di GitHub/Telegram/VPS**, bukan disimpulkan dari respons agent.
- Semua account, cloud secret, GitHub PAT, bot token, dan SSH keys dibuat pemilik akun saat setup; tidak ada di ZIP.

## Rujukan resmi

- OpenClaw exec approvals: https://docs.openclaw.ai/tools/exec-approvals-advanced
- OpenClaw Telegram: https://docs.openclaw.ai/channels/telegram/rich-messages
- OpenClaw ACP agents: https://docs.openclaw.ai/tools/acp-agents/quickstart
- GitHub CLI merge: https://cli.github.com/manual/gh_pr_merge
- GitHub PR checks: https://cli.github.com/manual/gh_pr_checks
- GitHub Actions GHCR: https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images
- GitHub Deployment Environments: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments
