import pytest
import json
from unittest.mock import AsyncMock, patch
from workflow import MCPWorkflow, WorkflowState
from langchain.tools import Tool
from langchain.chat_models import ChatOpenAI

@pytest.fixture
def mock_tools():
    return [
        Tool(
            name="test_tool",
            func=lambda x: "Test tool result",
            description="Test tool description"
        )
    ]

@pytest.fixture
def mock_chat_model():
    mock = AsyncMock(spec=ChatOpenAI)
    
    # プランナーの応答
    planner_response = {
        "analysis": {
            "purpose": "テスト目的",
            "requirements": ["要件1"],
            "constraints": ["制約1"]
        },
        "subtasks": [{"id": "task1", "name": "テストタスク"}],
        "schedule": {"total_estimated_time": "1h"}
    }
    
    # リサーチャーの応答
    researcher_response = {
        "search_summary": {
            "queries": ["テストクエリ"],
            "sources": ["テストソース"]
        },
        "findings": [{"topic": "テストトピック", "key_points": ["ポイント1"]}]
    }
    
    # エグゼキューターの応答
    executor_response = {
        "execution_summary": {
            "task_id": "task1",
            "status": "completed"
        },
        "results": {"success": True}
    }
    
    # レビューアーの応答
    reviewer_response = {
        "review_summary": {
            "artifact_id": "task1",
            "review_date": "2024-03-14"
        },
        "evaluation": {
            "requirements_compliance": {"score": 5},
            "quality_assessment": {"score": 4}
        }
    }
    
    # モックの応答を設定
    mock.agenerate.side_effect = [
        AsyncMock(generations=[
            [AsyncMock(text=json.dumps(resp))]
        ]) for resp in [
            planner_response,
            researcher_response,
            executor_response,
            reviewer_response
        ]
    ]
    
    return mock

@pytest.mark.asyncio
async def test_workflow_initialization(mock_chat_model, mock_tools):
    """ワークフローの初期化テスト"""
    workflow = MCPWorkflow(model_name="gpt-4", tools=mock_tools)
    assert workflow.model is not None
    assert len(workflow.tools) == len(mock_tools)
    assert workflow.planner is not None
    assert workflow.researcher is not None
    assert workflow.executor is not None
    assert workflow.reviewer is not None

@pytest.mark.asyncio
async def test_workflow_execution(mock_chat_model, mock_tools):
    """ワークフロー実行のテスト"""
    with patch("os.getenv", return_value="test-key"), \
         patch("langchain.chat_models.ChatOpenAI", return_value=mock_chat_model):
        workflow = MCPWorkflow(model_name="gpt-4", tools=mock_tools)
        result = await workflow.run("テストタスク")
        assert result["status"] == "completed"
        assert "results" in result

@pytest.mark.asyncio
async def test_workflow_error_handling(mock_chat_model, mock_tools):
    """エラーハンドリングのテスト"""
    with patch("os.getenv", return_value="test-key"), \
         patch("langchain.chat_models.ChatOpenAI", return_value=mock_chat_model):
        # エラーを発生させる
        mock_chat_model.agenerate.side_effect = Exception("テストエラー")
        
        workflow = MCPWorkflow(model_name="gpt-4", tools=mock_tools)
        result = await workflow.run("エラーテスト")
        assert result["status"] == "error"
        assert "error_message" in result

@pytest.mark.asyncio
async def test_workflow_state_transitions(mock_chat_model, mock_tools):
    """状態遷移のテスト"""
    with patch("os.getenv", return_value="test-key"), \
         patch("langchain.chat_models.ChatOpenAI", return_value=mock_chat_model):
        workflow = MCPWorkflow(model_name="gpt-4", tools=mock_tools)
        result = await workflow.run("テストタスク")
        
        # 各ステップの状態を検証
        assert "plan_result" in result["results"]
        assert "research_result" in result["results"]
        assert "execution_result" in result["results"]
        assert "review_result" in result["results"]