from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="MIDO_AI_", env_file=".env", extra="ignore")

    app_name: str = "MIDO AI Service"
    model_version: str = "mido-risk-v1"
    prompt_version: str = "explain-v1"
    osv_api_base_url: str = "https://api.osv.dev/v1"
    request_timeout_seconds: float = 10.0
    openai_api_key: str | None = None
    openai_model: str = "gpt-4o-mini"


settings = Settings()
