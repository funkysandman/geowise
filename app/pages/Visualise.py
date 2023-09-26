from azure.cosmos import CosmosClient
import streamlit as st
from utils import populate_user_info, load_and_validate_env
import folium
from streamlit_folium import st_folium
import pandas as pd
from pydeck import Deck, Layer, ViewState
import altair as alt
import wordcloud


st.set_page_config(
    page_title="GeoWise", page_icon="🌍", initial_sidebar_state="auto", layout="wide"
)
st.header("🌍 GeoWise - Visualise")
st.sidebar.info("ChatGPT augmented geocoding for unstrucutred text with Azure Maps")
user_details = populate_user_info()
project_name = st.sidebar.text_input("Project to query Data from", value="Default")


ENV = {
    "AZURE_OPENAI_API_ENDPOINT": "",
    "AZURE_OPENAI_API_VERSION": "",
    "AZURE_OPENAI_SERVICE_KEY": "",
    "AZURE_OPENAI_CHATGPT_DEPLOYMENT": "",
    "AZURE_OPENAI_GPT4_DEPLOYMENT": "",
    "COSMOSDB_URL": "",
    "COSMOSDB_KEY": "",
    "COSMOSDB_DATABASE_NAME": "",
    "COSMOSDB_CONTAINER_NAME": "",
}

ENV = load_and_validate_env(ENV)

cosmos_client = CosmosClient(url=ENV["COSMOSDB_URL"], credential=ENV["COSMOSDB_KEY"])
cos_db_client = cosmos_client.get_database_client(ENV["COSMOSDB_DATABASE_NAME"])
cos_container_client = cos_db_client.get_container_client(
    ENV["COSMOSDB_CONTAINER_NAME"]
)

query = st.text_area("Query", value="SELECT * FROM r", height=100)

st.sidebar.markdown("### Query Example \n ```sql\nSELECT * FROM r WHERE r.event_category_at_location = '[CATEGORY]'\n```")

data = cos_container_client.query_items(
    query, enable_cross_partition_query=True
)
df = pd.DataFrame(data)

with st.expander("Raw Data"):
    st.write(df)


# Altair bar Chart

bar_chart = (
    alt.Chart(df)
    .mark_bar()
    .encode(
        x="event_category_at_location", y="count()", color="event_category_at_location"
    )
)

# Wordcloud

wc = wordcloud.WordCloud(background_color="#0e1117", width=800, height=350)
# Use event_description as the text
wc.generate(" ".join(df["event_description"].tolist()))

st.altair_chart(bar_chart, use_container_width=True)

# Pydeck Map with tooltips

view_state = ViewState(
    latitude=df["lat"].mean(), longitude=df["lon"].mean(), zoom=3, bearing=15, pitch=30
)

tooltip = {
    "html": "<b>{location_name} - {event_category_at_location}</b> <br> {event_description}\n{geo_reasoning}",
    "style": {"backgroundColor": "steelblue", "color": "white"},
}

# color by event_category_at_location

layer = Layer(
    "ScatterplotLayer",
    data=df,
    get_position=["lon", "lat"],
    get_fill_color=[255, 0, 0],
    get_radius=10000,
    pickable=True,
    auto_highlight=True,
    tooltip=tooltip,
)

r = Deck(layers=[layer], initial_view_state=view_state, tooltip=tooltip)
st.pydeck_chart(r)
