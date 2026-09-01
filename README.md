# Udyam

**Voice-first product listing for Indian artisans — speak, and your listing builds itself.**

Udyam lets an artisan describe their handmade product out loud, in their own language, and turns that into a complete, ready-to-publish product listing: structured details, an enhanced product photo, and a data-driven suggested price — with no typing required.

> Built for **Smart India Hackathon (SIH)**.

---

## The problem

Many artisans in India are highly skilled at their craft but face real friction when selling online:
- Writing a product description, in English, for an e-commerce listing is a barrier — especially across India's many regional languages and literacy levels.
- Product photos taken on a phone often look unprofessional against cluttered backgrounds.
- Artisans have no easy way to know what a fair market price for their product should be.

Udyam removes all three barriers with one voice recording and one photo.

---

## How it works

1. **Artisan logs in** and selects their preferred language (used for both the app's UI and their voice input).
2. **They record themselves describing the product** — material, color, size, how it's made — in their native language.
3. **Speech-to-text** transcribes the recording natively, then translates it to Hindi and English.
4. **An LLM structures the transcript** into clean listing fields: product name, category, material, color, size, craft technique, and a polished description — without inventing details the artisan didn't say.
5. **The artisan uploads a product photo**, which is automatically background-removed, color-corrected, and centered on a clean canvas.
6. **A trained pricing model** suggests a fair price based on the product's name, category, material, and quantity.
7. The artisan reviews the auto-filled listing and publishes it — no typing needed.

---

## Tech stack

### Speech-to-text
- **AI4Bharat IndicWhisper / IndicConformer** (`ai4bharat/indic-conformer-600m-multilingual`) — a Whisper-based model fine-tuned specifically for Indian languages, chosen over generic speech-to-text APIs for its accuracy on Indian accents and dialects across 12+ languages.

### Translation
- **Google Translate** (via `deep-translator`) — converts the native-language transcript into Hindi and English.

### Listing generation
- **Gemini API** (`gemini-3.5-flash-lite`) — reads the translated transcript and extracts structured product fields as JSON, without fabricating information the artisan didn't mention.

### Image processing (classical computer vision)
- **rembg** — background removal from the uploaded product photo.
- **OpenCV** — classical CV pipeline for image enhancement:
  - Grayworld white balance correction (`cv2.xphoto`)
  - CLAHE contrast enhancement in LAB color space
  - Saturation adjustment in HSV space
  - Auto-cropping and centering on a clean canvas

### Pricing prediction
- **LightGBM regression model**, achieving an **R² score of 0.72** on held-out test data.
- Features: category and material (label-encoded), quantity, and **PCA-reduced sentence embeddings** (30 components) of the product name, generated via `sentence-transformers/all-MiniLM-L6-v2`.
- **Fuzzy category/material matching**: unseen category or material values (e.g. from Gemini's output) are matched to the closest known training category via cosine similarity on embeddings, rather than failing outright.
- Trained on a log-transformed price target; predictions are converted back via `expm1`.

### Backend
- **FastAPI** (Python) — single backend serving all three AI pipelines (voice, image, pricing) through dedicated endpoints. Models are loaded once at server startup and reused across requests for fast response times.

### Frontend
- **Flutter** — cross-platform mobile app for artisans, communicating with the FastAPI backend over HTTP (multipart form-data for audio/image uploads, JSON responses).

### Storage
- Product catalog, enhanced images, and listing data are stored for retrieval and stock management. *(Update this section with your actual database — e.g. Supabase/PostgreSQL — once finalized.)*

---

## API endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/process-voice` | POST | Accepts an audio file + language code; returns transcribed, translated, and structured product listing fields plus a suggested price. |
| `/image` | POST | Accepts a product photo; returns a background-removed, color-corrected, enhanced PNG. |

---

## Why these design choices

- **Why not just use a general speech-to-text or translation API for everything?** Google Translate only translates *text* — it can't transcribe speech. We needed a dedicated speech recognition model first, and chose one purpose-built for Indian languages and accents (IndicConformer) rather than a general-purpose model, for meaningfully better accuracy on this specific user base.
- **Why classical CV instead of a generative image model for photo enhancement?** Classical CV (white balance, CLAHE, saturation correction) is fast, deterministic, and doesn't risk hallucinating or altering the actual product's appearance — important for accurately representing what the artisan is really selling.
- **Why a trained regression model instead of an LLM guess for pricing?** Pricing needs to be grounded in real data patterns (material, category, market trends) rather than an LLM's free-form estimate, which can be inconsistent or ungrounded. The LightGBM model is trained specifically for this task and evaluated with a measurable R² score.

---

## Setup

```bash
# Clone the repo
git clone <your-repo-url>
cd udyam

# Install backend dependencies
pip install -r requirements.txt --break-system-packages

# Run the backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

cd into the udyam_app in folder then 'flutter pub get ' and 'flutter run ' to setup run.

---

## Team Udyam 

Aadish jain , Aarushi 



---

