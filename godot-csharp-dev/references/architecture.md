# 架构规范（组合模式与数据驱动）

## 组合模式（Composition Over Inheritance）

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

协调器负责挂载组件、转发信号；组件保持功能单一、可复用。

## 组件设计规范

```csharp
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

## 通信规范

| 场景 | 通信方式 | 说明 |
|------|---------|------|
| 节点间通信 | Godot `[Signal]` + `SignalName` | 可在编辑器可视化连接 |
| 逻辑层通信 | C# `event` / `Action` | 纯 C# 模块解耦 |
| 全局服务 | Autoload 单例 | 如 `GameManager`、`AudioManager` |
| 跨组件信号 | 父节点作为中转 | 子组件 → 信号 → 父节点 → 转发 |

## 信号声明与调用标准

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

## 数据驱动设计

### 原则

- **逻辑与数据分离**：数值配置存放在外部文件
- **优先使用 `Resources`**：支持编辑器直观编辑
- **JSON 作为补充**：适合频繁修改或工具生成的数据

### 数据存放位置

| 数据类型 | 存放位置 | 格式 |
|---------|---------|------|
| 角色属性、物品配置 | `Resources/` | `.tres` (Resource) |
| 关卡配置、剧情数据 | `Data/` | `.json` |
| 本地化文本 | `Data/` | `.csv` / `.json` |

### AI 编码约束

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
