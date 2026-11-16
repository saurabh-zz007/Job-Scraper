from abc import ABC, abstractmethod
from data_collection.schemas import RawJob

class BaseScraper(ABC):
    """
    Abstract Base Class for all job scrapers following the Open/Closed Principle.
    Each scraper implementation encapsulates the logic for fetching from a specific provider
    and normalizing the output into standard RawJob schemas.
    """

    def __init__(self, board_id: str, company_name: str | None = None):
        self.board_id = board_id
        self.company_name = company_name

    @abstractmethod
    async def fetch_and_normalize(self) -> list[RawJob]:
        """Fetch raw listings and normalize into RawJob objects."""
        pass

