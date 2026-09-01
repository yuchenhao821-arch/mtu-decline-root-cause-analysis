# K交易所 · 专项二 MTU 下滑归因 · SQL 版

## 📦 文件说明

| 文件 | 用途 |
|---|---|
| `K交易所_专项二_MTU数据.db` | SQLite 数据库文件(推荐,双击可用 DB Browser for SQLite 打开) |
| `01_schema.sql` | 建表 SQL(SQLite / MySQL / PostgreSQL 兼容) |
| `02_data.sql` | 插入数据 SQL(先执行 01_schema.sql,再执行此文件) |
| `README.md` | 本说明文档 |

## 🔧 使用方式(3 选 1)

### 方式 A(最简单):用 SQLite 打开 .db 文件
1. 下载 **DB Browser for SQLite**(免费):https://sqlitebrowser.org/
2. 双击 `K交易所_专项二_MTU数据.db`
3. 直接写 SELECT 查询

### 方式 B:MySQL / PostgreSQL
1. 建库(比如 `CREATE DATABASE htx_project2;`)
2. 执行 `01_schema.sql`(建表)
3. 执行 `02_data.sql`(插入数据)
4. 开始查询

### 方式 C:Python + sqlite3
```python
import sqlite3
conn = sqlite3.connect('K交易所_专项二_MTU数据.db')
df = pd.read_sql("SELECT * FROM daily_funnel", conn)
```

## 📊 表结构

### 1. `daily_funnel`(每日活跃漏斗事实表,63 行)

| 字段 | 类型 | 含义 |
|---|---|---|
| `activity_date` | DATE | 日期(2026-03-30 至 2026-05-31) |
| `week_num` | VARCHAR | 所在周(W14-W22) |
| `first_trade_uv` | INT | 当日**首次交易**用户数(全平台) |
| `recall_uv` | INT | 当日**召回**用户数(从沉默恢复交易) |
| `churn_uv` | INT | 当日**转沉默**用户数(30 天未交易) |
| `mtu_wan_end_of_week` | DECIMAL | 该周**周末快照** MTU(万,只有周日填,其他日子为 NULL) |

### 2. `weekly_tier_events`(分层事件汇总表,81 行 = 9 周 × 3 tier × 3 event)

| 字段 | 类型 | 含义 |
|---|---|---|
| `week_num` | VARCHAR | 所在周(W14-W22) |
| `tier` | VARCHAR | 用户分层:`重度用户` / `中度用户` / `轻度用户` |
| `event` | VARCHAR | 事件类型:`首交流入` / `召回流入` / `转沉默` |
| `user_count` | INT | 该(周, tier, event)组合的用户数 |

### 3. `weeks_dim`(周次维度表,9 行)

| 字段 | 类型 | 含义 |
|---|---|---|
| `week_num` | VARCHAR | 周次代号(W14-W22) |
| `start_date` | DATE | 周开始(周一) |
| `end_date` | DATE | 周结束(周日) |

## 🔗 表之间的关系

```
daily_funnel.week_num  ─────► weeks_dim.week_num
weekly_tier_events.week_num ─► weeks_dim.week_num
```

**关键约束**:

- `weekly_tier_events` 中,某周某事件的 3 个 tier 加总 = `daily_funnel` 中该周该事件的合计
- 例:`SELECT SUM(user_count) FROM weekly_tier_events WHERE week_num='W17' AND event='转沉默'`
  = `SELECT SUM(churn_ uv) FROM daily_funnel WHERE week_num='W17'`(=36,577)

## 🎯 典型 SQL 分析场景

1. 计算各周 MTU 环比,找拐点
2. 计算每周 (首交+召回)/沉默 比值(健康度指标)
3. 分层看 W17 各 tier 的沉默数,找责任客群
4. 用 WINDOW 函数看每周环比 / 移动平均
5. JOIN weeks_dim,做时间段筛选

## ⚠️ 注意

- 数据经过脱敏和虚构处理,与真实业务无关
- 日期格式 YYYY-MM-DD,数据库存储为 DATE 类型
- 中文字段值(tier / event)使用 UTF-8 编码,建议数据库和连接工具也用 UTF-8
