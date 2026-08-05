---
name: godot-csharp-dev
description: Godot 4.x (.NET) C# 项目开发规范。当用户在 Godot 4 C# 项目中编写、审查或重构脚本、设计场景结构、操作节点、处理信号/异步/多线程、使用 godot-ai MCP 工具，或配置美术资产与 Git LFS 时使用。涵盖五条核心红线（节点引用、动态创建、场景文件、信号调用、异步操作）、组合模式架构、数据驱动设计与编辑器优先哲学。
license: MIT
---

# Godot C# AI 辅助开发规范

> 适用引擎：Godot 4.x (.NET) · 语言：C# 12.0 (.NET 8.0) · 版本：2.2

将 AI 视为**“需要明确指导的资深实习生”**：API 知识丰富，但需要严格遵守以下红线与工作流，产出仍需人工审查。

## 零、底层工程原则（决策先过这条）

> 这是 Godot 红线之上、所有代码决策的元规则。冲突时以本节为准。

1. **不保留向后兼容**。过时的直接删，不加兼容层、不写 migration、不留 fallback。
2. **选能满足当前需求的最简单实现**。不预防性抽象，不多此一举的配置层。
3. **系统分层长**。先跑通一个最小的端到端版本，再往上加东西。绝不为未完成的复杂度拆掉能跑的东西。
4. **组件保持模块化，关注点分离**。单一职责，组合优于继承（详见五章）。
5. **优先用成熟的、有人维护的库**。没有明确理由别自己重写。
6. **先翻项目里已有依赖能做什么，再考虑加新包或自己写**。别假设库里没有。
7. **架构决策往长了做**。不接受“先这样以后再换”的临时方案。
8. **先看成熟产品怎么解决同一个问题**。用已验证的模式，别从零发明。

## 一、五条核心红线（最高优先级，必须遵守）

### 红线 1：节点引用 — 严禁硬编码路径

```csharp
// ❌ 禁止
_sprite = GetNode<Sprite2D>("Visuals/Sprite2D");

// ✅ 强制：[Export] 注入，由开发者在编辑器中拖拽赋值
[Export] private Sprite2D _sprite;
```

`GetNode<T>("path")` 仅允许用于**动态生成节点**或 **Autoload 单例**（如 `/root/GameManager`）。

### 红线 2：动态创建 — 严禁在 C# 中 `new` 可视节点

禁止 `new Sprite2D()` / `new Label()` / `new CollisionShape2D()` / `new AnimationPlayer()` / `new Control()` 及其子类。**可视节点必须在编辑器中创建**（或通过 godot-ai MCP 工具搭建）。

唯一例外：纯逻辑节点（`Timer`、`AudioStreamPlayer`）可在说明原因后动态创建。

### 红线 3：场景文件 — 严禁直接修改 `.tscn` / `.res`

场景结构与资源参数必须由开发者在 Godot 编辑器中调整。**例外**：通过 `godot-ai` MCP 工具进行的编辑器自动化操作不受此限（见 `references/mcp-editor.md`）。

### 红线 4：信号调用 — 严禁字符串字面量

```csharp
// ❌ 禁止：拼写错误不会被编译期捕获
EmitSignal("HealthChanged", 80, 100);
Connect("HealthChanged", Callable.From(OnHealthChanged));

// ✅ 强制：使用 Godot 源码生成器的 SignalName 静态类
[Signal]
public delegate void HealthChangedEventHandler(int current, int max);

EmitSignal(SignalName.HealthChanged, _currentHealth, _maxHealth);
healthComp.Connect(SignalName.HealthChanged, Callable.From<int, int>(OnHealthChanged));
```

声明要求：`[Signal]` + `delegate`，命名以 `EventHandler` 结尾。

### 红线 5：异步操作 — 严禁 `Task.Delay/Task.Run` 触碰 Godot API

```csharp
// ❌ 禁止：跨线程操作场景树，可能崩溃
await Task.Delay(1000);
_sprite.Modulate = Colors.Red;

// ✅ 强制：ToSignal + SceneTreeTimer（主线程）
await ToSignal(GetTree().CreateTimer(1.0f), SceneTreeTimer.SignalName.Timeout);

// ✅ 强制：ToSignal + 信号等待
await ToSignal(_animationPlayer, AnimationPlayer.SignalName.AnimationFinished);

// ✅ 后台计算后必须 CallDeferred 回主线程
Task.Run(() => {
    int result = HeavyCalculation();
    Callable.From(() => _label.Text = result.ToString()).CallDeferred();
});
```

Godot API 绝大多数**非线程安全**，必须在主线程调用。

## 二、开发哲学

- **组合优于继承**：通过子节点（Component）组合功能，避免深层继承链。
- **数据驱动**：逻辑与数据分离，数值配置外部化（`Resources/` 用 `.tres`，`Data/` 用 `.json`）。
- **事件驱动**：状态变更通过信号/事件传播，禁止轮询。
- **编辑器优先**：可视化元素在编辑器中创建，脚本只负责逻辑。
- **主线程安全**：场景树操作必须在 Godot 主线程执行。

## 三、关键命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 类名 / 方法 / 属性 / 公共字段 / 事件 | PascalCase | `PlayerController` / `TakeDamage()` |
| 私有字段 | `_camelCase` | `_currentHealth` |
| 局部变量 / 参数 | camelCase | `playerPosition` / `damageAmount` |
| 命名空间 | PascalCase | `MyGame.Controllers` |
| 场景节点名 | PascalCase | `HealthBar` |
| 资产文件 / 文件夹 | `snake_case`，禁止中文路径 | `player_idle.png` |

格式：4 空格缩进、LF 换行、UTF-8 无 BOM、Allman 大括号、行宽 ≤ 100。

## 四、生命周期约束

| 方法 | 用途 | 禁止行为 |
|------|------|---------|
| `_Ready()` | 初始化、缓存引用 | 耗时操作 |
| `_Process(double delta)` | 非物理更新（动画、UI） | 物理移动、节点查找、内存分配 |
| `_PhysicsProcess(double delta)` | 物理相关（移动、碰撞） | 非物理逻辑 |

**禁止在 `_Process` 中每帧 `GetNode`**——必须在 `_Ready` 缓存引用，事件触发更新。

## 五、工作流规范

### 标准工作流

```
1. 只读探查 → 读取场景结构、脚本内容、项目设置
2. 方案确认 → 描述修改计划，等待用户确认
3. 小步执行 → 拆分操作，逐一执行
4. 操作清单 → 列出需用户在编辑器中手动完成的步骤
5. 版本控制 → 所有改动可撤销
```

### 任务卡复述

接收任务时，先复述理解：目标、技术要求（继承的节点类型、引用方式、信号声明）、验收标准。**确认方向无误后再动手**。

### 推荐目录结构

```
YourGameProject/
├── Assets/          # 美术/音频（snake_case 命名）
│   ├── Art/         # Sprites/Textures/Models
│   ├── Audio/       # BGM/SFX
│   ├── Fonts/
│   └── Source/      # 设计源文件（.psd/.blend，不直接导入）
├── Scenes/          # .tscn 场景文件
├── Scripts/         # C# 脚本（按功能分子目录）
├── Resources/       # Godot Resource（.tres）
├── Data/            # JSON 配置
├── addons/          # 第三方插件（含 godot_ai/）
└── Docs/            # 项目文档
```

## 六、AI 输出检查清单（每次产出前自检）

**代码质量**
- [ ] 所有节点引用使用 `[Export]` 注入（无硬编码路径）
- [ ] 信号 `[Signal]` delegate 以 `EventHandler` 结尾
- [ ] 信号发送/连接使用 `SignalName.X`（无字符串字面量）
- [ ] 类名/方法 PascalCase，私有字段 `_camelCase`，Allman 大括号
- [ ] 无 `Task.Delay()` / `Task.Run()` 操作 Godot API
- [ ] 物理移动在 `_PhysicsProcess`，事件触发更新而非轮询

**架构合规**
- [ ] 未在代码中 `new` 任何可视节点
- [ ] 组件功能单一、职责明确
- [ ] 数值从 `.tres` / `.json` 读取，无硬编码
- [ ] 通信使用信号/事件，无直接耦合

**资产管理**
- [ ] 资产文件 `snake_case`，无中文路径
- [ ] 资产操作清单已输出（重命名/移动/删除由用户在编辑器执行）
- [ ] 3D 模型优先 `.glb`
- [ ] 未忽略 `.import` 文件（必须提交，含 UID 映射）

## 七、详细参考（按需加载）

具体场景的细节规则在 `references/` 中：

- **`references/coding-style.md`** — 完整命名表、格式示例、PlayerController/HealthComponent/HealthBar/主线程调度等代码模板
- **`references/architecture.md`** — 组合模式架构图、组件设计、通信规范（信号 vs C# event vs Autoload）、数据驱动设计
- **`references/special-mechanisms.md`** — 节点引用策略（Export / `[Node]` 源码生成器 / GetNode 适用场景）、生命周期、异步、多线程与主线程安全
- **`references/mcp-editor.md`** — godot-ai MCP 工具安装、职责边界、操作分级、推荐工作流
- **`references/assets-git.md`** — Git LFS 配置、`.gitignore`（Godot 4 特化）、资产管理四大铁律、AI 对资产文件的操作权限

**使用建议**：处理具体任务时按主题加载对应参考文档，避免一次性加载全部内容。
