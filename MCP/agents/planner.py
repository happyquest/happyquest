from typing import Dict, Any, List
from .base import BaseAgent
from langchain.prompts import ChatPromptTemplate
from langchain.schema import HumanMessage, SystemMessage

PLANNER_SYSTEM_PROMPT = """あなたは優秀なプロジェクトプランナーです。
与えられたタスクを以下の手順で分析し、実行可能なサブタスクに分解してください：

1. タスクの目的と要件を分析
2. 必要なリソースと制約条件の特定
3. サブタスクへの分解と依存関係の特定
4. 各サブタスクの優先順位付け
5. 実行スケジュールの提案

出力形式：
{
    "analysis": {
        "purpose": "タスクの目的",
        "requirements": ["要件1", "要件2", ...],
        "constraints": ["制約1", "制約2", ...]
    },
    "subtasks": [
        {
            "id": "サブタスクID",
            "name": "サブタスク名",
            "description": "詳細説明",
            "priority": 優先度(1-5),
            "dependencies": ["依存するサブタスクID", ...],
            "estimated_time": "見積時間"
        },
        ...
    ],
    "schedule": {
        "total_estimated_time": "合計見積時間",
        "recommended_sequence": ["サブタスクID", ...]
    }
}
"""

class PlannerAgent(BaseAgent):
    """タスクの分析と計画を行うエージェント"""
    
    def __init__(self, model):
        prompt_template = ChatPromptTemplate.from_messages([
            ("system", PLANNER_SYSTEM_PROMPT),
            ("human", "{input}")
        ])
        super().__init__(
            name="Planner",
            description="タスクの分析と計画を行うエージェント",
            model=model,
            prompt_template=prompt_template
        )

    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """タスクを分析し、実行計画を生成"""
        # 入力メッセージの作成
        messages = [
            SystemMessage(content=PLANNER_SYSTEM_PROMPT),
            HumanMessage(content=input_data["task"])
        ]
        
        # プランの生成
        response = await self._generate_response(messages)
        
        # 状態の更新
        self.update_state(
            current_task=input_data["task"],
            task_status="planning_completed",
            artifacts={"plan": response}
        )
        
        return {
            "status": "success",
            "plan": response,
            "agent_state": self.get_state()
        } 