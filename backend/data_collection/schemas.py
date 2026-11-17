import html
import re
from datetime import datetime
from pydantic import BaseModel, field_validator

class CollectionTriggerRequest(BaseModel):
    """Optional payload to run collection for specific boards."""
    greenhouse_boards: list[str] | None = None
    lever_boards: list[str] | None = None


class RawJob(BaseModel):
    source_name: str
    source_id: str | None = None
    source_url: str
    company_name: str
    raw_title: str
    raw_location: str | None = None
    description: str
    posted_at: datetime | None = None

    @field_validator("description", mode="before")
    @classmethod
    def strip_html_and_whitespace(cls, v: str | None) -> str:
        if not v:
            return ""
        # Unescape HTML entities first (e.g. &lt;p&gt; -> <p>)
        clean_text = html.unescape(str(v))
        # Remove HTML tags using regex
        clean_text = re.sub(r'<[^>]+>', ' ', clean_text)
        # Decode any residual entities and replace non-breaking spaces
        clean_text = html.unescape(clean_text).replace('\xa0', ' ')
        # Normalize whitespace (replace multiple spaces/newlines with a single space)
        return re.sub(r'\s+', ' ', clean_text).strip()

    @field_validator("source_url", mode="after")
    @classmethod
    def clean_url(cls, v: str) -> str:
        # Strip trailing slashes and query parameters to ensure exact DB deduplication works
        return str(v).strip().split('?')[0].rstrip('/')
        
    @field_validator("raw_title", "company_name", mode="after")
    @classmethod
    def clean_strings(cls, v: str) -> str:
        return v.strip()



