import os
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

MONGO_URI = os.getenv("MONGO_URI", "")

_client: AsyncIOMotorClient | None = None


def get_client() -> AsyncIOMotorClient:
    global _client
    if _client is None:
        if not MONGO_URI:
            raise RuntimeError("MONGO_URI is not set in .env")
        _client = AsyncIOMotorClient(MONGO_URI)
    return _client


def get_db():
    """Returns the 'phision' database."""
    return get_client()["phision"]


async def close_client():
    global _client
    if _client:
        _client.close()
        _client = None
