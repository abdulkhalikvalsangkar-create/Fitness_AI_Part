import os
import json
from openai import OpenAI, OpenAIError

# Copy of the original chatbot logic from app.py, refactored into a service

# Config
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
MAX_TOOL_ROUNDS = int(os.getenv("MAX_TOOL_ROUNDS", "5"))

# Global client
client = None


def get_client():
    global client
    if client is not None:
        return client
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set")
    client = OpenAI(api_key=api_key)
    return client


# Tool definitions
TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "get_health_data_by_date",
            "description": "Return every recorded health metric for one specific date.",
            "parameters": {
                "type": "object",
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Date in ISO-8601 format, e.g. 2023-01-05.",
                    }
                },
                "required": ["date"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_metric_summary",
            "description": (
                "Aggregate one numeric metric (average, min, max, latest) over the "
                "user's history, optionally within a date range."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "metric": {
                        "type": "string",
                        "description": (
                            "Metric field name, e.g. recovery_score, strain, "
                            "sleep_hours, sleep_efficiency, calories_burned, "
                            "workout_minutes, heart_rate, resting_heart_rate, weight."
                        ),
                    },
                    "start_date": {"type": "string", "description": "Optional ISO start date."},
                    "end_date": {"type": "string", "description": "Optional ISO end date."},
                },
                "required": ["metric"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_recent_trend",
            "description": "Return the most recent N daily values of a metric, newest last.",
            "parameters": {
                "type": "object",
                "properties": {
                    "metric": {"type": "string", "description": "Metric field name."},
                    "days": {
                        "type": "integer",
                        "description": "How many recent days to return (default 7).",
                    },
                },
                "required": ["metric"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_activity_history",
            "description": "List workout sessions, optionally filtered by activity type.",
            "parameters": {
                "type": "object",
                "properties": {
                    "activity_type": {
                        "type": "string",
                        "description": "Optional activity filter, e.g. CrossFit, Running.",
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Max sessions to return (default 20).",
                    },
                },
            },
        },
    },
]

FIELD_ALIASES = {
    "day_strain": "strain",
    "avg_heart_rate": "heart_rate",
    "weight_kg": "weight",
    "height_cm": "height",
    "activity_duration_min": "workout_minutes",
}


def _normalize_record(record):
    if not isinstance(record, dict):
        return {}
    normalized = dict(record)
    for alias, canonical in FIELD_ALIASES.items():
        if canonical not in normalized and alias in record:
            normalized[canonical] = record[alias]
    return normalized


def _history(context):
    csv = context.get("csv_health_data")
    if isinstance(csv, dict):
        records = csv.get("user_history") or []
    elif isinstance(csv, list):
        records = csv
    else:
        records = []
    return [_normalize_record(r) for r in records]


def _to_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _tool_get_health_data_by_date(args, context):
    target = args.get("date")
    for record in _history(context):
        if record.get("date") == target:
            return {"date": target, "record": record}
    return {"date": target, "record": None, "note": "No record found for that date."}


def _tool_get_metric_summary(args, context):
    metric = args.get("metric")
    start = args.get("start_date")
    end = args.get("end_date")
    values = []
    latest_value = None
    latest_date = None
    for record in _history(context):
        date = record.get("date")
        if start and date and date < start:
            continue
        if end and date and date > end:
            continue
        val = _to_float(record.get(metric))
        if val is None:
            continue
        values.append(val)
        if latest_date is None or (date and date > latest_date):
            latest_date, latest_value = date, val
    if not values:
        return {"metric": metric, "note": "No data available for this metric/range."}
    return {
        "metric": metric,
        "count": len(values),
        "average": round(sum(values) / len(values), 2),
        "min": min(values),
        "max": max(values),
        "latest": latest_value,
        "latest_date": latest_date,
    }


def _tool_get_recent_trend(args, context):
    metric = args.get("metric")
    days = int(args.get("days", 7))
    dated = [r for r in _history(context) if r.get("date") is not None]
    dated.sort(key=lambda r: r["date"])
    recent = dated[-days:]
    series = [
        {"date": r.get("date"), "value": _to_float(r.get(metric))}
        for r in recent
        if _to_float(r.get(metric)) is not None
    ]
    return {"metric": metric, "days": days, "series": series}


def _tool_get_activity_history(args, context):
    activity_type = args.get("activity_type")
    limit = int(args.get("limit", 20))
    sessions = []
    for record in _history(context):
        act = record.get("activity_type")
        if not act:
            continue
        if activity_type and act.lower() != activity_type.lower():
            continue
        sessions.append(
            {
                "date": record.get("date"),
                "activity_type": act,
                "workout_minutes": record.get("workout_minutes"),
                "calories_burned": record.get("calories_burned"),
                "strain": record.get("strain"),
            }
        )
    return {"activity_type": activity_type, "sessions": sessions[:limit]}


TOOL_EXECUTORS = {
    "get_health_data_by_date": _tool_get_health_data_by_date,
    "get_metric_summary": _tool_get_metric_summary,
    "get_recent_trend": _tool_get_recent_trend,
    "get_activity_history": _tool_get_activity_history,
}


def execute_tool(name, args, context):
    executor = TOOL_EXECUTORS.get(name)
    if executor is None:
        return {"error": "Unknown tool: " + str(name)}
    try:
        return executor(args, context)
    except Exception as e:
        return {"error": "Tool '" + str(name) + "' failed: " + str(e)}


def get_long_term_memory(context):
    return context.get("long_term_memory") or context.get("memory")


def _get_attached_docs(context):
    docs = context.get("attached_docs")
    if isinstance(docs, list):
        return [d for d in docs if isinstance(d, dict)]
    documents_text = context.get("documents")
    if isinstance(documents_text, str) and documents_text.strip():
        return [{"file_name": "Attached documents", "content_summary": documents_text}]
    return []


def build_system_prompt(context):
    parts = [
        "You are a helpful, knowledgeable fitness and health assistant inside a "
        "mobile fitness app. Give clear, encouraging, personalized guidance based "
        "on the user's data. When a question needs specific numbers, call the "
        "available tools rather than guessing. Never fabricate health values."
    ]
    profile = context.get("user_profile") or {}
    if profile:
        details = []
        if profile.get("name"):
            details.append("name: " + str(profile["name"]))
        if profile.get("age") is not None:
            details.append("age: " + str(profile["age"]))
        if profile.get("gender"):
            details.append("gender: " + str(profile["gender"]))
        if profile.get("height") is not None:
            details.append("height: " + str(profile["height"]) + " cm")
        if profile.get("weight") is not None:
            details.append("weight: " + str(profile["weight"]) + " kg")
        if details:
            parts.append("USER PROFILE - " + ", ".join(details) + ".")
    history = _history(context)
    if history:
        total = len(history)
        dates = [r.get("date") for r in history if r.get("date")]
        span = ""
        if dates:
            span = " spanning " + str(min(dates)) + " to " + str(max(dates))
        csv = context.get("csv_health_data")
        filter_hint = ""
        if isinstance(csv, dict):
            filter_hint = (
                " Currently viewing filter '" + str(csv.get("selected_filter")) +
                "' around '" + str(csv.get("selected_date")) + "'."
            )
        parts.append(
            "HEALTH DATA - " + str(total) + " daily records" + span + "." +
            filter_hint +
            " Use the tools to query specific dates, trends, or metric summaries."
        )
    long_term_memory = get_long_term_memory(context)
    if long_term_memory:
        parts.append("LONG-TERM MEMORY - " + str(long_term_memory))
    for doc in _get_attached_docs(context):
        if not doc.get("file_name"):
            continue
        summary = doc.get("content_summary") or (doc.get("full_text") or "")[:1500]
        parts.append("ATTACHED DOCUMENT '" + str(doc["file_name"]) + "' - " + summary)
    return "\n\n".join(parts)


def build_openai_messages(messages, context):
    openai_messages = [
        {"role": "system", "content": build_system_prompt(context)}
    ]
    for msg in messages:
        role = msg.get("role")
        if role in ("user", "assistant", "system"):
            openai_messages.append(
                {"role": role, "content": msg.get("content", "")}
            )
    return openai_messages


def run_chat_completion(messages, context):
    oa = get_client()
    for _ in range(MAX_TOOL_ROUNDS):
        response = oa.chat.completions.create(
            model=OPENAI_MODEL,
            messages=messages,
            tools=TOOL_DEFINITIONS,
            tool_choice="auto",
        )
        choice = response.choices[0].message
        if not choice.tool_calls:
            return choice.content or ""
        messages.append(
            {
                "role": "assistant",
                "content": choice.content or "",
                "tool_calls": [
                    {
                        "id": tc.id,
                        "type": "function",
                        "function": {
                            "name": tc.function.name,
                            "arguments": tc.function.arguments,
                        },
                    }
                    for tc in choice.tool_calls
                ],
            }
        )
        for tool_call in choice.tool_calls:
            try:
                args = json.loads(tool_call.function.arguments or "{}")
            except json.JSONDecodeError:
                args = {}
            result = execute_tool(tool_call.function.name, args, context)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result, default=str),
                }
            )
    final = oa.chat.completions.create(model=OPENAI_MODEL, messages=messages)
    return final.choices[0].message.content or ""


def summarize_memory(messages, previous_summary):
    oa = get_client()
    transcript = "\n".join(
        str(m.get("role")) + ": " + str(m.get("content")) for m in messages
    )
    system = (
        "You maintain a concise long-term memory of a fitness app user. "
        "Merge the previous summary with the new conversation into an updated, "
        "compact summary. Keep durable facts (goals, preferences, constraints, "
        "recurring topics). Drop small talk. Respond with the summary text only."
    )
    user = ""
    if previous_summary:
        user += "PREVIOUS SUMMARY:\n" + str(previous_summary) + "\n\n"
    user += "NEW CONVERSATION:\n" + transcript
    response = oa.chat.completions.create(
        model=OPENAI_MODEL,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    )
    return (response.choices[0].message.content or "").strip()
