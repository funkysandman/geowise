import os
from streamlit.web.server.websocket_headers import _get_websocket_headers
import base64
import json
import streamlit as st


class ConfigurationException(Exception):
    pass


def get_user_name(principal):
    """Get the user name from the principal object"""
    for obj in principal["claims"]:
        if obj["typ"] == "name":
            return obj["val"]
    return ""


def populate_user_info():
    """Populate the user information in the sidebar"""
    headers = _get_websocket_headers()

    if headers is not None:
        if "X-Ms-Client-Principal-Name" in headers:
            user_details = {
                "email": headers["X-Ms-Client-Principal-Name"],
                "id": headers["X-Ms-Client-Principal-Id"],
            }

            principal_details = json.loads(
                base64.b64decode(headers["X-Ms-Client-Principal"]).decode("utf-8")
            )
            user_details["name"] = get_user_name(principal_details)

            st.sidebar.markdown(f"Welcome **{user_details['name']}**!")
            with st.sidebar.expander("User Details"):
                st.write(user_details)
            return user_details
        else:
            st.sidebar.markdown("Running Locally")
            with st.sidebar.expander("Local Headers"):
                st.write(headers)


def load_and_validate_env(env_storage: dict):
    """Load environment variables and validate that they are present"""
    missing_env = []
    for key in env_storage:
        if key not in os.environ:
            missing_env.append(key)
            continue
        env_storage[key] = os.environ[key]
    if len(missing_env) > 0:
        raise ConfigurationException(f"Missing environment variables: {missing_env}")
    return env_storage
