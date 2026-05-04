# prototype-to-ui-spec

将高保真产品原型、Mockup 或 UI 截图转成可直接交付前端开发的 UI 设计说明。

## 安装

```bash
./install.sh
```

如果这个目录是作为 `codex-portable-config` 的随仓库 skill 分发，直接运行根目录 `./install.sh` 即可同步到 `~/.codex/skills/prototype-to-ui-spec`。

## 使用

在任务中显式引用：

```text
使用 $prototype-to-ui-spec，根据这组高保真原型图生成前端可落地的 UI 设计说明。
```

详细流程和输出约束见 `SKILL.md`，可复用输出模板见 `references/spec-template.md`。
