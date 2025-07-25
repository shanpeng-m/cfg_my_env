# Remote MP4 Manager

一个带有图形界面的远程 MP4 文件管理工具，支持通过 SSH 连接远程服务器进行文件浏览和下载。

## 功能特性

- 🔍 浏览远程服务器目录
- 📥 下载 MP4 文件
- 📊 查看文件信息
- 🔐 支持 SSH 密钥和密码认证
- 🖥️ 简洁直观的图形界面
- 📦 支持 Debian/Ubuntu 包安装

## 快速开始

### 方式 1：完整构建（推荐）

```bash
# 一键构建可执行文件和 Debian 包
./build-all.sh

# 安装包
sudo dpkg -i remote-mp4-manager_1.0.0-1_amd64.deb
sudo apt-get install -f  # 如果需要修复依赖

# 运行应用
mp4-manager
```

### 方式 2：分步构建

```bash
# 步骤 1：构建可执行文件
./build.sh

# 步骤 2：构建 Debian 包
./build-deb.sh

# 步骤 3：安装包
sudo dpkg -i remote-mp4-manager_1.0.0-1_amd64.deb
```

### 方式 3：直接运行

```bash
# 构建可执行文件
./build.sh

# 直接运行
./Remote_MP4_Manager
```

## 项目架构

### 脚本职责分工

| 脚本           | 职责           | 输入        | 输出                   |
| -------------- | -------------- | ----------- | ---------------------- |
| `build.sh`     | 构建可执行文件 | Python 源码 | `Remote_MP4_Manager`   |
| `build-deb.sh` | 构建 Debian 包 | 可执行文件  | `.deb` 包              |
| `build-all.sh` | 完整构建流程   | Python 源码 | 可执行文件 + `.deb` 包 |

### 文件结构

```
mp4-manager-gui/
├── build.sh              # 构建可执行文件
├── build-deb.sh          # 构建 Debian 包
├── build-all.sh          # 完整构建流程
├── mp4_manager_gui.py    # 源代码
├── remote-mp4-manager.desktop  # 桌面文件
├── remote-mp4-manager.svg      # 应用图标
├── debian/               # Debian 包结构
│   ├── DEBIAN/
│   │   ├── control       # 包信息
│   │   ├── postinst      # 安装后脚本
│   │   ├── prerm         # 卸载前脚本
│   │   └── postrm        # 卸载后脚本
│   ├── opt/remote-mp4-manager/
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
sudo dpkg -i remote-mp4-manager_1.0.0-1_amd64.deb

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
./Remote_MP4_Manager
```

**适用场景**：
- 快速测试
- 便携式使用
- 不需要系统集成

## 使用方法

### 启动应用

安装后，可以通过以下方式启动：

1. **命令行**：`mp4-manager`
2. **应用程序菜单**：搜索 "Remote MP4 Manager"
3. **直接运行**：`./Remote_MP4_Manager`

### 连接远程服务器

1. 输入服务器地址（IP 或域名）
2. 输入用户名
3. 选择认证方式：
   - 密码认证
   - SSH 密钥认证
4. 点击连接

### 文件操作

- **浏览目录**：双击文件夹
- **下载文件**：选择文件后点击下载
- **查看信息**：右键文件查看详细信息

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
   sudo chmod +x /opt/remote-mp4-manager/Remote_MP4_Manager
   sudo chmod +x /usr/bin/mp4-manager
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
sudo apt-get remove remote-mp4-manager

# 完全清理（包括配置文件）
sudo apt-get purge remote-mp4-manager
```

### 清理手动安装

```bash
# 删除可执行文件
rm -f Remote_MP4_Manager

# 删除桌面文件（如果手动安装）
rm -f ~/.local/share/applications/remote-mp4-manager.desktop
```

## 开发指南

### 修改源码

1. 编辑 `mp4_manager_gui.py`
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
- `debian/usr/share/doc/remote-mp4-manager/copyright` - 版权信息

### 更新版本

1. 修改 `debian/DEBIAN/control` 中的版本号
2. 更新 `debian/usr/share/doc/remote-mp4-manager/changelog.Debian`
3. 重新构建包

## 发布到 PPA

要将包发布到 Ubuntu PPA：

1. 创建 Launchpad 账户
2. 创建 PPA
3. 上传源码包（需要创建 .dsc 和 .tar.gz 文件）
4. 等待构建完成

## 许可证

本项目使用 MIT 许可证。详见 `debian/usr/share/doc/remote-mp4-manager/copyright`。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### v1.0.0
- 初始版本
- 远程 MP4 文件管理功能
- SSH 连接支持
- 图形用户界面
- Debian 包支持 