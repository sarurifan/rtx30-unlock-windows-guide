# check_profile_compat.ps1 — 检查你的 PROFILE.BIN 能否用已发布的产物
# 用法: pwsh check_profile_compat.ps1 -ProfileBin "C:\RTX-UNLOCK\PROFILE.BIN"
param([Parameter(Mandatory=$true)][string]$ProfileBin)
$known = @{
  # 联想刃7000 + RTX 3080 20G (本仓库实测机, 2026-10)
  "8065C8A9D768BFB5B3BC548D02D65B67ADEFCD61CD14AC5BD1B62DF20F8BFF5C" = "联想刃7000 + 3080 20G (实测发布档案)"
}
if (-not (Test-Path $ProfileBin)) { Write-Host "找不到文件: $ProfileBin"; exit 1 }
$b = [System.IO.File]::ReadAllBytes((Resolve-Path $ProfileBin))
if ($b.Length -lt 32) { Write-Host "文件太短, 不是有效 PROFILE.BIN"; exit 1 }
$magic = [System.Text.Encoding]::ASCII.GetString($b[0..7])
Write-Host "魔数: $magic (期望 GUPROF17)"
$prom = ($b[($b.Length-32)..($b.Length-1)] | ForEach-Object { $_.ToString("X2") }) -join ""
Write-Host "PROM SHA256: $prom"
if ($known.ContainsKey($prom)) {
  Write-Host "✅ 匹配: $($known[$prom]) — 可以直接用对应档案产物"
} else {
  Write-Host "❌ 不匹配已知档案 — 需要自己跑探测生成档案 (见 README 流程)"
}
