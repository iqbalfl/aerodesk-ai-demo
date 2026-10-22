# Opsional - Dedikasi Codex Coding Worker melalui OpenClaw ACP

Demo default menggunakan OpenClaw agent yang diberi tool host terbatas untuk edit code + GitHub. Untuk menunjukkan satu agent orchestration dan satu *coding worker* terpisah, OpenClaw mendukung ACP runtime (`@openclaw/acpx`).

1. `openclaw plugins install @openclaw/acpx`
2. `openclaw config set plugins.entries.acpx.enabled true`
3. Siapkan Codex harness serta akun/auth yang dipersyaratkan **oleh harness**. OAuth model OpenClaw tidak boleh diasumsikan otomatis memberi login harness Codex.
4. Jalankan `/acp doctor`; jika gagal, jangan lanjut ke demo ACP.
5. Dari Control UI / Telegram, delegasikan perbaikan Issue #N kepada coding worker. Untuk dukungan sesi, lihat `sessions_spawn({runtime:"acp",agentId:"codex",task:"..."})` atau `/acp spawn codex --mode oneshot --thread off`.
6. Pastikan worker coding **hanya** boleh menulis branch/PR. Jangan memberi SSH deploy key, token bot approval, atau akses merge/deploy langsung. Persetujuan merge tetap melalui OpenClaw Gateway channel Telegram dan script merge yang bisa diaudit.

Referensi: https://docs.openclaw.ai/tools/acp-agents/quickstart

**Batasan:** ACP punya permission profile dan perilaku execution sendiri; approval native OpenClaw `tools.exec` tidak otomatis membatasi setiap command ACP. Set permission mode dengan sadar dan gunakan VPS demo dedicated.
