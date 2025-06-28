#!/usr/bin/env python3
"""
VOD Copyright Removal Processor
"""

import os
import sys
import subprocess
import logging
import json
from pathlib import Path
from datetime import datetime
import concurrent.futures
import shutil
import time
import psutil
from typing import List, Dict, Optional, Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/vod-processor/processor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Check available audio separation methods
AVAILABLE_METHODS = ['demucs']  # Default to demucs
try:
    import spleeter
    AVAILABLE_METHODS.append('spleeter')
    logger.info("Spleeter is available")
except ImportError:
    logger.info("Spleeter not available - using Demucs only")

class SystemMonitor:
    """Monitor system resources"""
    
    @staticmethod
    def get_stats():
        return {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'load_average': os.getloadavg()
        }
    
    @staticmethod
    def check_resources():
        stats = SystemMonitor.get_stats()
        if stats['memory_percent'] > 90:
            logger.warning(f"High memory usage: {stats['memory_percent']}%")
            return False
        if stats['disk_usage'] > 85:
            logger.warning(f"High disk usage: {stats['disk_usage']}%")
            return False
        return True

class AudioProcessor:
    """Process audio to remove copyrighted music"""
    
    def __init__(self, method=None):
        # Auto-select method if not specified
        if method is None:
            method = 'spleeter' if 'spleeter' in AVAILABLE_METHODS else 'demucs'
        elif method not in AVAILABLE_METHODS:
            logger.warning(f"{method} not available, using demucs")
            method = 'demucs'
            
        self.method = method
        self.temp_dir = Path('/opt/vod-processor/processing')
        self.temp_dir.mkdir(exist_ok=True)
        logger.info(f"Using audio separation method: {self.method}")
        
    def process_video(self, video_path: Path, output_dir: Path) -> Optional[Path]:
        """Process a single video file"""
        logger.info(f"Processing video: {video_path.name}")
        
        # Check system resources
        if not SystemMonitor.check_resources():
            logger.error("Insufficient system resources")
            return None
        
        start_time = time.time()
        work_dir = self.temp_dir / f"work_{video_path.stem}_{int(time.time())}"
        work_dir.mkdir(exist_ok=True)
        
        try:
            # Extract audio
            audio_path = work_dir / "audio.wav"
            logger.info("Extracting audio...")
            self._extract_audio(video_path, audio_path)
            
            # Separate audio
            logger.info(f"Separating audio using {self.method}...")
            if self.method == 'spleeter' and 'spleeter' in AVAILABLE_METHODS:
                clean_audio = self._process_with_spleeter(audio_path, work_dir)
            else:
                clean_audio = self._process_with_demucs(audio_path, work_dir)
            
            # Recombine with video
            output_path = output_dir / f"{video_path.stem}_no_copyright.mp4"
            logger.info("Recombining with video...")
            self._combine_audio_video(video_path, clean_audio, output_path)
            
            # Log statistics
            duration = time.time() - start_time
            size_reduction = (video_path.stat().st_size - output_path.stat().st_size) / 1e6
            logger.info(f"Processing complete in {duration:.1f}s, size change: {size_reduction:.1f}MB")
            
            return output_path
            
        except Exception as e:
            logger.error(f"Processing failed: {e}", exc_info=True)
            return None
        finally:
            # Cleanup
            if work_dir.exists():
                shutil.rmtree(work_dir)
    
    def _extract_audio(self, video_path: Path, output_path: Path):
        """Extract audio from video"""
        cmd = [
            'ffmpeg', '-i', str(video_path),
            '-vn', '-acodec', 'pcm_s16le',
            '-ar', '44100', '-ac', '2',
            str(output_path), '-y'
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"FFmpeg error: {result.stderr}")
    
    def _process_with_spleeter(self, audio_path: Path, work_dir: Path) -> Path:
        """Process with Spleeter (faster, good quality)"""
        try:
            from spleeter.separator import Separator
            
            separator = Separator('spleeter:2stems')
            separator.separate_to_file(str(audio_path), str(work_dir))
            
            # Return vocals (commentary) path
            vocals_path = work_dir / audio_path.stem / 'vocals.wav'
            if vocals_path.exists():
                return vocals_path
            else:
                raise Exception("Spleeter output not found")
        except Exception as e:
            logger.error(f"Spleeter error: {e}")
            # Fallback to simple filtering
            return self._fallback_filter(audio_path, work_dir)
    
    def _process_with_demucs(self, audio_path: Path, work_dir: Path) -> Path:
        """Process with Demucs (slower, better quality)"""
        try:
            cmd = [
                sys.executable, '-m', 'demucs',
                '--two-stems=vocals',
                '-o', str(work_dir),
                str(audio_path)
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"Demucs error: {result.stderr}")
            
            # Find output file - demucs creates nested directories
            for root, dirs, files in os.walk(work_dir):
                for file in files:
                    if file == 'vocals.wav':
                        return Path(root) / file
            
            raise Exception("Demucs output not found")
        except Exception as e:
            logger.error(f"Demucs error: {e}")
            return self._fallback_filter(audio_path, work_dir)
    
    def _fallback_filter(self, audio_path: Path, work_dir: Path) -> Path:
        """Fallback audio filtering when AI models fail"""
        logger.warning("Using fallback audio filter")
        output_path = work_dir / "filtered.wav"
        cmd = [
            'ffmpeg', '-i', str(audio_path),
            '-af', 'highpass=f=200,lowpass=f=3000',
            str(output_path), '-y'
        ]
        subprocess.run(cmd, check=True)
        return output_path
    
    def _combine_audio_video(self, video_path: Path, audio_path: Path, output_path: Path):
        """Combine processed audio with original video"""
        cmd = [
            'ffmpeg', '-i', str(video_path), '-i', str(audio_path),
            '-c:v', 'copy',  # Don't re-encode video
            '-c:a', 'aac', '-b:a', '192k',
            '-map', '0:v:0', '-map', '1:a:0',
            '-shortest', str(output_path), '-y'
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"FFmpeg combine error: {result.stderr}")

class BatchProcessor:
    """Handle batch processing of videos"""
    
    def __init__(self, max_workers=2):
        self.max_workers = max_workers
        self.processor = AudioProcessor()
        self.incoming_dir = Path('/opt/vod-processor/incoming')
        self.processed_dir = Path('/opt/vod-processor/processed')
        
    def scan_for_videos(self) -> List[Path]:
        """Scan for unprocessed videos"""
        video_extensions = {'.mp4', '.avi', '.mov', '.mkv', '.webm'}
        videos = []
        
        if not self.incoming_dir.exists():
            self.incoming_dir.mkdir(parents=True)
            
        for file in self.incoming_dir.iterdir():
            if file.suffix.lower() in video_extensions:
                # Check if already processed
                output_file = self.processed_dir / f"{file.stem}_no_copyright.mp4"
                if not output_file.exists():
                    videos.append(file)
        
        return videos
    
    def process_all(self):
        """Process all pending videos"""
        videos = self.scan_for_videos()
        
        if not videos:
            logger.info("No videos to process")
            return
        
        logger.info(f"Found {len(videos)} videos to process")
        
        # Process videos with limited concurrency
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = []
            
            for video in videos:
                future = executor.submit(
                    self.processor.process_video,
                    video,
                    self.processed_dir
                )
                futures.append((video, future))
            
            # Wait for completion
            for video, future in futures:
                try:
                    result = future.result()
                    if result:
                        logger.info(f"Successfully processed: {video.name}")
                        # Archive original
                        archive_dir = self.incoming_dir / 'archive'
                        archive_dir.mkdir(exist_ok=True)
                        video.rename(archive_dir / video.name)
                except Exception as e:
                    logger.error(f"Failed to process {video.name}: {e}")

def main():
    """Main entry point"""
    logger.info("VOD Processor starting...")
    logger.info(f"Available methods: {AVAILABLE_METHODS}")
    logger.info(f"System stats: {SystemMonitor.get_stats()}")
    
    # Check if running as service or manual
    if len(sys.argv) > 1:
        # Process single file
        video_path = Path(sys.argv[1])
        if video_path.exists():
            processor = AudioProcessor()
            output = processor.process_video(
                video_path,
                Path('/opt/vod-processor/processed')
            )
            if output:
                print(f"Success: {output}")
            else:
                print("Processing failed")
                sys.exit(1)
    else:
        # Batch mode - continuous monitoring
        batch = BatchProcessor()
        while True:
            try:
                batch.process_all()
            except Exception as e:
                logger.error(f"Batch processing error: {e}")
            time.sleep(60)  # Check every minute

if __name__ == "__main__":
    main()
