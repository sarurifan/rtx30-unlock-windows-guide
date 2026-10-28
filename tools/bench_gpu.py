# bench_gpu.py — GEMM 跑分脚本 (与视频实测同款)
# 用法: python bench_gpu.py
# 依赖: pip install torch --index-url https://download.pytorch.org/whl/cu126
import json, time, torch, platform
dev = "cuda"
torch.cuda.init()
n = 4096
name = torch.cuda.get_device_name(0)
total_gb = torch.cuda.get_device_properties(0).total_memory / 1024**3
def bench(dt):
    a = torch.randn(n, n, device=dev, dtype=dt)
    b = torch.randn(n, n, device=dev, dtype=dt)
    for _ in range(3): c = a @ b
    torch.cuda.synchronize()
    t0 = time.perf_counter()
    iters = 10
    for _ in range(iters): c = a @ b
    torch.cuda.synchronize()
    dt_ = time.perf_counter() - t0
    return 2 * n**3 * iters / dt_ / 1e12
res = {
  "info": {"name": name, "total_mem_GB": round(total_gb, 1), "cc": torch.cuda.get_device_capability(0),
           "torch": torch.__version__, "cuda": torch.version.cuda},
  "tests": {
    "fp16_gemm_4096": round(bench(torch.float16), 2),
    "bf16_gemm_4096": round(bench(torch.bfloat16), 2),
    "fp32_gemm_4096": round(bench(torch.float32), 2),
  },
}
print(json.dumps(res, indent=2))
print()
print("判定: 3080 10G 原版 FP16≈52-55 / 解锁≈106+; 显存翻倍(20G)为解锁标志")
