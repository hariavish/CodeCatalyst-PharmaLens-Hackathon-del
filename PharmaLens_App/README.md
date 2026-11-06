# 💊 PharmaLens

> **One clear view of a patient's medicines.**
> AI-assisted prescription reading with rule-based reconciliation against hospital records, built so the **pharmacist always makes the final call**.

<!-- Replace with your own: demo video, deployed link, team name -->
**Hackathon:** `<Hackathon name>`  |  **Team:** `<Team name>`  |  **Demo video:** `<link>`

---

## Table of contents

1. [The problem](#the-problem)
2. [Our solution](#our-solution)
3. [Key features](#key-features)
4. [How it works](#how-it-works)
5. [Tech stack](#tech-stack)
6. [Project structure](#project-structure)
7. [Getting started](#getting-started)
8. [Demo accounts](#demo-accounts)
9. [Suggested demo walkthrough](#suggested-demo-walkthrough)
10. [API reference](#api-reference)
11. [Reconciliation rules](#reconciliation-rules)
12. [Safety and design principles](#safety-and-design-principles)
13. [Known limitations](#known-limitations)
14. [Roadmap](#roadmap)
15. [Troubleshooting](#troubleshooting)

---

## The problem

Between hospital visits, a patient's medication list quietly drifts. A dose is changed, a drug is dropped, a handwritten prescription is hard to read, and a new prescription gets compared to the old record by eye. Pharmacists have to do this manually, under time pressure, across many patients. Small transcription differences (`10mg` vs `100mg`, `once daily` vs `twice daily`) are easy to miss and matter a great deal.

## Our solution

PharmaLens turns a photo of a prescription into a **side-by-side reconciliation table** (Visit 1 hospital baseline vs. Visit 2 new prescription) and routes anything uncertain or different to a pharmacist for review.

Two portals share one live record:

* **Patient portal:** upload a prescription photo, see current medications, browse history, download an official record, and chat with a pharmacist.
* **Pharmacist portal:** connect to patients by Patient ID, review flagged rows, **Approve / Edit / Pass on** each one, and reply to patient questions in real time.

The AI only **reads**. Every status flag is **re-derived by deterministic Python code**, so every decision is explainable and traceable.

---

## Key features

| Area | What it does |
|---|---|
| **Prescription OCR** | Google Gemini Vision reads the image and returns structured JSON (medicine, dose, frequency, confidence). |
| **Baseline reconciliation** | Compares the new prescription to a hospital EHR baseline and labels each row `Matched` or `Conflict`. |
| **Missing-drug detection** | Baseline drugs that don't appear on the prescription are reported as `Not found on prescription`. |
| **Sudden-spike detection** | Flags doses that are ≥ 5x or ≤ 1/5 of the baseline (same unit). |
| **OCR confidence telemetry** | Shows `Stable` (≥ 90%) or a low-confidence warning asking for a visual check of the original image. |
| **Pharmacist workflow** | Approve, edit, or pass on each flagged medicine; unreliable readings never reach the patient's "current medications" until reviewed. |
| **Live chat** | Patient and pharmacist messaging with unread counters, synced across tabs. |
| **Patient IDs** | Every patient gets a unique ID (`PL-XXXX`); pharmacists link to patients by entering it (`pl-4928`, `PL4928` and `4928` all work). |
| **Profiles** | 10-field profile (blood type, allergies, conditions, emergency contact, physician, etc.) editable by each user. |
| **Official record** | Printable "PharmaLens Verified Health Record" containing only pharmacist-reconciled medicines. |
| **Original image viewer** | Pharmacists can open the uploaded prescription alongside the extracted rows. |
| **UX polish** | Light/dark theme, animated login, responsive layout, reduced-motion support. |

---

## How it works

```
┌────────────┐   image    ┌──────────────────┐   image    ┌──────────────┐
│  Patient / │ ─────────▶ │  FastAPI backend │ ─────────▶ │ Gemini Vision│
│ Pharmacist │            │    (main.py)     │ ◀───────── │  (OCR only)  │
│ dashboard  │ ◀───────── │                  │ raw rows   └──────────────┘
└────────────┘  reconciled│  reconcile():    │
     ▲          table     │  rule-based      │
     │                    │  status + flags  │
     │                    └──────────────────┘
     │ approve / edit / pass on
     ▼
 Pharmacist review ──▶ Verified "Current Medications" + Official Record
```

1. **Upload:** the dashboard sends the original image (not the downscaled preview) to `POST /upload`.
2. **Read:** Gemini extracts each medication using a strict JSON schema, with `temperature=0` for deterministic transcription.
3. **Reconcile:** the backend ignores the model's judgement and recomputes `Visit 1`, `Status` and `Sensor Telemetry` from the baseline using plain Python rules.
4. **Review:** the dashboard renders the table. Conflicts, low-confidence reads and spikes are highlighted and need a pharmacist decision.
5. **Publish:** only approved/edited (or cleanly matched, fully reviewed) medicines appear in the patient's current medications and official record.

If extraction fails, **nothing is saved**, so no made-up data ever reaches the table.

---

## Tech stack

**Backend:** Python 3.10+, FastAPI, Uvicorn, Pydantic v2, Google Generative AI SDK (Gemini Vision)

**Frontend:** Vanilla HTML/CSS/JavaScript, Tailwind CSS (CDN), Manrope font (Google Fonts). No build step.

**Data (demo):** browser `localStorage` as a mock database, with `sessionStorage` for per-tab sessions and cross-tab sync.

---

## Project structure

```
PharmaLens/
├── main.py            # FastAPI OCR + reconciliation API
├── login.html         # Sign in / create account (patient & pharmacist)
├── dashboard.html     # Patient portal + Pharmacist portal
├── requirements.txt   # Python dependencies
└── README.md
```

---

## Getting started

### Prerequisites

* Python 3.10 or newer
* A Google Gemini API key from [Google AI Studio](https://aistudio.google.com/)
* A modern browser (Chrome, Edge, Firefox, Safari)

### 1. Clone and install

```bash
git clone <your-repo-url>
cd PharmaLens
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Set your API key

```bash
export GEMINI_API_KEY="your-key"          # macOS / Linux
$env:GEMINI_API_KEY="your-key"            # Windows PowerShell
```

Optional: choose a different model.

```bash
export GEMINI_MODEL="your-model-name"
```

### 3. Start the backend

```bash
uvicorn main:app --reload --port 8000
```

Check it's alive: <http://localhost:8000/health> should return `{"status": "ok", ...}` with `api_key_configured: true`. Interactive API docs are at <http://localhost:8000/docs>.

### 4. Open the frontend

Open `login.html` directly in your browser (double-click), or serve the folder:

```bash
python -m http.server 5500      # then visit http://localhost:5500/login.html
```

The dashboard calls the backend at `http://localhost:8000/upload` (`OCR_URL` in `dashboard.html`). Change it there if you deploy the API elsewhere.

---

## Demo accounts

Test data is seeded automatically on first load (only when the local database is empty).

**Patients** (sign in with email + password)

| Name | Email | Password | Patient ID |
|---|---|---|---|
| Asha Raman | asha.raman@example.com | `Asha@2026` | PL-1001 |
| Rahul Menon | rahul.menon@example.com | `Rahul@2026` | PL-1002 |
| Priya Nair | priya.nair@example.com | `Priya@2026` | PL-1003 |
| Mohammed Farhan | mohammed.farhan@example.com | `Farhan@2026` | PL-1004 |
| Lakshmi Subramanian | lakshmi.subramanian@example.com | `Lakshmi@2026` | PL-1005 |

**Pharmacists** (sign in with email + password; the Staff ID field is required only if the account has one on file)

| Name | Email | Password |
|---|---|---|
| Anjali Krishnan | anjali.krishnan@example.org | `Anjali@Rx2026` |
| Rohan Desai | rohan.desai@example.org | `Rohan@Rx2026` |

You can also click **Create Account** to register new patients (you'll receive a unique Patient ID) or pharmacists (name, email, staff ID / license number, password of 8+ characters).

> These are fictional test accounts for demonstration only.

---

## Suggested demo walkthrough

Use **two browser tabs** side by side; sessions are per-tab, so you can be a patient and a pharmacist at once.

1. **Tab A: Patient.** Sign in as Asha Raman (`PL-1001`) and note her Patient ID.
2. **Tab B: Pharmacist.** Sign in as Anjali Krishnan → **Connect Patient** → enter `PL-1001`.
3. **Tab A:** upload a prescription photo. Watch the processing state, then the new entry in **History**.
4. **Tab B:** open the patient's prescription review. Examine rows flagged as **Conflict**, **Low Confidence** or **Sudden Spike**; open the **original image** to verify against the extracted values.
5. Use **Approve**, **Edit** (enter a corrected dose) or **Pass on** on each flagged row.
6. **Tab A:** the patient's **Current Medications** now shows only pharmacist-reconciled doses. Try **Download Official Record**.
7. **Chat:** send a question from the patient tab and reply from the pharmacist tab; both update live.
8. Toggle the **theme** to show light/dark mode.

**Backend baseline used for comparison (Visit 1)**

| Medicine | Baseline dose |
|---|---|
| Metformin | 500mg twice daily |
| Amlodipine | 5mg once daily |
| Atorvastatin | 10mg once daily |
| Levothyroxine | 25mcg once daily |

A good test prescription contains, for example, *Metformin 1000mg twice daily* (conflict), *Amlodipine 5mg once daily* (match), and omits Levothyroxine (reported as not found).

---

## API reference

### `GET /health`

Returns service status.

```json
{ "status": "ok", "model": "<model name>", "api_key_configured": true }
```

### `POST /upload`

`multipart/form-data` with a single field `file` (JPEG, PNG, WebP, HEIC/HEIF, max **10 MB**).

```bash
curl -X POST http://localhost:8000/upload -F "file=@prescription.jpg"
```

**Response:** a JSON array, one object per medication.

```json
[
  {
    "Medicine": "Metformin",
    "Visit 1": "500mg twice daily",
    "Visit 2": "1000mg twice daily",
    "Status": "Conflict",
    "Sensor Telemetry": "95% (Stable)"
  },
  {
    "Medicine": "Levothyroxine",
    "Visit 1": "25mcg once daily",
    "Visit 2": "Not found on prescription",
    "Status": "Conflict",
    "Sensor Telemetry": "N/A (medication not detected in image). Please verify original image."
  }
]
```

**Errors**

| Code | Meaning |
|---|---|
| 400 | Empty file |
| 413 | File larger than 10 MB |
| 415 | Unsupported file type |
| 500 | `GEMINI_API_KEY` is not set |
| 502 | Model request failed or returned unusable output |

---

## Reconciliation rules

All of these run in plain Python (`reconcile()` in `main.py`), **not** in the model.

* **Matching:** `Visit 2` is compared to the baseline after lowercasing and stripping spaces/punctuation, so `500 mg Twice Daily` equals `500mg twice daily`. Anything else is a `Conflict`.
* **Not on record:** a drug that isn't in the baseline is shown with `Visit 1 = "Not on record"` and flagged as a conflict.
* **Missing drug:** every baseline drug absent from the image is added as `Not found on prescription`.
* **Duplicates:** repeated medicine names are collapsed to the first occurrence.
* **Spike detection:** same unit and dose ratio ≥ 5.0 or ≤ 0.2 → `Sudden Spike Detected`.
* **Confidence:** ≥ 90% is `Stable`; below that is `Low Confidence` with a prompt to verify the original image. A missing score is `Unverified`.
* **Status override:** if the model's `Status` disagrees with the rules, the rules win (and the override is logged).

Thresholds are constants at the top of `main.py` (`STABLE_CONFIDENCE`, `SPIKE_RATIO`).

---

## Safety and design principles

* **AI reads, humans decide.** The model never recommends, approves, changes or discontinues anything, and is instructed never to diagnose.
* **Neutral language.** "Conflict" means *the two sources differ*, not that either is wrong.
* **Explainable by construction.** Every flag comes from a visible rule.
* **Prompt-injection resistant.** Text inside the image is treated strictly as data; any instruction written on a prescription is ignored.
* **Fail closed.** Unusable or blocked model output saves nothing.
* **Uncertainty is surfaced, not hidden.** A shaky reading is flagged even if the doses happen to match.
* **Strict transcription.** The model is told to lower its confidence rather than guess an unclear digit, unit or decimal.

---

## Known limitations

This is a hackathon prototype, and it's honest to say so:

* **Mock database.** Data lives in the browser's `localStorage`, so it is per-browser, not shared across devices, and clearable by the user.
* **Plain-text passwords and no real auth.** Passwords are stored unhashed for demo purposes. A real deployment needs server-side hashing, sessions/tokens and role-based access control.
* **Hardcoded EHR baseline** for four drugs in `BASELINE_EHR`. It is not connected to a real hospital system.
* **Open CORS** (`allow_origins=["*"]`) so a local HTML file can reach the API; restrict in production.
* **Not a medical device.** Not clinically validated, not HIPAA/GDPR compliant, and not intended for real patient care.
* OCR accuracy depends on image quality and handwriting legibility.

---

## Roadmap

* Real backend database and authentication (hashed credentials, JWT/session, audit log)
* FHIR / HL7 integration to pull real EHR medication lists
* Drug-name normalisation (brand → generic) via RxNorm
* Drug-interaction and allergy cross-checks as pharmacist-facing *information*
* Multi-page / multi-image prescriptions and PDF support
* Notifications (email / SMS) for pending reviews
* Multilingual prescription support
* Automated test suite with a labelled prescription image set

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Upload says "Server is missing GEMINI_API_KEY" | Set the env var **in the same terminal** that runs `uvicorn`, then restart. |
| `502 Vision model request failed` / model not found | Models get retired. Set `GEMINI_MODEL` to a currently available Gemini vision model. |
| Browser shows a network / CORS error | Make sure the backend is running on port 8000 and `OCR_URL` in `dashboard.html` matches. |
| Fresh demo data is needed | Clear this site's `localStorage` in your browser dev tools and reload `login.html`. |
| `ModuleNotFoundError` | Activate your virtual environment and run `pip install -r requirements.txt`. |
| Page looks unstyled offline | Tailwind and fonts load from CDNs, so an internet connection is needed. |

---

## Disclaimer

PharmaLens is a prototype built for a hackathon. It is a **review aid for pharmacists** and must not be used as a substitute for professional medical judgement. All demo patients, pharmacists and data are fictional.

## License

`<Choose a license, e.g. MIT>`

## Team

`<Names / roles / links>`
