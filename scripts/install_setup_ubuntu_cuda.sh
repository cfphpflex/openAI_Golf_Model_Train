#!/usr/bin/env bash
set -euo pipefail

# Ubuntu bootstrap for Parameter Golf:
# - installs Python + venv tooling
# - verifies CUDA/NVIDIA availability
# - optionally installs NVIDIA driver and CUDA toolkit
#
# Usage:
#   bash scripts/install_setup_ubuntu_cuda.sh
#
# Optional flags (env):
#   INSTALL_NVIDIA_DRIVER=1   # attempt ubuntu-drivers autoinstall if no nvidia-smi
#   INSTALL_CUDA_TOOLKIT=1    # install nvidia-cuda-toolkit from apt repos

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[setup][error] This script is intended for Ubuntu/Linux." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[setup][error] apt-get not found. This script expects Ubuntu/Debian." >&2
  exit 1
fi

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "[setup][error] Run as root or install sudo." >&2
    exit 1
  fi
fi

echo "[setup] Updating apt metadata..."
${SUDO} apt-get update

echo "[setup] Installing base packages (python3, pip, venv, build tools, ripgrep)..."
${SUDO} apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  build-essential \
  git \
  curl \
  ca-certificates \
  ripgrep

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "[setup] nvidia-smi detected:"
  nvidia-smi || true
else
  echo "[setup][warn] nvidia-smi not found."
  if [[ "${INSTALL_NVIDIA_DRIVER:-0}" == "1" ]]; then
    echo "[setup] Attempting NVIDIA driver install via ubuntu-drivers..."
    ${SUDO} apt-get install -y ubuntu-drivers-common
    ${SUDO} ubuntu-drivers autoinstall
    echo "[setup][warn] Driver installation completed. Reboot is typically required."
  else
    echo "[setup][hint] Set INSTALL_NVIDIA_DRIVER=1 to auto-install NVIDIA drivers."
  fi
fi

if [[ "${INSTALL_CUDA_TOOLKIT:-0}" == "1" ]]; then
  echo "[setup] Installing CUDA toolkit package (Ubuntu repo)..."
  ${SUDO} apt-get install -y nvidia-cuda-toolkit
else
  echo "[setup][hint] Skipping CUDA toolkit install. Set INSTALL_CUDA_TOOLKIT=1 to install."
fi

echo "[setup] Creating local venv (.venv) if missing..."
if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi

echo "[setup] Activating venv and installing Python dependencies..."
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo "[setup] Done."
echo "[setup] Next steps:"
echo "  1) source .venv/bin/activate"
echo "  2) python3 data/cached_challenge_fineweb.py --variant sp1024 --train-shards 10"
echo "  3) bash scripts/preflight_cuda_smoke.sh"
echo "  4) bash scripts/final_p5_run.sh"
