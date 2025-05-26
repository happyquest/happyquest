from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import Tool
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_community.chat_models import ChatOpenAI
from langchain.agents import AgentExecutor, create_structured_chat_agent
from typing import List, Dict, Any
from .base import BaseAgent

RESEARCHER_SYSTEM_PROMPT = """
あなたは情報収集と分析を行うエージェントです。
以下のステップで情報を収集し、分析を行ってください：

1. 与えられたトピックに関連する情報を収集
2. 収集した情報を整理・分析
3. 重要なポイントを抽出
4. 結論をまとめる

出力フォーマット：
{
    "collected_info": [収集した情報のリスト],
    "analysis": "分析結果",
    "key_points": [重要なポイントのリスト],
    "conclusion": "結論"
}
"""

class ResearcherAgent(BaseAgent):
    """情報収集と分析を行うエージェント"""
    
    def __init__(self, model, tools: List[Tool]):
        # ツール名とツールの説明を取得
        tool_names = [tool.name for tool in tools]
        tool_descriptions = [f"{tool.name}: {tool.description}" for tool in tools]
        
        # プロンプトテンプレートを作成
        prompt = ChatPromptTemplate.from_messages([
            ("system", RESEARCHER_SYSTEM_PROMPT + "\n\nAvailable tools:\n" + "\n".join(tool_descriptions)),
            ("human", "{input}\n\nTools: {tools}\nTool names: {tool_names}"),
            ("ai", "{agent_scratchpad}")
        ])
        
        # 親クラスの初期化
        super().__init__(
            name="Researcher",
            description="情報収集と分析を行うエージェント",
            model=model,
            prompt_template=prompt
        )
        
        # エージェントを作成
        agent = create_structured_chat_agent(
            llm=model,
            tools=tools,
            prompt=prompt
        )
        
        self.agent_executor = AgentExecutor(
            agent=agent,
            tools=tools,
            verbose=True,
            handle_parsing_errors=True
        )

    async def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        入力データを処理し、結果を返す

        Args:
            input_data (Dict[str, Any]): 処理する入力データ

        Returns:
            Dict[str, Any]: 処理結果
        """
        result = await self.agent_executor.ainvoke(input_data)
        return result 