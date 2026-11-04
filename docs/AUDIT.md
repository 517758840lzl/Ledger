# 双机对照审计（更新 2026-11-03 深夜）

## 本轮真机闭环（清空 → 造数 → 对照）

在 iPhone XR 上**真点「清空」**（确认对话框点「清空」，不是取消），再对照 Android `loop/`：

| 步骤 | Android | iOS 实测 |
|---|---|---|
| 清空后流水 | L10 `$0` 空态 + Add CTA | `¥0.00` +「还没有流水」+「记一笔」✓ |
| 支出 42 | L20–L26 | 保存后结余 `-¥42`、cell「餐饮」✓ |
| 收入 100 | L30–L32 | 结余 `¥58`（与 Android `$58` 同口径）✓ |
| 加账户 | L42/L111 | 「支付宝备用」卡片 + Edit + 头像字 ✓ |
| 资产空态 | L100 深绿英雄卡 | 已改为英雄卡 + 图标功能行 + CTA ✓ |
| 账户 cell | L111 圆角卡/Edit | `LedgerAccountCell` ✓ |

## 对照后修掉的差距

1. **二级页藏底栏** — Android push 无底栏；iOS 原先挡住「保存」。现 `flow/monthly/assets/settings` 有 path 时隐藏 TabBar。
2. **记一笔键盘固定底部** — 分类多时「保存」不再被挤出屏外。
3. **记一笔字段** — 付款账户/日期改为 outlined 浮动标签；分类选中深绿白字。
4. **资产空态** — 对齐 L100：深绿「家底看板」英雄卡 + 图标行 + 说明卡。
5. **月报** — 「较上月」并入结余卡；空月柱可见灰基线；预算 CTA 描边文案对齐。
6. **设置全走 path push** — 不再混用 `NavigationLink`（否则二级页不藏底栏、dismiss 栈乱）。
7. **账户类型选择** — `confirmationDialog` 失效改为自定义选中 cell sheet。

## 仍可继续抠

1. 流水 cell 副标题应优先显示子分类（现有时仍可能显示「无备注」）。
2. 资产已配置态的「储蓄目标」编辑（Android 文案提到）。
3. 导入 HTML 分片（Android chat HTML）。
4. 底栏资产图标：Android 存钱罐 vs iOS 美元符号（次要）。

## 截图

- Android：`peraledger-capture/loop/screenshots/`
- 产品环说明：`peraledger-capture/PRODUCT_CLOSED_LOOP.md`
