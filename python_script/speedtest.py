import urllib.request
import time
import statistics
import os
import tempfile
from tqdm import tqdm

def format_size(size):
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

class DownloadProgressBar:
    def __init__(self, total):
        self.pbar = tqdm(total=total, unit='B', unit_scale=True, unit_divisor=1024)

    def update(self, block_num, block_size, total_size):
        if total_size != -1:
            current = block_num * block_size
            if current < total_size:
                self.pbar.update(block_size)

    def close(self):
        self.pbar.close()

def test_speed(url, times=1):
    """
    Test download speed
    :param url: Download URL for testing
    :param times: Number of test iterations
    :return: Average speed (MB/s)
    """
    speeds = []
    print(f"Starting speed test...")
    
    # Use temporary file
    temp_file = tempfile.NamedTemporaryFile(delete=False)
    temp_path = temp_file.name
    temp_file.close()
    
    try:
        for i in range(times):
            try:
                # Get file size first
                req = urllib.request.Request(url, method='HEAD')
                response = urllib.request.urlopen(req)
                file_size = int(response.headers['Content-Length'])
                
                print(f"\nTest file size: {format_size(file_size)}")
                
                # Start download and timing
                start_time = time.time()
                
                # Create progress bar
                progress_bar = DownloadProgressBar(file_size)
                
                # Download file with progress
                urllib.request.urlretrieve(
                    url, 
                    temp_path,
                    reporthook=progress_bar.update
                )
                progress_bar.close()
                
                duration = time.time() - start_time
                
                # Calculate speed
                speed = file_size / (1024 * 1024 * duration)  # MB/s
                speeds.append(speed)
                
                print(f"\nTime elapsed: {duration:.2f} seconds")
                print(f"Current speed: {speed:.2f} MB/s ({speed * 8:.2f} Mbps)")
                
            except Exception as e:
                print(f"Test error: {e}")
                continue
                
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.unlink(temp_path)
            print("\nTemporary file cleaned")
            
    if speeds:
        avg_speed = statistics.mean(speeds)
        return avg_speed
    return None

def main():
    # Use stable test sources
    urls = [
        # VS Code latest version (≈100MB)
        "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user",
        # Python 3.12 (≈25MB)
        "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe",
        # Node.js LTS (≈30MB)
        "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
    ]
    
    print("Network Speed Test Tool (No Installation Required)\n")
    print("Available test sources:")
    print("1. VS Code Latest Version (≈100MB)")
    print("2. Python 3.12 Installer (≈25MB)")
    print("3. Node.js Installer (≈30MB)")
    
    try:
        choice = int(input("\nSelect test source (1-3, recommend 2 for first test): ")) - 1
        if choice < 0 or choice >= len(urls):
            print("Invalid choice, using Python installer for testing")
            choice = 1
    except:
        print("Invalid input, using Python installer for testing")
        choice = 1
    
    url = urls[choice]
    print(f"\nUsing test source: {url}")
    
    speed = test_speed(url)
    if speed:
        print("\n=== Test Results ===")
        print(f"Average download speed: {speed:.2f} MB/s")
        print(f"                     {speed * 8:.2f} Mbps")
    else:
        print("\nTest failed, please check your network connection")

if __name__ == "__main__":
    main()
