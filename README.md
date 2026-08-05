# Godot C# Dev Skill

Godot 4.x (.NET) C# 项目开发规范，封装为通用 AI Skill。同一份 SKILL.md 同时兼容 **Codex** 与 **Claude Code**。

## 触发场景

当你在 Godot 4 C# 项目中做以下事情时，skill 会自动加载：

- 编写 / 审查 / 重构 C# 脚本
- 设计场景结构、操作节点
- 处理信号、异步、多线程
- 使用 godot-ai MCP 工具
- 配置美术资产与 Git LFS

## 核心内容

- **5 条核心红线**：节点引用、动态创建、场景文件、信号调用、异步操作
- **组合模式架构**：组件设计、通信规范、数据驱动
- **特殊机制**：节点引用策略、生命周期、主线程安全
- **MCP 编辑器控制**：godot-ai 工具职责边界
- **资产管理**：Git LFS、`.gitignore`、四大铁律

## 安装

### Codex（自动安装）

把本仓库推到 GitHub 后，在 Codex 中说：

> 安装 skill：`TheShowerMaker/godot-csharp-dev-skill` 路径 `godot-csharp-dev`

Codex 会调用内置的 `skill-installer`，自动下载并安装到 `~/.codex/skills/godot-csharp-dev/`。

或手动调用脚本：

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo TheShowerMaker/godot-csharp-dev-skill \
  --path godot-csharp-dev
```

### Claude Code

Claude Code 没有 GitHub 自动安装机制，使用仓库内的 `install.sh`：

```bash
git clone https://github.com/TheShowerMaker/godot-csharp-dev-skill.git
cd godot-csharp-dev-skill
./install.sh                  # 默认安装到 ~/.claude/skills/
./install.sh --claude         # 显式指定 Claude Code
./install.sh --codex          # 显式指定 Codex
./install.sh --both           # 两个都装
./install.sh --dest /custom/path   # 自定义目标目录的父目录
```

### 手动复制

```bash
git clone https://github.com/TheShowerMaker/godot-csharp-dev-skill.git
cp -r godot-csharp-dev-skill/godot-csharp-dev ~/.claude/skills/   # Claude Code
cp -r godot-csharp-dev-skill/godot-csharp-dev ~/.codex/skills/    # Codex
```

## 验证

安装后启动 Codex 或 Claude Code，问一句 Godot C# 相关问题（如"帮我写一个 PlayerController"），skill 应被自动触发。

也可直接查看安装结果：

```bash
ls ~/.codex/skills/godot-csharp-dev/        # Codex
ls ~/.claude/skills/godot-csharp-dev/       # Claude Code
```

## 结构

```
.
├── README.md                          # 本文件
├── LICENSE                            # MIT
├── install.sh                         # 跨工具安装脚本
├── doc.md                             # 原始规范文档（v2.2 完整版）
└── godot-csharp-dev/                  # ← Skill 本体
    ├── SKILL.md                       # 入口：5 红线 + 工作流 + 清单
    ├── agents/openai.yaml             # Codex UI 元数据
    └── references/                    # 详细章节（按需加载）
        ├── coding-style.md
        ├── architecture.md
        ├── special-mechanisms.md
        ├── mcp-editor.md
        └── assets-git.md
```

## 维护

修改 `godot-csharp-dev/` 内的文件 → 提交 → 推送 → 在 Codex / Claude Code 中重装即可。

`doc.md` 是规范源文档；`SKILL.md` 与 `references/` 是从它提炼出的可加载格式。两者保持同步即可。

## License

MIT — 见 [LICENSE](LICENSE)。
