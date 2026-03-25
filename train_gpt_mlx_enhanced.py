#!/usr/bin/env python3
"""
Enhanced MLX launcher for Parameter Golf.

Purpose:
- Run `train_gpt_mlx.py` across multiple seeds.
- Track per-seed final metrics.
- Enforce "exceed requirements" gates:
  1) quality gate: val_bpb must beat baseline
  2) speed gate: wallclock must be under cap
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from dataclasses import asdict, dataclass
from pathlib import Path


FINAL_LINE_RE = re.compile(
    r"final_int8_zlib_roundtrip_exact val_loss:(?P<val_loss>[0-9.]+) val_bpb:(?P<val_bpb>[0-9.]+)"
)


@dataclass
class EnhancedConfig:
    run_id: str = os.environ.get("RUN_ID", "mlx_seed_sweep")
    iterations: int = int(os.environ.get("ITERATIONS", 400))
    train_batch_tokens: int = int(os.environ.get("TRAIN_BATCH_TOKENS", 16384))
    val_loss_every: int = int(os.environ.get("VAL_LOSS_EVERY", 0))
    val_batch_size: int = int(os.environ.get("VAL_BATCH_SIZE", 8192))
    seeds_csv: str = os.environ.get("SEEDS", "42,123,2025")
    data_path: str | None = os.environ.get("DATA_PATH")
    tokenizer_path: str | None = os.environ.get("TOKENIZER_PATH")
    vocab_size: int | None = int(os.environ["VOCAB_SIZE"]) if "VOCAB_SIZE" in os.environ else None
    train_seq_len: int | None = int(os.environ["TRAIN_SEQ_LEN"]) if "TRAIN_SEQ_LEN" in os.environ else None
    max_wallclock_seconds: float | None = float(os.environ["MAX_WALLCLOCK_SECONDS"]) if "MAX_WALLCLOCK_SECONDS" in os.environ else None
    warmup_steps: int | None = int(os.environ["WARMUP_STEPS"]) if "WARMUP_STEPS" in os.environ else None
    warmdown_iters: int | None = int(os.environ["WARMDOWN_ITERS"]) if "WARMDOWN_ITERS" in os.environ else None
    grad_accum_steps: int | None = int(os.environ["GRAD_ACCUM_STEPS"]) if "GRAD_ACCUM_STEPS" in os.environ else None
    train_log_every: int | None = int(os.environ["TRAIN_LOG_EVERY"]) if "TRAIN_LOG_EVERY" in os.environ else None
    mlx_max_microbatch_tokens: int | None = (
        int(os.environ["MLX_MAX_MICROBATCH_TOKENS"]) if "MLX_MAX_MICROBATCH_TOKENS" in os.environ else None
    )
    mlx_eager_eval: bool | None = bool(int(os.environ["MLX_EAGER_EVAL"])) if "MLX_EAGER_EVAL" in os.environ else None
    out_dir: str | None = os.environ.get("OUT_DIR")
    # Hardcoded baseline source selected by user; still overridable via env.
    baseline_val_bpb: float = float(os.environ.get("BASELINE_VAL_BPB", 1.2244))
    max_allowed_seconds: float = float(os.environ.get("MAX_ALLOWED_SECONDS", 600.0))
    fail_on_gate: bool = bool(int(os.environ.get("FAIL_ON_GATE", "1")))
    logs_dir: str = os.environ.get("ENHANCED_LOG_DIR", "logs")

    def seeds(self) -> list[int]:
        out: list[int] = []
        for token in self.seeds_csv.split(","):
            token = token.strip()
            if token:
                out.append(int(token))
        if not out:
            raise ValueError("SEEDS cannot be empty")
        return out


def parse_final_metrics(output: str) -> dict[str, float]:
    match = FINAL_LINE_RE.search(output)
    if not match:
        raise ValueError("Could not parse final metrics from output")
    return {
        "val_loss": float(match.group("val_loss")),
        "val_bpb": float(match.group("val_bpb")),
    }


def exceeds_requirements(val_bpb: float, wallclock_seconds: float, baseline_val_bpb: float, max_allowed_seconds: float) -> bool:
    return val_bpb < baseline_val_bpb and wallclock_seconds <= max_allowed_seconds


def run_one_seed(cfg: EnhancedConfig, seed: int) -> dict[str, float | int | bool]:
    env = os.environ.copy()
    seed_run_id = f"{cfg.run_id}_seed{seed}"
    updates: dict[str, str] = {
        "RUN_ID": seed_run_id,
        "SEED": str(seed),
        "ITERATIONS": str(cfg.iterations),
        "TRAIN_BATCH_TOKENS": str(cfg.train_batch_tokens),
        "VAL_LOSS_EVERY": str(cfg.val_loss_every),
        "VAL_BATCH_SIZE": str(cfg.val_batch_size),
    }
    optional_updates = {
        "DATA_PATH": cfg.data_path,
        "TOKENIZER_PATH": cfg.tokenizer_path,
        "VOCAB_SIZE": cfg.vocab_size,
        "TRAIN_SEQ_LEN": cfg.train_seq_len,
        "MAX_WALLCLOCK_SECONDS": cfg.max_wallclock_seconds,
        "WARMUP_STEPS": cfg.warmup_steps,
        "WARMDOWN_ITERS": cfg.warmdown_iters,
        "GRAD_ACCUM_STEPS": cfg.grad_accum_steps,
        "TRAIN_LOG_EVERY": cfg.train_log_every,
        "MLX_MAX_MICROBATCH_TOKENS": cfg.mlx_max_microbatch_tokens,
        "MLX_EAGER_EVAL": (1 if cfg.mlx_eager_eval else 0) if cfg.mlx_eager_eval is not None else None,
        "OUT_DIR": cfg.out_dir,
    }
    for key, value in optional_updates.items():
        if value is not None:
            updates[key] = str(value)
    env.update(updates)
    cmd = [sys.executable, "train_gpt_mlx.py"]
    start = time.perf_counter()
    proc = subprocess.run(cmd, env=env, capture_output=True, text=True)
    elapsed = time.perf_counter() - start
    if proc.returncode != 0:
        raise RuntimeError(
            f"Seed {seed} failed with exit code {proc.returncode}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
        )
    metrics = parse_final_metrics(proc.stdout + "\n" + proc.stderr)
    ok = exceeds_requirements(
        val_bpb=metrics["val_bpb"],
        wallclock_seconds=elapsed,
        baseline_val_bpb=cfg.baseline_val_bpb,
        max_allowed_seconds=cfg.max_allowed_seconds,
    )
    return {
        "seed": seed,
        "run_id": seed_run_id,
        "val_loss": metrics["val_loss"],
        "val_bpb": metrics["val_bpb"],
        "wallclock_seconds": elapsed,
        "meets_exceed_requirements": ok,
    }


def write_summary(cfg: EnhancedConfig, results: list[dict[str, float | int | bool]]) -> Path:
    logs_dir = Path(cfg.logs_dir)
    logs_dir.mkdir(parents=True, exist_ok=True)
    summary_path = logs_dir / f"{cfg.run_id}_enhanced_summary.json"
    best = min(results, key=lambda row: float(row["val_bpb"]))
    all_pass = all(bool(row["meets_exceed_requirements"]) for row in results)
    summary = {
        "config": asdict(cfg),
        "results": results,
        "best_seed": best,
        "all_seeds_meet_exceed_requirements": all_pass,
    }
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary_path


def main() -> None:
    cfg = EnhancedConfig()
    print(f"enhanced_run_id:{cfg.run_id}")
    print(f"seeds:{cfg.seeds()}")
    print(f"requirement_gate: val_bpb<{cfg.baseline_val_bpb} and wallclock<={cfg.max_allowed_seconds}s")
    print(f"fail_on_gate:{cfg.fail_on_gate}")
    results: list[dict[str, float | int | bool]] = []
    for seed in cfg.seeds():
        row = run_one_seed(cfg, seed)
        results.append(row)
        print(
            f"seed:{seed} val_loss:{row['val_loss']:.6f} val_bpb:{row['val_bpb']:.6f} "
            f"wallclock_seconds:{row['wallclock_seconds']:.2f} pass:{row['meets_exceed_requirements']}"
        )
    summary_path = write_summary(cfg, results)
    print(f"enhanced_summary:{summary_path}")

    if cfg.fail_on_gate and not all(bool(row["meets_exceed_requirements"]) for row in results):
        raise SystemExit(2)


if __name__ == "__main__":
    main()
