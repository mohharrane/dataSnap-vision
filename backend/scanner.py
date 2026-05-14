import json
import os
from openai import OpenAI
import base64

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize the OpenAI client pointing to OpenRouter
api_key = os.environ.get("OPENROUTER_API_KEY")
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=api_key,
)

def encode_image(image_path):
    """Encodes an image to base64 for the API."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def process_exam_paper(image_path):
    """
    Sends the exam paper to an OpenRouter model to extract both the Student Info AND the Grade.
    This replaces both the QR scanner and the PyTorch model with a single API call.
    """
    try:
        # Convert image to base64
        base64_image = encode_image(image_path)
        
        prompt = """
        You are an expert OCR AI specifically trained to read graded exam papers. 
        Look at the image provided and extract the student's information (from the QR code or text) 
        and their handwritten final mark/grade. 
        
        You must respond ONLY with a valid JSON object matching this exact structure: 
        {"student_info": {"name": "Text", "surname": "Text", "group": "Text"}, "mark": 0.0}
        """

        # Ask OpenRouter to process the image and prompt
        # You can change this model to any free vision model on OpenRouter (e.g. google/gemini-2.5-flash)
        response = client.chat.completions.create(
            model="google/gemini-2.5-flash", 
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ]
        )
        
        # Grab the text response
        result_string = response.choices[0].message.content
        
        # Clean up the output in case the AI wraps it in markdown (```json ... ```)
        if "```json" in result_string:
            result_string = result_string.split("```json")[1].split("```")[0].strip()
        elif "```" in result_string:
            result_string = result_string.split("```")[1].strip()
            
        # Parse the JSON string into a Python dictionary
        extracted_data = json.loads(result_string)
        
        print("🧠 OpenRouter Extracted Data:", extracted_data)
        
        # Return format expected by main.py and Flutter
        return {
            "status": "success",
            "qr_data": {"student_info": extracted_data.get("student_info", {})},
            "mark_data": {"mark": float(extracted_data.get("mark", 0.0)), "confidence": 0.99}
        }

    except Exception as e:
        print(f"❌ OpenRouter Error: {e}")
        return {
             "status": "error",
             "qr_data": {"error": str(e)},
             "mark_data": {"error": str(e)}
        }

