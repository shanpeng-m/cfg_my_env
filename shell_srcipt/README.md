## Job Assignment Calculator

一个用于计算工作时间分配比例的 Shell 脚本工具。支持 Bash 和 Zsh shell环境。

### 功能特点

- 计算多个工作项目的时间占比
- 自动转换时间为百分比
- 生成简化比例
- 将比例标准化为总和为10的分配比例
- 支持小时:分钟格式的时间输入
- 彩色输出提升可读性
- 自动处理浮点数计算

### 依赖要求

- Bash 或 Zsh shell环境
- `bc` 命令行计算器（用于浮点数计算）

#### 安装依赖

对于 Ubuntu/Debian：
```bash
sudo apt-get install bc
```

对于 CentOS/RHEL：
```bash
sudo yum install bc
```

### 使用方法

1. 给脚本添加执行权限：
```bash
chmod +x job_assign_calculator.sh
```

2. 运行脚本：
```bash
./job_assign_calculator.sh
```

3. 按照提示输入数据：
 - 首先输入工作项目名称
 - 然后输入对应的工时（格式：小时:分钟）
 - 重复以上步骤直到输入完所有项目
 - 输入空行结束输入

#### 输入示例

```
job1
35:01
job2
88:25
job3
12:00
[空行]
```

#### 输出说明

脚本将显示以下信息：

1. **结果统计**
 - 显示每个工作项目的时间和百分比

2. **简化比例**
 - 显示原始分钟数的比例关系

3. **比例对应关系**
 - 显示每个工作项目对应的分钟数

4. **总和为10的比例**
 - 将比例归一化为总和为10的整数比例

5. **总和为10的比例对应关系**
 - 显示每个工作项目对应的归一化比例值

### 输出示例

```
结果统计：
------------------------
job1: 35:1 (25.85%)
job2: 88:25 (65.28%)
job3: 12:0 (8.86%)

简化比例：
------------------------
2101:5305:720

比例对应关系：
------------------------
job1 => 2101
job2 => 5305
job3 => 720

转换为总和为10的比例：
------------------------
3:6:1

总和为10的比例对应关系：
------------------------
job1 => 3
job2 => 6
job3 => 1
```

### 注意事项

1. 时间输入格式必须为 "小时:分钟"
2. 确保系统已安装 `bc` 命令
3. 支持 Bash 和 Zsh shell环境
4. 小数计算精度保留到小数点后两位
5. 总和为10的比例会自动调整以确保总和正好等于10

### 错误处理

- 如果未安装 `bc`，脚本会提示安装方法
- 输入格式错误会显示错误信息
- 自动处理 Bash 和 Zsh 的语法差异

### 贡献

欢迎提交 Issues 和 Pull Requests 来改进这个脚本。

### 许可证

MIT License