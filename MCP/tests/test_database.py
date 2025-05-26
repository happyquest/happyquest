import pytest
from database import Database
from models import Process, SystemPrompt, ProcessLog, ProcessStatus, ProcessType
from datetime import datetime
from unittest.mock import patch, AsyncMock

@pytest.fixture
async def db(mock_mongo_client):
    with patch("motor.motor_asyncio.AsyncIOMotorClient", return_value=mock_mongo_client):
        test_db = Database()
        # データベース接続のモックを設定
        mock_mongo_client.admin.command.return_value = {"ok": 1}
        mock_mongo_client.test.command.return_value = {"ok": 1}
        # コレクションのモックを設定
        mock_collection = AsyncMock()
        mock_collection.insert_one.return_value = AsyncMock(inserted_id="test_id")
        mock_collection.update_one.return_value = AsyncMock(modified_count=1)
        mock_collection.delete_one.return_value = AsyncMock(deleted_count=1)
        mock_collection.find_one.side_effect = lambda filter: {
            "_id": filter.get("_id"),
            "name": "test",
            "type": ProcessType.SCRAPING.value,
            "description": "test",
            "steps": [],
            "status": ProcessStatus.PENDING.value,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        mock_collection.create_index.return_value = "test_index"
        mock_mongo_client.test.processes = mock_collection
        mock_mongo_client.test.system_prompts = mock_collection
        mock_mongo_client.test.process_logs = mock_collection
        await test_db.connect()
        await test_db.init_indexes()
        yield test_db

@pytest.mark.asyncio
async def test_process_crud(db):
    """プロセスのCRUD操作テスト"""
    # テストデータ
    process = Process(
        name="テストプロセス",
        type=ProcessType.SCRAPING,
        description="テスト用プロセス",
        steps=[{"step": 1, "action": "test"}],
        status=ProcessStatus.PENDING
    )
    
    # 作成
    result = await db.create_process(process)
    assert result.id is not None
    
    # 読み取り
    saved_process = await db.get_process(result.id)
    assert saved_process.name == "test"
    assert saved_process.type == ProcessType.SCRAPING
    
    # 更新
    saved_process.status = ProcessStatus.SUCCESS
    updated_process = await db.update_process(saved_process)
    assert updated_process.status == ProcessStatus.SUCCESS
    
    # 削除
    await db.delete_process(result.id)
    deleted_process = await db.get_process(result.id)
    assert deleted_process is None

@pytest.mark.asyncio
async def test_system_prompt_crud(db):
    """システムプロンプトのCRUD操作テスト"""
    # テストデータ
    prompt = SystemPrompt(
        name="テストプロンプト",
        content="これはテストプロンプトです",
        category="test",
        tags=["test"]
    )
    
    # 作成
    result = await db.create_system_prompt(prompt)
    assert result.id is not None
    
    # 読み取り
    saved_prompt = await db.get_system_prompt(result.id)
    assert saved_prompt.name == prompt.name
    
    # 更新
    saved_prompt.content = "更新されたプロンプト"
    updated_prompt = await db.update_system_prompt(saved_prompt)
    assert updated_prompt.content == "更新されたプロンプト"
    
    # 削除
    await db.delete_system_prompt(result.id)
    deleted_prompt = await db.get_system_prompt(result.id)
    assert deleted_prompt is None

@pytest.mark.asyncio
async def test_process_log_crud(db):
    """プロセスログのCRUD操作テスト"""
    # テストデータ
    log = ProcessLog(
        process_id="test_process",
        step_number=1,
        status=ProcessStatus.IN_PROGRESS,
        message="テストログ"
    )
    
    # 作成
    result = await db.create_process_log(log)
    assert result.id is not None
    
    # 読み取り
    saved_log = await db.get_process_log(result.id)
    assert saved_log.message == log.message
    
    # 更新
    saved_log.status = ProcessStatus.SUCCESS
    updated_log = await db.update_process_log(saved_log)
    assert updated_log.status == ProcessStatus.SUCCESS
    
    # 削除
    await db.delete_process_log(result.id)
    deleted_log = await db.get_process_log(result.id)
    assert deleted_log is None

@pytest.mark.asyncio
async def test_process_status_update(db):
    """プロセスのステータス更新テスト"""
    # テストデータ
    process = Process(
        name="テストプロセス",
        type=ProcessType.SCRAPING,
        description="テスト用プロセス",
        steps=[{"step": 1, "action": "test"}],
        status=ProcessStatus.IN_PROGRESS
    )
    
    # プロセスを作成
    result = await db.create_process(process)
    
    # ステータスを更新
    updated = await db.update_process_status(
        result.id,
        ProcessStatus.SUCCESS,
        error_message=None
    )
    assert updated.status == ProcessStatus.SUCCESS 