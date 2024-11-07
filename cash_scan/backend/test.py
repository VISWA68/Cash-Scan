import requests

# Replace with the path to your image file
image_path = "C:/Users/viswa/Downloads/10.jpg"
url = 'http://192.168.32.231:5000/predict'

# Open the image file in binary mode
with open(image_path, 'rb') as img:
    # Send the POST request with the image file
    response = requests.post(url, files={'file': img})

# Print the response from the server
print(response.json())
