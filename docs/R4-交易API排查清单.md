# R4｜Trade API 不可用 — 长桥侧排查清单

> 文档版本：v1.0 ｜ 编制日期：2026-08-26 ｜ 对应代码：`rust-backend/src/live.rs:752-822`
> 关联风险：`07-风险登记册.md` 的 **R4（交易 API 不可用，高）**
> 适用范围：OptionWorkstation 连接设置页显示 **Trade API = Unavailable** 时

---

## 0. 先理解判定逻辑（代码真因）

`live.rs` 判断是否"交易可用"靠两个长桥 OpenAPI 调用，任一成功即视为可用：

```rust
// live.rs:752-822（节选）
let trade_overview = trade.us_asset_overview().await.ok();        // 资产概览
let trade_balances  = if trade_overview.is_none() {
    trade.account_balance(Some("USD")).await.ok()                 // 账户余额（兜底）
} else { None };
let trade_connected = trade_overview.is_some() || trade_balances.is_some();
// ...
trade: trade_connected.then_some(trade),   // 为 false 时 TradeContext 不入库
```

- 前端显示 **Unavailable** = `trade_connected == false`
  = `us_asset_overview()` 与 `account_balance()` **两个调用都返回 None**（`.ok()` 把 Err/空都吞成 None）。
- 一旦 false，`TradeContext` 不存入 engine → 所有 `/api/trade/*` 报
  `trade permission is unavailable for this token`。

> 注意：这是**长桥账户/授权层面**的问题，OptionWorkstation 无需改代码。即便打通，本版 `order_execution_enabled` 还要求 `paper_account && paper_execution_requested`——即**只支持模拟账户(paper)的模拟单，实盘下单锁定**。

---

## 1. 常见根因（按概率排序）

| # | 根因 | 外在表现 |
|---|------|----------|
| 1 | **OAuth 授权 scope 未含「交易」** | 登录时申请的是 `quote` 权限，Trade 查询被拒（最常见） |
| 2 | **账户未开通 OpenAPI 交易服务** | App 内「美国期权市场 ✅」是下单/市场权限，与资产查询 API 是两套体系 |
| 3 | **账户无交易账户（未开户/未激活）** | `us_asset_overview` 无数据可查 |
| 4 | **应用为「只读行情」类型** | 在长桥开发者后台创建 OAuth 应用时选错了类型 |

---

## 2. 真值探测（在你的电脑上跑，验证到底是哪一类）

用你本机已装的长桥 CLI（路径 `C:\Users\SJTUH\AppData\Local\Programs\longbridge\longbridge`）：

```powershell
# 1) 先看 CLI 是否提供交易类子命令（以实际 --help 为准）
& "C:\Users\SJTUH\AppData\Local\Programs\longbridge\longbridge" --help
& "C:\Users\SJTUH\AppData\Local\Programs\longbridge\longbridge" trade --help

# 2) 尝试账户/资产查询（对应代码里的 us_asset_overview / account_balance）
& "C:\Users\SJTUH\AppData\Local\Programs\longbridge\longbridge" trade assets --format json
& "C:\Users\SJTUH\AppData\Local\Programs\longbridge\longbridge" trade balances --format json
```

- 若返回 **`code=...: no trade access` / `trade permission denied`** → 命中根因 1/2/4。
- 若返回 **正常 JSON 账户数据** → 说明权限在，问题在 OW 的 OAuth token 授权范围；回到第 3 步重连并刷新凭证。

> 注：CLI 子命令名以 `longbridge --help` 实际输出为准，不同版本略有差异。

---

## 3. 修复步骤（按顺序）

### 步骤 A — 确认 OAuth 应用授权范围含「交易」
1. 登录长桥开发者后台（OpenAPI / 应用管理）。
2. 找到 OptionWorkstation 使用的 OAuth 应用。
3. 检查 **授权范围(scopes)** 是否包含 `trade`（或 `account`、`assets`）。
4. 若仅含 `quote`，**在后台追加交易相关 scope 并保存**。

### 步骤 B — 确认账户已开通交易服务
1. 长桥 App → 账户 → 检查是否**已开通美股交易账户**（且已激活）。
2. 在长桥「开发者 / OpenAPI」页确认该账户已**启用交易 API**。
3. 注意「美国期权市场 ✅」是**下单/市场权限**，与 `us_asset_overview` 资产查询 API **是两套**，需分别确认。

### 步骤 C — 在 OptionWorkstation 内重连刷新凭证
1. 打开连接设置页。
2. 点 **「更换并验证凭证」**（触发 OAuth 重新授权，确保新 scope 生效）。
3. 观察 **Trade API** 状态是否变为可用。

### 步骤 D — 仍不可用时的二次确认
- 回到第 2 步用 CLI 真值探测，确认是权限还是网络。
- 若 CLI 正常、OW 仍 Unavailable，清理本地 token 缓存后重连：
  - 删除 `.option-workstation/` 下相关 token 文件，重启 `start.bat` 重新 OAuth。

---

## 4. 验证通过标准（验收）

- [ ] 连接设置页 **Trade API = Available**
- [ ] `GET /api/trade/account` 返回账户 JSON（非 `trade permission is unavailable`）
- [ ] 模拟单接口 `POST /api/trade/orders` 在 `paper_account && paper_execution_requested` 下可提交（实盘仍锁定，符合设计）

---

## 5. 关联文档
- `02-需求规格说明书.md` FR-19
- `04-接口设计说明书.md` 第 8 节（交易，预留）
- `07-风险登记册.md` R4
- `操作手册.md` 第 4/7 节（`.env` 与排查）
