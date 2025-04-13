from typing import Dict, Any, List
from .base import BaseAgent
from langchain.prompts import ChatPromptTemplate
from langchain.schema import HumanMessage, SystemMessage

REVIEWER_SYSTEM_PROMPT = """あなたは優秀なレビューアーです。
提出された成果物を以下の観点で評価してください：

1. 要件との適合性
2. 品質基準の達成度
3. エラーや問題点の特定
4. 改善提案の作成
5. 総合評価の決定

出力形式：
{
    "review_summary": {
        "artifact_id": "成果物ID",
        "review_date": "レビュー日時",
        "reviewer": "レビューアー名"
    },
    "evaluation": {
        "requirements_compliance": {
            "score": 評価スコア(1-5),
            "comments": ["コメント1", "コメント2", ...]
        },
        "quality_assessment": {
            "score": 評価スコア(1-5),
            "findings": ["発見事項1", "発見事項2", ...]
        },
        "issues": [
            {
                "severity": "重要度",
                "description": "問題の説明",
                "recommendation": "改善提案"
            },
            ...
        ]
    },
    "overall_rating": {
        "score": 総合評価スコア(1-5),
        "decision": "判定結果",
        "next_steps": ["次のステップ1", "次のステップ2", ...]
    }
}
"""

class ReviewerAgent(BaseAgent):
    """成果物のレビューを行うエージェント"""
    
    def __init__(self, model):
        prompt_template = ChatPromptTemplate.from_messages([
            ("system", REVIEWER_SYSTEM_PROMPT),
            ("human", "{input}")
        ])
        super().__init__(
            name="Reviewer",
            description="成果物のレビューを行うエージェント",
            model=model,
            prompt_template=prompt_template
        )

    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """成果物をレビューし、評価結果を返す"""
        # 入力メッセージの作成
        artifact = input_data["artifact"]
        requirements = input_data.get("requirements", [])
        quality_criteria = input_data.get("quality_criteria", [])
        
        review_input = {
            "artifact": artifact,
            "requirements": requirements,
            "quality_criteria": quality_criteria
        }
        
        messages = [
            SystemMessage(content=REVIEWER_SYSTEM_PROMPT),
            HumanMessage(content=str(review_input))
        ]
        
        # レビューの実行
        response = await self._generate_response(messages)
        
        # 状態の更新
        self.update_state(
            current_task=f"Review of {input_data.get('artifact_id', 'unknown')}",
            task_status="review_completed",
            artifacts={"review": response}
        )
        
        return {
            "status": "success",
            "review": response,
            "agent_state": self.get_state()
        } 