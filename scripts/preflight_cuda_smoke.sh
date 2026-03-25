#!/usr/bin/env bash
set -euo pipefail

# Cheap preflight for CUDA path before expensive full runs.
# Runs a short single-GPU smoke to catch path/config/runtime issues.

RUN_ID="${RUN_ID:-preflight_cuda_smoke}"
DATA_PATH="${DATA_PATH:-./data/datasets/fineweb10B_sp1024}"
TOKENIZER_PATH="${TOKENIZER_PATH:-./data/tokenizers/fineweb_1024_bpe.model}"
VOCAB_SIZE="${VOCAB_SIZE:-1024}"

echo "[preflight] RUN_ID=${RUN_ID}"
echo "[preflight] DATA_PATH=${DATA_PATH}"
echo "[preflight] TOKENIZER_PATH=${TOKENIZER_PATH}"

if [[ ! -d "${DATA_PATH}" ]]; then
  echo "[preflight][error] DATA_PATH missing: ${DATA_PATH}" >&2
  exit 1
fi
if [[ ! -f "${TOKENIZER_PATH}" ]]; then
  echo "[preflight][error] TOKENIZER_PATH missing: ${TOKENIZER_PATH}" >&2
  exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[preflight][error] nvidia-smi not found (CUDA host required)." >&2
  exit 1
fi
nvidia-smi >/dev/null

# Keep this run short and cheap; validation only at end.
RUN_ID="${RUN_ID}" \
DATA_PATH="${DATA_PATH}" \
TOKENIZER_PATH="${TOKENIZER_PATH}" \
VOCAB_SIZE="${VOCAB_SIZE}" \
NUM_LAYERS="${NUM_LAYERS:-11}" \
XSA_LAST_N="${XSA_LAST_N:-4}" \
ROPE_DIMS="${ROPE_DIMS:-16}" \
LN_SCALE="${LN_SCALE:-1}" \
EMA_ENABLED="${EMA_ENABLED:-1}" \
EMA_DECAY="${EMA_DECAY:-0.997}" \
EVAL_STRIDE="${EVAL_STRIDE:-64}" \
GPTQ_LITE="${GPTQ_LITE:-1}" \
WARMDOWN_ITERS="${WARMDOWN_ITERS:-120}" \
TRAIN_SEQ_LEN="${TRAIN_SEQ_LEN:-1024}" \
TRAIN_BATCH_TOKENS="${TRAIN_BATCH_TOKENS:-65536}" \
VAL_BATCH_SIZE="${VAL_BATCH_SIZE:-65536}" \
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-0}" \
ITERATIONS="${ITERATIONS:-50}" \
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-120}" \
torchrun --standalone --nproc_per_node=1 train_gpt.py

echo "[preflight] Completed. Check logs/${RUN_ID}.txt for final_int8_zlib_roundtrip_exact."
