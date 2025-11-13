import requests
from firebase_admin import initialize_app
from firebase_functions import https_fn
import os


# Initialize the Firebase app
initialize_app()


@https_fn.on_call()
def checkUrl(req: https_fn.CallableRequest) -> any:
    """Receives a URL from the client, analyzes it using Google Safe Browsing API, and returns a verdict."""

    
 
    GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY")
    # ------------------------------------------

    if not GOOGLE_API_KEY or GOOGLE_API_KEY == "YOUR_GOOGLE_SAFE_BROWSING_API_KEY":
        print("ERROR: Google Safe Browsing API key is not set.")
        # Return a warning if the API key is missing
        return {"verdict": "WARNING", "finalUrl": "API key not configured.", "threatTypes": []}

    # 1. Get the URL from the request
    url = req.data.get("url")
    if not url:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="The function must be called with one argument 'url' containing the URL to analyze.",
        )

    print(f"Analyzing URL: {url}")

    try:
        # 2. Expand the URL to its final destination
        final_url = url
        try:
            # Use a timeout to prevent waiting too long for a response
            response = requests.head(url, allow_redirects=True, timeout=5)
            final_url = response.url
            print(f"Expanded URL to: {final_url}")
        except requests.RequestException as e:
            # If expansion fails, just use the original URL
            print(f"Could not expand URL: {e}")
            final_url = url

        # 3. Check the final URL with Google Safe Browsing API v4
        safe_browsing_url = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={GOOGLE_API_KEY}"
        
        # Safe Browsing API payload
        payload = {
            "client": {
                "clientId": "secure-qr-scanner",
                "clientVersion": "1.0.0"
            },
            "threatInfo": {
                "threatTypes": [
                    "MALWARE",
                    "SOCIAL_ENGINEERING", 
                    "UNWANTED_SOFTWARE",
                    "POTENTIALLY_HARMFUL_APPLICATION"
                ],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [
                    {"url": final_url}
                ]
            }
        }
        
        # Make the API call
        api_response = requests.post(safe_browsing_url, json=payload, timeout=10)
        api_data = api_response.json()

        # 4. Determine the verdict based on Safe Browsing response
        threat_types = []
        if api_data.get("matches"):
            # Threat found
            matches = api_data["matches"]
            threat_types = [match.get("threatType", "UNKNOWN") for match in matches]
            print(f"Threat found for {final_url}: {threat_types}")
            verdict = "DANGEROUS"
        else:
            # No threat found
            print(f"No threat found for {final_url}")
            verdict = "SAFE"

        # 5. Return the result with additional threat information
        return {
            "verdict": verdict, 
            "finalUrl": final_url,
            "threatTypes": threat_types,
            "originalUrl": url
        }

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        # Return a generic warning if any part of the analysis fails
        return {"verdict": "WARNING", "finalUrl": url, "threatTypes": [], "error": str(e)}
