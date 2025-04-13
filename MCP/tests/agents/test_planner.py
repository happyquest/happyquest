import pytest
import json
from unittest.mock import AsyncMock
from agents.planner import PlannerAgent
from langchain.chat_models import ChatOpenAI

@pytest.fixture
def mock_model():
    mock = AsyncMock(spec=ChatOpenAI)
    mock_response = {
        "analysis": {
            "purpose": "テストタスクの実行",
            "requirements": ["要件1", "要件2"],
            "constraints": ["制約1", "制約2"]
        },
        "subtasks": [
            {
                "id": "task1",
                "name": "サブタスク1",
                "description": "サブタスク1の説明",
                "priority": 1,
                "dependencies": [],
                "estimated_time": "1h"
            },
            {
                "id": "task2",
                "name": "サブタスク2",
                "description": "サブタスク2の説明",
                "priority": 2,
                "dependencies": ["task1"],
                "estimated_time": "2h"
            }
        ],
        "schedule": {
            "total_estimated_time": "3h",
            "recommended_sequence": ["task1", "task2"]
        }
    }
    mock.agenerate.return_value.generations[0][0].text = json.dumps(mock_response)
    return mock

@pytest.fixture
def planner_agent(mock_model):
    return PlannerAgent(model=mock_model)

@pytest.mark.asyncio
async def test_planner_initialization(planner_agent):
    """プランナーエージェントの初期化テスト"""
    assert planner_agent.name == "Planner"
    assert "タスクの分析と計画" in planner_agent.description
    assert planner_agent.state.task_status == "pending"

@pytest.mark.asyncio
async def test_planner_process(planner_agent):
    """プランナーエージェントの処理テスト"""
    result = await planner_agent.process({"task": "テストタスク"})
    
    assert result["status"] == "success"
    assert "plan" in result
    
    plan = json.loads(result["plan"])
    assert "analysis" in plan
    assert "subtasks" in plan
    assert "schedule" in plan
    
    # 分析結果の検証
    analysis = plan["analysis"]
    assert analysis["purpose"] == "テストタスクの実行"
    assert len(analysis["requirements"]) == 2
    assert len(analysis["constraints"]) == 2
    
    # サブタスクの検証
    subtasks = plan["subtasks"]
    assert len(subtasks) == 2
    assert subtasks[0]["id"] == "task1"
    assert subtasks[1]["id"] == "task2"
    assert subtasks[1]["dependencies"] == ["task1"]
    
    # スケジュールの検証
    schedule = plan["schedule"]
    assert schedule["total_estimated_time"] == "3h"
    assert len(schedule["recommended_sequence"]) == 2

@pytest.mark.asyncio
async def test_planner_error_handling(planner_agent, mock_model):
    """エラーハンドリングのテスト"""
    # モデルにエラーを発生させる
    mock_model.agenerate.side_effect = Exception("テストエラー")
    
    result = await planner_agent.process({"task": "エラーテスト"})
    assert result["status"] == "error"
    assert "error" in result
    assert "テストエラー" in str(result["error"])

@pytest.mark.asyncio
async def test_planner_state_updates(planner_agent):
    """状態更新のテスト"""
    await planner_agent.process({"task": "テストタスク"})
    
    state = planner_agent.get_state()
    assert state["current_task"] == "テストタスク"
    assert state["task_status"] == "planning_completed"
    assert "plan" in state["artifacts"] 