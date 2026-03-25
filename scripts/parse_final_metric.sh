#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/parse_final_metric.sh <run_id_or_log_path>
#
# Examples:
#   scripts/parse_final_metric.sh p5_final_topstack
#   scripts/parse_final_metric.sh logs/p5_final_topstack.txt

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run_id_or_log_path>" >&2
  exit 1
fi

arg="$1"
if [[ -f "$arg" ]]; then
  log_path="$arg"
else
  log_path="logs/${arg}.txt"
fi

if [[ ! -f "$log_path" ]]; then
  echo "[parse][error] log file not found: $log_path" >&2
  exit 1
fi

final_line="$(rg "final_int8_zlib_roundtrip_exact" "$log_path" | sed -n '$p')"
size_line="$(rg "Serialized model int8\\+zlib:|serialized_model_int8_zlib:" "$log_path" | sed -n '$p')"
total_line="$(rg "Total submission size int8\\+zlib:|Total submission size:" "$log_path" | sed -n '$p')"

if [[ -z "$final_line" ]]; then
  echo "[parse][error] final metric line not found in $log_path" >&2
  exit 1
fi

val_loss="$(printf '%s\n' "$final_line" | sed -nE 's/.*val_loss:([0-9.]+).*/\1/p')"
val_bpb="$(printf '%s\n' "$final_line" | sed -nE 's/.*val_bpb:([0-9.]+).*/\1/p')"

echo "log_path=$log_path"
echo "val_loss=$val_loss"
echo "val_bpb=$val_bpb"
if [[ -n "$size_line" ]]; then
  echo "artifact_line=$size_line"
fi
if [[ -n "$total_line" ]]; then
  echo "submission_size_line=$total_line"
fi
