# verify_unlock.ps1 — 验证解锁是否生效 (nvidia-smi 显存翻倍)
$out = & nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
Write-Host "GPU: $out"
$mem = ($out -split ",")[1].Trim()
if ($mem -match "20480") { Write-Host "✅ 解锁生效: 显存 20480 MiB (20G)" }
elseif ($mem -match "10240") { Write-Host "❌ 锁定态: 显存 10240 MiB (10G) — 解锁器未跑" }
else { Write-Host "未知显存: $mem" }
