import os
import uuid
import requests
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
from pathlib import Path
import time

env_path = Path(__file__).parent.parent/'.env'
load_dotenv(dotenv_path=env_path)
api_key = os.getenv("API_KEY")
app = FastAPI(title="PhisGuard Security Engine")

class PhishingRequest(BaseModel):
    url: str

def submit(target_url, api_key):
    vt_url = "https://www.virustotal.com/api/v3/urls"
    payload = {"url" : target_url}
    headers = {
        "accept": "application/json",
        "x-apikey": api_key,
        "content-type": "application/x-www-form-urlencoded"
    }
    vt_response = requests.post(vt_url, data=payload, headers=headers)
    return vt_response.json()['data']['id']

def get_result(analysis_id, api_key):
    report_url = f"https://www.virustotal.com/api/v3/analyses/{analysis_id}"
    headers = {
        "x-apikey": api_key
    }
    response = requests.get(report_url, headers = headers)
    return response.json()['data']['attributes']['stats']

def get_status(status):
    if status['malicious'] > 0 or status['suspicious'] > 0:
        result = "dangerous"
        return result
    
    return "not dangerous"

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/analyze")
async def analyze_url(request_data: PhishingRequest):

    analysis_id = submit(request_data.url, api_key)

    time.sleep(15)

    result = get_result(analysis_id, api_key)

    final_status = get_status(result)
    return {
        "id": str(uuid.uuid4()),
        "url": request_data.url,
        "status": final_status,
        "malicious_count": result['malicious'],
        "suspicious_count": result['suspicious'],
        "analysis_date": time.strftime("%Y-%m-%d %H:%M:%S"),
        "from_cache": False
    }