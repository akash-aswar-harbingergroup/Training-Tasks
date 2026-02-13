import asyncio
from pathlib import Path

from autogen_agentchat.agents import AssistantAgent, CodeExecutorAgent, UserProxyAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.ui import Console
from autogen_agentchat.conditions import TextMentionTermination

from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.code_executors.local import LocalCommandLineCodeExecutor


from autogen_ext.models.openai import OpenAIChatCompletionClient

from dotenv import load_dotenv
from crewai import Agent, LLM
import os
# Load .env file
load_dotenv()
GEMINI_API_KEY =os.environ["GEMINI_API_KEY"]

# Google Gemini OpenAI-compatible endpoint
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/openai"

# Gemini 2.5 Flash model
GEMINI_MODEL = "gemini-2.5-flash"

model_client = OpenAIChatCompletionClient(
    model=GEMINI_MODEL,
    api_key=GEMINI_API_KEY,
    base_url=GEMINI_BASE_URL,  # No /deployments needed
    api_version=None,  # Gemini does not use api-version

    model_info={
        "type": "chat",
        "family": "gemini",
        "max_tokens": 32768,
        "input_cost_per_token": 0.0,
        "output_cost_per_token": 0.0,
        "supports_image_input": False,
        "vision": False,
        "function_calling": True,
        "parallel_tool_calls": True,
        "json_schema": True,
        "json_output": True,
        "response_format": True,
        "structured_output": False
    }
)


# -------------------------
# AGENTS
# -------------------------
coder = AssistantAgent(
    name="coder",
    model_client=model_client,
    system_message=(
        "You are a coding assistant that gives short and precised answers."
        ),
)

executor = CodeExecutorAgent(
    name="executor",
    model_client=model_client,
    code_executor=LocalCommandLineCodeExecutor(work_dir=Path.cwd() / "runs")
)

user = UserProxyAgent("user")

termination = TextMentionTermination("exit", sources=["user"])


team = RoundRobinGroupChat(
    [user, coder, executor],
    termination_condition=termination
)


# -------------------------
# MAIN ASYNC FUNCTION
# -------------------------
async def main():
    try:
        await Console(team.run_stream())
    finally:
        await model_client.close()


# -------------------------
# ENTRY POINT
# -------------------------
if __name__ == "__main__":
    asyncio.run(main())