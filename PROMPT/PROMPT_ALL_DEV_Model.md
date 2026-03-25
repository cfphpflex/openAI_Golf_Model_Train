# ALL_DEV_Model — Single prompt to build the full system (model → API → dashboard)

Follow WORKFLOW.md strictly for this task.

ABSOLUTELY STOP the Pleasantries and sentiment analysis
Absolutley no sentiment analysis and/or attempting to relate or empathize
Sentiment, Pleasantries wastes my time (don't), quit associating and reflecting with commentary; 
DO NOT COMMENT OR SAY OR WRITE OR RESPONSE UNLESS I ASK YOU!!!!
AND EVEN THEN, 100% ONLY BE BRIEF AND ONLY ANSWER WITH 80% RELIABLE, ACCURATE, KNOWN and proven  OR BETTER ANSWERS .
NO unproven, no guesswork, only high probability accuracy & reliability answers with  correlation and variability measurements:  r & r squared
Absolutely required, when experimenting or exploring or researching, put all your files that you are creating to generate an answer, inside a TESTS folder,
because tha is your protype and proof of concept and not yer approved for the project until I give my review and blessing.  clearly understood?



stop snooping around, all data is in the project, all data is private, proprietary and owned by me, not you, do not ever look outside the project
Do complete project analysis and evaluation for understanding context and status and architecture in the tech stack written in
Before every task complete project analysis and evaluation and progression of tasks completed
specifically fully understand architecture 

put all md analysis files in the MD folder
put all Tests in the TESTS folder
   

sw2

Based on our previous discussion, I’m implementing [component].
Here’s my planned approach:
[Your brief explanation]

Before I code:
What edge cases am I missing? Where might this break at scale?

⸻

sw3 — Pre-coding spec
	•	What I’m building: [feature/component]
	•	User story & acceptance criteria: [bullets]
	•	Interfaces & data contracts: [endpoints/types]
	•	Test plan: [unit/integration/E2E]
	•	Rollout & rollback: [steps/metrics]
	•	Risks & mitigations: [bullets]

⸻

sw4

Review this implementation:
[Your code]

Focus on:
	1.	Performance optimizations
	2.	Security vulnerabilities
	3.	Design pattern improvements
	4.	Error handling gaps

⸻

sw5

You are a [framework/language] expert. I need to implement [feature].
Walk me through:
	1.	The relevant API methods/classes
	2.	Common pitfalls and how to avoid them
	3.	Performance optimization techniques
	4.	Code examples for each key concept

⸻

swfix

Approach this problem using the IDEAL problem-solving framework:
	1.	Identify the problem precisely: [DESCRIBE SPECIFIC ISSUE]
	2.	Define the constraints and requirements: [LIST ALL TECHNICAL CONSTRAINTS]
	3.	Explore potential strategies: Generate at least three different approaches
	4.	Act on the best strategy: Implement the solution with clean, documented code
	5.	Look back and learn: Evaluate the solution’s efficiency, edge cases, and potential improvements

Problem to solve: [YOUR SPECIFIC DEVELOPMENT CHALLENGE]



Role:
Act as a senior software architect, ML engineer, and backend/frontend developer. Build a production‑ready pet retail demand forecasting system end‑to‑end: data prep, model training (positive‑only), artifact packaging, Flask API, and Streamlit dashboard. Deliver a fully tested, functional, stable system that runs locally on macOS using Python 3.9+.

Structure:
1. System requirements and constraints
2. Core architectural decisions
3. Data models and relationships
4. API contract design
5. Security considerations

Additional Instructions:
• Challenge assumptions; propose better options when relevant.
• Use pragmatic defaults; prefer robustness and clarity over novelty.

---

sw3 — Pre-coding spec
• What I’m building: An end‑to‑end forecasting platform that trains a positive‑only XGBoost regressor with conformal intervals, serves predictions via a Flask API, and presents results in a Streamlit dashboard with operational ordering logic (ROP and suggested order). 
• User story & acceptance criteria:
  - As an operator, I can train a model filtering out negative/zero quantities and save artifacts in `src/models/`.
  - As an API client, I can POST minimal `item` (category) or rich payload and receive consistent JSON: forecast, price recommendation, confidence, interval, ROP, suggested_order, action.
  - As a dashboard user, I see Suggested Order, Recommended Price, and Confidence on the top row; Forecast and ROP on the second row. I can optionally enter price, cost, stock, YTD, lead time (days), cycle stock, service level. Defaults applied if omitted.
  - System is stable: models load at startup; ports are auto‑freed; logs are emitted; end‑to‑end parity between CLI weekly script, API, and dashboard.
• Interfaces & data contracts:
  - Model artifacts: `xgboost_positive_model.joblib`, `xgboost_positive_scaler.joblib`, `xgboost_positive_model_info.json` with keys: `feature_names`, `model_performance.r2`, `conformal_intervals.q80/q90`.
  - API endpoint `POST /inventory/update` accepts JSON with optional fields `{inventory_id, item, product_name, dept, category, price, cost, quantity_on_hand, ytd_sold, lead_time_days, cycle_stock, service_level}`. Returns JSON `{status, message, inventory_id, predicted_quantity, predicted_price, confidence_score, recommendation, current_price, current_quantity, service_level, lead_time_days, interval_lower, interval_upper, rop, cycle_stock, suggested_order, action}`.
• Test plan:
  - Unit: feature engineering numeric conversions; conformal quantile compute; ROP and suggested_order function.
  - Integration: model save/load; API load artifacts; endpoint parity with CLI outputs; dashboard renders metrics without NoneType errors.
  - E2E: train → serve → dashboard; verify Suggested Order equals CLI for same inputs.
• Rollout & rollback: gated by health check `/health`; keep legacy artifacts fallback; log to `real_time_integration.log`; revert by setting `MODEL_DIR` to previous models.
• Risks & mitigations: large data (use sampling); feature mismatch (store `feature_names` and project inputs); port conflicts (auto‑free 5001); environment pinning (requirements compatible with Python 3.9: xgboost≈1.7.x).

---

System requirements and constraints
- OS: macOS (Darwin 23.x), Python 3.9 (venv at `.venv`).
- Data CSVs in `src/data/` or `data/`; resolve with `DATA_DIR` env, else fallbacks.
- Model artifacts live in `src/models/` (or `MODEL_DIR`).
- No negative or zero quantities in training set.
- Conformal intervals (q80/q90) saved in model info.
- API on port 5001 with CORS enabled and auto‑free when busy.
- Dashboard on 8501. Only item required; all other fields optional with defaults.

Core architectural decisions
- Tabular ML with XGBoost regressor (positive‑only target) + StandardScaler for numeric features.
- Time‑aware feature set (year, month, day_of_week, weekend, holiday_season) + inventory/price ratios.
- Feature selection pipeline: mutual information (broad set), LassoCV stability, permutation/booster importance; force‑include core time/inventory features.
- Conformal residual quantiles on validation for 80% and 90% intervals.
- API returns both point forecast and operational ordering outputs in one call to align dashboard and CLI.

Data models and relationships
- Inputs: `history_invoice_header.csv`, `history_invoice_detail.csv`, `inventory.csv` merged on keys (handle duplicate columns like COST_x/COST_y; cast numerics robustly with `errors='coerce'`).
- Derived columns: `PROFIT`, `price_cost_ratio`, `price_msrp_ratio`, `cost_wac_ratio`, `stockout_risk`, `inventory_turnover`.
- Categoricals: `DEPT, CATEGORY, TYPE, CLERK` lowercased and one‑hot; persist `feature_names`.

API contract design
- `GET /health` → `{status, timestamp, system_running}`.
- `POST /inventory/update` → immediate prediction + price suggestion + weekly ordering logic:
  - `e = q80 if service_level==80 else q90` (defaults 90).
  - `lead_time_weeks = lead_time_days / 7`.
  - `rop = forecast * lead_time_weeks + e`.
  - `suggested_order = max(0, rop - stock + cycle_stock)`.
  - `action = "Order N units" if suggested_order>0 else "Do not order"`.
  - Logs the serialized API model response.

Security considerations
- CORS limited to local; avoid secrets; validate JSON; clamp negative outputs to 0.

Implementation details
1) Training script
- Filter `QUANTITY > 0` strictly for training; drop or coerce bad numerics.
- Wide feature search then compact stable set (20–40 features) using MI/Lasso/importance.
- Save artifacts to `src/models/` and write `model_info` JSON with `feature_names`, `r2`, `q80`, `q90`.

2) CLI weekly forecaster (parity reference)
- Accepts `--item/--category`, `--price`, `--cost`, `--stock`, `--ytd`, `--lead-time-days`, `--cycle-stock`, `--service-level`.
- Loads artifacts from `MODEL_DIR` or `src/models/`.
- Prints forecast, interval, ROP, suggested order, action.

3) Flask API backend
- On init, resolve `MODEL_DIR` (default `models` when cwd is `src/`), load positive artifacts; fallback to legacy names; log paths loaded.
- Prepare features, project to `feature_names`, scale, predict.
- Compute interval, ROP, suggested_order, action and return JSON.
- Auto‑free port 5001 via `lsof` and SIGTERM/SIGKILL if `AUTO_FREE_PORT=1`.
- Log to `src/real_time_integration.log` and stream to console.

4) Streamlit dashboard
- Only product selection required. Optional Advanced and Inventory expanders with defaults:
  - price=8.00, cost=4.00, stock=1, ytd=1000, lead_time_days=30, cycle_stock=20, service_level=90.
- Submit builds payload with provided fields only; otherwise defaults applied client‑side.
- Layout:
  - Top row: Suggested Order, Recommended Price, Confidence.
  - Second row: Forecast (next week), ROP.
  - Summary includes interval, ROP, lead time, cycle stock, service level.
- Robust against None deltas; no arithmetic with NoneType.

Run commands (macOS)
1) Environment
```
cd /Users/amilvila/PycharmProjects/retail_petfeed
python -m venv .venv && source .venv/bin/activate
pip install -r src/requirements.txt  # xgboost==1.7.x for Python 3.9
```

2) Train model (artifacts → `src/models/`)
```
cd src && MODEL_DIR=models python TRAIN_quick_strategic_implementation.py
```

3) Start API (auto‑free port; load models from `src/models`)
```
cd src && AUTO_FREE_PORT=1 MODEL_DIR=models python WEB_BackEnd_real_time_integration.py
curl -s http://localhost:5001/health
```

4) Start dashboard
```
cd src && source ../.venv/bin/activate && streamlit run WEB_FrontEnd_real_time_dashboard.py --server.port 8501
```

5) CLI parity check
```
MODEL_DIR=src/models python src/TEST_predict_weekly_demand_positive.py \
  --item "DOG FOOD" --price 8.00 --cost 4.00 --stock 1 --ytd 1000 \
  --lead-time-days 30 --cycle-stock 20 --service-level 90
```

Testing & validation
- Unit: numeric coercion and engineered features; ROP calculator; conformal quantiles.
- Integration: API loads artifacts, returns all fields; logs contain serialized API response; dashboard consumes and displays suggested order and ROP.
- E2E: values (forecast, ROP, suggested_order) match CLI within rounding.

Observability & reliability
- Logs: training prints absolute artifact paths; API logs model/scaler/info loaded and each model response.
- SQLite tables for inventory/predictions/alerts retained; background processor runs safely.
- Port 5001 conflicts resolved automatically when `AUTO_FREE_PORT=1`.

Deliverables
- Source code in `src/` with training, API, dashboard, CLI weekly script, models in `src/models/`, data under `src/data/`.
- This prompt and `ALL_DEV.md` prompts for quick reuse.

---

swfix

Approach this problem using the IDEAL framework:
1. Identify the problem precisely: Build a stable pet retail forecasting system with model training (positive‑only), consistent API, and dashboard parity with CLI ordering logic.
2. Define constraints and requirements: Python 3.9; xgboost 1.7.x; artifacts in `src/models`; API port 5001; defaults for optional inputs; robust path/env handling.
3. Explore strategies: (a) XGBoost + conformal; (b) LightGBM/CatBoost variants (optional) behind flag; (c) pure time‑series baseline for comparison. Choose (a) for reliability and speed.
4. Act: Implement training, artifact save, API with ordering math, dashboard with metrics and safe deltas; add health checks, logging, and port auto‑free.
5. Look back and learn: Verify CLI/API/FE parity; ensure intervals and suggested order make sense at stock boundaries (0/on‑hand high); document runbooks and commands above.

 