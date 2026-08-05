# godot-csharp-dev-skill

让 Codex 和 Claude Code 在帮你写 Godot 4 C# 代码时，自动遵守一套工程红线，少出崩溃坑、少写不规范代码。

## 这个 skill 能为你做什么

装好后，你在 Codex 或 Claude Code 里写 Godot C# 时，AI 会自动：

- **强制类型安全**：用 `[Export]` 注入节点、用 `SignalName.X` 发送/连接信号——不再有 `GetNode<T>("path/to/node")`、`EmitSignal("HealthChanged")` 这种拼写错误编译期抓不到的代码
- **避免跨线程崩溃**：用 `ToSignal + SceneTreeTimer` 取代 `Task.Delay()`，后台计算自动 `CallDeferred` 回主线程
- **不偷偷 new 可视节点**：所有 `Sprite2D` / `Label` / `CollisionShape2D` 等必须编辑器里建，AI 不会用 `new` 偷懒
- **守场景文件**：AI 不会去改你的 `.tscn` / `.res`（除了通过 godot-ai MCP 透明操作）
- **生命周期不乱用**：物理移动进 `_PhysicsProcess`、引用在 `_Ready` 缓存而非 `_Process` 每帧 `GetNode`
- **组合优于继承**：以组件（`HealthComponent` / `MovementComponent`）拆分功能，避免深层继承
- **数据驱动**：数值从 `.tres` / `.json` 读，不硬编码
- **资产操作合规**：重命名/移动资产的命令始终以「人工操作清单」形式输出，让你在 Godot 编辑器里执行——保护 UID 映射不撕裂
- **Git LFS / .gitignore**：自动按 Godot 4 规范配置

skill 还内嵌 8 条底层工程原则（不保留向后兼容 / 最简单实现 / 垂直切片 / 模块化 / 优先成熟库 / 复用现有依赖 / 长期主义 / 参考成熟方案），在 AI 做架构决策时优先级高于 Godot 专用规则。

## 安装

### Codex

一句话装好（Codex 自带的 skill-installer 会处理）：

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo TheShowerMaker/godot-csharp-dev-skill \
  --path godot-csharp-dev
```

或直接在 Codex 对话里说：

> 装 skill：`TheShowerMaker/godot-csharp-dev-skill` 路径 `godot-csharp-dev`

### Claude Code

```bash
git clone https://github.com/TheShowerMaker/godot-csharp-dev-skill.git
cd godot-csharp-dev-skill
./install.sh              # 自动装到 ~/.claude/skills/
```

`install.sh` 也支持 `--codex` / `--both` / `--dest <path>`。

## 使用

装完即用，无需任何额外命令。下次启动 Codex 或 Claude Code，在任意 Godot 4 C# 项目里正常对话——只要任务涉及 Godot 脚本、场景、节点、信号、资产等，skill 会自动加载并提供规范约束。

**示例对话**：

```
你：帮我写一个玩家控制器，能跑能跳
AI：（自动用 [Export] 注入节点、_PhysicsProcess 做物理移动、
    SignalName.X 发信号、给出组件拆分建议）
```

```
你：这段代码为什么崩溃？
AI：（识别出 Task.Delay 跨线程操作 Godot API，给 ToSignal 替换方案）
```

## 规则一览

skill 内置规则分两类，详细在 [`godot-csharp-dev/SKILL.md`](godot-csharp-dev/SKILL.md) 和 `references/`：

| 类别 | 内容 |
|------|------|
| **8 条底层原则** | 工程决策元规则，冲突时最高优先 |
| **5 条 Godot 红线** | 节点引用 / 动态创建 / 场景文件 / 信号 / 异步 |
| **架构规范** | 组合模式、组件设计、通信协议、数据驱动 |
| **特殊机制** | 节点引用策略、生命周期、多线程、可视化节点约束 |
| **MCP 控制** | godot-ai 工具的职责边界与操作分级 |
| **资产管理** | Git LFS / .gitignore / Godot 编辑器操作铁律 |

## 兼容性

- Godot 4.x (.NET) · C# 12.0 (.NET 8.0)
- Codex CLI（含 `skill-installer`）
- Claude Code

## License

MIT — 见 [LICENSE](LICENSE)。
