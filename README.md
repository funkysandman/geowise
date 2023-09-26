# GeoWise
## A Streamlit app for extracting and geocoding locations from text using GPT-3.5 and GPT-4

## DevContainer

This project uses a devcontainer to ensure that the development environment is consistent across all developers. To use the devcontainer, you will need to install the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for VSCode.

## Getting Started

### Deployment
1. Make a copy of the local.env.example file: 
```bash
cp scripts/environments/local.env.example scripts/environments/local.env
```
2. Fill in the values in the `local.env` file
3. Run `make deploy`
4. Navigate to the WebApp URL mentioned in the stdout.

### Developing Locally
1. Run `source scripts/environments/local.env` to populate your environment variables
2. Run `streamlit run app/Home.py`
3. Open your browser and navigate to `http://localhost:8501`
