from typing import Dict, Any, List
from abc import ABC, abstractmethod
from langchain.schema import BaseMessage
from langchain_community.chat_models import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

class AgentState(BaseModel):
    """エージェントの状態を管理するクラス"""
    messages: List[BaseMessage] = Field(default_factory=list)
    current_task: str = ""
    task_status: str = "pending"
    artifacts: Dict[str, Any] = Field(default_factory=dict)

class BaseAgent(ABC):
    """基本エージェントクラス"""
    def __init__(
        self,
        name: str,
        description: str,
        model: ChatOpenAI,
        prompt_template: ChatPromptTemplate
    ):
        self.name = name
        self.description = description
        self.model = model
        self.prompt_template = prompt_template
        self.state = AgentState()

    @abstractmethod
    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """入力データを処理し、結果を返す"""
        pass

    async def _generate_response(self, messages: List[BaseMessage]) -> str:
        """LLMを使用してレスポンスを生成"""
        response = await self.model.agenerate([messages])
        return response.generations[0][0].text

    def update_state(self, **kwargs):
        """エージェントの状態を更新"""
        for key, value in kwargs.items():
            if hasattr(self.state, key):
                setattr(self.state, key, value)

    def get_state(self) -> Dict[str, Any]:
        """現在の状態を取得"""
        return self.state.dict()

    def reset_state(self):
        """状態をリセット"""
        self.state = AgentState() 