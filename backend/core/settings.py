from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config=SettingsConfigDict(env_file=".env", extra="ignore")

    DATABASE_URL:str
    DEEPSEEK_API_KEY: str
    DEEPSEEK_URL:str

    LLM_MODEL:str
    LLM_INPUT_COST_PER_1M: float
    LLM_OUTPUT_COST_PER_1M: float

    ACTIVATION_TRIGGER_SECRET:str


settings = Settings() #type:ignore