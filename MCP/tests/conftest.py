import pytest
import os
from unittest.mock import AsyncMock, MagicMock, patch
from langchain_community.chat_models import ChatOpenAI
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo.results import InsertOneResult, UpdateResult, DeleteResult

# テスト用の環境変数を事前に設定
os.environ["MONGO_USERNAME"] = "test"
os.environ["MONGO_PASSWORD"] = "test"
os.environ["MONGO_HOST"] = "localhost"
os.environ["MONGO_PORT"] = "27017"
os.environ["JWT_SECRET"] = "test-secret-key"
os.environ["API_KEY"] = "test-key"
os.environ["TESTING"] = "true"
os.environ["OPENAI_API_KEY"] = "test-openai-key"

@pytest.fixture
def mock_chat_model():
    mock = AsyncMock(spec=ChatOpenAI)
    mock.agenerate.return_value = AsyncMock(
        generations=[[AsyncMock(text="テスト応答")]]
    )
    return mock

@pytest.fixture
def mock_mongo_client():
    mock_client = AsyncMock(spec=AsyncIOMotorClient)
    mock_db = AsyncMock(spec=AsyncIOMotorDatabase)
    
    # コレクションのモック
    mock_collection = AsyncMock()
    mock_collection.insert_one.return_value = AsyncMock(spec=InsertOneResult, inserted_id="test_id")
    mock_collection.update_one.return_value = AsyncMock(spec=UpdateResult, modified_count=1)
    mock_collection.delete_one.return_value = AsyncMock(spec=DeleteResult, deleted_count=1)
    mock_collection.find_one.return_value = AsyncMock(return_value={"_id": "test_id", "name": "test", "type": "test", "description": "test", "steps": [], "status": "pending"})
    mock_collection.create_index.return_value = "test_index"
    
    # データベースのモック
    mock_db.command = AsyncMock(return_value={"ok": 1})
    mock_db.list_collection_names = AsyncMock(return_value=["processes", "system_prompts", "process_logs"])
    mock_db.processes = mock_collection
    mock_db.system_prompts = mock_collection
    mock_db.process_logs = mock_collection
    
    # クライアントのモック
    mock_client.test = mock_db
    mock_client.admin = mock_db
    
    return mock_client

@pytest.fixture(autouse=True)
def setup_test_env():
    with patch("motor.motor_asyncio.AsyncIOMotorClient") as mock_client:
        mock_db = AsyncMock(spec=AsyncIOMotorDatabase)
        mock_db.command.return_value = {"ok": 1}
        mock_client.return_value.test = mock_db
        mock_client.return_value.admin = mock_db
        yield
    
    # テスト後にクリーンアップ
    test_env_vars = [
        "MONGO_USERNAME",
        "MONGO_PASSWORD",
        "MONGO_HOST",
        "MONGO_PORT",
        "JWT_SECRET",
        "API_KEY",
        "TESTING",
        "OPENAI_API_KEY"
    ]
    for var in test_env_vars:
        os.environ.pop(var, None) 