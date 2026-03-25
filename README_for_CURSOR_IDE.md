# =========================
# Parameter Golf server bootstrap (copy/paste)
# Run first section on your MAC, second on SERVER.
# =========================

# ---------- [MAC] set these ----------

MY_DO_NOT_CHANGE_THIS_SSH_KEY=~/.ssh/thinkonomy3.pem
LOCAL_REPO="/Users/amilvila/PycharmProjects/parameter-golf"
SERVER_USER="ubuntu"
SERVER_HOST="emilio.tnktrade.ai"
SERVER_IP="204.236.165.199"
REMOTE_DIR="/home/${SERVER_USER}"


sudo scp -i "$MY_DO_NOT_CHANGE_THIS_SSH_KEY" -r "${LOCAL_REPO}" "${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}"

# OpenAI Golf-replace ip
sudo scp -i  ~/.ssh/thinkonomy3.pem  -r  /Users/amilvila/PycharmProjects/parameter-golf  ubuntu@204.236.165.199:/home/ubuntu

# NOT NEED; no more rsync chnages repeat syncs (faster):
# rsync -avz -e "ssh -i $MY_DO_NOT_CHANGE_THIS_SSH_KEY" --delete "${LOCAL_REPO}/" "${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/parameter-golf/"

# ssh in (same as: sudo ssh -i ~/.ssh/thinkonomy3.pem ubuntu@emilio.tnktrade.ai — only literals swapped for vars):
sudo ssh -i "$MY_DO_NOT_CHANGE_THIS_SSH_KEY" "${SERVER_USER}@${SERVER_HOST}"
#  sudo ssh -i ~/.ssh/thinkonomy3.pem ubuntu@emilio.tnktrade.ai


### SERVER INSTALL and CONFIG #######

# ---------- [SERVER] run on Ubuntu ----------
set -euo pipefail
cd /home/ubuntu/parameter-golf

# 1) Check GPU / driver location
command -v nvidia-smi || true
which nvidia-smi || true
nvidia-smi || true

# 2) Setup Python + deps + (optional driver/toolkit hooks)
bash scripts/install_setup_ubuntu_cuda.sh
# If nvidia-smi was missing, you can retry with:
# INSTALL_NVIDIA_DRIVER=1 bash scripts/install_setup_ubuntu_cuda.sh
# INSTALL_CUDA_TOOLKIT=1 bash scripts/install_setup_ubuntu_cuda.sh

# 3) Activate venv
source .venv/bin/activate

# 4) Sanity-check CUDA from Python
python3 -c "import torch; print('cuda?', torch.cuda.is_available(), 'gpus=', torch.cuda.device_count())"

# 5) Download data/tokenizer (use larger shards after smoke)
python3 data/cached_challenge_fineweb.py --variant sp1024 --train-shards 10

# 6) Cheap CUDA preflight (must pass before expensive run)
bash scripts/preflight_cuda_smoke.sh

# 7) Final run (8 GPUs on p5/p5en)
RUN_ID="p5_final_topstack_$(date +%Y%m%d_%H%M%S)"
export RUN_ID
bash scripts/final_p5_run.sh

# 8) Parse final metric (RUN_ID must be set in this shell — not only on the bash one-liner above)
bash scripts/parse_final_metric.sh "${RUN_ID}"

# If you lost RUN_ID, parse by path:
# bash scripts/parse_final_metric.sh "$(ls -t logs/*.txt | head -1)"



##### NOT NEED#######

# Use this guide to run a gstack-style agent workflow in any project using only Cursor built-in agents.

## 1) Prerequisite

# NOT REQUIRED: Install Bun if not installed:

```bash
brew install oven-sh/bun/bun
```

## 2) Copy starter files into your target project

run in repo project root folder:

```bash
cp "/Users/amilvila/PycharmProjects/gstack/cursor-rules-starter/"*.mdc .cursor/rules/
cp "/Users/amilvila/PycharmProjects/gstack/cursor-rules-starter/WORKFLOW.md" .
```

## 3) Start each feature with this prompt

In Cursor agent chat, paste:

```text
Follow WORKFLOW.md strictly for this task.

python3 -m py_compile train_gpt_mlx_enhanced.py

python3 train_gpt_mlx.py

python3 train_gpt_mlx_enhanced.py

```
bash scripts/install_setup_ubuntu_cuda.sh

scripts/preflight_cuda_smoke.sh
scripts/final_p5_run.sh

scripts/parse_final_metric.sh

scripts/parse_final_metric.sh p5_final_topstack
scripts/parse_final_metric.sh logs/p5_final_topstack.txt


Then provide project commands: 
FOR your feature, enhancement clear and precise specs.
Example: new feature green button display modal "hello" when clicked on landing page top right!

```text
Build command: <your build command>
Test command: <your test command>
QA/E2E command: <optional command>
```

## 4) Command examples by stack

### Bun + TypeScript

- Build command: `bun run build`
- Test command: `bun test`
- QA/E2E command: `bun run test:e2e`

### Node (npm)

- Build command: `npm run build`
- Test command: `npm test`
- QA/E2E command: `npm run test:e2e`

### Node (pnpm monorepo)

- Build command: `pnpm -r build`
- Test command: `pnpm -r test`
- QA/E2E command: `pnpm --filter web test:e2e`

### Python (pytest)

- Build command: `python -m pip install -r requirements.txt`
- Test command: `pytest -q`
- QA/E2E command: `pytest tests/e2e -q`

### Next.js

- Build command: `npm run build`
- Test command: `npm run test`
- QA/E2E command: `npm run test:e2e`

### No E2E yet

- Build command: `npm run build`
- Test command: `npm test`
- QA/E2E command: `none yet (run manual QA checklist)`