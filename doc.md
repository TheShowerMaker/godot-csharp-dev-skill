好的，已确认所有内容。以下是 **Godot C# AI 辅助开发规范文档 2.2 完整版**，所有章节已整合完毕。


# Godot C# AI 辅助开发规范文档

> **版本**：2.2  
> **适用引擎**：Godot 4.x (.NET)  
> **语言**：C# 12.0 (.NET 8.0)  
> **AI 工具**：Codex / Cursor / 通用 MCP 客户端  
> **最后更新**：2026-08-05


## 目录

- [零、底层工程原则](#零底层工程原则)
- [一、核心红线](#一核心红线)
- [二、核心理念](#二核心理念)
- [三、工作流规范](#三工作流规范)
- [四、代码风格规范（C#）](#四代码风格规范c)
- [五、架构规范](#五架构规范)
- [六、数据驱动设计](#六数据驱动设计)
- [七、特殊机制规范](#七特殊机制规范)
- [八、MCP 编辑器控制（godot-ai）](#八mcp-编辑器控制godot-ai)
- [九、检查清单](#九检查清单)
- [十、美术资产与 Git 版本控制规范](#十美术资产与-git-版本控制规范)
- [附录](#附录)


## 零、底层工程原则

> Godot 红线之上、所有代码决策的元规则。冲突时以本节为准。

1. **不保留向后兼容**。过时的直接删，不加兼容层、不写 migration、不留 fallback。
2. **选能满足当前需求的最简单实现**。不预防性抽象，不多此一举的配置层。
3. **系统分层长**。先跑通一个最小的端到端版本，再往上加东西。绝不为未完成的复杂度拆掉能跑的东西。
4. **组件保持模块化，关注点分离**。单一职责，组合优于继承（见第五章）。
5. **优先用成熟的、有人维护的库**。没有明确理由别自己重写。
6. **先翻项目里已有依赖能做什么，再考虑加新包或自己写**。别假设库里没有。
7. **架构决策往长了做**。不接受“先这样以后再换”的临时方案。
8. **先看成熟产品怎么解决同一个问题**。用已验证的模式，别从零发明。


## 一、核心红线

> **以下规则为最高优先级，任何代码生成都必须遵守。**

### 1. 节点引用规则
- **严禁硬编码节点路径**：禁止使用 `GetNode<T>("path/to/node")` 获取编辑器内创建的节点。
- **强制使用 `[Export]` 注入**：所有需要引用的可视节点，必须在脚本中声明 `[Export]` 字段，由开发者在编辑器中拖拽赋值。

### 2. 动态创建规则
- **严禁在 C# 中 `new` 任何可视节点**：禁止 `new Sprite2D()`、`new Label()`、`new CollisionShape2D()` 等。
- **唯一例外**：纯逻辑节点（如 `Timer`、`AudioStreamPlayer`）可在必要时动态创建，但必须说明原因。

### 3. 场景文件规则
- **严禁修改 `.tscn` / `.res` 文件内容**：场景结构、资源参数必须在 Godot 编辑器中手动调整。
- **例外**：通过 `godot-ai` MCP 工具进行的编辑器自动化操作不受此限（见第八章）。

### 4. 信号调用规则
- **严禁使用字符串字面量发送或连接信号**：
  ```csharp
  // ❌ 禁止：字符串拼写错误不会触发编译期检查
  EmitSignal("HealthChanged", 80, 100);
  Connect("HealthChanged", Callable.From(OnHealthChanged));
  
  // ✅ 强制：使用 Godot 源码生成器提供的 SignalName
  EmitSignal(SignalName.HealthChanged, 80, 100);
  Connect(SignalName.HealthChanged, Callable.From(OnHealthChanged));
  ```

### 5. 异步操作规则
- **严禁使用 `Task.Delay()` 或 `Task.Run()` 操作 Godot API**。
- **强制使用 `ToSignal()` + `SceneTreeTimer`** 进行延时操作。


## 二、核心理念

### 2.1 AI 的角色定位
将 AI 视为一个**“需要明确指导的资深实习生”**：
- 它具备丰富的 C# 和 Godot API 知识
- 它需要清晰的项目规范才能输出高质量代码
- 它的产出需要经过人工审查

### 2.2 开发哲学
- **组合优于继承**：优先通过子节点（Component）组合功能
- **数据驱动**：逻辑与数据分离，数值配置外部化
- **事件驱动**：状态变更通过信号/事件传播，避免轮询
- **编辑器优先**：可视化元素在编辑器中创建，脚本只负责逻辑
- **主线程安全**：任何场景树操作必须在 Godot 主线程执行


## 三、工作流规范

### 3.1 项目目录结构

```
YourGameProject/
├── .cursorrules                    # AI 总控规则（本文件）
├── .gitattributes                  # Git LFS 配置
├── .gitignore                      # 忽略 .godot/、export/
├── YourGame.csproj                 # C# 项目文件
├── project.godot                   # Godot 项目配置
│
├── Assets/                         # 美术与音频资产
│   ├── Art/
│   │   ├── Sprites/
│   │   ├── Textures/
│   │   └── Models/
│   ├── Audio/
│   │   ├── BGM/
│   │   └── SFX/
│   ├── Fonts/
│   └── Source/                     # 源文件（不直接导入 Godot）
│
├── Scenes/                         # 场景文件（.tscn）
│   ├── Main.tscn
│   ├── UI/
│   └── Levels/
│
├── Scripts/                        # C# 脚本
│   ├── Player/
│   │   ├── PlayerController.cs
│   │   └── Components/
│   ├── UI/
│   └── Systems/
│
├── Resources/                      # Godot Resources（.tres）
├── Data/                           # JSON 配置文件
├── addons/                         # 第三方插件
│   └── godot_ai/                   # godot-ai MCP 插件
│
└── Docs/                           # 项目文档
    ├── ARCHITECTURE.md
    ├── CODING_STYLE.md
    ├── OPEN_QUESTIONS.md
    └── API_REFERENCE.md
```

### 3.2 AI 辅助开发工作流

```
┌─────────────────────────────────────────────────────────────┐
│                    开发者（人类）                            │
│  1. 编写任务卡 → 明确需求、约束、验收标准                    │
│  2. 启动对话 → 要求 AI 先读取总控规则和任务卡               │
│  3. 审查代码 → 运行测试、检查规范符合度                     │
│  4. 迭代修正 → 反馈问题、要求 AI 修正                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AI（Codex / Cursor）                    │
│  1. 读取总控规则 → 理解项目约束和技术栈                     │
│  2. 读取任务卡 → 明确本次任务目标和边界                     │
│  3. 复述理解 → 确认方向无误后再动手                        │
│  4. 生成代码 → 符合命名、格式、架构规范                     │
│  5. 提供操作清单 → 说明需要在编辑器中手动完成的步骤          │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 任务卡模板

每次给 AI 下达指令时，使用以下模板：

```markdown
# 任务：[功能名称]

## 目标
在 `Scripts/[路径]/[文件名].cs` 中实现 [功能描述]。

## 技术要求
- 继承自：`[Node 类型]`
- 节点引用：使用 `[Export]` 注入（禁止 `GetNode<T>("path")`）
- 信号声明：使用 Godot `[Signal]`，delegate 以 `EventHandler` 结尾
- 信号调用：使用 `SignalName.X`（禁止字符串字面量）
- 生命周期：逻辑放入 `_Ready()` / `_PhysicsProcess(double delta)`

## 验收标准
1. [具体标准1]
2. [具体标准2]

## 禁止行为
- 禁止硬编码节点路径
- 禁止在 `_Process` 中做物理移动或节点查找
- 禁止使用 `Task.Delay()` 或 `Task.Run()` 操作 Godot API
- 禁止动态创建可视节点
- 禁止使用字符串字面量发送/连接信号
- 禁止修改 .tscn / .res 文件

## API 参考
```csharp
// 在此附上标准代码模板
```
```


## 四、代码风格规范（C#）

### 4.1 语言与工具链

| 项目 | 规范 |
|------|------|
| 语言版本 | C# 12.0 (.NET 8.0) |
| 缩进 | 4 个空格 |
| 换行符 | LF |
| 文件编码 | UTF-8 without BOM |
| 大括号风格 | Allman（换行） |
| 行宽限制 | 不超过 100 字符 |

### 4.2 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 命名空间 | PascalCase | `MyGame.Controllers` |
| 类名 | PascalCase | `PlayerController` |
| 方法 | PascalCase | `TakeDamage()` |
| 属性 | PascalCase | `CurrentHealth` |
| 事件 | PascalCase | `OnScoreUpdated` |
| 公共字段 | PascalCase | `MaxSpeed` |
| 私有字段 | `_camelCase` | `_currentHealth` |
| 局部变量 | camelCase | `playerPosition` |
| 参数 | camelCase | `damageAmount` |
| C# 脚本文件 | PascalCase | `PlayerController.cs` |
| 场景节点名 | PascalCase | `HealthBar` |
| 文件夹/资源 | snake_case | `player_sprites/` |
| 资产文件 | snake_case | `player_idle.png` |

### 4.3 格式示例

```csharp
using Godot;
using System;

namespace MyGame.Player;

/// <summary>
/// 玩家控制器，处理移动和输入
/// </summary>
public partial class PlayerController : CharacterBody2D
{
    // 导出变量（编辑器可见）
    [Export] private float _moveSpeed = 300.0f;
    [Export] private float _acceleration = 10.0f;
    
    // 节点引用（编辑器注入）✅
    [Export] private Sprite2D _sprite;
    [Export] private AnimationPlayer _animationPlayer;
    
    // 信号声明 ✅
    [Signal]
    public delegate void PlayerDiedEventHandler();
    
    // 私有状态
    private Vector2 _inputDirection;
    
    public override void _Ready()
    {
        // 初始化逻辑
    }
    
    public override void _PhysicsProcess(double delta)
    {
        HandleInput();
        ApplyMovement((float)delta);
    }
    
    private void HandleInput()
    {
        _inputDirection = Input.GetVector("move_left", "move_right", 
                                          "move_up", "move_down");
    }
    
    private void ApplyMovement(float delta)
    {
        Velocity = Velocity.Lerp(_inputDirection * _moveSpeed, 
                                 _acceleration * delta);
        MoveAndSlide();
    }
}
```


## 五、架构规范

### 5.1 组合模式（Composition Over Inheritance）

**核心原则**：通过子节点组合功能，避免深层继承链。

```
Player (CharacterBody2D)           ← 协调器（Orchestrator）
├── HealthComponent (Node)         ← 组件（Component）
│   └── [Signal] HealthChanged
├── MovementComponent (Node)       ← 组件（Component）
│   └── [Signal] Jumped
├── AnimationComponent (Node)      ← 组件（Component）
└── Visuals (Node2D)
    ├── Sprite2D                   ← 编辑器创建
    └── CollisionShape2D           ← 编辑器创建
```

### 5.2 组件设计规范

```csharp
// 组件：功能单一，可复用
public partial class HealthComponent : Node
{
    [Export] private int _maxHealth = 100;
    private int _currentHealth;
    
    [Signal]
    public delegate void HealthChangedEventHandler(int current, int max);
    
    [Signal]
    public delegate void DiedEventHandler();
    
    public override void _Ready()
    {
        _currentHealth = _maxHealth;
    }
    
    public void TakeDamage(int damage)
    {
        _currentHealth = Math.Max(0, _currentHealth - damage);
        
        // ✅ 使用 SignalName 静态类
        EmitSignal(SignalName.HealthChanged, _currentHealth, _maxHealth);
        
        if (_currentHealth <= 0)
            EmitSignal(SignalName.Died);
    }
}
```

### 5.3 通信规范

| 场景 | 通信方式 | 说明 |
|------|---------|------|
| 节点间通信 | Godot `[Signal]` + `SignalName` | 可在编辑器可视化连接 |
| 逻辑层通信 | C# `event` / `Action` | 纯 C# 模块解耦 |
| 全局服务 | Autoload 单例 | 如 `GameManager`、`AudioManager` |
| 跨组件信号 | 父节点作为中转 | 子组件 → 信号 → 父节点 → 转发 |

### 5.4 信号声明与调用标准

```csharp
// ✅ Godot 原生信号（节点间通信）
[Signal]
public delegate void HealthChangedEventHandler(int currentHealth, int maxHealth);

[Signal]
public delegate void PlayerDiedEventHandler();

// ✅ 发送信号（使用 SignalName）
EmitSignal(SignalName.HealthChanged, _currentHealth, _maxHealth);

// ✅ 连接信号（使用 SignalName）
HealthComponent healthComp = GetNode<HealthComponent>("HealthComponent");
healthComp.Connect(SignalName.HealthChanged, Callable.From<int,int>(OnHealthChanged));

// ❌ 禁止：字符串字面量
EmitSignal("HealthChanged", _currentHealth, _maxHealth);
Connect("HealthChanged", Callable.From(OnHealthChanged));

// ✅ C# 事件（逻辑层通信，非 Node 类）
public event Action<int> OnScoreUpdated;
OnScoreUpdated?.Invoke(newScore);
```


## 六、数据驱动设计

### 6.1 原则
- **逻辑与数据分离**：数值配置存放在外部文件
- **优先使用 `Resources`**：支持编辑器直观编辑
- **JSON 作为补充**：适合频繁修改或工具生成的数据

### 6.2 数据存放位置

| 数据类型 | 存放位置 | 格式 |
|---------|---------|------|
| 角色属性、物品配置 | `Resources/` | `.tres` (Resource) |
| 关卡配置、剧情数据 | `Data/` | `.json` |
| 本地化文本 | `Data/` | `.csv` / `.json` |

### 6.3 AI 编码约束

```csharp
// ✅ 正确：从 Resource 读取配置
[Export] private PlayerStats _stats; // 在编辑器拖拽赋值

// ✅ 正确：从 JSON 加载
using System.Text.Json;
private LevelData _levelData;

public override void _Ready()
{
    string json = File.ReadAllText("Data/level_1.json");
    _levelData = JsonSerializer.Deserialize<LevelData>(json);
}

// ❌ 错误：硬编码数值
private int _health = 100;  // 应改为从配置读取
```


## 七、特殊机制规范

### 7.1 节点引用策略

**原则**：禁止硬编码节点路径，必须通过以下方式之一获取节点。

| 方式 | 适用场景 | 示例 |
|------|---------|------|
| `[Export]` 注入 | **首选**，灵活调整 | `[Export] private Sprite2D _sprite;` |
| `[Node]` 源码生成器 | 结构固定，需要编译时检查 | `[Node("Visuals/Sprite2D")]` |
| `GetNode<T>()` | **仅限**动态生成或 Autoload | `GetNode<GameManager>("/root/GameManager")` |

```csharp
// ✅ 推荐：Export 注入
[Export] private Sprite2D _sprite;
[Export] private CollisionShape2D _collisionShape;
[Export] private Label _healthLabel;

// ✅ 可选：源码生成器（需安装 Godot.SourceGenerators）
[Node("Visuals/Sprite2D")] private Sprite2D _sprite;

// ❌ 禁止：硬编码路径
_sprite = GetNode<Sprite2D>("Visuals/Sprite2D");
```

### 7.2 生命周期约束

| 方法 | 用途 | 禁止行为 |
|------|------|---------|
| `_Ready()` | 初始化、缓存引用 | 耗时操作 |
| `_Process(double delta)` | 非物理更新（动画、UI） | 物理移动、节点查找、内存分配 |
| `_PhysicsProcess(double delta)` | 物理相关（移动、碰撞） | 非物理逻辑 |

```csharp
// ✅ 正确：缓存引用，事件驱动更新
private Label _healthLabel;
public override void _Ready()
{
    _healthLabel = GetNode<Label>("UI/HealthLabel");
}

private void OnHealthChanged(int newHealth)
{
    _healthLabel.Text = newHealth.ToString(); // 事件触发更新
}

// ❌ 错误：_Process 中每帧查找节点
public override void _Process(double delta)
{
    var label = GetNode<Label>("UI/HealthLabel"); // 性能灾难
    label.Text = _health.ToString();
}
```

### 7.3 异步编程规范

**原则**：禁止使用 `System.Threading.Tasks.Task.Delay()` 或 `Task.Run()` 操作 Godot API。

```csharp
// ✅ 正确：ToSignal + 计时器
await ToSignal(GetTree().CreateTimer(1.0f), SceneTreeTimer.SignalName.Timeout);

// ✅ 正确：ToSignal + 信号等待
await ToSignal(_animationPlayer, AnimationPlayer.SignalName.AnimationFinished);

// ✅ 正确：TaskCompletionSource 封装回调
public Task<bool> ShowDialog()
{
    var tcs = new TaskCompletionSource<bool>();
    _dialog.Confirmed += () => tcs.SetResult(true);
    _dialog.Canceled += () => tcs.SetResult(false);
    _dialog.Popup();
    return tcs.Task;
}

// ❌ 禁止：跨线程操作 Godot API
await Task.Delay(1000);
_sprite.Modulate = Colors.Red; // 可能崩溃！
```

### 7.4 多线程与主线程安全

**核心原则**：Godot API 绝大多数**非线程安全**，必须在主线程调用。

```csharp
// ❌ 危险：后台线程操作 Godot API
Task.Run(() => {
    // 任何场景树操作在此都是非法的！
    var label = GetNode<Label>("UI/Label"); 
    label.Text = "Hello";
});

// ✅ 正确：后台线程计算数据，通过 CallDeferred 调度回主线程
Task.Run(() => {
    // 纯计算，不触碰 Godot API
    int result = HeavyCalculation();
    
    // 调度回主线程更新 UI
    Callable.From(() => {
        _resultLabel.Text = result.ToString();
    }).CallDeferred();
});

// ✅ 正确：使用 Godot 的 SceneTreeTimer 在主线程延时
public async void DelayedAction()
{
    await ToSignal(GetTree().CreateTimer(1.0f), SceneTreeTimer.SignalName.Timeout);
    // 此时仍在主线程，安全操作 Godot API
    _sprite.Modulate = Colors.Red;
}
```

### 7.5 可视化节点创建约束

**代码运行时（C# Script）**：
- **绝对禁止**动态创建以下类型：
  - `Sprite2D` / `Sprite3D`
  - `Label` / `RichTextLabel`
  - `CollisionShape2D` / `CollisionShape3D`
  - `AnimationPlayer`
  - `Control` 及其子类（UI 元素）
- **唯一例外**：纯逻辑节点（`Timer`、`AudioStreamPlayer`），且需说明原因。

**编辑器设计期（MCP Tooling）**：
- **允许** AI 使用 `godot-ai` MCP 工具在编辑器中自动化搭建场景层级、创建节点并挂载脚本。
- 这是“编辑器操作”，不是“代码运行时行为”，不受上述约束限制。


## 八、MCP 编辑器控制（godot-ai）

### 8.1 安装配置

1. **安装 Godot 插件**：AssetLib → 搜索 "Godot AI" → 安装
2. **安装 Python 服务端**：`curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **连接 AI 客户端**：Godot AI 面板 → Codex → Configure（自动配置 MCP）

### 8.2 职责边界

| 层面 | 责任方 | 允许操作 | 禁止操作 |
|------|--------|---------|---------|
| **代码运行时** (C# Script) | AI 生成代码 | 逻辑控制、数据计算、信号通信 | `new` 可视节点、硬编码路径 |
| **编辑器设计期** (MCP Tooling) | AI + godot-ai | 创建节点、搭建场景、挂载脚本 | 未经确认的大规模重构 |

### 8.3 操作分级

| 级别 | 操作类型 | 示例 |
|------|---------|------|
| ✅ 安全（允许） | 读取节点树、获取脚本内容、查询项目设置 | `list_nodes`、`read_script` |
| ⚠️ 高风险（需确认） | 修改节点属性、保存场景、运行项目 | `set_node_property`、`save_scene` |
| ❌ 危险（禁止） | 大规模重写脚本、修改项目文件 | 未经许可的重构 |

### 8.4 推荐工作流

```
1. 只读探查 → AI 读取当前场景结构
2. 方案确认 → AI 描述修改计划，等待用户确认
3. 小步执行 → 拆分操作，逐一执行
4. 即时反馈 → 用户在编辑器中查看效果
5. 版本控制 → 所有改动可撤销
```


## 九、检查清单

在执行任务前，开发者可使用此清单检查 AI 产出：

### 代码质量
- [ ] 所有节点引用使用 `[Export]` 注入（无硬编码路径）
- [ ] 信号使用 `[Signal]` 委托（delegate 以 `EventHandler` 结尾）
- [ ] 信号发送/连接使用 `SignalName.X`（无字符串字面量）
- [ ] 类名、方法名符合 PascalCase，私有字段使用 `_camelCase`
- [ ] 大括号为 Allman 风格
- [ ] 无 `Task.Delay()` 或 `Task.Run()` 操作 Godot API
- [ ] 物理移动在 `_PhysicsProcess` 中
- [ ] 场景树操作在主线程执行

### 架构合规
- [ ] 未在代码中动态创建可视节点（`new Sprite2D()` 等）
- [ ] 组件功能单一，职责明确
- [ ] 数值从配置读取，无硬编码
- [ ] 通信使用信号/事件，无直接耦合

### MCP 操作
- [ ] 先读取再修改
- [ ] 高风险操作已确认
- [ ] 改动可在编辑器中撤销

### 资产管理
- [ ] 资产文件使用 `snake_case` 命名
- [ ] 资产操作在 Godot 编辑器 FileSystem 面板中执行
- [ ] 3D 模型优先使用 `.glb` 格式
- [ ] `.gitattributes` 已配置 LFS 追踪
- [ ] 未忽略 `.import` 文件


## 十、美术资产与 Git 版本控制规范

### 10.1 核心原则

| 原则 | 说明 |
|------|------|
| **大文件用 LFS** | 所有二进制资产（图像、音频、3D 模型）必须通过 Git LFS 追踪 |
| **资产在编辑器内操作** | 重命名、移动、删除资产必须在 Godot 编辑器的 FileSystem 面板中执行 |
| **目录与代码解耦** | `Assets/` 存放所有美术/音频资产，`Scripts/` 只含代码，二者平级 |
| **命名统一** | 所有资产文件及目录名使用 `snake_case`，禁止中文路径 |

---

### 10.2 Git LFS 配置（`.gitattributes`）

在项目根目录创建 `.gitattributes`，**必须在首次提交资产前配置完成**：

```gitattributes
# ===== 图像资产 =====
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.tga filter=lfs diff=lfs merge=lfs -text
*.svg filter=lfs diff=lfs merge=lfs -text

# ===== 源文件（设计稿） =====
*.psd filter=lfs diff=lfs merge=lfs -text
*.aseprite filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.ai filter=lfs diff=lfs merge=lfs -text

# ===== 3D 资产与动画 =====
*.fbx filter=lfs diff=lfs merge=lfs -text
*.gltf filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
*.obj filter=lfs diff=lfs merge=lfs -text

# ===== 音频与视频 =====
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text

# ===== 字体与库文件 =====
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.dll filter=lfs diff=lfs merge=lfs -text

# ===== 注意：.import 是文本文件，不强制 LFS，但必须提交 =====
*.import -text
```

---

### 10.3 `.gitignore` 规则（Godot 4 特化）

```gitattributes
# ===== Godot 4 缓存与中间文件 =====
.godot/
export/
export_credentials.cfg

# ===== C# / .NET 编译产物 =====
.vs/
.idea/
.vscode/
bin/
obj/
packages/
*.csproj.user
*.pidb
*.userprefs

# ===== 系统临时文件 =====
.DS_Store
Thumbs.db
*.tmp
*.log

# ===== 注意：.import 文件必须提交（含 UID 映射） =====
# ❌ 绝对不要忽略 .import 文件！
!*.import
```

---

### 10.4 资产目录结构

```
YourGameProject/
├── Assets/                        # 所有美术与音频资产（与代码解耦）
│   ├── Art/
│   │   ├── Sprites/               # 2D 精灵图
│   │   │   ├── Player/
│   │   │   │   ├── player_idle_sheet.png
│   │   │   │   └── player_run_sheet.png
│   │   │   ├── Enemies/
│   │   │   └── UI/
│   │   │       ├── button_normal.png
│   │   │       └── button_pressed.png
│   │   ├── Textures/              # 3D 纹理 / 材质贴图
│   │   │   └── terrain_diffuse.png
│   │   └── Models/                # 3D 模型（优先 .glb）
│   │       ├── enemy.glb
│   │       └── props/
│   ├── Audio/
│   │   ├── BGM/                   # 背景音乐（.ogg 推荐）
│   │   └── SFX/                   # 音效（.wav 推荐）
│   ├── Fonts/                     # 字体文件
│   │   └── noto_sans.ttf
│   └── Source/                    # 源文件（PSD、Blend 等，不直接导入 Godot）
│       ├── characters/
│       └── ui_designs/
│
├── Scripts/                       # C# 代码（见第三章）
├── Scenes/                        # 场景文件（见第三章）
├── Resources/                     # Godot Resources（见第五章）
└── Data/                          # JSON 配置（见第五章）
```

**文件命名硬规则**：
- ✅ 统一使用 `snake_case`：`player_idle_sheet.png`、`menu_click_sfx.wav`
- ❌ 严禁使用中文路径或特殊字符（避免跨平台加载失败）

---

### 10.5 Godot 4 资产管理四大铁律

#### 铁律一：资产操作必须在 Godot 编辑器中进行

| 场景 | ✅ 正确做法 | ❌ 错误做法 |
|------|-----------|-----------|
| 重命名文件 | 在 Godot FileSystem 面板中右键 → Rename | 在 Windows Explorer / Finder 中直接改名 |
| 移动文件 | 在 Godot FileSystem 面板中拖拽 | 在文件管理器中剪切粘贴 |
| 删除文件 | 在 Godot FileSystem 面板中右键 → Delete | 在文件管理器中直接删除 |

**原因**：Godot 通过 `.import` 文件中的 UID（唯一标识符）追踪每个资产。在编辑器中操作时，Godot 会自动更新所有场景中的引用关系。外部操作会导致 UID 映射断裂，场景中的资源引用全部丢失，且难以恢复。

#### 铁律二：源文件与导出文件隔离

- `.psd`、`.blend`、`.aseprite` 等设计源文件，推荐存放在 `Assets/Source/` 中，或**完全存放在项目外部**（如独立的 `design/` 仓库）。
- Godot 项目内**只引用**已导出的资产（`.png`、`.glb`、`.wav` 等）。
- 避免在项目仓库中提交体积巨大的未烘焙源文件。

#### 铁律三：3D 资产优先使用 `.glb` 格式

| 格式 | Godot 4 支持度 | 推荐度 |
|------|--------------|--------|
| `.glb` / `.gltf` | 原生支持，导入稳定 | ⭐⭐⭐⭐⭐ **首选** |
| `.fbx` | 需要转换，可能产生元数据误差 | ⭐⭐⭐ 备选 |
| `.obj` | 基础支持，无材质/动画 | ⭐⭐ 仅用于静态模型 |

**规范**：所有 3D 模型导出时优先选择 `.glb` 格式。如果必须使用 `.fbx`，建议在导入后检查材质、动画和骨骼绑定是否准确。

#### 铁律四：AI 对资产文件的操作权限

| 级别 | 允许操作 | 禁止操作 |
|------|---------|---------|
| ❌ **绝对禁止** | — | AI 生成包含 `File.Delete()`、`Directory.Move()`、`FileSystemWatcher` 等文件系统操作的代码 |
| ❌ **绝对禁止** | — | AI 直接修改 `Assets/` 目录下的文件路径 |
| ⚠️ **有限允许** | 通过 `godot-ai` MCP 工具的**只读操作**查询资产列表、读取 `.import` 信息 | AI 通过 MCP 执行批量重命名或删除操作（除非经开发者逐条确认） |
| ✅ **推荐做法** | AI 生成**手动操作清单**，说明需要执行的操作 | — |

**示例：AI 应输出的操作清单**

```markdown
## 人工操作清单

为完成本次任务，请在 Godot 编辑器中执行以下操作：

1. 打开 Godot 编辑器，进入 FileSystem 面板
2. 将 `Assets/Art/Sprites/Player/player_old.png` 重命名为 `player_idle.png`
3. 右键点击 `Assets/Art/Sprites/UI/` → 新建文件夹 → 命名为 `icons/`
4. 将 `menu_icon.png` 拖入 `icons/` 文件夹中
5. 以上操作完成后，重新打开 `Scenes/Main.tscn`，检查 Sprite2D 节点的纹理引用是否正常
```

---

### 10.6 资产优化建议（加分项）

| 资产类型 | 推荐规格 | 说明 |
|---------|---------|------|
| 2D 精灵图 | 2x 或 4x 分辨率 | 适应高 DPI 显示，避免缩放模糊 |
| 背景音乐 | `.ogg`，192kbps | Godot 原生支持，压缩比优于 MP3 |
| 音效 | `.wav`，16bit 44100Hz | 保持原始质量，引擎内可压缩 |
| 纹理 | 尺寸为 2 的幂次（如 256x256、512x512） | 优化 GPU 内存对齐 |
| 字体 | `.ttf` / `.otf` | 在 Godot 中生成 BitmapFont 或使用动态字体 |


## 附录

### A. 常用代码模板

**玩家控制器模板**：
```csharp
using Godot;

public partial class PlayerController : CharacterBody2D
{
    [Export] private float _speed = 300.0f;
    [Export] private Sprite2D _sprite;
    
    [Signal]
    public delegate void MovedEventHandler(Vector2 direction);
    
    public override void _PhysicsProcess(double delta)
    {
        Vector2 input = Input.GetVector("left", "right", "up", "down");
        Velocity = input * _speed;
        MoveAndSlide();
        
        if (input != Vector2.Zero)
            EmitSignal(SignalName.Moved, input);
    }
}
```

**组件模板**：
```csharp
using Godot;

public partial class HealthComponent : Node
{
    [Export] private int _maxHealth = 100;
    private int _currentHealth;
    
    [Signal]
    public delegate void HealthChangedEventHandler(int current, int max);
    
    [Signal]
    public delegate void DiedEventHandler();
    
    public override void _Ready()
    {
        _currentHealth = _maxHealth;
    }
    
    public void TakeDamage(int damage)
    {
        _currentHealth = Math.Max(0, _currentHealth - damage);
        EmitSignal(SignalName.HealthChanged, _currentHealth, _maxHealth);
        if (_currentHealth <= 0) EmitSignal(SignalName.Died);
    }
}
```

**UI 更新模板**：
```csharp
public partial class HealthBar : Control
{
    [Export] private TextureProgressBar _progressBar;
    [Export] private Label _valueLabel;
    
    public void UpdateHealth(int current, int max)
    {
        _progressBar.Value = (float)current / max * 100;
        _valueLabel.Text = $"{current}/{max}";
    }
}
```

**主线程调度模板**：
```csharp
// 后台线程计算完成后，调度回主线程
private void HeavyOperation()
{
    Task.Run(() => {
        int result = PerformLongCalculation();
        
        // 调度回主线程更新 Godot API
        Callable.From(() => {
            _resultLabel.Text = result.ToString();
            _progressBar.Value = 100;
        }).CallDeferred();
    });
}
```

### B. 参考资源

- [Godot 官方 C# 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_style_guide.html)
- [Godot C# API 文档](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_differences.html)
- [godot-ai GitHub](https://github.com/hi-godot/godot-ai)
- [Godot 最佳实践](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [Git LFS 官方文档](https://git-lfs.com/)


> **文档版本**：2.2  
> **最后更新**：2026-08-05  
> **维护者**：项目技术负责人

---

以上是完整版 **Godot C# AI 辅助开发规范文档 2.2**。所有章节已整合完毕，可直接作为项目根目录的 `.cursorrules` 文件使用，也可拆分为多个子文档引用。