# C# 代码风格规范（详细）

## 语言与工具链

| 项目 | 规范 |
|------|------|
| 语言版本 | C# 12.0 (.NET 8.0) |
| 缩进 | 4 个空格 |
| 换行符 | LF |
| 文件编码 | UTF-8 without BOM |
| 大括号风格 | Allman（换行） |
| 行宽限制 | 不超过 100 字符 |

## 完整命名规范表

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

## 格式示例

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

## 常用代码模板

### 玩家控制器模板

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

### 组件模板（HealthComponent）

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

### UI 更新模板

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

### 主线程调度模板

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

### TaskCompletionSource 封装回调

```csharp
public Task<bool> ShowDialog()
{
    var tcs = new TaskCompletionSource<bool>();
    _dialog.Confirmed += () => tcs.SetResult(true);
    _dialog.Canceled += () => tcs.SetResult(false);
    _dialog.Popup();
    return tcs.Task;
}
```
