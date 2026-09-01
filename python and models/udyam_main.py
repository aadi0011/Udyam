from fastapi import FastAPI, UploadFile, File, Form
import torch
import torchaudio.transforms as T
import soundfile as sf
from transformers import AutoModel
from deep_translator import GoogleTranslator
from google import genai
from google.genai import types
import json
from deep_translator import GoogleTranslator , MyMemoryTranslator
import time
from sklearn.metrics.pairwise import cosine_similarity
import math
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware
import cv2 
import numpy as np
from PIL import Image
from rembg import remove , new_session
import io
from fastapi.responses import Response
from pydub import AudioSegment
import subprocess
import joblib
from sentence_transformers import SentenceTransformer
import os
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)




app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

print("loading ASRmodel...")
model = AutoModel.from_pretrained( "ai4bharat/indic-conformer-600m-multilingual",trust_remote_code=True)
print("asr model loaded..")
print("client server linked...")
print("prcing model loaded...")
session = new_session("isnet-general-use")
print("new_session loaded")


lgb_model = joblib.load("lgb_model.pkl")
le_category = joblib.load("le_category.pkl")
le_material = joblib.load("le_material.pkl")
pca = joblib.load("pca_transform.pkl")
known_categories = joblib.load("known_categories.pkl")
known_materials = joblib.load("known_materials.pkl")
known_cat_embeddings = joblib.load("known_cat_embeddings.pkl")
known_mat_embeddings = joblib.load("known_mat_embeddings.pkl")
X_columns = joblib.load("x_columns_2.pkl")
embedding_model = SentenceTransformer("all-MiniLM-L6-v2")

@app.post("/image")
async def process_image(file: UploadFile = File(...)):
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes))

    cutout = remove(image, session=session)
    

    if isinstance(cutout, bytes):
        cutout = Image.open(io.BytesIO(cutout))
    elif not isinstance(cutout, Image.Image):
        cutout = Image.fromarray(cutout)


    alpha = np.array(cutout.split()[-1])
    ys, xs = np.where(alpha > 8)

    if len(xs) == 0 or len(ys) == 0:
        return Response(content=b"", media_type="image/png", status_code=422)

    x0, x1, y0, y1 = map(int, (xs.min(), xs.max(), ys.min(), ys.max()))
    subject = cutout.crop((x0, y0, x1 + 1, y1 + 1))

    pad = int(max(subject.size) * 0.08)  # 8% margin, used later for the canvas
    flattened = Image.new("RGB", (subject.width, subject.height), (255, 255, 255))
    flattened.paste(subject, (0, 0), subject)

    bgr = cv2.cvtColor(np.array(flattened), cv2.COLOR_RGB2BGR)

    wb = cv2.xphoto.createGrayworldWB()
    wb.setSaturationThreshold(0.4)  # lower = safer for white/near-white products
    bgr = wb.balanceWhite(bgr)
 
    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=0.8, tileGridSize=(16, 16))  # gentle + large tiles = global, not local
    l = clahe.apply(l)
    bgr = cv2.cvtColor(cv2.merge((l, a, b)), cv2.COLOR_LAB2BGR)

    corrected = Image.fromarray(cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB))

    hsv = cv2.cvtColor(np.array(corrected), cv2.COLOR_RGB2HSV).astype(np.float32)
    hsv[..., 1] = np.clip(hsv[..., 1] * 1.08, 0, 255)  # +8% — drop to 1.0 (no-op) for white items, ~1.03 for paintings
    final_arr = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2RGB)
    final = Image.fromarray(final_arr)

    w, h = final.width + 2 * pad, final.height + 2 * pad
    side = max(w, h)  # square: both sides = the larger dimension

    canvas = Image.new("RGB", (side, side), (250, 250, 248))  # soft off-white
    offset = ((side - final.width) // 2, (side - final.height) // 2)
    canvas.paste(final, offset)

    output = io.BytesIO()
    canvas.save(output, format="PNG")

    return Response(content=output.getvalue(), media_type="image/png")



@app.post("/process-voice")
async def process_voice(
    audio_file: UploadFile = File(...),
    native_lang: str = Form(...),
):
    Target_sample_rate = 16000

    contents = await audio_file.read()
    raw_path = "temp_raw_audio"
    with open(raw_path, "wb") as f:
        f.write(contents)

    temp_path = "temp_audio.wav"
 
    subprocess.run(
    ["ffmpeg", "-y", "-i", raw_path, "-ar", str(Target_sample_rate), "-ac", "1", temp_path],
    check=True,
    capture_output=True,
)
  

    

    def load_and_resample(audio_path: str):
        data , sr = sf.read(audio_path)
        wav = torch.tensor(data, dtype = torch.float32).unsqueeze(0)
        resampler = T.Resample(orig_freq=sr,new_freq=Target_sample_rate)
        wav_16k = resampler(wav)
        return wav_16k

    def convert_to_transcript(wav_16k,native_lang_code):
        transcript = model(wav_16k, native_lang_code , "rnnt")
        return transcript


    def safe_translate(text, source_lang, target_lang, retries=3, delay=1.5):
        for attempt in range(retries):
            try:
                return GoogleTranslator(source=source_lang, target=target_lang).translate(text)
            except Exception as e:
                print(f"Google translate attempt {attempt+1} failed: {e}")
                time.sleep(delay)

        try:
            return MyMemoryTranslator(source=source_lang, target=target_lang).translate(text)
        except Exception as e:
            print(f"MyMemory translate also failed: {e}")
            return text  # last resort: return original text rather than crashing

    def convert_to_hin_eng(transcript, native_lang_code):
        if native_lang_code == "hi":
            hindi_text = transcript
        else:
            hindi_text = safe_translate(transcript, native_lang_code, "hi")

        english_text = safe_translate(transcript, native_lang_code, "en")
        return hindi_text, english_text

    
    def gemini_convert(hindi_text , english_text ):
        prompt = (f"""
        You are extracting product listing details from an artisan's spoken description, already transcribed and translated.

        Hindi transcript: {hindi_text}
        English translation: {english_text}

        Extract ONLY what the artisan actually said. Do not invent details they didn't mention.
        description should be in about 25 words which should be SEO friendly ,product details should be in english,
        predict category which is avaiable on e commerce platforms, the product name should not be null , use keywords used by e - commerce platforms to predict name , length of
        name should be 5 to 6 words , size and capacity should be in numbers with proper unit

        Respond ONLY with valid JSON in this exact format:
        {{
        "product_name": "...",
        "material": "...",
        "color": "...",
        "category": "...",
        "size_or_capacity": "...",
        "craft_technique": "...",
        "विवरण": "...",
        "description": "...",
        "quantity": "..."
        }}
        If a field isn't mentioned in the transcript, set it to null. Do not include a "price" field.""")
            

        response = client.models.generate_content(
        model="gemini-3.5-flash-lite",
        contents=prompt,
        config=types.GenerateContentConfig(response_mime_type="application/json")
    )

        product_details = json.loads(response.text)
        
        return product_details
    
    
    def match_known(value, known_list, known_embeddings, threshold=0.5):
        val_str = str(value)
        if val_str in known_list:
            return val_str
        query_emb = embedding_model.encode([val_str])
        sims = cosine_similarity(query_emb, known_embeddings)[0]
        best_idx = sims.argmax()
        if sims[best_idx] < threshold:
            return known_list[0]
        return known_list[best_idx]

    def safe_transform(le, value):
        val_str = str(value)
        if val_str in le.classes_:
            return le.transform([val_str])[0]
        return 0

    def predict_price(name, category, refined_material, quantity):
        try:
            matched_category = match_known(category, known_categories, known_cat_embeddings)
            matched_material = match_known(refined_material, known_materials, known_mat_embeddings)

            cat_encoded = safe_transform(le_category, matched_category)
            mat_encoded = safe_transform(le_material, matched_material)

            name_embedding = embedding_model.encode([str(name)])
            name_embedding_df = pd.DataFrame(name_embedding, columns=[f'emb_{i}' for i in range(name_embedding.shape[1])])
            name_pca = pca.transform(name_embedding_df)

            pca_cols = [f'pca_{i}' for i in range(name_pca.shape[1])]
            pca_df = pd.DataFrame(name_pca, columns=pca_cols)

            input_features = pd.DataFrame({
                'category': [cat_encoded],
                'refined_material': [mat_encoded],
                'quantity': [quantity]
            })

            X_input = pd.concat([input_features, pca_df], axis=1)
            X_input = X_input.reindex(columns=X_columns, fill_value=0)

            log_pred = lgb_model.predict(X_input)[0]
            return round(float(np.expm1(log_pred)))

        except Exception as e:
            print(f"predict_price failed for '{name}': {e}")
            return 0.0


    

    wav_16k = load_and_resample(temp_path)                              # call + capture
    native_transcript = convert_to_transcript(wav_16k, native_lang)          # call + capture
    hindi_text, english_text = convert_to_hin_eng(native_transcript, native_lang)  # call + capture (two values this time)     # call + capture
                 

    product_details = gemini_convert(hindi_text, english_text) 
    quantity = product_details.get("quantity") or 1
    try:
        quantity = float(quantity)
    except (TypeError, ValueError):
        quantity = 1
    name = product_details.get("product_name", "Unknown")
    category = product_details.get("category", "Unknown")
    size = product_details.get("size_or_capacity", "Unknown")
    name_category_key = f"{name} {size}-{category}"
    hindi_dec = product_details.get("विवरण")
    material = product_details.get("material")
    craft_techinque= product_details.get("craft_technique")
    des = product_details.get("description")
    color = product_details.get("color")
    predicted_price = predict_price(name , category , material , quantity)                  # call + capture
    
    
        

    return {
         "product_Name": name,
         "category": category,
         "size": size,
         "hindi_dec" : hindi_dec,
         "Material": material,
         "Description" : des,
         "color": color,
         "Crafting_technique": craft_techinque,
         "suggested_price": predicted_price




    }





    

