# requirements-to-ui-frontend

从需求文档或高保真原型推进到前端交付的 Codex skill。核心流程是先做静态 HTML DEMO 高还原校准，再截图对比打分，通过后产出 UI 说明并进入正式前端开发。

## 安装

```bash
./install.sh
```

如果这个目录是作为 `codex-portable-config` 的随仓库 skill 分发，直接运行根目录 `./install.sh` 即可同步到 `~/.codex/skills/requirements-to-ui-frontend`。

## 使用

在任务中显式引用：

```text
使用 $requirements-to-ui-frontend，先根据原型图实现静态 HTML DEMO，浏览器截图对比原型并以 UI 设计师视角评分，达到 90 分后再产出 UI 说明并完成正式前端开发。
```

详细流程和验收要求见 `SKILL.md`。
