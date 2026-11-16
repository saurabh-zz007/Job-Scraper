"""
Data Collection models module.
Per project architecture requirements, the primary Job model and its ETL states
are centralized in `core.models`.
"""

from core.models import Job, JobStatus

__all__ = ["Job", "JobStatus"]

