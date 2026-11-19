from fastapi import APIRouter
from api.jobs.router import router as jobs_router

api_router = APIRouter()
api_router.include_router(jobs_router)

