from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional, List, Dict, Any
import os
from datetime import datetime
from models import Process, SystemPrompt, ProcessLog, ProcessStatus
from bson import ObjectId
from urllib.parse import quote_plus

class Database:
    def __init__(self, mongodb_uri: str = None):
        if mongodb_uri:
            self.mongodb_uri = mongodb_uri
        else:
            # 環境変数から認証情報を取得
            username = quote_plus(os.getenv("MONGO_USERNAME", "admin"))
            password = quote_plus(os.getenv("MONGO_PASSWORD", "adminpassword"))
            host = os.getenv("MONGO_HOST", "mongodb")
            port = os.getenv("MONGO_PORT", "27017")
            
            # 認証情報付きのURIを構築
            self.mongodb_uri = f"mongodb://{username}:{password}@{host}:{port}/"
        self.client = None
        self.db = None

    async def connect(self):
        try:
            self.client = AsyncIOMotorClient(self.mongodb_uri)
            self.db = self.client.mcp
            # 接続テスト
            await self.client.admin.command('ping')
        except Exception as e:
            print(f"Failed to connect to MongoDB: {e}")
            raise

    async def close(self):
        if self.client:
            self.client.close()

    async def init_indexes(self):
        # 必要なインデックスを作成
        await self.db.processes.create_index("process_type")
        await self.db.processes.create_index("status")
        await self.db.system_prompts.create_index("name")
        await self.db.process_logs.create_index("process_id")
        await self.db.process_logs.create_index("timestamp")

    # プロセス関連の操作
    async def save_process(self, process: Process) -> str:
        result = await self.db.processes.insert_one(process.dict())
        return str(result.inserted_id)

    async def get_process(self, process_id: str) -> Optional[Process]:
        result = await self.db.processes.find_one({"_id": ObjectId(process_id)})
        if result:
            return Process(**result)
        return None

    async def update_process_status(self, process_id: str, status: ProcessStatus) -> bool:
        result = await self.db.processes.update_one(
            {"_id": ObjectId(process_id)},
            {"$set": {"status": status}}
        )
        return result.modified_count > 0

    async def search_processes(self, query: str) -> List[Process]:
        cursor = self.db.processes.find({})
        processes = []
        async for doc in cursor:
            processes.append(Process(**doc))
        return processes

    # システムプロンプト関連の操作
    async def save_system_prompt(self, prompt: SystemPrompt) -> str:
        result = await self.db.system_prompts.insert_one(prompt.dict())
        return str(result.inserted_id)

    async def get_system_prompt(self, prompt_id: str) -> Optional[SystemPrompt]:
        result = await self.db.system_prompts.find_one({"_id": ObjectId(prompt_id)})
        if result:
            return SystemPrompt(**result)
        return None

    async def search_system_prompts(self, query: str) -> List[SystemPrompt]:
        cursor = self.db.system_prompts.find({})
        prompts = []
        async for doc in cursor:
            prompts.append(SystemPrompt(**doc))
        return prompts

    # プロセスログ関連の操作
    async def save_process_log(self, log: ProcessLog) -> str:
        result = await self.db.process_logs.insert_one(log.dict())
        return str(result.inserted_id)

    async def get_process_log(self, log_id: str) -> Optional[ProcessLog]:
        result = await self.db.process_logs.find_one({"_id": ObjectId(log_id)})
        if result:
            return ProcessLog(**result)
        return None

    async def get_process_logs(self, process_id: str) -> List[ProcessLog]:
        cursor = self.db.process_logs.find({"process_id": process_id})
        logs = []
        async for doc in cursor:
            logs.append(ProcessLog(**doc))
        return logs 