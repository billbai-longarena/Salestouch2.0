# 贡献指南

## 欢迎的贡献

- ✅ 引擎能力：本体、权限、变更集、知识包加载器、MCP 工具、评测框架、UI 组件
- ✅ Bug 修复与性能优化
- ✅ 文档（**关于代码与机制的**）
- ✅ 测试与测试夹具
- ✅ 新数据库/部署环境的适配

## 不接受的贡献

- ❌ **某个行业的业务打法、阶段划分、判定标准**
- ❌ 真实客户数据（任何形态）
- ❌ 生产用的知识包

原因见 [`COMMERCIAL.md`](COMMERCIAL.md)：引擎是开源的，**使用者的业务方法论是使用者的资产**。
本项目不为任何特定行业预设业务规则——这正是"知识包可插拔"的设计目的。

## 提交前

```bash
npm run lint && npm run test
```

**提交守卫**：本仓库只放纯代码。安装钩子后，设计文档、调研、业务知识会被拒绝提交。

```bash
bash tools/precommit-guard.sh --install
```

## 贡献者协议

采用 **DCO**（Developer Certificate of Origin），不使用 CLA。

提交时加 `-s`：

```bash
git commit -s -m "fix: correct permission predicate pushdown"
```

这表示你确认有权提交该贡献，并同意以本项目的许可证（Apache-2.0）分发。

## 提交信息

只描述**代码改动**，不要描述业务设计。
