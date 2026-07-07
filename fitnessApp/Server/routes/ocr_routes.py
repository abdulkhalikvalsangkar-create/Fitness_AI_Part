import sys
from pathlib import Path
from flask import Blueprint, request, jsonify

# Add Server directory to path to allow absolute imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from services import classify_file, process_image_to_text, process_image_to_chunks


ocr_bp = Blueprint('ocr', __name__)


@ocr_bp.route('/process-image', methods=['POST', 'OPTIONS'])
def process_image():
    if request.method == 'OPTIONS':
        response = jsonify({'success': True})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', '*')
        response.headers.add('Access-Control-Allow-Methods', '*')
        return response
    
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'error': 'No file part'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No selected file'}), 400
        
        # Check file type
        file_type = classify_file(file.filename)
        if file_type != 'image':
            return jsonify({'success': False, 'error': f'Unsupported file type: {file_type}'}), 400
        
        # Get optional parameters
        chunk_size = request.form.get('chunk_size', 1200, type=int)
        overlap = request.form.get('overlap', 150, type=int)
        return_type = request.form.get('return_type', 'text')  # 'text' or 'chunks'
        
        # Read file bytes
        image_bytes = file.read()
        
        if return_type == 'chunks':
            result = process_image_to_chunks(image_bytes, file.filename, chunk_size, overlap)
            return jsonify({
                'success': True,
                'type': 'chunks',
                'data': result
            })
        else:
            text = process_image_to_text(image_bytes, file.filename)
            return jsonify({
                'success': True,
                'type': 'text',
                'data': text
            })
            
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
