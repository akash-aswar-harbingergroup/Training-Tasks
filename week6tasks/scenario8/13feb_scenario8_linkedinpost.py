import os
import asyncio
from autogen_agentchat.ui import Console
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.agents.web_surfer import MultimodalWebSurfer
from autogen_core.models import ModelInfo, ModelFamily
from dotenv import load_dotenv

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")


gemini_client = OpenAIChatCompletionClient(
    model="gemini-2.0-flash", 
    api_key=GEMINI_API_KEY,
    base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
    model_info=ModelInfo(
        vision=True, 
        function_calling=True, 
        json_output=True, 
        structured_output=True,
        family=ModelFamily.UNKNOWN
    )
)

async def main() -> None:
    # Specialized agents for the industry post workflow
    researcher = MultimodalWebSurfer(name="Researcher", model_client=gemini_client)
    
    analyst = AssistantAgent(
        name="Analyst",
        model_client=gemini_client,
        system_message="Technical Analyst. Validate AI trends for engineering ROI."
    )

    writer = AssistantAgent(
        name="Writer",
        model_client=gemini_client,
        system_message="Content Specialist. Craft a punchy LinkedIn post with hooks."
    )

    editor = AssistantAgent(
        name="Editor",
        model_client=gemini_client,
        system_message="Executive Editor. Refine for CTO/VP clarity and impact."
    )

    # Collaborative team
    industry_post_team = RoundRobinGroupChat([researcher, analyst, writer, editor], max_turns=6)

    task = "Research 3 AI breakthroughs from the last 7 days and draft a LinkedIn post for CTOs."

    try:
        stream = industry_post_team.run_stream(task=task)
        await Console(stream)
    finally:
        await researcher.close()

if __name__ == "__main__":
    asyncio.run(main())
