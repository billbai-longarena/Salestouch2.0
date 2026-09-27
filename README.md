# SaleTouch 2.0

> 可私有化部署的 AI 原生销售系统 —— **引擎**。
>
> 本仓库只包含引擎代码。业务方法论、行业模板与校准逻辑是独立的专有资产，
> 通过**可插拔的知识包（seed pack）**加载，不在本仓库中。

## 这是什么

一个以「业务知识可插拔」为核心的销售流程引擎：

- **本体驱动的数据层** —— 对象/关系/动作/函数由元数据定义，一套定义同时驱动 UI、权限、API 与 MCP 工具
- **统一的权限内核** —— RBAC + 组织树 + 共享规则，收敛到单一判定入口；含字段级与位置轨迹等独立权限维度
- **变更集与溯源** —— 所有写入走 ChangeSet，AI 产出可逐字段溯源、可回滚、可人审
- **知识包运行时** —— 从签名知识包加载业务形态定义、提示词与评测集；可通过 MCP 在线迭代
- **原生 MCP Server** —— 基于 MCP 2026-07-28 无状态核心，通用工具 + 知识层工具 + 领域能力工具
- **三端**：手机（捕获·轻审批）、PC（深研·治理）、MCP（批量·集成）

## 快速开始

```bash
git clone <this-repo> salestouch2.0
cd salestouch2.0
cp .env.example .env      # 按需修改
docker compose up -d
```

启动后访问 `http://localhost:3000`。

> 首次启动会加载内置的**演示知识包**（占位符内容），用于验证部署与 MCP 连通性。
> 要跑真实业务，需要提供自己的知识包。

## 架构

```
消费层   手机 · PC · MCP
           │
能力层   受控查询 · 动作服务 · 变更集 · 任务
           │
内核层   ① 本体  ② 权限  ③ 变更集与溯源  ④ 知识运行时  ⑤ AI 运行时
           │                                    ▲
数据层   PostgreSQL 单库             知识包 ──────┘
        （OLTP + JSONB + 向量 + 全文 + RLS）
控制平面  多实例部署 · 升级 · 监控 · 计量
```

**四条不变量：**

1. 任何数据访问经权限内核裁决；
2. 任何数据写入经变更集内核；
3. 任何 AI 判断可追溯到具体的提示词版本；
4. 知识包必须验签通过才可加载。

## 知识包

引擎通过知识包加载业务规则，因此**换知识包 = 换一套业务打法**。
公开 schema 只描述一个通用的**阶段门（stage-gate）**引擎，不含任何业务语义。

格式示例见 [`testdata/demo-pack/`](testdata/demo-pack/)。

## 技术栈

TypeScript（Node 24 LTS）· PostgreSQL 18（JSONB + pgvector + 全文 + RLS）· React + Vite · Docker Compose

## 贡献

见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。欢迎贡献**引擎能力**。
**请不要贡献"某个行业的业务打法"**——那属于使用者的专有资产。见 [`COMMERCIAL.md`](COMMERCIAL.md)。

## 安全

漏洞披露流程见 [`SECURITY.md`](SECURITY.md)。

## 许可

Apache-2.0，见 [`LICENSE`](LICENSE)。
商标不随代码授权，见 [`TRADEMARKS.md`](TRADEMARKS.md)。
