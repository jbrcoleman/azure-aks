from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

@app.route('/')
def home():
    """
    Basic home route that returns system information
    """
    return jsonify({
        "hostname": socket.gethostname(),
        "message": "Welcome to the Restricted Access Web App!",
        "environment": os.environ.get('APP_ENV', 'Development')
    })

@app.route('/health')
def health_check():
    """
    Health check endpoint for Kubernetes
    """
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)