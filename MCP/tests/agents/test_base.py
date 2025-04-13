import pytest
from unittest.mock import AsyncMock
from agents.base import BaseAgent, AgentState
from langchain.schema import HumanMessage, SystemMessage
from langchain_community.chat_models import ChatOpenAI
from langchain.prompts import ChatPromptTemplate

class TestAgent(BaseAgent):
    """テスト用エージェントクラス"""
    async def process(self, input_data):
        messages = [
            SystemMessage(content="Test system message"),
            HumanMessage(content=str(input_data))
        ]
        response = await self._generate_response(messages)
        self.update_state(current_task="test_task", task_status="completed")
        return {"status": "success", "result": response}

@pytest.fixture
def mock_model():
    mock = AsyncMock(spec=ChatOpenAI)
    mock.agenerate.return_value.generations[0][0].text = "Test response"
    return mock

@pytest.fixture
def test_agent(mock_model):
    prompt_template = ChatPromptTemplate.from_messages([
        ("system", "Test system message"),
        ("human", "{input}")
    ])
    return TestAgent(
        name="TestAgent",
        description="Test agent description",
        model=mock_model,
        prompt_template=prompt_template
    )

@pytest.mark.asyncio
async def test_agent_initialization(test_agent):
    """エージェントの初期化テスト"""
    assert test_agent.name == "TestAgent"
    assert test_agent.description == "Test agent description"
    assert isinstance(test_agent.state, AgentState)
    assert test_agent.state.current_task == ""
    assert test_agent.state.task_status == "pending"

@pytest.mark.asyncio
async def test_agent_process(test_agent):
    """エージェントの処理テスト"""
    result = await test_agent.process({"test": "data"})
    assert result["status"] == "success"
    assert result["result"] == "Test response"
    assert test_agent.state.current_task == "test_task"
    assert test_agent.state.task_status == "completed"

@pytest.mark.asyncio
async def test_agent_state_management(test_agent):
    """エージェントの状態管理テスト"""
    # 状態の更新
    test_agent.update_state(
        current_task="new_task",
        task_status="in_progress",
        artifacts={"test": "data"}
    )
    
    # 状態の検証
    state = test_agent.get_state()
    assert state["current_task"] == "new_task"
    assert state["task_status"] == "in_progress"
    assert state["artifacts"] == {"test": "data"}
    
    # 状態のリセット
    test_agent.reset_state()
    assert test_agent.state.current_task == ""
    assert test_agent.state.task_status == "pending"
    assert test_agent.state.artifacts == {} 