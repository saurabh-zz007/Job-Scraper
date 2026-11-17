import re
import logging

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from core.models import Job

logger = logging.getLogger(__name__)

class Filtering:
    def __init__(self, db_session: AsyncSession):
        self.db_session=db_session
        self._title_fresher_pattern = re.compile(
            r"""
            \b(?:
                intern(?:s|ship(?:s)?)? |
                co[-\s]?op(?:s)? |
                summer\s+(?:intern|analyst|associate) |
                off[-\s]?cycle\s+intern |
                industrial\s+placement |
                year\s+in\s+industry |
                new\s+grad(?:uate)?(?:s)? |
                recent\s+graduate(?:s)? |
                graduate\s+(?:scheme|program(?:me)?|engineer\s+trainee|apprentice|trainee) |
                early\s+career |
                entry[-\s]?level |
                junior |
                jr\.? |
                fresher(?:s)? |
                trainee(?:s|ship)? |
                apprentice(?:s|ship)? |
                sde[\s-]*(?:1|i) |
                sdet(?:\s+intern)? |
                software\s+(?:development\s+)?engineer[\s-]*(?:1|i) |
                engineer[\s-]*(?:1|i) |
                developer[\s-]*(?:1|i) |
                analyst[\s-]*(?:1|i) |
                associate\s+(?:software\s+engineer|consultant|analyst)
            )\b
            """,
            re.IGNORECASE | re.VERBOSE,
        )
        self._desc_fresher_pattern = re.compile(
            r"""
            \b(?:
                0[\s-]*(?:to[\s-]*)?[12]\s*(?:year|yr)s? |
                less\s+than\s+(?:1|one)\s+year |
                no\s+(?:prior\s+)?experience\s+required |
                freshers?\s+(?:can\s+apply|welcome|eligible) |
                campus\s+(?:placement|drive|hiring) |
                off[-\s]?campus\s+(?:drive|hiring) |
                pre[-\s]?placement\s+offer |
                ppo
            )\b
            """,
            re.IGNORECASE | re.VERBOSE,
        )
        self._title_exclude_pattern = re.compile(
            r"\b(?:senior|sr\.?|lead|principal|staff|manager|director|vp|vice\s+president|head\s+of|architect|executive|counsel|phd|[3-9]\+?\s*years)\b",
            re.IGNORECASE,
        )


    def _deterministic_filter(self, job_data)-> bool|None:
        title = job_data.get("raw_title")
        description = job_data.get("description")

        if self._title_exclude_pattern.search(title):
            return False

        if self._title_fresher_pattern.search(title):
            return True

        if self._desc_fresher_pattern.search(description):
            return True

        return False

    def _semantic_classification(self, job_data)-> bool:
        #TODO: Impliment LLM based classification for uncertain cases, Default set to false so that no uncertain job enters into the DB
        return False

    def _is_fresher_or_intern(self, job_data)->bool:
        return self._deterministic_filter(job_data) or self._semantic_classification(job_data)

    async def _is_duplicate(self, job_data)->bool:
        #TODO: Make this more efficient using hashing/vectorDB for similar titles    
        source_url = job_data.get("source_url")
        company_name = job_data.get("company_name")
        raw_title = job_data.get("raw_title")
        raw_location = job_data.get("raw_location")

        conditions = []
        if source_url:
            conditions.append(Job.source_url == source_url)
        if company_name:
            conditions.append(Job.company_name == company_name)
        if raw_title:
            conditions.append(Job.raw_title == raw_title)
        if raw_location:
            conditions.append(Job.raw_location == raw_location)

        if not conditions:
            return False

        stmt = select(Job.id).where(and_(*conditions)).limit(1)
        result = await self.db_session.execute(stmt)

        return result.scalar_one_or_none() is not None

    async def is_valid_job(self, job_data)->bool:
        title = job_data.get("raw_title", "Unknown Title")

        # Gate 1: Fresher / Internship role check
        if not self._is_fresher_or_intern(job_data):
            logger.info("[FILTER DROPPED - NOT FRESHER/INTERN] %s ", title)
            return False

        # Gate 2: Database duplicate check
        if await self._is_duplicate(job_data):
            logger.info("[FILTER DROPPED - DUPLICATE IN DB] %s ", title)
            return False

        logger.info("[FILTER PASSED -> QUEUING FOR LLM] %s ", title)
        return True