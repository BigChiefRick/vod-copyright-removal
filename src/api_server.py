from fastapi import FastAPI, UploadFile, File, BackgroundTasks, HTTPException
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import shutil
from pathlib import Path
import uuid
from datetime import datetime
import asyncio
import os
import sys

# Add the processor directory to path
sys.path.append('/opt/vod-processor')

app = FastAPI(title="VOD Processor API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create directories if they don't exist
Path("/opt/vod-processor/processed").mkdir(parents=True, exist_ok=True)
Path("/var/log/vod-processor").mkdir(parents=True, exist_ok=True)

# Mount static files
app.mount("/processed", StaticFiles(directory="/opt/vod-processor/processed"), name="processed")
app.mount("/logs", StaticFiles(directory="/var/log/vod-processor"), name="logs")

@app.get("/")
async def root():
    return {
        "message": "VOD Processor API",
        "status": "operational",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/stats")
async def get_stats():
    try:
        from vod_processor import SystemMonitor, AVAILABLE_METHODS
        stats = SystemMonitor.get_stats()
        stats['available_methods'] = AVAILABLE_METHODS
        return stats
    except Exception as e:
        return {"error": str(e)}

@app.post("/upload")
async def upload_video(file: UploadFile = File(...), background_tasks: BackgroundTasks = None):
    if not file.filename.lower().endswith(('.mp4', '.avi', '.mov', '.mkv', '.webm')):
        raise HTTPException(status_code=400, detail="Invalid file format")
    
    # Save uploaded file
    file_id = str(uuid.uuid4())
    input_path = Path(f"/opt/vod-processor/incoming/{file_id}_{file.filename}")
    
    try:
        input_path.parent.mkdir(parents=True, exist_ok=True)
        with input_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")
    
    # Queue for processing
    if background_tasks:
        background_tasks.add_task(process_video_task, input_path)
    
    return {
        "file_id": file_id,
        "filename": file.filename,
        "status": "queued",
        "size_mb": input_path.stat().st_size / 1e6
    }

@app.get("/videos")
async def list_videos():
    processed = Path("/opt/vod-processor/processed")
    videos = []
    
    if processed.exists():
        for video in processed.glob("*.mp4"):
            videos.append({
                "filename": video.name,
                "size_mb": video.stat().st_size / 1e6,
                "modified": datetime.fromtimestamp(video.stat().st_mtime).isoformat()
            })
    
    return {"videos": sorted(videos, key=lambda x: x['modified'], reverse=True)}

@app.delete("/videos/{filename}")
async def delete_video(filename: str):
    video_path = Path(f"/opt/vod-processor/processed/{filename}")
    if video_path.exists() and video_path.suffix == '.mp4':
        video_path.unlink()
        return {"message": "Video deleted"}
    raise HTTPException(status_code=404, detail="Video not found")

def process_video_task(video_path):
    """Background task to process video"""
    try:
        from vod_processor import AudioProcessor
        processor = AudioProcessor()
        processor.process_video(video_path, Path("/opt/vod-processor/processed"))
    except Exception as e:
        print(f"Background processing error: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
