import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from mcp_server import app
from models import Process, SystemPrompt, ProcessLog, ProcessType, ProcessStatus
from workflow import MCPWorkflow

@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture
def mock_workflow():
    mock = AsyncMock(spec=MCPWorkflow)
    mock.run.return_value = {
        "task": "テストタスク",
        "status": "completed",
        "results": {
            "plan": '{"analysis": {"purpose": "テスト目的"}}',
            "research": '{"findings": [{"topic": "テストトピック"}]}',
            "execution": '{"results": {"success": true}}',
            "review": '{"evaluation": {"score": 5}}'
        }
    }
    return mock

def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_auth_token():
    response = client.post(
        "/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "username": "test",
            "password": "test",
            "grant_type": "password"
        }
    )
    assert response.status_code == 200
    assert "access_token" in response.json()
    assert response.json()["token_type"] == "bearer"

def test_auth_token_invalid():
    response = client.post(
        "/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "username": "wrong",
            "password": "wrong",
            "grant_type": "password"
        }
    )
    assert response.status_code == 401

@pytest.fixture
def auth_token():
    # トークンの取得
    response = client.post(
        "/token",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data={
            "username": "test",
            "password": "test",
            "grant_type": "password"
        }
    )
    assert response.status_code == 200
    return response.json()["access_token"]

def test_process_workflow(auth_token):
    # プロセスの作成
    process = {
        "process_type": ProcessType.SCRAPING,
        "status": ProcessStatus.PENDING,
        "parameters": {"url": "https://example.com"}
    }
    response = client.post(
        "/processes",
        headers={"Authorization": f"Bearer {auth_token}"},
        json=process
    )
    assert response.status_code == 200
    process_id = response.json()["process_id"]

    # プロセスの取得
    response = client.get(
        f"/processes/{process_id}",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert response.json()["process_type"] == ProcessType.SCRAPING
    assert response.json()["status"] == ProcessStatus.PENDING

def test_system_prompt_workflow(auth_token):
    # システムプロンプトの作成
    prompt = {
        "name": "test_prompt",
        "content": "This is a test prompt",
        "category": "test",
        "tags": ["test"]
    }
    response = client.post(
        "/system-prompts",
        headers={"Authorization": f"Bearer {auth_token}"},
        json=prompt
    )
    assert response.status_code == 200
    prompt_id = response.json()["prompt_id"]

    # プロンプトの取得
    response = client.get(
        f"/system-prompts/{prompt_id}",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert response.json()["name"] == "test_prompt"
    assert response.json()["content"] == "This is a test prompt"

def test_process_log_workflow(auth_token):
    # プロセスログの作成
    log = {
        "process_id": "test_process",
        "step_number": 1,
        "status": ProcessStatus.IN_PROGRESS,
        "message": "Test log message"
    }
    response = client.post(
        "/process-logs",
        headers={"Authorization": f"Bearer {auth_token}"},
        json=log
    )
    assert response.status_code == 200
    log_id = response.json()["log_id"]

    # ログの取得
    response = client.get(
        f"/process-logs/{log_id}",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert response.json()["process_id"] == "test_process"
    assert response.json()["message"] == "Test log message"

def test_unauthorized_access():
    # 認証なしでのアクセス
    response = client.get("/processes/123")
    assert response.status_code == 401

def test_workflow_execution(client, mock_workflow):
    """ワークフロー実行エンドポイントのテスト"""
    # 認証トークンの取得
    auth_response = client.post(
        "/token",
        data={"username": "test", "password": "test"}
    )
    token = auth_response.json()["access_token"]
    
    with patch("mcp_server.workflow", return_value=mock_workflow):
        response = client.post(
            "/workflow/execute",
            json={"task": "テストタスク"},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert "results" in data
        
        # 各ステップの結果を検証
        results = data["results"]
        assert "plan" in results
        assert "research" in results
        assert "execution" in results
        assert "review" in results

def test_workflow_error_handling(client, mock_workflow):
    """ワークフローエラーハンドリングのテスト"""
    # エラーを発生させる
    mock_workflow.run.side_effect = Exception("テストエラー")
    
    # 認証トークンの取得
    auth_response = client.post(
        "/token",
        data={"username": "test", "password": "test"}
    )
    token = auth_response.json()["access_token"]
    
    with patch("mcp_server.workflow", return_value=mock_workflow):
        response = client.post(
            "/workflow/execute",
            json={"task": "エラーテスト"},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 500
        data = response.json()
        assert "detail" in data
        assert "テストエラー" in data["detail"]

def test_invalid_token(client):
    """無効なトークンのテスト"""
    response = client.post(
        "/workflow/execute",
        json={"task": "テストタスク"},
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Could not validate credentials" 