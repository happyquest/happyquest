import json
import datetime
import os
import google.generativeai as genai
import textwrap # for dedenting prompts
import subprocess # For execute_command simulation
import time # For potential retries

LOG_FILE = "gemini_agent_v2_log.txt" # Use a new log file
MAX_ITERATIONS = 3 # Limit the number of plan-execute-improve cycles

# --- Gemini API Key Configuration ---
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise ValueError("エラー: 環境変数 GOOGLE_API_KEY が設定されていません。")

genai.configure(api_key=API_KEY)

# --- Available Tools Definition (Simulated Cline Tools) ---
AVAILABLE_TOOLS = [
    {
        "name": "read_file",
        "description": "指定されたパスのファイルの内容を読み取る。",
        "parameters": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "読み取るファイルのパス"}
            },
            "required": ["path"]
        }
    },
    {
        "name": "write_to_file",
        "description": "指定されたパスに指定された内容を書き込む。ファイルが存在しない場合は作成される。",
        "parameters": {
            "type": "object",
            "properties": {
                "path": {"type": "string", "description": "書き込むファイルのパス"},
                "content": {"type": "string", "description": "書き込む内容"}
            },
            "required": ["path", "content"]
        }
    },
    {
        "name": "execute_command",
        "description": "指定されたシェルコマンドを実行する。",
        "parameters": {
            "type": "object",
            "properties": {
                "command": {"type": "string", "description": "実行するシェルコマンド"}
            },
            "required": ["command"]
        }
    },
    # { # Example for adding search_files later
    #     "name": "search_files",
    #     "description": "指定されたディレクトリ内のファイルを正規表現で検索する。",
    #     "parameters": { ... }
    # }
]

# --- System Prompts ---
PLANNER_PROMPT = textwrap.dedent("""
あなたは優秀なAIプランナーです。ユーザーのタスク要求を分析し、それを達成するために利用可能なツールを使って実行可能なステップのシーケンスに分解してください。

**制約:**
- 利用可能なツールのみを使用してください。
- 各ステップは、単一のツール呼び出しに対応する必要があります。
- ステップ間の依存関係を考慮してください。前のステップの出力が必要な場合は、`args` 内で `{ステップID}_output` の形式で参照してください。 (例: `"content": "{step_1_output}"`)
- 出力は必ず以下のJSON形式に従ってください。他のテキストは含めないでください。

**利用可能なツール:**
{tools_json}

**タスク:**
{task_description}

**出力形式 (JSON):**
```json
[
  {{
    "id": "ユニークなステップID (例: step_1)",
    "tool": "使用するツール名 (例: read_file)",
    "args": {{ "引数名1": "値1", "引数名2": "{{step_0_output}}", ... }},
    "description": "このステップの簡単な説明",
    "dependencies": ["依存するステップIDのリスト (例: [step_0])"] // 依存がない場合は空リスト
  }},
  ...
]
```
""")

IMPROVER_PROMPT = textwrap.dedent("""
あなたは経験豊富なAIデバッガー兼改善提案者です。以下のタスク実行結果を分析し、問題点、原因、そして具体的な改善策（次の計画に反映できる形式）を提案してください。

**分析対象:**
- 元のタスク: {task_description}
- 実行計画: {plan_json}
- 実行結果ログ: {execution_log_json}

**分析の観点:**
- 計画はタスクを達成するために適切でしたか？
- 各ステップは正しく実行されましたか？ エラーやスキップはありましたか？
- エラーが発生した場合、その根本原因は何ですか？ (計画の不備、ツールの誤用、外部要因など)
- 計画やツールの使い方に改善点はありますか？ (例: より効率的なツールの組み合わせ、エラーハンドリングの追加など)
- タスク達成のために、計画をどのように修正すべきですか？ 修正が必要ない場合はその旨を述べてください。

**出力形式:**
```text
分析結果:
(問題点の詳細な分析。エラーが発生したステップ、予期せぬ結果などを具体的に指摘)

原因:
(考えられる根本原因)

改善提案:
(具体的な改善策や代替アプローチ。可能であれば、修正後の計画ステップや、次の試行で考慮すべき点を記述。改善不要の場合は「改善不要」と記述)
```
""")

# --- Helper Functions ---
def log_message(message):
    """ログファイルにメッセージを追記する"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(message, (dict, list)):
        log_content = json.dumps(message, indent=2, ensure_ascii=False)
    else:
        log_content = str(message)
    full_message = f"[{timestamp}] {log_content}\n"
    print(full_message.strip())
    try:
        # ログファイルがなければ作成
        if not os.path.exists(LOG_FILE):
            with open(LOG_FILE, "w", encoding="utf-8") as f: f.write("")
        with open(LOG_FILE, "a", encoding="utf-8") as f: f.write(full_message)
    except Exception as e:
        print(f"Error writing to log file: {e}")

def call_gemini(prompt: str, model_name="gemini-1.5-pro-latest") -> str:
    """Gemini APIを呼び出して応答を取得する"""
    log_message(f"Calling Gemini API (Model: {model_name})...")
    try:
        safety_settings = [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
        ]
        model = genai.GenerativeModel(model_name, safety_settings=safety_settings)
        response = model.generate_content(prompt)

        if response.candidates:
             candidate = response.candidates[0]
             if candidate.content and candidate.content.parts:
                 log_message("Gemini API call successful.")
                 return candidate.content.parts[0].text
             else:
                 finish_reason = candidate.finish_reason.name if hasattr(candidate, 'finish_reason') and candidate.finish_reason else "UNKNOWN"
                 log_message(f"Gemini API response candidate had no parts. Finish Reason: {finish_reason}")
                 safety_ratings = candidate.safety_ratings if hasattr(candidate, 'safety_ratings') else []
                 safety_issues = [f"{r.category.name}: {r.probability.name}" for r in safety_ratings if hasattr(r, 'probability') and r.probability.name != "NEGLIGIBLE"]
                 if safety_issues:
                     safety_msg = ", ".join(safety_issues)
                     log_message(f"Safety issues detected: {safety_msg}")
                     return f"Error: Content blocked by safety settings ({safety_msg})"
                 return f"Error: No text content in Gemini response candidate (Finish Reason: {finish_reason})."
        else:
            if hasattr(response, 'prompt_feedback') and response.prompt_feedback.block_reason:
                 block_reason = response.prompt_feedback.block_reason.name if hasattr(response.prompt_feedback.block_reason, 'name') else "UNKNOWN"
                 log_message(f"Content blocked due to: {block_reason}")
                 return f"Error: Content blocked by safety settings ({block_reason})"
            log_message("Gemini API response did not contain text or candidates.")
            log_message(f"Full Gemini Response: {response}")
            return "Error: Unknown issue with Gemini response."

    except Exception as e:
        log_message(f"Error calling Gemini API: {type(e).__name__}: {e}")
        return f"Error calling Gemini API: {type(e).__name__}: {e}"


def parse_json_from_gemini(response_text: str) -> list | dict | None:
    """Geminiの応答からJSON部分を抽出してパースする"""
    try:
        json_match = response_text.split('```json\n')
        if len(json_match) > 1:
            json_str = json_match[1].split('\n```')[0]
            return json.loads(json_str)
        else:
            try:
                return json.loads(response_text)
            except json.JSONDecodeError:
                 log_message("Response is not a JSON block and not valid JSON itself.")
                 log_message(f"Response text was:\n{response_text}")
                 return None
    except json.JSONDecodeError as e:
        log_message(f"Failed to parse JSON from Gemini response: {e}")
        log_message(f"Response text was:\n{response_text}")
        return None
    except Exception as e:
        log_message(f"An unexpected error occurred during JSON parsing: {e}")
        log_message(f"Response text was:\n{response_text}")
        return None

# --- Core Agent Functions ---
def plan(task_description: str) -> list | None:
    """Gemini APIを使ってタスクの実行計画を生成する"""
    log_message(f"--- Planning Task ---")
    log_message(f"Task: {task_description}")
    tools_json = json.dumps(AVAILABLE_TOOLS, indent=2, ensure_ascii=False)
    prompt = PLANNER_PROMPT.format(tools_json=tools_json, task_description=task_description)

    response_text = call_gemini(prompt)
    if response_text.startswith("Error:"):
        log_message(f"Planning failed due to Gemini API error: {response_text}")
        return None

    plan_steps = parse_json_from_gemini(response_text)

    if isinstance(plan_steps, list):
        log_message(f"Generated plan:")
        log_message(plan_steps)
        return plan_steps
    else:
        log_message("Planning failed: Could not generate a valid plan list from Gemini response.")
        return None

def execute(steps: list) -> list:
    """
    計画されたステップを実行する。
    Clineツールの呼び出しは模倣し、実行指示をログに出力する。
    """
    results = []
    memory = {} # ステップ間のデータ保持用 (ステップID -> 出力結果 or None)
    log_message(f"--- Executing Plan ({len(steps)} steps) ---")

    for i, step in enumerate(steps):
        step_id = step.get("id", f"step_{i+1}")
        log_message(f"--- Executing Step {i+1}/{len(steps)} (ID: {step_id}) ---")
        log_message(f"Description: {step.get('description', 'N/A')}")
        tool_name = step.get("tool")
        args = step.get("args", {}).copy()

        step_result = {
            "step": i + 1, "id": step_id, "tool": tool_name, "args": args,
            "resolved_args": {}, "status": "pending", "output": None,
            "error": None, "skipped": False
        }

        if not tool_name:
             log_message(f"Skipping step {step_id} because 'tool' is missing.")
             step_result.update({"status": "skipped", "error": "Tool name missing", "skipped": True})
             results.append(step_result)
             memory[step_id] = None
             continue

        try:
            # 依存関係の解決
            dependencies = step.get("dependencies", [])
            can_execute = True
            log_message(f"Checking dependencies: {dependencies}")
            for dep_id in dependencies:
                if dep_id not in memory:
                    step_result.update({"status": "skipped", "error": f"Dependency '{dep_id}' result not found", "skipped": True})
                    can_execute = False; break
                if memory[dep_id] is None:
                    step_result.update({"status": "skipped", "error": f"Dependency '{dep_id}' failed/skipped", "skipped": True})
                    can_execute = False; break

            if not can_execute:
                results.append(step_result)
                memory[step_id] = None
                continue

            # 引数プレースホルダー置換
            resolved_args = args.copy()
            for key, value in args.items():
                 if isinstance(value, str) and value.startswith("{") and value.endswith("}"):
                    placeholder = value[1:-1]
                    if placeholder.endswith("_output"):
                        dep_id = placeholder[:-7]
                        if dep_id in memory and memory[dep_id] is not None:
                            resolved_args[key] = memory[dep_id]
                            log_message(f"Resolved placeholder '{value}' using output from step '{dep_id}'.")
                        else:
                            raise ValueError(f"Could not resolve placeholder '{value}': Dependency '{dep_id}' result not found or is None.")
                    # else: # Ignore non-output placeholders

            step_result["resolved_args"] = resolved_args
            log_message(f"Tool: {tool_name}")
            log_message(f"Arguments (resolved):")
            log_message(resolved_args)

            # --- Cline Tool Execution Simulation ---
            output_from_tool = None

            if tool_name == "write_to_file":
                path = resolved_args.get("path")
                content = resolved_args.get("content")
                if path is not None and content is not None:
                    content_str = str(content) # Ensure content is string
                    log_message(f"[SIMULATE] Would call Cline: <write_to_file><path>{path}</path><content>...
