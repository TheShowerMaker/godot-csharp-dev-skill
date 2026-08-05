# 美术资产与 Git 版本控制规范

## 核心原则

| 原则 | 说明 |
|------|------|
| **大文件用 LFS** | 所有二进制资产（图像、音频、3D 模型）必须通过 Git LFS 追踪 |
| **资产在编辑器内操作** | 重命名、移动、删除资产必须在 Godot 编辑器的 FileSystem 面板中执行 |
| **目录与代码解耦** | `Assets/` 存放所有美术/音频资产，`Scripts/` 只含代码，二者平级 |
| **命名统一** | 所有资产文件及目录名使用 `snake_case`，禁止中文路径 |

## Git LFS 配置（`.gitattributes`）

**必须在首次提交资产前配置完成**：

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

## `.gitignore` 规则（Godot 4 特化）

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

## 资产目录结构

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
├── Scripts/                       # C# 代码
├── Scenes/                        # 场景文件
├── Resources/                     # Godot Resources
└── Data/                          # JSON 配置
```

**文件命名硬规则**：
- ✅ 统一使用 `snake_case`：`player_idle_sheet.png`、`menu_click_sfx.wav`
- ❌ 严禁使用中文路径或特殊字符（避免跨平台加载失败）

## 资产管理四大铁律

### 铁律一：资产操作必须在 Godot 编辑器中进行

| 场景 | ✅ 正确做法 | ❌ 错误做法 |
|------|-----------|-----------|
| 重命名文件 | 在 Godot FileSystem 面板中右键 → Rename | 在 Windows Explorer / Finder 中直接改名 |
| 移动文件 | 在 Godot FileSystem 面板中拖拽 | 在文件管理器中剪切粘贴 |
| 删除文件 | 在 Godot FileSystem 面板中右键 → Delete | 在文件管理器中直接删除 |

**原因**：Godot 通过 `.import` 文件中的 UID（唯一标识符）追踪每个资产。在编辑器中操作时，Godot 会自动更新所有场景中的引用关系。外部操作会导致 UID 映射断裂，场景中的资源引用全部丢失，且难以恢复。

### 铁律二：源文件与导出文件隔离

- `.psd`、`.blend`、`.aseprite` 等设计源文件，推荐存放在 `Assets/Source/` 中，或**完全存放在项目外部**（如独立的 `design/` 仓库）。
- Godot 项目内**只引用**已导出的资产（`.png`、`.glb`、`.wav` 等）。
- 避免在项目仓库中提交体积巨大的未烘焙源文件。

### 铁律三：3D 资产优先使用 `.glb` 格式

| 格式 | Godot 4 支持度 | 推荐度 |
|------|--------------|--------|
| `.glb` / `.gltf` | 原生支持，导入稳定 | ⭐⭐⭐⭐⭐ **首选** |
| `.fbx` | 需要转换，可能产生元数据误差 | ⭐⭐⭐ 备选 |
| `.obj` | 基础支持，无材质/动画 | ⭐⭐ 仅用于静态模型 |

**规范**：所有 3D 模型导出时优先选择 `.glb` 格式。如果必须使用 `.fbx`，建议在导入后检查材质、动画和骨骼绑定是否准确。

### 铁律四：AI 对资产文件的操作权限

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

## 资产优化建议（加分项）

| 资产类型 | 推荐规格 | 说明 |
|---------|---------|------|
| 2D 精灵图 | 2x 或 4x 分辨率 | 适应高 DPI 显示，避免缩放模糊 |
| 背景音乐 | `.ogg`，192kbps | Godot 原生支持，压缩比优于 MP3 |
| 音效 | `.wav`，16bit 44100Hz | 保持原始质量，引擎内可压缩 |
| 纹理 | 尺寸为 2 的幂次（如 256x256、512x512） | 优化 GPU 内存对齐 |
| 字体 | `.ttf` / `.otf` | 在 Godot 中生成 BitmapFont 或使用动态字体 |
