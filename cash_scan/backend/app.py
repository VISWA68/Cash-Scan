from flask import Flask, request, jsonify
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import numpy as np
import os

app = Flask(__name__)

# Load the trained model
model = load_model('model_final.h5')

# Define the class index mapping using the model's training data
class_indices = {
    0: '10',
    1: '100',
    2: '20',
    3: '200',
    4: '2000',
    5: '50',
    6: '500',
    7: 'Background'
}

# Create a reverse mapping from index to class name
index_to_class = {k: v for k, v in class_indices.items()}  # Corrected mapping

def preprocess_image(img_path):
    # Load the image, convert to grayscale, and resize
    img = image.load_img(img_path, color_mode="grayscale", target_size=(64, 64))
    # Convert the image to a numpy array and scale
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0) / 255.0
    return img_array

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    # Save the file temporarily
    file_path = "temp_image.jpg"
    file.save(file_path)

    # Preprocess the image and make a prediction
    img_array = preprocess_image(file_path)
    prediction = model.predict(img_array)

    predicted_class_index = np.argmax(prediction, axis=-1)[0]

    # Map the predicted index to class name
    predicted_class_name = index_to_class.get(predicted_class_index, "Unknown Class")

    # Remove the temporary file
    os.remove(file_path)

    # Return the result as a JSON response
    return jsonify({"predicted_class": predicted_class_name})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
