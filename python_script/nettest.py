import urllib.request
import time
import statistics
import os
import tempfile
from tqdm import tqdm
import requests
from ping3 import ping
import json
from typing import List, Dict, Optional
from datetime import datetime
import matplotlib.pyplot as plt

class SpeedTestResult:
    def __init__(self):
        self.download_speed: float = 0
        self.upload_speed: float = 0
        self.latency: float = 0
        self.jitter: float = 0
        self.packet_loss: float = 0
        self.timestamp: str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def to_dict(self) -> Dict:
        return {
            "timestamp": self.timestamp,
            "download_speed_mbps": round(self.download_speed * 8, 2),
            "upload_speed_mbps": round(self.upload_speed * 8, 2),
            "latency_ms": round(self.latency, 2),
            "jitter_ms": round(self.jitter, 2),
            "packet_loss_percent": round(self.packet_loss, 2)
        }

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

class NetworkTester:
    def __init__(self):
        self.test_urls = {
            "download": [
                "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user",
                "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe",
                "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
            ],
            "upload": [
                "https://httpbin.org/post",
                "https://postman-echo.com/post"
            ],
            "ping": [
                "8.8.8.8",      # Google DNS
                "1.1.1.1",      # Cloudflare DNS
                "208.67.222.222"  # OpenDNS
            ]
        }
        self.results_history: List[SpeedTestResult] = []

    def format_size(self, size: float) -> str:
        """Convert bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024:
                return f"{size:.2f} {unit}"
            size /= 1024

    def test_download(self, url: str) -> Optional[float]:
        """Test download speed"""
        try:
            temp_file = tempfile.NamedTemporaryFile(delete=False)
            temp_path = temp_file.name
            temp_file.close()

            req = urllib.request.Request(url, method='HEAD')
            response = urllib.request.urlopen(req)
            file_size = int(response.headers['Content-Length'])
            
            print(f"\nTest file size: {self.format_size(file_size)}")
            
            start_time = time.time()
            progress_bar = DownloadProgressBar(file_size)
            
            urllib.request.urlretrieve(
                url, 
                temp_path,
                reporthook=progress_bar.update
            )
            progress_bar.close()
            
            duration = time.time() - start_time
            speed = file_size / (1024 * 1024 * duration)  # MB/s
            
            os.unlink(temp_path)
            return speed
            
        except Exception as e:
            print(f"Download test error: {e}")
            return None

    def test_upload(self, size_mb: int = 10) -> Optional[float]:
        """Test upload speed"""
        try:
            # Create test data
            data = os.urandom(size_mb * 1024 * 1024)
            
            print(f"\nUploading {size_mb}MB test file...")
            
            # Create progress bar
            pbar = tqdm(total=size_mb * 1024 * 1024, unit='B', unit_scale=True)
            
            start_time = time.time()
            
            # Use a custom adapter to track upload progress
            class ProgressAdapter:
                def __init__(self, pbar):
                    self.pbar = pbar
                    self.last_pos = 0
                
                def write(self, data):
                    current = len(data)
                    self.pbar.update(current - self.last_pos)
                    self.last_pos = current
                    return data
            
            adapter = ProgressAdapter(pbar)
            
            # Try each upload URL until one succeeds
            for upload_url in self.test_urls["upload"]:
                try:
                    response = requests.post(
                        upload_url,
                        files={
                            'file': ('test.dat', adapter.write(data), 'application/octet-stream')
                        }
                    )
                    if response.status_code == 200:
                        break
                except:
                    continue
            
            pbar.close()
            duration = time.time() - start_time
            speed = size_mb / duration  # MB/s
            
            return speed
            
        except Exception as e:
            print(f"Upload test error: {e}")
            return None

    def test_latency(self, host: str, count: int = 20) -> Dict[str, float]:
        """Test network latency and jitter"""
        latencies = []
        lost_packets = 0
        
        print(f"\nTesting latency to {host}...")
        for i in range(count):
            try:
                delay = ping(host, timeout=2)
                if delay is not None:
                    latencies.append(delay * 1000)  # Convert to ms
                else:
                    lost_packets += 1
            except Exception:
                lost_packets += 1
            time.sleep(0.5)  # Increased interval between pings
            
        if not latencies:
            return {"avg_latency": 0, "jitter": 0, "packet_loss": 100}
            
        avg_latency = statistics.mean(latencies)
        jitter = statistics.stdev(latencies) if len(latencies) > 1 else 0
        packet_loss = (lost_packets / count) * 100
        
        return {
            "avg_latency": avg_latency,
            "jitter": jitter,
            "packet_loss": packet_loss
        }

    def plot_results(self):
        """Plot test results"""
        if not self.results_history:
            print("No historical data available for plotting")
            return
            
        timestamps = [r.timestamp for r in self.results_history]
        download_speeds = [r.download_speed * 8 for r in self.results_history]
        upload_speeds = [r.upload_speed * 8 for r in self.results_history]
        latencies = [r.latency for r in self.results_history]
        
        plt.style.use('seaborn')
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
        
        # Speed plot
        ax1.plot(timestamps, download_speeds, 'b-', label='Download', marker='o')
        ax1.plot(timestamps, upload_speeds, 'g-', label='Upload', marker='s')
        ax1.set_title('Network Speed Over Time')
        ax1.set_ylabel('Speed (Mbps)')
        ax1.legend()
        ax1.grid(True)
        plt.setp(ax1.xaxis.get_ticklabels(), rotation=45)
        
        # Latency plot
        ax2.plot(timestamps, latencies, 'r-', label='Latency', marker='o')
        ax2.set_title('Network Latency Over Time')
        ax2.set_ylabel('Latency (ms)')
        ax2.legend()
        ax2.grid(True)
        plt.setp(ax2.xaxis.get_ticklabels(), rotation=45)
        
        plt.tight_layout()
        plt.savefig('network_test_results.png')
        print("\nResults plot saved as network_test_results.png")

    def load_history(self):
        """Load test history from file"""
        try:
            if os.path.exists('network_test_results.json'):
                with open('network_test_results.json', 'r') as f:
                    for line in f:
                        data = json.loads(line.strip())
                        result = SpeedTestResult()
                        result.timestamp = data['timestamp']
                        result.download_speed = data['download_speed_mbps'] / 8
                        result.upload_speed = data['upload_speed_mbps'] / 8
                        result.latency = data['latency_ms']
                        result.jitter = data['jitter_ms']
                        result.packet_loss = data['packet_loss_percent']
                        self.results_history.append(result)
        except Exception as e:
            print(f"Error loading history: {e}")

    def run_complete_test(self) -> SpeedTestResult:
        """Run all network tests"""
        result = SpeedTestResult()
        
        # Download speed test
        print("\n=== Testing Download Speed ===")
        download_speeds = []
        for url in self.test_urls["download"][1:2]:  # Use Python installer for quick test
            speed = self.test_download(url)
            if speed:
                download_speeds.append(speed)
        result.download_speed = statistics.mean(download_speeds) if download_speeds else 0
        
        # Upload speed test
        print("\n=== Testing Upload Speed ===")
        upload_speed = self.test_upload(5)  # Use 5MB file for upload test
        result.upload_speed = upload_speed if upload_speed else 0
        
        # Latency and jitter test
        print("\n=== Testing Network Latency ===")
        latency_results = []
        for host in self.test_urls["ping"]:
            metrics = self.test_latency(host)
            if metrics["avg_latency"] > 0:
                latency_results.append(metrics)
        
        if latency_results:
            result.latency = statistics.mean([r["avg_latency"] for r in latency_results])
            result.jitter = statistics.mean([r["jitter"] for r in latency_results])
            result.packet_loss = statistics.mean([r["packet_loss"] for r in latency_results])
        
        # Add to history
        self.results_history.append(result)
        return result

def main():
    print("Network Performance Test Tool v2.1\n")
    print("This tool will test:")
    print("1. Download speed")
    print("2. Upload speed")
    print("3. Network latency and jitter")
    print("4. Packet loss")
    
    input("\nPress Enter to start the test...")
    
    tester = NetworkTester()
    tester.load_history()  # Load previous test results
    
    result = tester.run_complete_test()
    
    print("\n=== Test Results ===")
    results_dict = result.to_dict()
    for key, value in results_dict.items():
        if key == "timestamp":
            print(f"Test time: {value}")
        elif "speed" in key:
            print(f"{key.replace('_', ' ').title()}: {value} Mbps")
        elif "ms" in key:
            print(f"{key.replace('_', ' ').title()}: {value} ms")
        elif "percent" in key:
            print(f"{key.replace('_', ' ').title()}: {value}%")
    
    # Save results to file
    try:
        with open('network_test_results.json', 'a') as f:
            json.dump(results_dict, f)
            f.write('\n')
        print("\nResults saved to network_test_results.json")
        
        # Generate plots if we have enough data
        tester.plot_results()
    except Exception as e:
        print(f"\nCouldn't save results: {e}")

if __name__ == "__main__":
    main()
