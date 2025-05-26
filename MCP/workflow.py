from typing import Dict, Any, List
from langchain_community.chat_models import ChatOpenAI
from langchain.tools import Tool
from agents.planner import PlannerAgent
from agents.researcher import ResearcherAgent
from agents.executor import ExecutorAgent
from agents.reviewer import ReviewerAgent
from langgraph.graph import StateGraph, END, START
from pydantic import BaseModel
import os

class WorkflowState(BaseModel):
    """ワークフローの状態を管理するクラス"""
    task: str = ""
    plan_result: Dict[str, Any] = {}
    research_result: Dict[str, Any] = {}
    execution_result: Dict[str, Any] = {}
    review_result: Dict[str, Any] = {}
    status: str = "pending"
    error: Dict[str, Any] = None

class MCPWorkflow:
    """MCPワークフローを管理するクラス"""
    
    def __init__(self, model_name: str = "gpt-4", tools: List[Tool] = None, model: ChatOpenAI = None):
        if model:
            self.model = model
        else:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable is not set")
            self.model = ChatOpenAI(model_name=model_name, openai_api_key=api_key)
        self.tools = tools or []
        
        # エージェントの初期化
        self.planner = PlannerAgent(self.model)
        self.researcher = ResearcherAgent(self.model, self.tools)
        self.executor = ExecutorAgent(self.model, self.tools)
        self.reviewer = ReviewerAgent(self.model)
        
        # ワークフローグラフの構築
        self.workflow = self._build_workflow()

    def _build_workflow(self) -> StateGraph:
        """ワークフローグラフを構築"""
        workflow = StateGraph(WorkflowState)
        
        # ノードの追加
        workflow.add_node("planning", self._run_planner)
        workflow.add_node("researching", self._run_researcher)
        workflow.add_node("executing", self._run_executor)
        workflow.add_node("reviewing", self._run_reviewer)
        workflow.add_node("error_handler", self._handle_error)
        
        # 開始点の定義
        workflow.add_edge(START, "planning")
        
        # 通常のエッジの定義
        workflow.add_edge("planning", "researching")
        workflow.add_edge("researching", "executing")
        workflow.add_edge("executing", "reviewing")
        workflow.add_edge("reviewing", END)
        
        # エラーエッジの定義
        def is_error(state: WorkflowState) -> str:
            return "error_handler" if state.status == "error" else None
        
        workflow.add_conditional_edges(
            "planning",
            is_error,
            {
                "error_handler": "error_handler",
                None: "researching"
            }
        )
        workflow.add_conditional_edges(
            "researching",
            is_error,
            {
                "error_handler": "error_handler",
                None: "executing"
            }
        )
        workflow.add_conditional_edges(
            "executing",
            is_error,
            {
                "error_handler": "error_handler",
                None: "reviewing"
            }
        )
        workflow.add_conditional_edges(
            "reviewing",
            is_error,
            {
                "error_handler": "error_handler",
                None: END
            }
        )
        workflow.add_edge("error_handler", END)
        
        return workflow.compile()

    async def _run_planner(self, state: WorkflowState) -> WorkflowState:
        """プランナーエージェントを実行"""
        try:
            result = await self.planner.process({"task": state.task})
            state.plan_result = result["plan"]
            state.status = "planning_completed"
        except Exception as e:
            state.error = {"step": "planning", "error": str(e)}
            state.status = "error"
        return state

    async def _run_researcher(self, state: WorkflowState) -> WorkflowState:
        """リサーチャーエージェントを実行"""
        try:
            result = await self.researcher.process({"topic": state.task})
            state.research_result = result["research"]
            state.status = "research_completed"
        except Exception as e:
            state.error = {"step": "research", "error": str(e)}
            state.status = "error"
        return state

    async def _run_executor(self, state: WorkflowState) -> WorkflowState:
        """エグゼキューターエージェントを実行"""
        try:
            result = await self.executor.process({
                "task": state.task,
                "plan": state.plan_result,
                "research": state.research_result
            })
            state.execution_result = result["result"]
            state.status = "execution_completed"
        except Exception as e:
            state.error = {"step": "execution", "error": str(e)}
            state.status = "error"
        return state

    async def _run_reviewer(self, state: WorkflowState) -> WorkflowState:
        """レビューアーエージェントを実行"""
        try:
            result = await self.reviewer.process({
                "artifact": state.execution_result,
                "requirements": state.plan_result.get("requirements", []),
                "quality_criteria": state.plan_result.get("quality_criteria", [])
            })
            state.review_result = result["review"]
            state.status = "completed"
        except Exception as e:
            state.error = {"step": "review", "error": str(e)}
            state.status = "error"
        return state

    async def _handle_error(self, state: WorkflowState) -> WorkflowState:
        """エラーハンドリング"""
        if not state.error:
            state.error = {
                "type": "UnknownError",
                "message": "An unknown error occurred"
            }
        return state

    async def run(self, task: str) -> Dict[str, Any]:
        """ワークフローを実行"""
        initial_state = WorkflowState(task=task)
        final_state = await self.workflow.arun(initial_state)
        
        return {
            "task": final_state.task,
            "status": final_state.status,
            "results": {
                "plan": final_state.plan_result,
                "research": final_state.research_result,
                "execution": final_state.execution_result,
                "review": final_state.review_result
            },
            "error": final_state.error
        } 