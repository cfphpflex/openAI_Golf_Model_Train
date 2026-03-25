#!/usr/bin/env bash
set -euo pipefail

# Final 8xH100 run preset for p5.48xlarge.
# Use after preflight passes to reduce failed expensive attempts.

RUN_ID="${RUN_ID:-p5_final_topstack}"
DATA_PATH="${DATA_PATH:-./data/datasets/fineweb10B_sp1024}"
TOKENIZER_PATH="${TOKENIZER_PATH:-./data/tokenizers/fineweb_1024_bpe.model}"
VOCAB_SIZE="${VOCAB_SIZE:-1024}"

echo "[final] RUN_ID=${RUN_ID}"
echo "[final] DATA_PATH=${DATA_PATH}"
echo "[final] TOKENIZER_PATH=${TOKENIZER_PATH}"
echo "[final] Starting 8-GPU run..."

if [[ ! -d "${DATA_PATH}" ]]; then
  echo "[final][error] DATA_PATH missing: ${DATA_PATH}" >&2
  exit 1
fi
if [[ ! -f "${TOKENIZER_PATH}" ]]; then
  echo "[final][error] TOKENIZER_PATH missing: ${TOKENIZER_PATH}" >&2
  exit 1
fi
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "[final][error] nvidia-smi not found (CUDA host required)." >&2
  exit 1
fi

# Record GPU snapshot for reproducibility.
nvidia-smi

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
WARMDOWN_ITERS="${WARMDOWN_ITERS:-3500}" \
TRAIN_SEQ_LEN="${TRAIN_SEQ_LEN:-2048}" \
TRAIN_BATCH_TOKENS="${TRAIN_BATCH_TOKENS:-786432}" \
VAL_BATCH_SIZE="${VAL_BATCH_SIZE:-524288}" \
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-0}" \
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-600}" \
torchrun --standalone --nproc_per_node=8 train_gpt.py

echo "[final] Completed. Parse logs/${RUN_ID}.txt:"
echo "        grep 'final_int8_zlib_roundtrip_exact' logs/${RUN_ID}.txt"
