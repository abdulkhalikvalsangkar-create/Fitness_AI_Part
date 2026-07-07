import os
import sys
from pathlib import Path
from flask import Blueprint, request, jsonify
from openai import OpenAIError

# Add Server directory to path to allow absolute imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from services import (
    build_openai_messages,
    run_chat_completion,
    summarize_memory,
    get_long_term_memory
)


chatbot_bp = Blueprint('chatbot', __name__)


@chatbot_bp.route('/', methods=['GET', 'POST', 'OPTIONS'])
def chat():
    if request.method == 'OPTIONS':
        response = jsonify({'success': True})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', '*')
        response.headers.add('Access-Control-Allow-Methods', '*')
        return response
    
    # Status check
    if request.method == 'GET':
        return jsonify({
            'message': 'AI Chatbot Backend API',
            'status': 'Running',
            'openai_configured': bool(os.getenv('OPENAI_API_KEY')),
            'usage': 'POST JSON with "messages" and "context" to this endpoint'
        })
    
    # Chat request
    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return jsonify({'success': False, 'error': 'Invalid or missing JSON body'}), 400
        
        messages = data.get('messages') or []
        if not messages:
            return jsonify({'success': False, 'error': '"messages" must not be empty'}), 400
        
        context = data.get('context') or {}
        update_memory = bool(data.get('update_memory', False))
        
        openai_messages = build_openai_messages(messages, context)
        reply_text = run_chat_completion(openai_messages, context)
        
        updated_summary = None
        if update_memory:
            updated_summary = summarize_memory(messages, get_long_term_memory(context))
        
        return jsonify({
            'success': True,
            'assistant_message': {
                'role': 'assistant',
                'content': reply_text,
                'type': 'text'
            },
            'updated_memory_summary': updated_summary
        })
        
    except RuntimeError as e:
        return jsonify({'success': False, 'error': str(e)}), 503
    except OpenAIError as e:
        return jsonify({'success': False, 'error': f'OpenAI error: {str(e)}'}), 502
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
