import json
import datetime
import subprocess # Clineのexecute_commandを模倣するため（実際はClineツールを使う）
import os # Clineのwrite_to_file, read_fileを模倣するため（実際はClineツールを使う）

LOG_FILE = "agent_log.txt"

def log_message(message):
    """ログファイルにメッセージを追記する"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    full_message = f"[{timestamp}] {message}\n"
    # ここでは標準出力とファイル書き込みを行う（Cline環境では不要になる想定）
    print(full_message.strip())
    # --- Cline環境では以下のファイル書き込みは不要 ---
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(full_message)
    except Exception as e:
        print(f"Error writing to log file: {e}")
    # --- ここまで ---

def plan(task_description: str) -> list:
    """
    タスク記述に基づいて実行ステップのリストを作成する（シンプルなルールベース）。
    現時点では以下の形式に対応:
    1. "'ファイル名'を作成し、'内容'と書き込む"
    2. "'入力ファイル'の内容を読み取り、'出力ファイル'にコピーする"
    """
    log_message(f"Planning task: {task_description}")
    steps = []
    try:
        # 形式1: ファイル作成と書き込み
        if "を作成し、" in task_description and "と書き込む" in task_description:
            parts = task_description.split("を作成し、")
            file_part = parts[0].strip()
            content_part = parts[1].split("と書き込む")[0].strip().strip("'")
            if file_part and content_part:
                steps.append({
                    "id": "write_step", # ステップIDを追加
                    "tool": "write_to_file",
                    "args": {
                        "path": file_part,
                        "content": content_part
                    },
                    "description": f"Write '{content_part}' to {file_part}"
                })
        # 形式2: ファイル読み取りとコピー
        elif "の内容を読み取り、" in task_description and "にコピーする" in task_description:
            parts = task_description.split("の内容を読み取り、")
            read_file_part = parts[0].strip()
            write_file_part = parts[1].split("にコピーする")[0].strip()
            if read_file_part and write_file_part:
                steps.append({
                    "id": "read_step", # ステップIDを追加
                    "tool": "read_file",
                    "args": {"path": read_file_part},
                    "description": f"Read content from {read_file_part}"
                })
                steps.append({
                    "id": "copy_step", # ステップIDを追加
                    "tool": "write_to_file",
                    "args": {
                        "path": write_file_part,
                        # 読み取った内容を使うことを示すプレースホルダー
                        "content": "{read_step_output}"
                    },
                    "description": f"Copy content to {write_file_part}",
                    "dependencies": ["read_step"] # 依存関係を追加
                })
        else:
            log_message(f"Could not parse task description: {task_description}")

    except Exception as e:
        log_message(f"Error during planning: {e}")

    log_message(f"Generated plan: {steps}")
    return steps

def execute(steps: list) -> list:
    """
    実行ステップのリストを受け取り、順番に実行する。
    ステップ間のデータ連携（メモリ）と read_file ツール（模倣）を追加。
    """
    results = []
    memory = {} # ステップ間のデータ保持用
    log_message(f"Executing {len(steps)} steps...")

    # TODO: 依存関係に基づいて実行順序を決定するロジックを追加 (現在はリスト順)
    for i, step in enumerate(steps):
        step_id = step.get("id", f"step_{i+1}")
        log_message(f"Executing step {i+1}/{len(steps)} (ID: {step_id}): {step.get('description', step['tool'])}")
        tool_name = step.get("tool")
        args = step.get("args", {}).copy() # 引数をコピーして変更可能にする
        step_result = {
            "step": i + 1,
            "id": step_id,
            "tool": tool_name,
            "args": args, # 元の引数も記録
            "status": "pending",
            "output": None,
            "error": None
        }

        try:
            # 引数内のプレースホルダーをメモリの値で置換
            for key, value in args.items():
                if isinstance(value, str) and value.startswith("{") and value.endswith("}"):
                    placeholder = value[1:-1] # {} を削除
                    if placeholder.endswith("_output") and placeholder[:-7] in memory:
                         # 例: {read_step_output} -> memory['read_step']
                        args[key] = memory.get(placeholder[:-7])
                    elif placeholder in memory:
                        args[key] = memory.get(placeholder)

            if tool_name == "write_to_file":
                path = args.get("path")
                content = args.get("content")
                if path is not None and content is not None:
                    # --- Cline write_to_file 実行部分 (模倣) ---
                    dir_path = os.path.dirname(path)
                    if dir_path and not os.path.exists(dir_path):
                        os.makedirs(dir_path, exist_ok=True)
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(str(content)) # contentがNoneでないことを保証
                    step_result["status"] = "success"
                    step_result["output"] = f"Successfully wrote to {path}"
                    memory[step_id] = step_result["output"] # 結果をメモリに保存
                    log_message(f"Step {i+1} success: {step_result['output']}")
                    # --- ここまで ---
                else:
                    # contentがNoneの場合もエラーとする
                    raise ValueError("Missing 'path' or valid 'content' for write_to_file")

            elif tool_name == "read_file":
                path = args.get("path")
                if path is not None:
                    # --- Cline read_file 実行部分 (模倣) ---
                    # 実際にはClineの <read_file> ツールを使用する
                    if os.path.exists(path):
                        with open(path, "r", encoding="utf-8") as f:
                            file_content = f.read()
                        step_result["status"] = "success"
                        step_result["output"] = file_content
                        memory[step_id] = file_content # 結果をメモリに保存
                        log_message(f"Step {i+1} success: Read {len(file_content)} characters from {path}")
                    else:
                        raise FileNotFoundError(f"File not found: {path}")
                    # --- ここまで ---
                else:
                    raise ValueError("Missing 'path' for read_file")

            # --- 他のClineツール (execute_command) の呼び出しをここに追加 ---
            # elif tool_name == "execute_command":
            #     # Cline <execute_command> 呼び出し
            # --- ここまで ---

            else:
                raise NotImplementedError(f"Tool '{tool_name}' is not implemented yet.")

        except Exception as e:
            step_result["status"] = "error"
            step_result["error"] = f"{type(e).__name__}: {e}"
            memory[step_id] = None # エラー時はNoneをメモリに保存
            log_message(f"Step {i+1} error: {step_result['error']}")

        results.append(step_result)

    log_message("Execution finished.")
    return results

# スクリプトが直接実行された場合にのみ以下のコードを実行
if __name__ == "__main__":
    # フェーズ3のテストタスク (エラー発生)
    # task = "output.txtを作成し、'Hello from Agent!'と書き込む" # フェーズ1
    # task = "input.txtの内容を読み取り、output.txtにコピーする" # フェーズ2
    task = "non_existent_input.txtの内容を読み取り、error_output.txtにコピーする" # フェーズ3

    log_message("--- Starting Agent ---")

    # 1. 計画
    plan_steps = plan(task)

    # 2. 実行
    if plan_steps:
        execution_results = execute(plan_steps)
        log_message("--- Execution Results ---")
        # 結果をJSON形式で整形してログに出力
        log_message(json.dumps(execution_results, indent=2, ensure_ascii=False))
    else:
        log_message("No plan generated. Exiting.")

    log_message("--- Agent Finished ---")
