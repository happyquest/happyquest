from typing import Dict, Any, List
from .base import BaseAgent
from langchain.prompts import ChatPromptTemplate
from langchain.schema import HumanMessage, SystemMessage
from langchain.tools import Tool

EXECUTOR_SYSTEM_PROMPT = """あなたは優秀なタスク実行者です。
与えられたタスクを以下の手順で実行してください：

1. タスクの前提条件の確認
2. 必要なリソースの準備
3. 実行手順の最適化
4. タスクの実行
5. 結果の検証と報告

出力形式：
{
    "execution_summary": {
        "task_id": "タスクID",
        "status": "実行状態",
        "start_time": "開始時刻",
        "end_time": "終了時刻"
    },
    "steps": [
        {
            "step_id": "ステップID",
            "description": "実行内容",
            "status": "実行状態",
            "output": "出力結果",
            "error": "エラー情報（該当する場合）"
        },
        ...
    ],
    "results": {
        "success": 成功/失敗,
        "artifacts": ["成果物1", "成果物2", ...],
        "metrics": {
            "metric1": 値1,
            "metric2": 値2,
            ...
        }
    }
}
"""

class ExecutorAgent(BaseAgent):
    """タスクを実行するエージェント"""
    
    def __init__(self, model, tools: List[Tool]):
        prompt_template = ChatPromptTemplate.from_messages([
            ("system", EXECUTOR_SYSTEM_PROMPT),
            ("human", "{input}")
        ])
        super().__init__(
            name="Executor",
            description="タスクを実行するエージェント",
            model=model,
            prompt_template=prompt_template
        )
        self.tools = tools

    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """タスクを実行し、結果を返す"""
        # 入力メッセージの作成
        messages = [
            SystemMessage(content=EXECUTOR_SYSTEM_PROMPT),
            HumanMessage(content=str(input_data["task"]))
        ]
        
        # タスクの実行
        try:
            # 適切なツールの選択と実行
            tool_name = input_data.get("tool", "default")
            tool = next((t for t in self.tools if t.name == tool_name), None)
            
            if tool:
                result = await tool.arun(input_data["task"])
            else:
                result = await self._generate_response(messages)
            
            status = "success"
            error = None
            
        except Exception as e:
            status = "error"
            result = str(e)
            error = {
                "type": type(e).__name__,
                "message": str(e)
            }
        
        # 状態の更新
        self.update_state(
            current_task=input_data["task"],
            task_status=status,
            artifacts={
                "result": result,
                "error": error
            }
        )
        
        return {
            "status": status,
            "result": result,
            "error": error,
            "agent_state": self.get_state()
        } 