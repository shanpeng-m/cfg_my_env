# SystemD Analyzer GUI

一个带有图形界面的 SystemD 分析工具，支持通过 SSH 连接远程服务器进行 SystemD 服务分析和监控。

## 功能特性

- 🔍 多服务器 SystemD 服务分析
- 📊 可视化主机配置管理
- 📝 实时执行日志显示
- 📁 自动结果文件组织
- 🔐 支持 SSH 密钥和密码认证
- 🖥️ 简洁直观的图形界面
- 📦 支持 Debian/Ubuntu 包安装

## 快速开始

### 方式 1：完整构建（推荐）

```bash
# 一键构建可执行文件和 Debian 包
./build-all.sh

# 安装包
sudo dpkg -i systemd-analyzer-gui_1.0.0-1_amd64.deb
sudo apt-get install -f  # 如果需要修复依赖

# 运行应用
systemd-analyzer
```

### 方式 2：分步构建

```bash
# 步骤 1：构建可执行文件
./build.sh

# 步骤 2：构建 Debian 包
./build-deb.sh

# 步骤 3：安装包
sudo dpkg -i systemd-analyzer-gui_1.0.0-1_amd64.deb
```

### 方式 3：直接运行

```bash
# 构建可执行文件
./build.sh

# 直接运行
./SystemD_Analyzer
```

## 项目架构

### 脚本职责分工

| 脚本           | 职责           | 输入        | 输出                   |
| -------------- | -------------- | ----------- | ---------------------- |
| `build.sh`     | 构建可执行文件 | Python 源码 | `SystemD_Analyzer`     |
| `build-deb.sh` | 构建 Debian 包 | 可执行文件  | `.deb` 包              |
| `build-all.sh` | 完整构建流程   | Python 源码 | 可执行文件 + `.deb` 包 |

### 文件结构

```
systemd-analyzer-gui/
├── build.sh              # 构建可执行文件
├── build-deb.sh          # 构建 Debian 包
├── build-all.sh          # 完整构建流程
├── systemd_analyzer_gui.py    # 源代码
├── systemd-analyzer.desktop   # 桌面文件
├── systemd-analyzer.svg       # 应用图标
├── host_list.json             # 主机配置文件
├── debian/               # Debian 包结构
│   ├── DEBIAN/
│   │   ├── control       # 包信息
│   │   ├── postinst      # 安装后脚本
│   │   ├── prerm         # 卸载前脚本
│   │   └── postrm        # 卸载后脚本
│   ├── opt/systemd-analyzer-gui/
│   ├── usr/bin/
│   ├── usr/share/applications/
│   ├── usr/share/icons/
│   └── usr/share/doc/
└── README.md             # 本文档
```

## 安装方式

### 1. Debian 包安装（推荐）

```bash
# 安装包
sudo dpkg -i systemd-analyzer-gui_1.0.0-1_amd64.deb

# 修复依赖（如果需要）
sudo apt-get install -f
```

**优势**：
- 自动桌面集成（在应用程序菜单中显示）
- 系统级安装
- 自动依赖管理
- 支持标准卸载

### 2. 直接运行

```bash
./SystemD_Analyzer
```

**适用场景**：
- 快速测试
- 便携式使用
- 不需要系统集成

## 使用方法

### 启动应用

安装后，可以通过以下方式启动：

1. **命令行**：`systemd-analyzer`
2. **应用程序菜单**：搜索 "SystemD Analyzer"
3. **直接运行**：`./SystemD_Analyzer`

### 配置设置

1. **SSH 密码**：输入目标主机的 SSH 密码
2. **Sudo 密码**：输入 sudo 密码（如果与 SSH 密码不同）

### 配置目标主机

点击 "Configure Hosts" 按钮打开主机配置对话框：

- **添加主机**：填写主机名和地址（格式：user@ip），点击 "Add Host"
- **编辑主机**：双击列表中的主机，或选中后修改信息点击 "Update Selected"
- **删除主机**：选中主机后点击 "Delete Selected"
- **导入配置**：点击 "Load from File" 从 JSON 文件导入主机列表
- **导出配置**：点击 "Save to File" 将当前配置保存为 JSON 文件
- **重置默认**：点击 "Reset to Default" 恢复默认主机配置

### 选择输出目录

- 点击 "Browse" 按钮选择结果保存目录
- 如果不选择，将使用当前目录

### 开始分析

- 点击 "Start Analysis" 按钮开始分析
- 观察日志输出了解执行进度
- 可以随时点击 "Stop" 按钮停止分析

### 查看结果

- 点击 "Open Results" 按钮打开结果目录
- 分析结果按主机名和时间戳组织

## 依赖关系

### 构建时依赖
- `python3` (>= 3.6)
- `python3-pip`
- `python3-tk`
- `pyinstaller`
- `dpkg-dev` (用于构建包)

### 运行时依赖
- `python3-tk`
- `sshpass`

## 故障排除

### 构建失败

1. **检查 Python 环境**：
   ```bash
   python3 --version
   pip3 --version
   ```

2. **安装缺失依赖**：
   ```bash
   sudo apt-get install python3 python3-pip python3-tk dpkg-dev
   pip3 install --user pyinstaller
   ```

3. **检查构建工具**：
   ```bash
   dpkg-deb --version
   ```

### 安装失败

1. **修复依赖问题**：
   ```bash
   sudo apt-get install -f
   ```

2. **手动安装依赖**：
   ```bash
   sudo apt-get install python3-tk sshpass
   ```

3. **检查权限**：
   ```bash
   sudo chmod +x /opt/systemd-analyzer-gui/SystemD_Analyzer
   sudo chmod +x /usr/bin/systemd-analyzer
   ```

### 桌面集成问题

1. **刷新桌面数据库**：
   ```bash
   update-desktop-database /usr/share/applications
   ```

2. **重启桌面环境**：
   - 注销并重新登录
   - 或重启系统

### 连接问题

1. **检查 SSH 服务**：
   ```bash
   ssh user@server
   ```

2. **检查 sshpass**：
   ```bash
   sshpass -V
   ```

3. **检查防火墙设置**

## 卸载

### 卸载 Debian 包

```bash
# 卸载包
sudo apt-get remove systemd-analyzer-gui

# 完全清理（包括配置文件）
sudo apt-get purge systemd-analyzer-gui
```

### 清理手动安装

```bash
# 删除可执行文件
rm -f SystemD_Analyzer

# 删除桌面文件（如果手动安装）
rm -f ~/.local/share/applications/systemd-analyzer.desktop
```

## 开发指南

### 修改源码

1. 编辑 `systemd_analyzer_gui.py`
2. 重新构建：
   ```bash
   ./build-all.sh
   ```

### 自定义包信息

编辑以下文件来自定义包：

- `debian/DEBIAN/control` - 包的基本信息和依赖
- `debian/DEBIAN/postinst` - 安装后脚本
- `debian/DEBIAN/prerm` - 卸载前脚本
- `debian/DEBIAN/postrm` - 卸载后脚本
- `debian/usr/share/doc/systemd-analyzer-gui/copyright` - 版权信息

### 更新版本

1. 修改 `debian/DEBIAN/control` 中的版本号
2. 更新 `debian/usr/share/doc/systemd-analyzer-gui/changelog.Debian`
3. 重新构建包

## 发布到 PPA

要将包发布到 Ubuntu PPA：

1. 创建 Launchpad 账户
2. 创建 PPA
3. 上传源码包（需要创建 .dsc 和 .tar.gz 文件）
4. 等待构建完成

## 许可证

本项目使用 MIT 许可证。详见 `debian/usr/share/doc/systemd-analyzer-gui/copyright`。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本
- SystemD 服务分析功能
- SSH 连接支持
- 图形用户界面
- Debian 包支持