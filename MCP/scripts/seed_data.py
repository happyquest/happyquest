import asyncio
from database import Database
from models import Process, SystemPrompt, ProcessLog, ProcessStatus, ProcessType
from datetime import datetime

async def seed_data():
    db = Database()
    await db.init_indexes()

    # テストプロセスの作成
    process = Process(
        name="VeyraXインストール",
        type=ProcessType.INSTALLATION,
        description="VeyraXのインストール手順",
        steps=[
            {
                "step": 1,
                "command": "git clone https://github.com/your-org/veyrax.git",
                "description": "リポジトリのクローン"
            },
            {
                "step": 2,
                "command": "cd veyrax && pip install -r requirements.txt",
                "description": "依存関係のインストール"
            },
            {
                "step": 3,
                "command": "python setup.py install",
                "description": "パッケージのインストール"
            }
        ],
        status=ProcessStatus.SUCCESS
    )
    process_id = await db.save_process(process)

    # テストシステムプロンプトの作成
    prompt = SystemPrompt(
        name="VeyraXインストールガイド",
        content="""
# VeyraXインストールガイド

## 前提条件
- Python 3.8以上
- Git
- pip

## インストール手順
1. リポジトリのクローン
2. 依存関係のインストール
3. パッケージのインストール

## トラブルシューティング
- 依存関係のエラー: requirements.txtの内容を確認
- インストールエラー: Pythonバージョンを確認
        """,
        category="インストール",
        tags=["veyrax", "インストール", "セットアップ", "ガイド"]
    )
    prompt_id = await db.save_system_prompt(prompt)

    # テストプロセスログの作成
    logs = [
        ProcessLog(
            process_id=process_id,
            step_number=1,
            status=ProcessStatus.SUCCESS,
            message="リポジトリのクローンが完了しました"
        ),
        ProcessLog(
            process_id=process_id,
            step_number=2,
            status=ProcessStatus.SUCCESS,
            message="依存関係のインストールが完了しました"
        ),
        ProcessLog(
            process_id=process_id,
            step_number=3,
            status=ProcessStatus.SUCCESS,
            message="パッケージのインストールが完了しました"
        )
    ]

    for log in logs:
        await db.save_process_log(log)

    print("テストデータの投入が完了しました")

if __name__ == "__main__":
    asyncio.run(seed_data()) 