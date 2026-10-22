# Quick Start - Full Cycle Demo

- [ ] Buat public repo fiktif `OWNER/aerodesk-ai-demo`; push isi project, termasuk `.github/workflows/`.
- [ ] Proteksi branch `main`: PR required, `Test & Build` required, nonaktifkan force push.
- [ ] Jalankan baseline buggy di VPS: `docker compose up -d --build`.
- [ ] Instal & uji OpenClaw native, ChatGPT/Codex OAuth, Gemini embeddings, Telegram allowlist, Cloudflare Access.
- [ ] Di OpenClaw user, clone repo ke `~/projects/aerodesk-ai-demo` dan autentikasi `gh` dengan token minimum satu repo.
- [ ] Pasang AGENTS.md versi full cycle lalu `tools.exec.mode=ask` dan Telegram `execApprovals.approvers`.
- [ ] Buat user VPS deploy khusus dengan akses Docker; setup SSH key dari GitHub Actions secrets (key terpisah).
- [ ] Simpan `compose.prod.yaml`, `remote-deploy.sh`, dan `/opt/aerodesk/deploy.env` pada VPS.
- [ ] Siapkan environment `production` serta SSH secrets `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`.
- [ ] Jika GHCR image private, `docker login ghcr.io` di account deploy VPS.
- [ ] Uji investigasi, Issue, code fix, PR CI, approval native Telegram, merged main, Action deploy, dan endpoint fixed.
- [ ] Lakukan reset seed bug untuk latihan ulang dengan PR baru **tanpa force push main**; gunakan repo/branch demo yang aman.

**Jangan memberi deploy SSH key ke OpenClaw**, dan jangan menafsirkan balasan chat sebagai bukti GitHub merged / VPS updated.
