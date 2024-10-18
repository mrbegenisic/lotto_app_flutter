from flask import Flask, jsonify, request

app = Flask(__name__)

# A simple route to test the API
@app.route('/api/greet', methods=['GET'])
def greet():
    return jsonify({"message": "Hello from Python!"})

# A route that processes POST requests
@app.route('/api/process', methods=['POST'])
def process_data():
    data = request.json # Get data from the Flutter app
    response = {"processed_data": data["input_data"].upper()}
    return jsonify(response)

if __name__ == '__main__':
    app.run('0.0.0.0', port=5000)