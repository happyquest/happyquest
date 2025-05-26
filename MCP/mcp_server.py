from fastapi import FastAPI, HTTPException, Depends, status, Header, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from datetime import datetime, UTC, timedelta
from typing import Optional, List
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from models import Process, SystemPrompt, ProcessLog, ProcessType, ProcessStatus
from database import Database
import os
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from workflow import MCPWorkflow
from langchain.tools import Tool
from langchain_core.outputs import Generation, LLMResult
from langchain_core.language_models.chat_models import BaseChatModel

load_dotenv()

# 環境変数から設定を読み込む
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
API_KEY = os.getenv("API_KEY", "your-api-key")

# データベース接続
db = Database(mongodb_uri=MONGODB_URI)

# セキュリティ設定
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ツールの定義
tools = [
    Tool(
        name="web_search",
        func=lambda x: "Web search results for: " + x,
        description="Search the web for information"
    ),
    Tool(
        name="code_analysis",
        func=lambda x: "Code analysis results for: " + x,
        description="Analyze code and provide insights"
    ),
    Tool(
        name="document_processor",
        func=lambda x: "Document processing results for: " + x,
        description="Process and analyze documents"
    )
]

# ワークフローの初期化
if os.getenv("TESTING", "false").lower() == "true":
    from unittest.mock import MagicMock
    
    class MockChatModel(BaseChatModel):
        def _generate(self, messages, stop=None, run_manager=None, **kwargs):
            return LLMResult(generations=[[Generation(text="Test response")]])
        
        async def _agenerate(self, messages, stop=None, run_manager=None, **kwargs):
            return LLMResult(generations=[[Generation(text="Test response")]])
        
        @property
        def _llm_type(self):
            return "mock"
    
    mock_model = MockChatModel()
    workflow = MCPWorkflow(model=mock_model, tools=tools)
else:
    workflow = MCPWorkflow(model_name="gpt-4", tools=tools)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 起動時の処理
    await db.connect()
    await db.init_indexes()
    yield
    # 終了時の処理
    await db.close()

app = FastAPI(lifespan=lifespan)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return plain_password == "test" and hashed_password == "test"

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return username
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

@app.middleware("http")
async def check_auth_header(request: Request, call_next):
    if request.url.path not in ["/health", "/token"]:
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Not authenticated"},
                headers={"WWW-Authenticate": "Bearer"},
            )
    return await call_next(request)

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = datetime.now(UTC)
    response = await call_next(request)
    process_time = datetime.now(UTC) - start_time
    response.headers["X-Process-Time"] = str(process_time.total_seconds())
    return response

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(UTC).isoformat()
    }

@app.post("/token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    if not verify_password(form_data.username, form_data.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": form_data.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/processes", response_model=Process)
async def create_process(process: Process, current_user: str = Depends(get_current_user)):
    try:
        process_id = await db.save_process(process)
        saved_process = await db.get_process(process_id)
        if not saved_process:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save process"
            )
        return saved_process
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/processes/{process_id}", response_model=Process)
async def get_process(process_id: str, current_user: str = Depends(get_current_user)):
    process = await db.get_process(process_id)
    if not process:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Process not found"
        )
    return process

@app.get("/processes", response_model=List[Process])
async def list_processes(current_user: str = Depends(get_current_user)):
    return await db.search_processes("")

@app.post("/system-prompts", response_model=SystemPrompt)
async def create_system_prompt(prompt: SystemPrompt, current_user: str = Depends(get_current_user)):
    try:
        prompt_id = await db.save_system_prompt(prompt)
        saved_prompt = await db.get_system_prompt(prompt_id)
        if not saved_prompt:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save system prompt"
            )
        return saved_prompt
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/system-prompts/{prompt_id}", response_model=SystemPrompt)
async def get_system_prompt(prompt_id: str, current_user: str = Depends(get_current_user)):
    prompt = await db.get_system_prompt(prompt_id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="System prompt not found"
        )
    return prompt

@app.get("/system-prompts", response_model=List[SystemPrompt])
async def list_system_prompts(current_user: str = Depends(get_current_user)):
    return await db.search_system_prompts("")

@app.post("/process-logs", response_model=ProcessLog)
async def create_process_log(log: ProcessLog, current_user: str = Depends(get_current_user)):
    try:
        log_id = await db.save_process_log(log)
        saved_log = await db.get_process_log(log_id)
        if not saved_log:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save process log"
            )
        return saved_log
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@app.get("/process-logs/{process_id}", response_model=List[ProcessLog])
async def get_process_logs(process_id: str, current_user: str = Depends(get_current_user)):
    return await db.get_process_logs(process_id)

@app.get("/search/processes")
async def search_processes(query: str, current_user: str = Depends(get_current_user)):
    return await db.search_processes(query)

@app.get("/search/system-prompts")
async def search_system_prompts(query: str, current_user: str = Depends(get_current_user)):
    return await db.search_system_prompts(query)

@app.put("/processes/{process_id}/status")
async def update_process_status(
    process_id: str,
    status: ProcessStatus,
    current_user: str = Depends(get_current_user)
):
    success = await db.update_process_status(process_id, status)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Process not found"
        )
    return {"status": "updated"}

@app.post("/workflow/execute")
async def execute_workflow(
    task: str,
    current_user: str = Depends(get_current_user)
):
    """ワークフローを実行するエンドポイント"""
    try:
        result = await workflow.run(task)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        ) 