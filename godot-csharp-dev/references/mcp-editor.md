# MCP 编辑器控制（godot-ai）

## 安装配置

1. **安装 Godot 插件**：AssetLib → 搜索 "Godot AI" → 安装
2. **安装 Python 服务端**：`curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **连接 AI 客户端**：Godot AI 面板 → Codex → Configure（自动配置 MCP）

## 职责边界

| 层面 | 责任方 | 允许操作 | 禁止操作 |
|------|--------|---------|---------|
| **代码运行时** (C# Script) | AI 生成代码 | 逻辑控制、数据计算、信号通信 | `new` 可视节点、硬编码路径 |
| **编辑器设计期** (MCP Tooling) | AI + godot-ai | 创建节点、搭建场景、挂载脚本 | 未经确认的大规模重构 |

## 操作分级

| 级别 | 操作类型 | 示例 |
|------|---------|------|
| ✅ 安全（允许） | 读取节点树、获取脚本内容、查询项目设置 | `list_nodes`、`read_script` |
| ⚠️ 高风险（需确认） | 修改节点属性、保存场景、运行项目 | `set_node_property`、`save_scene` |
| ❌ 危险（禁止） | 大规模重写脚本、修改项目文件 | 未经许可的重构 |

## 推荐工作流

```
1. 只读探查 → AI 读取当前场景结构
2. 方案确认 → AI 描述修改计划，等待用户确认
3. 小步执行 → 拆分操作，逐一执行
4. 即时反馈 → 用户在编辑器中查看效果
5. 版本控制 → 所有改动可撤销
```

## 参考资源

- [godot-ai GitHub](https://github.com/hi-godot/godot-ai)
