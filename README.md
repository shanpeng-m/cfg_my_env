# 配置我的环境

## 配置apt免密码

要在执行 `apt` 命令时不用输入密码，可以通过配置 `sudoers` 文件为特定用户授予不需要密码的权限。下面是实现步骤：

### 步骤 1：打开 `sudoers` 文件

在终端中输入以下命令以编辑 `sudoers` 文件：

```bash
sudo visudo
```

> **提示**：`visudo` 命令会在编辑时检查语法错误，确保不会导致 `sudoers` 文件损坏。

### 步骤 2：添加免密码权限

在 `sudoers` 文件中，找到适当的位置（通常是在 `%sudo` 行的下方），然后添加以下行：

```bash
<your_username> ALL=(ALL) NOPASSWD: /usr/bin/apt
```

将 `<your_username>` 替换为你的用户名。该配置的含义是：允许指定用户在 `/usr/bin/apt` 路径下执行 `apt` 命令时免输入密码。

例如，如果你的用户名是 `shanpengma`，那么添加的内容为：

```bash
shanpengma ALL=(ALL) NOPASSWD: /usr/bin/apt
```

### 步骤 3：保存并退出

在 `visudo` 编辑器中，保存更改并退出（通常是按 `Ctrl + X`，然后按 `Y` 确认保存，最后按 `Enter`）。

### 注意事项

1. **安全性**：确保仅对需要免密码的命令添加 `NOPASSWD` 选项，不要对所有 `sudo` 命令启用免密码，以避免安全风险。
2. **命令路径**：确认 `apt` 的路径是 `/usr/bin/apt`。你可以通过运行 `which apt` 来验证。

完成以上步骤后，执行 `sudo apt update` 或其他 `apt` 命令时，将不再需要输入密码。这种设置适合需要自动化 `apt` 操作的脚本。
