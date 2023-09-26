import streamlit as st
from utils import populate_user_info

st.set_page_config(
    page_title="GeoWise", page_icon="🌍", initial_sidebar_state="auto", layout="wide"
)
st.header("🌍 GeoWise")
st.sidebar.info("ChatGPT augmented geocoding for unstrucutred text with Azure Maps")
user_details = populate_user_info()

st.markdown(
    "Welcome to GeoWise, a tool to help you process text data into geocoded data. Head to the 'Extraction' tab to get started and 'Visualisation' to see your results."
)
