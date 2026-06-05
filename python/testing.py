import os
import requests
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent.parent/'.env'
load_dotenv(dotenv_path=env_path)
api_key = os.getenv("API_KEY")
app = FastAPI(title="PhisGuard Security Engine")

class PhishingRequest(BaseModel):
    url: str

def debug_phishing():
    user_input = input("Masukkan link yang ingin dicek: ")
    vt_url = "https://www.virustotal.com/api/v3/urls"
    
    payload = { "url": user_input }
    headers = {
        "accept": "application/json",
        "x-apikey": api_key,
        "content-type": "application/x-www-form-urlencoded"
    }
    print("\n--- Sedang Menghubungi VirusTotal... ---")
    
    try:
        response = requests.post(vt_url, data=payload, headers=headers)
        
        if response.status_code == 200:
            print("Berhasil Terhubung!")
            print(response.json())
        else:
            print(f"Gagal! Error Code: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"Terjadi kesalahan koneksi: {e}")

if __name__ == "__main__":
    debug_phishing()