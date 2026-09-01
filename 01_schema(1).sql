-- ==================================================
-- K交易所商分实战 · 专项二 MTU 下滑归因 · 数据库表结构
-- ==================================================
-- 兼容:SQLite / MySQL / PostgreSQL(基本 SQL 语法)
-- 数据来源:2026年Q2 W14-W22(2026-03-30 至 2026-05-31)


-- --------------------------------------------------
-- 表 1:每日活跃漏斗事实表(全平台每日汇总)
-- --------------------------------------------------
DROP TABLE IF EXISTS daily_funnel;
CREATE TABLE daily_funnel (
    activity_date        DATE           NOT NULL,       -- 日期
    week_num             VARCHAR(10)    NOT NULL,       -- 所在周(W14-W22)
    first_trade_uv       INTEGER        NOT NULL,       -- 首交流入用户数
    recall_uv            INTEGER        NOT NULL,       -- 召回流入用户数
    churn_uv             INTEGER        NOT NULL,       -- 转沉默用户数
    mtu_wan_end_of_week  DECIMAL(10,2),                 -- 该周周末快照 MTU(万,只有周日填,其他为 NULL)
    PRIMARY KEY (activity_date)
);


-- --------------------------------------------------
-- 表 2:分层事件汇总表(按周 × 客群 × 事件类型 拆分)
-- --------------------------------------------------
DROP TABLE IF EXISTS weekly_tier_events;
CREATE TABLE weekly_tier_events (
    week_num    VARCHAR(10)  NOT NULL,     -- 所在周(W14-W22)
    tier        VARCHAR(20)  NOT NULL,     -- 用户分层:重度用户 / 中度用户 / 轻度用户
    event       VARCHAR(20)  NOT NULL,     -- 事件类型:首交流入 / 召回流入 / 转沉默
    user_count  INTEGER      NOT NULL,     -- 该(周,tier,event)组合的用户数
    PRIMARY KEY (week_num, tier, event)
);


-- --------------------------------------------------
-- 表 3:周次维度表(方便 JOIN 和日期计算)
-- --------------------------------------------------
DROP TABLE IF EXISTS weeks_dim;
CREATE TABLE weeks_dim (
    week_num    VARCHAR(10)  NOT NULL,     -- 周次代号(W14-W22)
    start_date  DATE         NOT NULL,     -- 周开始日期(周一)
    end_date    DATE         NOT NULL,     -- 周结束日期(周日)
    PRIMARY KEY (week_num)
);
