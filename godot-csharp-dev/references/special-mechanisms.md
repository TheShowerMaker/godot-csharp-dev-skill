# 特殊机制规范（节点引用、生命周期、异步、多线程）

## 节点引用策略

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

## 生命周期约束

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

## 异步编程规范

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

## 多线程与主线程安全

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

## 可视化节点创建约束

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
- 这是“编辑器操作”，不是“代码运行时行为”，不受上述约束限制。详见 `mcp-editor.md`。
