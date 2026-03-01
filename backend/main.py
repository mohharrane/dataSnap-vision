from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from pydantic import BaseModel
from scanner import process_exam_paper
import pandas as pd
import shutil
import tempfile
import uuid
import os

app = FastAPI(title="DataSnap Vision - API")

# Allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class StudentResult(BaseModel):
    name: str    
    group: str
    module: str
    mark: float

@app.post("/scan")
async def scan_paper(file: UploadFile = File(...)):
    """
    Receives an image of an exam paper, saves it temporarily, and runs the scanner.
    """
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, f"{uuid.uuid4()}_{file.filename}")
    
    try:
        # Save uploaded file
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Process the image
        result = process_exam_paper(temp_path)
        
        # Format the response
        return JSONResponse(content=result)
        
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
    finally:
         if os.path.exists(temp_path):
             os.remove(temp_path)

@app.post("/export")
async def export_results_to_excel(results: List[StudentResult]):
    """
    Receives JSON list of results, generated an Excel file and returns it.
    """
    if not results:
        return JSONResponse(status_code=400, content={"error": "No data provided."})
        
    try:
        # Convert list of pydantic models to dicts
        data = [r.model_dump() for r in results]
        
        # Create DataFrame
        df = pd.DataFrame(data)
        
        # Reorder/rename columns if necessary
        df = df[["module", "name", "group", "mark"]]
        df.columns = ["Module", "Full Name", "Group", "Mark"]
        
        # Generate Excel file
        temp_dir = tempfile.gettempdir()
        excel_path = os.path.join(temp_dir, f"DataSnap_Export_{uuid.uuid4()}.xlsx")
        df.to_excel(excel_path, index=False)
        
        # Return file for download
        return FileResponse(excel_path, filename="exam_results.xlsx", media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        
    except Exception as e:
         return JSONResponse(status_code=500, content={"error": str(e)})
