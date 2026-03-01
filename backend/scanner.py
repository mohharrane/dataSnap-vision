import json
import os
from google import genai
import PIL.Image

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize the new Gemini API client
# Get your FREE API key here: https://aistudio.google.com/
api_key = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

def process_exam_paper(image_path):
    """
    Sends the exam paper to Google Gemini to extract both the Student Info AND the Grade.
    This replaces both the QR scanner and the PyTorch model with a single, highly accurate API call.
    """
    try:
        # Load the image using Pillow (required by the Gemini SDK)
        img = PIL.Image.open(image_path)
        
        prompt = """
        You are an expert OCR AI specifically trained to read graded exam papers. 
        Look at the image provided and extract the student's information (from the QR code or text) 
        and their handwritten final mark/grade. 
        
        You must respond ONLY with a valid JSON object matching this exact structure: 
        {"student_info": {"name": "Text", "surname": "Text", "group": "Text"}, "mark": 0.0}
        """

        # Ask Gemini to process the image and prompt
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt, img]
        )
        
        # Grab the text response
        result_string = response.text
        
        # Clean up the output in case the AI wraps it in markdown (```json ... ```)
        if "```json" in result_string:
            result_string = result_string.split("```json")[1].split("```")[0].strip()
        elif "```" in result_string:
            result_string = result_string.split("```")[1].strip()
            
        # Parse the JSON string into a Python dictionary
        extracted_data = json.loads(result_string)
        
        print("🧠 Gemini Extracted Data:", extracted_data)
        
        # Return format expected by main.py and Flutter
        return {
            "status": "success",
            "qr_data": {"student_info": extracted_data.get("student_info", {})},
            "mark_data": {"mark": float(extracted_data.get("mark", 0.0)), "confidence": 0.99}
        }

    except Exception as e:
        print(f"❌ Gemini Error: {e}")
        return {
             "status": "error",
             "qr_data": {"error": str(e)},
             "mark_data": {"error": str(e)}
        }
