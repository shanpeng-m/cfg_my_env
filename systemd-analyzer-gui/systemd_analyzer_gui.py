#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import subprocess
import threading
import os
import datetime
import json
from pathlib import Path

class HostConfigDialog:
    def __init__(self, parent, hosts_dict):
        self.result = None
        self.hosts = hosts_dict.copy()
        self.parent = parent
        
        # 创建对话框窗口
        self.dialog = tk.Toplevel(parent)
        self.dialog.title("Host Configuration")
        # 增加窗口大小，确保内容完全显示
        self.dialog.geometry("800x850")
        self.dialog.resizable(True, True)
        self.dialog.transient(parent)
        
        # 先不设置grab_set，让子对话框能正常显示
        # self.dialog.grab_set()
        
        # 居中显示
        self.center_window()
        
        # 设置最小窗口大小
        self.dialog.minsize(650, 500)
        
        self.setup_ui()
        
        # 在UI设置完成后再设置grab_set，但允许子窗口
        self.dialog.after(100, self.setup_modal)
        
    def center_window(self):
        # 更好的居中算法
        self.dialog.update_idletasks()
        parent_x = self.parent.winfo_rootx()
        parent_y = self.parent.winfo_rooty()
        parent_width = self.parent.winfo_width()
        parent_height = self.parent.winfo_height()
        
        dialog_width = 800
        dialog_height = 850
        
        x = parent_x + (parent_width - dialog_width) // 2
        y = parent_y + (parent_height - dialog_height) // 2
        
        self.dialog.geometry(f"{dialog_width}x{dialog_height}+{x}+{y}")
        
    def setup_modal(self):
        # 设置为模态，但不完全阻止子窗口
        self.dialog.focus_set()
        self.dialog.lift()
        
    def setup_ui(self):
        main_frame = ttk.Frame(self.dialog, padding="15")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 标题
        title_label = ttk.Label(main_frame, text="Configure Target Hosts", 
                               font=("Arial", 14, "bold"))
        title_label.pack(pady=(0, 15))
        
        # 主机列表框架
        list_frame = ttk.LabelFrame(main_frame, text="Host List", padding="10")
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 15))
        
        # 创建Treeview用于显示和编辑主机
        columns = ("hostname", "address")
        self.tree = ttk.Treeview(list_frame, columns=columns, show="headings", height=12)
        
        # 设置列标题
        self.tree.heading("hostname", text="Hostname")
        self.tree.heading("address", text="Address (user@ip)")
        
        # 设置列宽
        self.tree.column("hostname", width=180, minwidth=120)
        self.tree.column("address", width=350, minwidth=250)
        
        # 添加滚动条
        scrollbar_v = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=self.tree.yview)
        scrollbar_h = ttk.Scrollbar(list_frame, orient=tk.HORIZONTAL, command=self.tree.xview)
        self.tree.configure(yscrollcommand=scrollbar_v.set, xscrollcommand=scrollbar_h.set)
        
        # 网格布局
        self.tree.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        scrollbar_v.grid(row=0, column=1, sticky=(tk.N, tk.S))
        scrollbar_h.grid(row=1, column=0, sticky=(tk.W, tk.E))
        
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        
        # 填充现有主机数据
        self.refresh_tree()
        
        # 编辑框架
        edit_frame = ttk.LabelFrame(main_frame, text="Add/Edit Host", padding="10")
        edit_frame.pack(fill=tk.X, pady=(0, 15))
        
        # 使用网格布局，增加间距
        ttk.Label(edit_frame, text="Hostname:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10), pady=5)
        self.hostname_var = tk.StringVar()
        hostname_entry = ttk.Entry(edit_frame, textvariable=self.hostname_var, width=25)
        hostname_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 20), pady=5)
        
        ttk.Label(edit_frame, text="Address:").grid(row=0, column=2, sticky=tk.W, padx=(0, 10), pady=5)
        self.address_var = tk.StringVar()
        address_entry = ttk.Entry(edit_frame, textvariable=self.address_var, width=35)
        address_entry.grid(row=0, column=3, sticky=(tk.W, tk.E), padx=(0, 20), pady=5)
        
        edit_frame.columnconfigure(1, weight=1)
        edit_frame.columnconfigure(3, weight=2)
        
        # 按钮框架 - 放在第二行
        button_frame = ttk.Frame(edit_frame)
        button_frame.grid(row=1, column=0, columnspan=4, pady=(10, 0))
        
        add_button = ttk.Button(button_frame, text="Add Host", command=self.add_host)
        add_button.pack(side=tk.LEFT, padx=(0, 10))
        
        update_button = ttk.Button(button_frame, text="Update Selected", command=self.update_host)
        update_button.pack(side=tk.LEFT, padx=(0, 10))
        
        delete_button = ttk.Button(button_frame, text="Delete Selected", command=self.delete_host)
        delete_button.pack(side=tk.LEFT)
        
        # 文件操作框架
        file_frame = ttk.LabelFrame(main_frame, text="File Operations", padding="10")
        file_frame.pack(fill=tk.X, pady=(0, 15))
        
        file_button_frame = ttk.Frame(file_frame)
        file_button_frame.pack()
        
        ttk.Button(file_button_frame, text="Load from File", command=self.load_from_file).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(file_button_frame, text="Save to File", command=self.save_to_file).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(file_button_frame, text="Reset to Default", command=self.reset_to_default).pack(side=tk.LEFT)
        
        # 底部按钮
        bottom_frame = ttk.Frame(main_frame)
        bottom_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(bottom_frame, text="Cancel", command=self.cancel).pack(side=tk.RIGHT, padx=(10, 0))
        ttk.Button(bottom_frame, text="OK", command=self.ok).pack(side=tk.RIGHT)
        
        # 添加说明文本
        help_frame = ttk.Frame(main_frame)
        help_frame.pack(fill=tk.X, pady=(5, 0))
        
        help_text = "Tip: Double-click a row to edit, or select a row and use the buttons above."
        help_label = ttk.Label(help_frame, text=help_text, font=("Arial", 9), foreground="gray")
        help_label.pack()
        
        # 绑定事件
        self.tree.bind("<Double-1>", self.on_item_double_click)
        self.tree.bind("<Button-1>", self.on_item_click)
        
        # 绑定回车键
        hostname_entry.bind("<Return>", lambda e: address_entry.focus())
        address_entry.bind("<Return>", lambda e: self.add_host())
        
    def refresh_tree(self):
        # 清空树
        for item in self.tree.get_children():
            self.tree.delete(item)
            
        # 添加主机
        for hostname, address in self.hosts.items():
            self.tree.insert("", tk.END, values=(hostname, address))
            
    def on_item_click(self, event):
        # 单击时清空输入框
        pass
        
    def on_item_double_click(self, event):
        selection = self.tree.selection()
        if selection:
            item = selection[0]
            values = self.tree.item(item, "values")
            self.hostname_var.set(values[0])
            self.address_var.set(values[1])
            
    def add_host(self):
        hostname = self.hostname_var.get().strip()
        address = self.address_var.get().strip()
        
        if not hostname or not address:
            # 创建临时的消息框，确保它在对话框前面
            msg = tk.Toplevel(self.dialog)
            msg.withdraw()  # 先隐藏
            msg.title("Error")
            msg.transient(self.dialog)
            msg.lift(self.dialog)
            msg.focus_set()
            messagebox.showerror("Error", "Please enter both hostname and address", parent=self.dialog)
            return
            
        if hostname in self.hosts:
            messagebox.showerror("Error", f"Hostname '{hostname}' already exists", parent=self.dialog)
            return
            
        self.hosts[hostname] = address
        self.refresh_tree()
        self.hostname_var.set("")
        self.address_var.set("")
        
    def update_host(self):
        selection = self.tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a host to update", parent=self.dialog)
            return
            
        hostname = self.hostname_var.get().strip()
        address = self.address_var.get().strip()
        
        if not hostname or not address:
            messagebox.showerror("Error", "Please enter both hostname and address", parent=self.dialog)
            return
            
        # 获取选中的原始主机名
        item = selection[0]
        old_hostname = self.tree.item(item, "values")[0]
        
        # 如果主机名改变了，删除旧的
        if old_hostname != hostname:
            if hostname in self.hosts:
                messagebox.showerror("Error", f"Hostname '{hostname}' already exists", parent=self.dialog)
                return
            del self.hosts[old_hostname]
            
        self.hosts[hostname] = address
        self.refresh_tree()
        self.hostname_var.set("")
        self.address_var.set("")
        
    def delete_host(self):
        selection = self.tree.selection()
        if not selection:
            messagebox.showerror("Error", "Please select a host to delete", parent=self.dialog)
            return
            
        item = selection[0]
        hostname = self.tree.item(item, "values")[0]
        
        if messagebox.askyesno("Confirm", f"Delete host '{hostname}'?", parent=self.dialog):
            del self.hosts[hostname]
            self.refresh_tree()
            
    def load_from_file(self):
        # 临时释放模态状态，让文件对话框正常显示
        self.dialog.grab_release()
        
        file_path = filedialog.askopenfilename(
            title="Load Host Configuration",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            parent=self.dialog
        )
        
        # 重新设置焦点
        self.dialog.focus_set()
        self.dialog.lift()
        
        if file_path:
            try:
                with open(file_path, 'r') as f:
                    loaded_hosts = json.load(f)
                self.hosts = loaded_hosts
                self.refresh_tree()
                messagebox.showinfo("Success", "Host configuration loaded successfully", parent=self.dialog)
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load file: {str(e)}", parent=self.dialog)
                
    def save_to_file(self):
        # 临时释放模态状态
        self.dialog.grab_release()
        
        file_path = filedialog.asksaveasfilename(
            title="Save Host Configuration",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
            parent=self.dialog
        )
        
        # 重新设置焦点
        self.dialog.focus_set()
        self.dialog.lift()
        
        if file_path:
            try:
                with open(file_path, 'w') as f:
                    json.dump(self.hosts, f, indent=2)
                messagebox.showinfo("Success", "Host configuration saved successfully", parent=self.dialog)
            except Exception as e:
                messagebox.showerror("Error", f"Failed to save file: {str(e)}", parent=self.dialog)
                
    def reset_to_default(self):
        if messagebox.askyesno("Confirm", "Reset to default host configuration?", parent=self.dialog):
            self.hosts = {
                "main": "autoware@192.168.20.11",
                "sub": "autoware@192.168.20.21", 
                "perception1": "autoware@192.168.20.31",
                "perception2": "autoware@192.168.20.32",
                "logging": "autoware@192.168.20.71"
            }
            self.refresh_tree()
            
    def ok(self):
        if not self.hosts:
            messagebox.showerror("Error", "Please configure at least one host", parent=self.dialog)
            return
        self.result = self.hosts
        self.dialog.destroy()
        
    def cancel(self):
        self.result = None
        self.dialog.destroy()

class SystemDAnalyzerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("SystemD Analysis Tool")
        self.root.geometry("950x750")
        self.root.resizable(True, True)
        
        # 配置变量
        self.hosts = {
            "main": "autoware@192.168.20.11",
            "sub": "autoware@192.168.20.21", 
            "perception1": "autoware@192.168.20.31",
            "perception2": "autoware@192.168.20.32",
            "logging": "autoware@192.168.20.71"
        }
        
        self.ssh_password = tk.StringVar(value="autoware")
        self.sudo_password = tk.StringVar(value="autoware")
        self.output_dir = tk.StringVar(value="")
        self.is_running = False
        self.current_progress = 0
        self.total_hosts = 0
        
        self.setup_ui()
        self.update_host_display()
        
    def setup_ui(self):
        # 创建主框架
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 配置网格权重
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # 标题
        title_label = ttk.Label(main_frame, text="SystemD Analysis Tool", 
                               font=("Arial", 16, "bold"))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # 密码配置区域
        config_frame = ttk.LabelFrame(main_frame, text="Configuration", padding="10")
        config_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        config_frame.columnconfigure(1, weight=1)
        
        ttk.Label(config_frame, text="SSH Password:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        ssh_entry = ttk.Entry(config_frame, textvariable=self.ssh_password, show="*", width=20)
        ssh_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 20))
        
        ttk.Label(config_frame, text="Sudo Password:").grid(row=0, column=2, sticky=tk.W, padx=(0, 10))
        sudo_entry = ttk.Entry(config_frame, textvariable=self.sudo_password, show="*", width=20)
        sudo_entry.grid(row=0, column=3, sticky=(tk.W, tk.E))
        
        # 主机列表区域
        hosts_frame = ttk.LabelFrame(main_frame, text="Target Hosts", padding="10")
        hosts_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        hosts_frame.columnconfigure(0, weight=1)
        
        # 主机显示和配置按钮
        host_display_frame = ttk.Frame(hosts_frame)
        host_display_frame.grid(row=0, column=0, sticky=(tk.W, tk.E))
        host_display_frame.columnconfigure(0, weight=1)
        
        self.hosts_text_var = tk.StringVar()
        hosts_label = ttk.Label(host_display_frame, textvariable=self.hosts_text_var, 
                               font=("Courier", 10), justify=tk.LEFT)
        hosts_label.grid(row=0, column=0, sticky=tk.W)
        
        config_hosts_button = ttk.Button(host_display_frame, text="Configure Hosts", 
                                       command=self.configure_hosts)
        config_hosts_button.grid(row=0, column=1, sticky=tk.E, padx=(10, 0))
        
        # 输出目录选择
        dir_frame = ttk.Frame(main_frame)
        dir_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        dir_frame.columnconfigure(1, weight=1)
        
        ttk.Label(dir_frame, text="Output Directory:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        dir_entry = ttk.Entry(dir_frame, textvariable=self.output_dir, state="readonly")
        dir_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        
        dir_button = ttk.Button(dir_frame, text="Browse", command=self.browse_directory)
        dir_button.grid(row=0, column=2)
        
        # 控制按钮
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=4, column=0, columnspan=3, pady=(0, 10))
        
        self.start_button = ttk.Button(button_frame, text="Start Analysis", 
                                     command=self.start_analysis, style="Accent.TButton")
        self.start_button.pack(side=tk.LEFT, padx=(0, 10))
        
        self.stop_button = ttk.Button(button_frame, text="Stop", 
                                    command=self.stop_analysis, state="disabled")
        self.stop_button.pack(side=tk.LEFT, padx=(0, 10))
        
        clear_button = ttk.Button(button_frame, text="Clear Log", command=self.clear_log)
        clear_button.pack(side=tk.LEFT, padx=(0, 10))
        
        open_button = ttk.Button(button_frame, text="Open Results", command=self.open_results)
        open_button.pack(side=tk.LEFT)
        
        # 进度条和状态
        progress_frame = ttk.Frame(main_frame)
        progress_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        progress_frame.columnconfigure(0, weight=1)
        
        self.progress = ttk.Progressbar(progress_frame, mode='determinate')
        self.progress.grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 10))
        
        self.progress_label = ttk.Label(progress_frame, text="Ready")
        self.progress_label.grid(row=0, column=1)
        
        # 日志输出区域
        log_frame = ttk.LabelFrame(main_frame, text="Output Log", padding="5")
        log_frame.grid(row=6, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        main_frame.rowconfigure(6, weight=1)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=20, wrap=tk.WORD)
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 状态栏
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var, relief=tk.SUNKEN)
        status_bar.grid(row=7, column=0, columnspan=3, sticky=(tk.W, tk.E))
        
    def update_host_display(self):
        hosts_text = "\n".join([f"• {name}: {addr}" for name, addr in self.hosts.items()])
        self.hosts_text_var.set(hosts_text)
        
    def configure_hosts(self):
        dialog = HostConfigDialog(self.root, self.hosts)
        self.root.wait_window(dialog.dialog)
        
        if dialog.result is not None:
            self.hosts = dialog.result
            self.update_host_display()
            self.log_message(f"Host configuration updated. Total hosts: {len(self.hosts)}", "INFO")
            
    def update_progress(self, completed, total, current_host=""):
        self.current_progress = completed
        self.total_hosts = total
        
        if total > 0:
            percentage = (completed / total) * 100
            self.progress['value'] = percentage
            
            if current_host:
                self.progress_label.config(text=f"Processing {current_host} ({completed}/{total})")
            else:
                self.progress_label.config(text=f"{completed}/{total} completed ({percentage:.1f}%)")
        else:
            self.progress['value'] = 0
            self.progress_label.config(text="Ready")
            
        self.root.update()
        
    def browse_directory(self):
        directory = filedialog.askdirectory(title="Select Output Directory")
        if directory:
            self.output_dir.set(directory)
            
    def log_message(self, message, level="INFO"):
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        colors = {"INFO": "black", "SUCCESS": "green", "ERROR": "red", "WARNING": "orange"}
        
        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        
        # 设置颜色
        if level in colors:
            start_line = self.log_text.index(tk.END + "-2l linestart")
            end_line = self.log_text.index(tk.END + "-1l lineend")
            self.log_text.tag_add(level, start_line, end_line)
            self.log_text.tag_config(level, foreground=colors[level])
        
        self.log_text.config(state=tk.DISABLED)
        self.log_text.see(tk.END)
        self.root.update()
        
    def clear_log(self):
        self.log_text.config(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state=tk.DISABLED)
        
    def start_analysis(self):
        if not self.ssh_password.get() or not self.sudo_password.get():
            messagebox.showerror("Error", "Please enter both SSH and Sudo passwords")
            return
            
        if not self.hosts:
            messagebox.showerror("Error", "Please configure at least one host")
            return
            
        if not self.output_dir.get():
            # 如果没有选择目录，使用当前目录
            self.output_dir.set(os.getcwd())
            
        self.is_running = True
        self.start_button.config(state="disabled")
        self.stop_button.config(state="normal")
        self.current_progress = 0
        self.total_hosts = len(self.hosts)
        self.update_progress(0, self.total_hosts)
        self.status_var.set("Running analysis...")
        
        # 在新线程中运行分析
        self.analysis_thread = threading.Thread(target=self.run_analysis)
        self.analysis_thread.daemon = True
        self.analysis_thread.start()
        
    def stop_analysis(self):
        self.is_running = False
        self.start_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.update_progress(self.current_progress, self.total_hosts)
        self.status_var.set("Analysis stopped")
        self.log_message("Analysis stopped by user", "WARNING")
        
    def run_analysis(self):
        try:
            # 检查sshpass
            if not self.check_sshpass():
                return
                
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            local_dir = os.path.join(self.output_dir.get(), f"systemd_analysis_{timestamp}")
            os.makedirs(local_dir, exist_ok=True)
            
            self.log_message(f"Starting SystemD analysis task...", "INFO")
            self.log_message(f"Timestamp: {timestamp}", "INFO")
            self.log_message(f"Results will be saved to: {local_dir}", "INFO")
            self.log_message(f"Total hosts to process: {self.total_hosts}", "INFO")
            self.log_message("-" * 50, "INFO")
            
            success_count = 0
            completed_count = 0
            
            for hostname, host_addr in self.hosts.items():
                if not self.is_running:
                    break
                    
                self.update_progress(completed_count, self.total_hosts, hostname)
                self.log_message(f"Processing host: {hostname} ({host_addr})", "INFO")
                
                # 检查SSH连接
                if not self.test_ssh_connection(host_addr):
                    self.log_message(f"  ✗ Cannot connect to {hostname} ({host_addr})", "ERROR")
                    completed_count += 1
                    self.update_progress(completed_count, self.total_hosts)
                    continue
                    
                self.log_message(f"  ✓ SSH connection successful", "SUCCESS")
                
                # 执行远程命令
                if self.execute_remote_commands(hostname, host_addr, local_dir, timestamp):
                    success_count += 1
                    self.log_message(f"  ✓ {hostname} completed successfully", "SUCCESS")
                else:
                    self.log_message(f"  ✗ {hostname} failed", "ERROR")
                    
                completed_count += 1
                self.update_progress(completed_count, self.total_hosts)
                self.log_message("-" * 50, "INFO")
                
            if self.is_running:
                self.log_message(f"Task completed! {success_count}/{self.total_hosts} hosts processed successfully", "SUCCESS")
                self.log_message(f"Result files saved in: {local_dir}", "INFO")
                
                # 设置权限
                self.set_permissions(local_dir)
                
                # 生成报告
                self.generate_report(local_dir, timestamp)
                
                self.status_var.set(f"Completed - {success_count}/{self.total_hosts} hosts successful")
                self.progress_label.config(text=f"Completed ({success_count}/{self.total_hosts} successful)")
            
        except Exception as e:
            self.log_message(f"Error: {str(e)}", "ERROR")
            self.status_var.set("Error occurred")
        finally:
            self.start_button.config(state="normal")
            self.stop_button.config(state="disabled")
            
    def check_sshpass(self):
        try:
            subprocess.run(["sshpass", "-V"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.log_message("Error: sshpass is not installed", "ERROR")
            self.log_message("Please install it: sudo apt-get install sshpass", "ERROR")
            messagebox.showerror("Error", "sshpass is not installed.\nPlease install it with: sudo apt-get install sshpass")
            return False
            
    def test_ssh_connection(self, host_addr):
        try:
            cmd = [
                "sshpass", "-p", self.ssh_password.get(),
                "ssh", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no",
                host_addr, "echo 'SSH connection successful'"
            ]
            result = subprocess.run(cmd, capture_output=True, timeout=10)
            return result.returncode == 0
        except:
            return False
            
    def execute_remote_commands(self, hostname, host_addr, local_dir, timestamp):
        try:
            self.log_message(f"  > Executing systemd-analyze commands...", "INFO")
            
            # 创建远程脚本
            remote_script = f'''
            TEMP_DIR="/tmp/systemd_analysis_$(date +%s)"
            mkdir -p "$TEMP_DIR"
            cd "$TEMP_DIR"
            
            echo "Executing systemd-analyze dump..."
            echo "{self.sudo_password.get()}" | sudo -S systemd-analyze dump > dump.log 2>&1
            
            echo "Executing systemd-analyze plot..."
            echo "{self.sudo_password.get()}" | sudo -S systemd-analyze plot > plot.svg 2>&1
            
            if [ -f dump.log ] && [ -f plot.svg ]; then
                echo "Files generated successfully"
                echo "$TEMP_DIR"
            else
                echo "File generation failed"
                exit 1
            fi
            '''
            
            # 执行远程脚本
            cmd = [
                "sshpass", "-p", self.ssh_password.get(),
                "ssh", "-o", "StrictHostKeyChecking=no", host_addr
            ]
            
            result = subprocess.run(cmd, input=remote_script, text=True, capture_output=True, timeout=60)
            
            if result.returncode == 0:
                # 获取远程临时目录
                lines = result.stdout.strip().split('\n')
                remote_temp_dir = lines[-1] if lines else ""
                
                if remote_temp_dir and remote_temp_dir.startswith('/tmp/systemd_analysis_'):
                    return self.download_files(hostname, host_addr, remote_temp_dir, local_dir, timestamp)
                    
            return False
            
        except Exception as e:
            self.log_message(f"  ✗ Remote command execution failed: {str(e)}", "ERROR")
            return False
            
    def download_files(self, hostname, host_addr, remote_temp_dir, local_dir, timestamp):
        try:
            self.log_message(f"  > Downloading files...", "INFO")
            
            success = True
            
            # 下载dump.log
            dump_file = os.path.join(local_dir, f"{hostname}_{timestamp}_dump.log")
            cmd = [
                "sshpass", "-p", self.ssh_password.get(),
                "scp", "-o", "StrictHostKeyChecking=no",
                f"{host_addr}:{remote_temp_dir}/dump.log", dump_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, timeout=30)
            if result.returncode == 0:
                self.log_message(f"    ✓ dump.log downloaded successfully", "SUCCESS")
            else:
                self.log_message(f"    ✗ dump.log download failed", "ERROR")
                success = False
                
            # 下载plot.svg
            plot_file = os.path.join(local_dir, f"{hostname}_{timestamp}_plot.svg")
            cmd = [
                "sshpass", "-p", self.ssh_password.get(),
                "scp", "-o", "StrictHostKeyChecking=no",
                f"{host_addr}:{remote_temp_dir}/plot.svg", plot_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, timeout=30)
            if result.returncode == 0:
                self.log_message(f"    ✓ plot.svg downloaded successfully", "SUCCESS")
            else:
                self.log_message(f"    ✗ plot.svg download failed", "ERROR")
                success = False
                
            # 清理远程临时文件
            cmd = [
                "sshpass", "-p", self.ssh_password.get(),
                "ssh", "-o", "StrictHostKeyChecking=no", host_addr,
                f"rm -rf {remote_temp_dir}"
            ]
            subprocess.run(cmd, capture_output=True, timeout=10)
            self.log_message(f"  ~ Remote temporary files cleaned up", "INFO")
            
            return success
            
        except Exception as e:
            self.log_message(f"  ✗ File download failed: {str(e)}", "ERROR")
            return False
            
    def set_permissions(self, local_dir):
        try:
            self.log_message("> Setting file permissions...", "INFO")
            
            # 设置目录权限
            os.chmod(local_dir, 0o755)
            self.log_message("  ✓ Directory permissions set (755)", "SUCCESS")
            
            # 设置文件权限
            for file in os.listdir(local_dir):
                file_path = os.path.join(local_dir, file)
                if os.path.isfile(file_path):
                    os.chmod(file_path, 0o644)
            self.log_message("  ✓ File permissions set (644)", "SUCCESS")
            
        except Exception as e:
            self.log_message(f"  ! Could not set permissions: {str(e)}", "WARNING")
            
    def generate_report(self, local_dir, timestamp):
        try:
            self.log_message("Generating summary report...", "INFO")
            
            report_file = os.path.join(local_dir, "README.txt")
            with open(report_file, 'w') as f:
                f.write("SystemD Analysis Report\n")
                f.write("======================\n")
                f.write(f"Generated at: {datetime.datetime.now()}\n")
                f.write(f"Timestamp: {timestamp}\n\n")
                f.write("File descriptions:\n")
                f.write("- *_dump.log: systemd-analyze dump output\n")
                f.write("- *_plot.svg: systemd-analyze plot output\n\n")
                f.write("Host list:\n")
                for hostname, host_addr in self.hosts.items():
                    f.write(f"- {hostname}: {host_addr}\n")
                    
            os.chmod(report_file, 0o644)
            self.log_message("✓ Summary report generated", "SUCCESS")
            
        except Exception as e:
            self.log_message(f"! Could not generate report: {str(e)}", "WARNING")
            
    def open_results(self):
        if self.output_dir.get() and os.path.exists(self.output_dir.get()):
            subprocess.run(["xdg-open", self.output_dir.get()])
        else:
            messagebox.showwarning("Warning", "No output directory selected or directory doesn't exist")

def main():
    root = tk.Tk()
    app = SystemDAnalyzerGUI(root)
    
    # 设置应用图标（如果有的话）
    try:
        # root.iconbitmap('icon.ico')  # 如果有图标文件
        pass
    except:
        pass
        
    root.mainloop()

if __name__ == "__main__":
    main()