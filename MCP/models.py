from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

class ProcessStatus(str, Enum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILURE = "failure"
    IN_PROGRESS = "in_progress"

class ProcessType(str, Enum):
    INSTALLATION = "installation"
    CONFIGURATION = "configuration"
    DEPLOYMENT = "deployment"
    TESTING = "testing"
    SCRAPING = "scraping"

class Process(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    name: str
    type: ProcessType
    description: str
    steps: List[Dict[str, Any]]
    status: ProcessStatus
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    error_message: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class SystemPrompt(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    name: str
    content: str
    category: str
    tags: List[str]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = None

class ProcessLog(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    process_id: str
    step_number: int
    status: ProcessStatus
    message: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    error_details: Optional[Dict[str, Any]] = None
    metadata: Optional[Dict[str, Any]] = None 