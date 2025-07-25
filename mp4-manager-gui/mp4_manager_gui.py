#!/usr/bin/env python3
"""
Remote MP4 File Manager GUI
A GUI application for managing remote MP4 files and screen recorder service
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import subprocess
import threading
import os
import tempfile
from datetime import datetime
import queue
import json

class RemoteMP4Manager:
    def __init__(self, root):
        self.root = root
        self.root.title("Remote MP4 File Manager")
        self.root.geometry("900x700")
        self.root.minsize(800, 600)
        
        # Configuration variables
        self.remote_user = tk.StringVar(value="autoware")
        self.remote_host = tk.StringVar(value="192.168.20.21")
        self.remote_password = tk.StringVar(value="autoware")
        self.remote_dir = tk.StringVar(value="/tmp")
        self.local_dir = tk.StringVar(value="./downloaded_videos")
        self.service_name = tk.StringVar(value="screen-recorder.service")
        
        # GUI state variables
        self.is_connected = tk.BooleanVar(value=False)
        self.operation_in_progress = tk.BooleanVar(value=False)
        
        # Message queue for thread communication
        self.message_queue = queue.Queue()
        
        # File list data
        self.file_list_data = []
        
        self.setup_gui()
        self.check_dependencies()
        self.process_queue()
        
    def setup_gui(self):
        """Setup the main GUI layout"""
        # Create main notebook for tabs
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Configuration tab
        config_frame = ttk.Frame(notebook)
        notebook.add(config_frame, text="Configuration")
        self.setup_config_tab(config_frame)
        
        # Service management tab
        service_frame = ttk.Frame(notebook)
        notebook.add(service_frame, text="Service Management")
        self.setup_service_tab(service_frame)
        
        # File management tab
        files_frame = ttk.Frame(notebook)
        notebook.add(files_frame, text="File Management")
        self.setup_files_tab(files_frame)
        
        # Logs tab
        logs_frame = ttk.Frame(notebook)
        notebook.add(logs_frame, text="Logs")
        self.setup_logs_tab(logs_frame)
        
        # Status bar
        self.setup_status_bar()
        
    def setup_config_tab(self, parent):
        """Setup configuration tab"""
        main_frame = ttk.Frame(parent)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Connection settings
        conn_frame = ttk.LabelFrame(main_frame, text="Connection Settings", padding=15)
        conn_frame.pack(fill=tk.X, pady=(0, 20))
        
        ttk.Label(conn_frame, text="Remote User:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(conn_frame, textvariable=self.remote_user, width=30).grid(row=0, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        
        ttk.Label(conn_frame, text="Remote Host:").grid(row=1, column=0, sticky=tk.W, pady=5)
        ttk.Entry(conn_frame, textvariable=self.remote_host, width=30).grid(row=1, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        
        ttk.Label(conn_frame, text="Password:").grid(row=2, column=0, sticky=tk.W, pady=5)
        password_entry = ttk.Entry(conn_frame, textvariable=self.remote_password, show="*", width=30)
        password_entry.grid(row=2, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        
        # Directory settings
        dir_frame = ttk.LabelFrame(main_frame, text="Directory Settings", padding=15)
        dir_frame.pack(fill=tk.X, pady=(0, 20))
        
        ttk.Label(dir_frame, text="Remote Directory:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(dir_frame, textvariable=self.remote_dir, width=40).grid(row=0, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        
        ttk.Label(dir_frame, text="Local Directory:").grid(row=1, column=0, sticky=tk.W, pady=5)
        local_frame = ttk.Frame(dir_frame)
        local_frame.grid(row=1, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        ttk.Entry(local_frame, textvariable=self.local_dir, width=30).pack(side=tk.LEFT)
        ttk.Button(local_frame, text="Browse", command=self.browse_local_dir).pack(side=tk.LEFT, padx=(10, 0))
        
        # Service settings
        service_frame = ttk.LabelFrame(main_frame, text="Service Settings", padding=15)
        service_frame.pack(fill=tk.X, pady=(0, 20))
        
        ttk.Label(service_frame, text="Service Name:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(service_frame, textvariable=self.service_name, width=40).grid(row=0, column=1, sticky=tk.W, padx=(10, 0), pady=5)
        
        # Connection test
        test_frame = ttk.Frame(main_frame)
        test_frame.pack(fill=tk.X, pady=(0, 20))
        
        self.test_button = ttk.Button(test_frame, text="Test Connection", command=self.test_connection)
        self.test_button.pack(side=tk.LEFT)
        
        self.connection_status = ttk.Label(test_frame, text="Not connected", foreground="red")
        self.connection_status.pack(side=tk.LEFT, padx=(20, 0))
        
    def setup_service_tab(self, parent):
        """Setup service management tab"""
        main_frame = ttk.Frame(parent)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Service status frame
        status_frame = ttk.LabelFrame(main_frame, text="Service Status", padding=15)
        status_frame.pack(fill=tk.X, pady=(0, 20))
        
        self.service_status_text = scrolledtext.ScrolledText(status_frame, height=8, width=80)
        self.service_status_text.pack(fill=tk.BOTH, expand=True)
        
        # Service control buttons
        control_frame = ttk.Frame(main_frame)
        control_frame.pack(fill=tk.X, pady=(0, 20))
        
        ttk.Button(control_frame, text="Check Status", command=self.check_service_status).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(control_frame, text="Enable & Start Service", command=self.enable_service).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(control_frame, text="Stop Service", command=self.stop_service).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(control_frame, text="Restart Service", command=self.restart_service).pack(side=tk.LEFT)
        
    def setup_files_tab(self, parent):
        """Setup file management tab"""
        main_frame = ttk.Frame(parent)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # File list frame
        list_frame = ttk.LabelFrame(main_frame, text="Remote MP4 Files", padding=15)
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 20))
        
        # Treeview for file list
        columns = ("filename", "size", "date")
        self.file_tree = ttk.Treeview(list_frame, columns=columns, show="headings", height=15)
        
        self.file_tree.heading("filename", text="Filename")
        self.file_tree.heading("size", text="Size")
        self.file_tree.heading("date", text="Date Modified")
        
        self.file_tree.column("filename", width=400)
        self.file_tree.column("size", width=100)
        self.file_tree.column("date", width=200)
        
        # Scrollbar for treeview
        tree_scroll = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.file_tree.yview)
        self.file_tree.configure(yscrollcommand=tree_scroll.set)
        
        self.file_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        tree_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        
        # File operations frame
        ops_frame = ttk.Frame(main_frame)
        ops_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Button(ops_frame, text="Refresh List", command=self.refresh_file_list).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(ops_frame, text="Download Selected", command=self.download_selected).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(ops_frame, text="Download All", command=self.download_all).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(ops_frame, text="Delete Selected", command=self.delete_selected).pack(side=tk.LEFT)
        
        # Progress frame
        progress_frame = ttk.Frame(main_frame)
        progress_frame.pack(fill=tk.X)
        
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(progress_frame, variable=self.progress_var, maximum=100)
        self.progress_bar.pack(fill=tk.X, pady=(0, 5))
        
        self.progress_label = ttk.Label(progress_frame, text="Ready")
        self.progress_label.pack()
        
    def setup_logs_tab(self, parent):
        """Setup logs tab"""
        main_frame = ttk.Frame(parent)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)
        
        # Log text area
        log_frame = ttk.LabelFrame(main_frame, text="Application Logs", padding=15)
        log_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=20, width=80)
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        # Log control buttons
        log_control_frame = ttk.Frame(main_frame)
        log_control_frame.pack(fill=tk.X)
        
        ttk.Button(log_control_frame, text="Clear Logs", command=self.clear_logs).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(log_control_frame, text="Save Logs", command=self.save_logs).pack(side=tk.LEFT)
        
    def setup_status_bar(self):
        """Setup status bar"""
        self.status_bar = ttk.Frame(self.root)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=(0, 10))
        
        self.status_label = ttk.Label(self.status_bar, text="Ready")
        self.status_label.pack(side=tk.LEFT)
        
        # Connection indicator
        self.conn_indicator = ttk.Label(self.status_bar, text="●", foreground="red")
        self.conn_indicator.pack(side=tk.RIGHT, padx=(10, 0))
        
        ttk.Label(self.status_bar, text="Connection:").pack(side=tk.RIGHT)
        
    def log_message(self, message, level="INFO"):
        """Add message to log"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] {level}: {message}\n"
        
        self.log_text.insert(tk.END, log_entry)
        self.log_text.see(tk.END)
        
        # Also update status bar for important messages
        if level in ["ERROR", "SUCCESS"]:
            self.status_label.config(text=message)
            
    def check_dependencies(self):
        """Check if required dependencies are installed"""
        try:
            subprocess.run(["sshpass", "-V"], capture_output=True, check=True)
            self.log_message("sshpass is installed")
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.log_message("sshpass is not installed. Please install it: sudo apt-get install sshpass", "ERROR")
            messagebox.showerror("Dependency Missing", 
                               "sshpass is required but not installed.\n\n"
                               "Please install it with:\n"
                               "sudo apt-get install sshpass")
            
    def execute_remote_command(self, command):
        """Execute command on remote host"""
        cmd = [
            "sshpass", "-p", self.remote_password.get(),
            "ssh", "-o", "StrictHostKeyChecking=no",
            f"{self.remote_user.get()}@{self.remote_host.get()}",
            command
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
            
    def test_connection(self):
        """Test SSH connection to remote host"""
        if self.operation_in_progress.get():
            return
            
        self.operation_in_progress.set(True)
        self.test_button.config(state="disabled")
        
        def test_thread():
            self.log_message("Testing SSH connection...")
            success, stdout, stderr = self.execute_remote_command("echo 'Connection test successful'")
            
            self.message_queue.put(("connection_test", success, stdout, stderr))
            
        threading.Thread(target=test_thread, daemon=True).start()
        
    def check_service_status(self):
        """Check screen recorder service status"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        if self.operation_in_progress.get():
            return
            
        self.operation_in_progress.set(True)
        
        def status_thread():
            self.log_message("Checking service status...")
            service = self.service_name.get()
            success, stdout, stderr = self.execute_remote_command(f"systemctl status {service}")
            
            self.message_queue.put(("service_status", success, stdout, stderr))
            
        threading.Thread(target=status_thread, daemon=True).start()
        
    def enable_service(self):
        """Enable and start the screen recorder service"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        if self.operation_in_progress.get():
            return
            
        result = messagebox.askyesno("Confirm", "Enable and start the screen recorder service?")
        if not result:
            return
            
        self.operation_in_progress.set(True)
        
        def enable_thread():
            service = self.service_name.get()
            self.log_message(f"Enabling service {service}...")
            
            # Enable service
            success1, stdout1, stderr1 = self.execute_remote_command(f"sudo systemctl enable {service}")
            
            # Start service
            success2, stdout2, stderr2 = self.execute_remote_command(f"sudo systemctl start {service}")
            
            self.message_queue.put(("service_enable", success1 and success2, 
                                  f"Enable: {stdout1}\nStart: {stdout2}", 
                                  f"Enable: {stderr1}\nStart: {stderr2}"))
            
        threading.Thread(target=enable_thread, daemon=True).start()
        
    def stop_service(self):
        """Stop the screen recorder service"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        result = messagebox.askyesno("Confirm", "Stop the screen recorder service?")
        if not result:
            return
            
        self.operation_in_progress.set(True)
        
        def stop_thread():
            service = self.service_name.get()
            self.log_message(f"Stopping service {service}...")
            success, stdout, stderr = self.execute_remote_command(f"sudo systemctl stop {service}")
            
            self.message_queue.put(("service_stop", success, stdout, stderr))
            
        threading.Thread(target=stop_thread, daemon=True).start()
        
    def restart_service(self):
        """Restart the screen recorder service"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        result = messagebox.askyesno("Confirm", "Restart the screen recorder service?")
        if not result:
            return
            
        self.operation_in_progress.set(True)
        
        def restart_thread():
            service = self.service_name.get()
            self.log_message(f"Restarting service {service}...")
            success, stdout, stderr = self.execute_remote_command(f"sudo systemctl restart {service}")
            
            self.message_queue.put(("service_restart", success, stdout, stderr))
            
        threading.Thread(target=restart_thread, daemon=True).start()
        
    def refresh_file_list(self):
        """Refresh the remote MP4 file list"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        if self.operation_in_progress.get():
            return
            
        self.operation_in_progress.set(True)
        
        def refresh_thread():
            self.log_message("Refreshing file list...")
            remote_dir = self.remote_dir.get()
            command = f"find '{remote_dir}' -maxdepth 1 -name '*.mp4' -type f -exec ls -lh {{}} \\; 2>/dev/null"
            success, stdout, stderr = self.execute_remote_command(command)
            
            self.message_queue.put(("file_list", success, stdout, stderr))
            
        threading.Thread(target=refresh_thread, daemon=True).start()
        
    def download_selected(self):
        """Download selected files"""
        selected_items = self.file_tree.selection()
        if not selected_items:
            messagebox.showwarning("No Selection", "Please select files to download")
            return
            
        self.download_files([self.file_tree.item(item)["values"][0] for item in selected_items])
        
    def download_all(self):
        """Download all files"""
        if not self.file_list_data:
            messagebox.showwarning("No Files", "No files to download")
            return
            
        result = messagebox.askyesno("Confirm", f"Download all {len(self.file_list_data)} files?")
        if result:
            self.download_files([file_data["filename"] for file_data in self.file_list_data])
            
    def download_files(self, filenames):
        """Download specified files"""
        if not self.is_connected.get():
            messagebox.showwarning("Not Connected", "Please test connection first")
            return
            
        if self.operation_in_progress.get():
            return
            
        # Create local directory
        local_dir = self.local_dir.get()
        os.makedirs(local_dir, exist_ok=True)
        
        self.operation_in_progress.set(True)
        self.progress_var.set(0)
        
        def download_thread():
            total_files = len(filenames)
            downloaded = 0
            failed = 0
            
            for i, filename in enumerate(filenames):
                self.message_queue.put(("progress_update", (i / total_files) * 100, f"Downloading {filename}..."))
                
                remote_path = f"{self.remote_dir.get()}/{filename}"
                local_path = os.path.join(local_dir, filename)
                
                cmd = [
                    "sshpass", "-p", self.remote_password.get(),
                    "scp", "-o", "StrictHostKeyChecking=no",
                    f"{self.remote_user.get()}@{self.remote_host.get()}:{remote_path}",
                    local_path
                ]
                
                try:
                    result = subprocess.run(cmd, capture_output=True, timeout=300)
                    if result.returncode == 0:
                        downloaded += 1
                        self.message_queue.put(("log", f"Downloaded: {filename}", "SUCCESS"))
                    else:
                        failed += 1
                        self.message_queue.put(("log", f"Failed to download: {filename}", "ERROR"))
                except Exception as e:
                    failed += 1
                    self.message_queue.put(("log", f"Error downloading {filename}: {str(e)}", "ERROR"))
                    
            self.message_queue.put(("download_complete", downloaded, failed, total_files))
            
        threading.Thread(target=download_thread, daemon=True).start()
        
    def delete_selected(self):
        """Delete selected remote files"""
        selected_items = self.file_tree.selection()
        if not selected_items:
            messagebox.showwarning("No Selection", "Please select files to delete")
            return
            
        filenames = [self.file_tree.item(item)["values"][0] for item in selected_items]
        
        result = messagebox.askyesno("Confirm Deletion", 
                                   f"Delete {len(filenames)} selected file(s) from remote host?\n\n"
                                   "This action cannot be undone!")
        if not result:
            return
            
        if self.operation_in_progress.get():
            return
            
        self.operation_in_progress.set(True)
        
        def delete_thread():
            deleted = 0
            failed = 0
            
            for filename in filenames:
                remote_path = f"{self.remote_dir.get()}/{filename}"
                success, stdout, stderr = self.execute_remote_command(f"rm '{remote_path}'")
                
                if success:
                    deleted += 1
                    self.message_queue.put(("log", f"Deleted: {filename}", "SUCCESS"))
                else:
                    failed += 1
                    self.message_queue.put(("log", f"Failed to delete: {filename}", "ERROR"))
                    
            self.message_queue.put(("delete_complete", deleted, failed))
            
        threading.Thread(target=delete_thread, daemon=True).start()
        
    def browse_local_dir(self):
        """Browse for local directory"""
        directory = filedialog.askdirectory(initialdir=self.local_dir.get())
        if directory:
            self.local_dir.set(directory)
            
    def clear_logs(self):
        """Clear the log text area"""
        self.log_text.delete(1.0, tk.END)
        
    def save_logs(self):
        """Save logs to file"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        if filename:
            try:
                with open(filename, 'w') as f:
                    f.write(self.log_text.get(1.0, tk.END))
                messagebox.showinfo("Success", f"Logs saved to {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save logs: {str(e)}")
                
    def process_queue(self):
        """Process messages from worker threads"""
        try:
            while True:
                message = self.message_queue.get_nowait()
                msg_type = message[0]
                
                if msg_type == "connection_test":
                    success, stdout, stderr = message[1], message[2], message[3]
                    self.operation_in_progress.set(False)
                    self.test_button.config(state="normal")
                    
                    if success:
                        self.is_connected.set(True)
                        self.connection_status.config(text="Connected", foreground="green")
                        self.conn_indicator.config(foreground="green")
                        self.log_message("SSH connection successful", "SUCCESS")
                    else:
                        self.is_connected.set(False)
                        self.connection_status.config(text="Connection failed", foreground="red")
                        self.conn_indicator.config(foreground="red")
                        self.log_message(f"SSH connection failed: {stderr}", "ERROR")
                        
                elif msg_type == "service_status":
                    success, stdout, stderr = message[1], message[2], message[3]
                    self.operation_in_progress.set(False)
                    
                    self.service_status_text.delete(1.0, tk.END)
                    if success:
                        self.service_status_text.insert(tk.END, stdout)
                        self.log_message("Service status retrieved", "SUCCESS")
                    else:
                        self.service_status_text.insert(tk.END, f"Error: {stderr}")
                        self.log_message(f"Failed to get service status: {stderr}", "ERROR")
                        
                elif msg_type in ["service_enable", "service_stop", "service_restart"]:
                    success, stdout, stderr = message[1], message[2], message[3]
                    self.operation_in_progress.set(False)
                    
                    if success:
                        self.log_message(f"Service operation completed successfully", "SUCCESS")
                        # Refresh service status
                        self.check_service_status()
                    else:
                        self.log_message(f"Service operation failed: {stderr}", "ERROR")
                        
                elif msg_type == "file_list":
                    success, stdout, stderr = message[1], message[2], message[3]
                    self.operation_in_progress.set(False)
                    
                    # Clear existing items
                    for item in self.file_tree.get_children():
                        self.file_tree.delete(item)
                    self.file_list_data.clear()
                    
                    if success and stdout.strip():
                        lines = stdout.strip().split('\n')
                        for line in lines:
                            if line.strip():
                                parts = line.split()
                                if len(parts) >= 9:
                                    filename = os.path.basename(parts[-1])
                                    size = parts[4]
                                    date = f"{parts[5]} {parts[6]} {parts[7]}"
                                    
                                    self.file_tree.insert("", tk.END, values=(filename, size, date))
                                    self.file_list_data.append({
                                        "filename": filename,
                                        "size": size,
                                        "date": date,
                                        "full_path": parts[-1]
                                    })
                        
                        self.log_message(f"Found {len(self.file_list_data)} MP4 files", "SUCCESS")
                    else:
                        self.log_message("No MP4 files found", "INFO")
                        
                elif msg_type == "progress_update":
                    progress, status = message[1], message[2]
                    self.progress_var.set(progress)
                    self.progress_label.config(text=status)
                    
                elif msg_type == "download_complete":
                    downloaded, failed, total = message[1], message[2], message[3]
                    self.operation_in_progress.set(False)
                    self.progress_var.set(100)
                    self.progress_label.config(text=f"Download complete: {downloaded}/{total} successful")
                    
                    messagebox.showinfo("Download Complete", 
                                      f"Download completed!\n\n"
                                      f"Successfully downloaded: {downloaded}\n"
                                      f"Failed: {failed}\n"
                                      f"Total: {total}")
                    
                    # Refresh file list
                    self.refresh_file_list()
                    
                elif msg_type == "delete_complete":
                    deleted, failed = message[1], message[2]
                    self.operation_in_progress.set(False)
                    
                    messagebox.showinfo("Delete Complete", 
                                      f"Delete completed!\n\n"
                                      f"Successfully deleted: {deleted}\n"
                                      f"Failed: {failed}")
                    
                    # Refresh file list
                    self.refresh_file_list()
                    
                elif msg_type == "log":
                    message_text, level = message[1], message[2]
                    self.log_message(message_text, level)
                    
        except queue.Empty:
          pass
          
        # Schedule next check
        self.root.after(100, self.process_queue)

def main():
    """Main function to run the application"""
    root = tk.Tk()
    app = RemoteMP4Manager(root)
    
    # Set application icon (if available)
    try:
        root.iconname("Remote MP4 Manager")
    except:
        pass
        
    # Handle window close
    def on_closing():
        if app.operation_in_progress.get():
            if messagebox.askokcancel("Quit", "An operation is in progress. Do you want to quit anyway?"):
                root.destroy()
        else:
            root.destroy()
            
    root.protocol("WM_DELETE_WINDOW", on_closing)
    
    # Start the GUI
    root.mainloop()

if __name__ == "__main__":
    main()