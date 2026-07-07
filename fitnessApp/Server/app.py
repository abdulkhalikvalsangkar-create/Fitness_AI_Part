import os
from flask import Flask

from routes.chatbot_routes import chatbot_bp
from routes.ocr_routes import ocr_bp


app = Flask(__name__)


# CORS headers
@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    return response


# Register blueprints
app.register_blueprint(chatbot_bp, url_prefix='/')
app.register_blueprint(ocr_bp, url_prefix='/api/ocr')


# WSGI entry point
application = app


if __name__ == "__main__":
    print("=" * 60)
    print("AI Chatbot + OCR Backend API")
    print("=" * 60)
    print("Server Starting...")
    print("Chat Endpoint: POST /")
    print("OCR Endpoint: POST /api/ocr/process-image")
    print("=" * 60)
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False,
        threaded=True
    )
