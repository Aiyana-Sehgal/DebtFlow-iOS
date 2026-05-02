from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import easyocr
import uvicorn
import asyncio
from concurrent.futures import ThreadPoolExecutor
from langchain_community.llms import Ollama
from langchain_core.prompts import PromptTemplate
import json
import re

app = FastAPI(
    title="DebtFlow AI Microservice",
    description="OCR + LangChain/Ollama-powered subscription analysis",
    version="1.0.0"
)

# Initialize EasyOCR reader (downloads model on first run, then cached)
reader = easyocr.Reader(['en'], gpu=False)

# Thread pool for running blocking LLM calls concurrently
executor = ThreadPoolExecutor(max_workers=3)

# ---------------------------------------------------------------------------
# LLM Setup — single Ollama model used across 3 distinct analytical personas
# ---------------------------------------------------------------------------
MODEL_NAME = "llama3.1"

def make_llm() -> Ollama:
    """Create a fresh Ollama instance (one per thread to avoid shared state)."""
    return Ollama(model=MODEL_NAME)

# ---------------------------------------------------------------------------
# Prompt Templates
# ---------------------------------------------------------------------------
conservative_prompt = PromptTemplate(
    input_variables=["text"],
    template="""You are a Conservative Financial Planner. Analyze the following OCR text of subscriptions and upcoming payments.
Identify the payments, costs, and frequencies.
Recommend immediately cutting all non-essential subscriptions to maximize debt payoff.
Provide a concise, specific output with names and amounts.
Text: {text}"""
)

growth_prompt = PromptTemplate(
    input_variables=["text"],
    template="""You are a Growth & Utility Strategist. Analyze the following OCR text of subscriptions and upcoming payments.
Identify the payments, costs, and frequencies.
Recommend keeping subscriptions that provide high utility or growth (learning, essential software), and suggest how to optimize the rest.
Provide a concise, specific output with names and amounts.
Text: {text}"""
)

balanced_prompt = PromptTemplate(
    input_variables=["text"],
    template="""You are a Balanced Financial Advisor. Analyze the following OCR text of subscriptions and upcoming payments.
Identify the payments, costs, and frequencies.
Provide a pragmatic, middle-ground approach to managing these subscriptions while paying off debt. What are the quick wins?
Provide a concise, specific output with names and amounts.
Text: {text}"""
)

synthesizer_prompt = PromptTemplate(
    input_variables=["conservative", "growth", "balanced"],
    template="""You are the Lead Financial Synthesizer. You have received three analyses of a user's subscriptions from different advisors:

Conservative Model: {conservative}

Growth Model: {growth}

Balanced Model: {balanced}

Compare these three perspectives. Evaluate the feasibility for an average user trying to pay off debt faster.
Provide exactly 3 simple, final, actionable suggestions.
Return ONLY a valid JSON object like this — no markdown, no extra text:
{{"final_suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"]}}
"""
)

# ---------------------------------------------------------------------------
# Helper: run a chain in a thread (LangChain's Ollama is blocking)
# ---------------------------------------------------------------------------
def _run_chain(prompt: PromptTemplate, variables: dict) -> str:
    llm = make_llm()
    chain = prompt | llm
    return chain.invoke(variables)


async def run_chain_async(prompt: PromptTemplate, variables: dict) -> str:
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(executor, _run_chain, prompt, variables)


def _extract_json_block(text: str) -> str:
    """Pull out the first {...} block from an LLM response."""
    match = re.search(r'\{.*\}', text, re.DOTALL)
    if match:
        return match.group(0)
    return text


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health")
async def health():
    """Liveness probe — called by the Swift backend before proxying."""
    return {"status": "ok", "model": MODEL_NAME}


@app.post("/analyze")
async def analyze_subscriptions(file: UploadFile = File(...)):
    """
    1. OCR-extract text from the uploaded screenshot.
    2. Run 3 LLM analyses (conservative, growth, balanced) concurrently.
    3. Synthesize a final recommendation from the 3 outputs.
    4. Return structured JSON to the Swift backend.
    """
    # -- Read image bytes -------------------------------------------------------
    contents = await file.read()

    # -- 1. OCR -----------------------------------------------------------------
    try:
        ocr_results = reader.readtext(contents, detail=0)
        extracted_text = " ".join(ocr_results).strip()
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"OCR Failed: {str(e)}"}
        )

    if not extracted_text:
        extracted_text = "No readable text found in the image."

    # -- 2. Concurrent LLM analysis --------------------------------------------
    try:
        cons_task   = run_chain_async(conservative_prompt, {"text": extracted_text})
        growth_task = run_chain_async(growth_prompt,       {"text": extracted_text})
        bal_task    = run_chain_async(balanced_prompt,     {"text": extracted_text})

        cons_output, grow_output, bal_output = await asyncio.gather(
            cons_task, growth_task, bal_task
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"AI Analysis Failed: {str(e)}"}
        )

    # -- 3. Synthesize ----------------------------------------------------------
    try:
        final_output_str = await run_chain_async(
            synthesizer_prompt,
            {
                "conservative": cons_output,
                "growth":       grow_output,
                "balanced":     bal_output,
            }
        )

        # Parse the JSON block robustly
        try:
            cleaned = _extract_json_block(final_output_str)
            final_json = json.loads(cleaned)
            suggestions = final_json.get("final_suggestions", [final_output_str])
        except Exception:
            suggestions = [final_output_str]

    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"error": f"Synthesis Failed: {str(e)}"}
        )

    return {
        "extracted_text": extracted_text,
        "models_output": {
            "conservative": cons_output,
            "growth":       grow_output,
            "balanced":     bal_output,
        },
        "final_suggestions": suggestions,
    }


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level="info")
