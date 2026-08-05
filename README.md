# godot-csharp-dev-skill

一个 [Codex](https://github.com/openai/codex) 与 [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) 通用的 AI skill，给 Godot 4.x (.NET) C# 项目提供开发规范约束。

同一份 `SKILL.md` 同时被两个工具加载，无需维护两套规则。

## 这是什么

仓库只发布一个 skill：`godot-csharp-dev`。安装后，当你在 Godot 4 C# 项目里写/审查代码、设计场景、配置资产时，Codex 和 Claude Code 会自动加载它，强制执行：

- 5 条核心红线（节点引用、动态创建、场景文件、信号调用、异步操作）
- 8 条底层工程原则（不保留向后兼容、最简单实现、垂直切片、模块化、优先成熟库、复用现有依赖、长期主义、参考成熟方案）
- 组合模式架构 / 数据驱动 / 主线程安全

规则本身在 [`godot-csharp-dev/SKILL.md`](godot-csharp-dev/SKILL.md) 与 `references/` 下，不在本 README 重复。

## 安装

### Codex

Codex 自带 skill-installer，一句话安装：

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo TheShowerMaker/godot-csharp-dev-skill \
  --path godot-csharp-dev
```

或在 Codex 对话里说「安装 skill `TheShowerMaker/godot-csharp-dev-skill` 路径 `godot-csharp-dev`」，由它自己调脚本。

### Claude Code

```bash
git clone https://github.com/TheShowerMaker/godot-csharp-dev-skill.git
cd godot-csharp-dev-skill
./install.sh                  # 自动检测已安装的工具，装到对应目录
./install.sh --both           # 显式同时装到 ~/.claude/skills/ 和 ~/.codex/skills/
./install.sh --dest ~/my/dir  # 装到自定义父目录
```

### 验证

```bash
ls ~/.codex/skills/godot-csharp-dev/SKILL.md
ls ~/.claude/skills/godot-csharp-dev/SKILL.md
```

## 仓库结构

```
.
├── godot-csharp-dev/         # skill 本体
│   ├── SKILL.md              # 入口：红线 + 原则 + 工作流 + 检查清单
│   ├── agents/openai.yaml    # Codex UI 显示元数据
│   └── references/           # 详细章节，按需加载
│       ├── coding-style.md
│       ├── architecture.md
│       ├── special-mechanisms.md
│       ├── mcp-editor.md
│       └── assets-git.md
├── install.sh                # Claude Code / 跨工具安装脚本
├── LICENSE                   # MIT
└── README.md
```

## 修改与发布

改 `godot-csharp-dev/` 下任意文件 → `git commit` → `git push`。已安装的用户重跑 install 脚本即可更新。

`agents/openai.yaml` 修改 `display_name` / `short_description` 只影响 Codex UI 展示，不影响触发逻辑——触发逻辑由 `SKILL.md` 的 frontmatter `description` 字段决定。

## License

MIT — 见 [LICENSE](LICENSE)。
