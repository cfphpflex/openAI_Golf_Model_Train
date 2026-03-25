# Parameter Golf Records Submission Checklist

Use this checklist when preparing a new folder under `records/track_10min_16mb/` or `records/track_non_record_16mb/`.

## Folder Setup

- [ ] Create a new dated folder (for example: `YYYY-MM-DD_short_name`).
- [ ] Keep everything needed to reproduce the run inside this folder.
- [ ] Ensure the folder is additive-only for PRs (do not modify existing record folders unless intended).

## Required Files

- [ ] `README.md` with method summary, key hyperparameters, hardware, runtime, and reproducibility notes.
- [ ] `submission.json` with author metadata, primary score (`val_bpb`), and related run metadata.
- [ ] Training log(s) from the submitted configuration.
- [ ] Runnable `train_gpt.py` and any local dependencies used by that run.

## Reproducibility + Validity

- [ ] Script runs successfully from inside the record folder.
- [ ] Final metrics are logged, including `final_int8_zlib_roundtrip_exact`.
- [ ] Artifact size is reported and under 16,000,000 bytes (code + compressed model).
- [ ] No training on validation data or any prohibited evaluation leakage.
- [ ] If claiming SOTA, include enough runs/statistics to support significance.

## Practical QA Before PR

- [ ] At least one rerun confirms comparable result.
- [ ] Logs are readable and include seed, wallclock, and core env settings.
- [ ] README command example matches the exact submitted script behavior.
- [ ] Mention non-default dependencies/setup steps, if any.

## Optional Extras (Recommended)

- [ ] Multi-seed table with mean/std.
- [ ] Pre-quant vs post-quant metric comparison.
- [ ] Notes on known caveats/limitations.
