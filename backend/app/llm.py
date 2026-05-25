from collections.abc import AsyncIterator
from functools import lru_cache

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from app.config import get_settings


@lru_cache(maxsize=1)
def get_chat_model() -> ChatOpenAI:
    settings = get_settings()
    return ChatOpenAI(
        model=settings.llm_model,
        api_key=settings.openai_api_key,
        base_url=settings.openai_base_url,
        temperature=settings.llm_temperature,
        streaming=True,
    )


async def astream_answer(system_prompt: str, user_prompt: str) -> AsyncIterator[str]:
    model = get_chat_model()
    messages = [SystemMessage(content=system_prompt), HumanMessage(content=user_prompt)]
    async for chunk in model.astream(messages):
        text = getattr(chunk, "content", "") or ""
        if text:
            yield text
