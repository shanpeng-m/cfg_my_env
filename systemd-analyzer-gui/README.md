# SystemD Analyzer GUI - Installation Guide

## 系统要求

- Ubuntu 18.04 或更高版本
- Python 3.6 或更高版本
- 网络连接（用于安装依赖）

## 安装步骤

### 1. 准备系统环境

```bash
# 更新系统包
sudo apt update

# 安装必要的系统依赖
sudo apt install python3 python3-pip python3-tk sshpass

# 安装 PyInstaller
pip3 install --user pyinstaller
```

### 2. 下载和构建

```bash
# 创建工作目录
mkdir systemd-analyzer-gui
cd systemd-analyzer-gui

# 保存 Python 脚本为 systemd_analyzer_gui.py
# 保存构建脚本为 build.sh

# 给构建脚本执行权限
chmod +x build.sh

# 运行构建脚本
./build.sh
```

### 3. 运行应用程序

```bash
# 直接运行可执行文件
./SystemD_Analyzer

# 或者安装到应用程序菜单
cp systemd-analyzer.desktop ~/.local/share/applications/
```

## 功能说明

### 主要功能
- **图形化界面**：友好的 GUI 界面，无需命令行操作
- **多主机支持**：同时分析多台服务器的 SystemD 状态
- **主机配置管理**：可视化配置和管理目标主机列表
- **实时日志**：显示执行过程和结果
- **文件管理**：自动下载和组织分析结果
- **权限管理**：自动设置文件权限
- **配置导入导出**：支持保存和加载主机配置

### 界面元素
1. **Configuration**: 设置 SSH 和 Sudo 密码
2. **Target Hosts**: 显示要分析的主机列表，点击 "Configure Hosts" 进行管理
3. **Output Directory**: 选择结果保存目录
4. **Control Buttons**: 
   - Start Analysis: 开始分析
   - Stop: 停止分析
   - Clear Log: 清空日志
   - Open Results: 打开结果目录
5. **Progress Bar**: 显示执行进度
6. **Output Log**: 显示详细的执行日志
7. **Status Bar**: 显示当前状态

## 使用说明

### 1. 配置设置
- 在 "SSH Password" 字段输入目标主机的 SSH 密码
- 在 "Sudo Password" 字段输入 sudo 密码（如果与 SSH 密码不同）

### 2. 配置目标主机
- 点击 "Configure Hosts" 按钮打开主机配置对话框
- 在对话框中可以：
  - **添加主机**：填写主机名和地址（格式：user@ip），点击 "Add Host"
  - **编辑主机**：双击列表中的主机，或选中后修改信息点击 "Update Selected"
  - **删除主机**：选中主机后点击 "Delete Selected"
  - **导入配置**：点击 "Load from File" 从 JSON 文件导入主机列表
  - **导出配置**：点击 "Save to File" 将当前配置保存为 JSON 文件
  - **重置默认**：点击 "Reset to Default" 恢复默认主机配置

### 3. 选择输出目录
- 点击 "Browse" 按钮选择结果保存目录
- 如果不选择，将使用当前目录

### 4. 开始分析
- 点击 "Start Analysis" 按钮开始分析
- 观察日志输出了解执行进度
- 可以随时点击 "Stop" 按钮停止分析

### 5. 查看结果
- 分析完成后，点击 "Open Results" 打开结果目录
- 每个主机会生成两个文件：
  - `hostname_timestamp_dump.log`: SystemD 配置转储
  - `hostname_timestamp_plot.svg`: SystemD 启动时序图
- 同时生成 `README.txt` 汇总报告

## 主机配置对话框详细说明

### 界面布局
- **Host List**: 显示当前配置的所有主机，支持滚动查看
- **Add/Edit Host**: 输入区域，包含主机名和地址字段
- **操作按钮**:
  - Add Host: 添加新主机
  - Update Selected: 更新选中的主机
  - Delete Selected: 删除选中的主机
- **File Operations**: 文件导入导出功能
- **底部按钮**: OK 确认更改，Cancel 取消更改

### 操作技巧
- 双击主机列表中的项目可以快速编辑
- 支持键盘导航：Tab 键切换字段，Enter 键添加主机
- 主机地址格式：`username@ip_address`，例如：`autoware@192.168.20.11`
- 配置文件格式为 JSON，可以手动编辑后导入

### 默认主机配置
```json
{
  "main": "autoware@192.168.20.11",
  "sub": "autoware@192.168.20.21",
  "perception1": "autoware@192.168.20.31",
  "perception2": "autoware@192.168.20.32",
  "logging": "autoware@192.168.20.71"
}
```

## 故障排除

### 常见问题

1. **SSH 连接失败**
   - 检查目标主机是否可达：`ping <target_ip>`
   - 确认 SSH 服务运行：`ssh user@target_ip`
   - 验证用户名和密码是否正确

2. **sshpass 未安装**
   - 错误信息："sshpass is not installed"
   - 解决方法：`sudo apt-get install sshpass`

3. **权限不足**
   - 确保目标主机用户有 sudo 权限
   - 检查 sudo 密码是否正确

4. **主机配置对话框显示不完整**
   - 已修复：对话框现在默认尺寸为 750x550，确保所有内容可见
   - 支持窗口调整大小和滚动

5. **子对话框被遮挡**
   - 已修复：文件选择和消息框现在能正确显示在前面
   - 改进了窗口层级管理

6. **网络超时**
   - 增加连接超时时间
   - 检查网络连接稳定性
   - 确认防火墙设置

### 日志级别说明
- **INFO** (黑色): 一般信息
- **SUCCESS** (绿色): 操作成功
- **WARNING** (橙色): 警告信息
- **ERROR** (红色): 错误信息

### 性能建议
- 对于大量主机，建议分批处理
- 网络较慢时可以增加超时设置
- 定期清理日志以提高界面响应速度

## 更新日志

### v1.1 (最新版本)
- 修复主机配置对话框尺寸问题，默认显示所有内容
- 修复子对话框层级问题，确保文件选择框正常显示
- 改进用户界面布局和交互体验
- 增加键盘快捷键支持
- 优化窗口居中算法
- 添加操作提示和帮助信息

### v1.0
- 初始版本发布
- 基本的多主机 SystemD 分析功能
- 图形化用户界面
- 实时日志显示