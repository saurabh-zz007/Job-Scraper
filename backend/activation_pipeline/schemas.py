from datetime import datetime
from pydantic import BaseModel, ConfigDict


class CompanySeedItem(BaseModel):
    company: str
    ats: str


class CompanyTargetRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    company: str
    ats: str
    created_at: datetime