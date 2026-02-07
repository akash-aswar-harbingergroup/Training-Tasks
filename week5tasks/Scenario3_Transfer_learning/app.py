# =========================
# Streamlit App
# Land Cover Classification
# Urban | Forest | Water
# =========================

import streamlit as st
import tensorflow as tf
import numpy as np
from PIL import Image
from tensorflow.keras.applications.resnet50 import preprocess_input

# -------------------------
# CONFIG
# -------------------------
IMG_SIZE = (224, 224)
CLASS_NAMES = ["Forest", "Urban", "Water"]

# -------------------------
# PAGE SETTINGS
# -------------------------
st.set_page_config(
    page_title="Land Cover Classification",
    page_icon="🛰️",
    layout="centered"
)

st.title("🛰️ Land Cover Classification")
st.write("Upload a satellite image to classify **Urban**, **Forest**, or **Water**")

# -------------------------
# LOAD MODEL
# -------------------------
@st.cache_resource
def load_model():
    model = tf.keras.models.load_model("landcover_resnet50.keras")
    return model

model = load_model()

# -------------------------
# IMAGE PREPROCESSING
# -------------------------
def preprocess_image(image):
    image = image.resize(IMG_SIZE)
    image = np.array(image)
    image = np.expand_dims(image, axis=0)
    image = preprocess_input(image)
    return image

# -------------------------
# FILE UPLOAD
# -------------------------
uploaded_file = st.file_uploader(
    "Upload an image",
    type=["jpg", "jpeg", "png"]
)

# -------------------------
# PREDICTION
# -------------------------
if uploaded_file is not None:
    image = Image.open(uploaded_file).convert("RGB")

    st.image(
        image,
        caption="Uploaded Image",
        use_column_width=True
    )

    with st.spinner("Classifying..."):
        processed_image = preprocess_image(image)
        predictions = model.predict(processed_image)[0]

        predicted_index = int(np.argmax(predictions))
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = float(predictions[predicted_index])

    st.markdown("### ✅ Prediction")
    st.write(f"**Class:** {predicted_class}")
    st.write(f"**Confidence:** {confidence:.2%}")

    # -------------------------
    # CONFIDENCE BAR CHART
    # -------------------------
    st.markdown("### 📊 Class Probabilities")

    prob_dict = {
        CLASS_NAMES[i]: float(predictions[i])
        for i in range(len(CLASS_NAMES))
    }

    st.bar_chart(prob_dict)