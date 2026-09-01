# MTU趋势下滑归因

> ```
> 现象：MTU从什么时候开始异常？
> 原因：是流入不足还是流失增加？
> 洞察：具体是哪类用户在流失，为什么值得关注？
> 行动：应该采取什么止血和运营措施？
> ```

## 分析层次是：

```
第一部分：定位异常
→ W17 是拐点，W17–W18 连续恶化

第二部分：拆解原因
→ 首交 + 召回 - 转沉默
→ 比较各项在 W17 前后怎么变化

第三部分：下钻客群
→ 到底哪些用户在转沉默
```

## 定位MTU核心拐点

```
SELECT
week_num,
mtu_wan_end_of_week as current_mtu,
LAG(mtu_wan_end_of_week) over(ORDER BY week_num)  as previous_mtu,
(mtu_wan_end_of_week-LAG(mtu_wan_end_of_week,1,0) over(ORDER BY week_num)) as mtu_change,
ROUND((mtu_wan_end_of_week-LAG(mtu_wan_end_of_week,1,0) over(ORDER BY week_num))/NULLIF(LAG(mtu_wan_end_of_week,1,0) over(ORDER BY week_num),0),4) as mom_change_rate
FROM
daily_funnel 
WHERE
mtu_wan_end_of_week is not null 
```

![image-20260806163912663](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260806163912663.png)

> W17 是核心拐点：MTU环比降幅由 W16 的 1.45% 扩大到 4.95%。并且 W18 又下降 4.54%，说明不是单周波动，而是进入了连续恶化阶段。

## 拆MTU公式

假设以下公式成立

```
理论MTU变化量（万）
= [SUM(first_trade_uv) + SUM(recall_uv) - SUM(churn_uv)] / 10000
实际MTU变化量
= 本周MTU - 上周MTU
差异值
= 实际MTU变化量 - 理论MTU变化量
```

具体落在daily_funnel数据上

```
SELECT
week_num,
SUM(first_trade_uv) as first_trade_cnt,
SUM(recall_uv) as recall_cnt,
SUM(churn_uv) as churn_cnt,
(SUM(first_trade_uv)+SUM(recall_uv)-SUM(churn_uv))/10000 as theoretical_change_wan,
(MAX(mtu_wan_end_of_week)-LAG(max(mtu_wan_end_of_week),1) over(ORDER BY week_num)) as actual_change_wan,
((max(mtu_wan_end_of_week)-LAG(max(mtu_wan_end_of_week),1) over(ORDER BY week_num))-(SUM(first_trade_uv)+SUM(recall_uv)-SUM(churn_uv))/10000) as difference_wan
FROM
daily_funnel 
GROUP BY
week_num 
```

![image-20260807004441584](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260807004441584.png)

> 实际MTU变化与理论拆解结果存在一定差异，说明该公式更适合作为MTU变化的业务解释框架，而非严格的会计恒等式。差异可能来自统计时点、指标口径或未纳入的其他因素，后续分析中保留该差异项。
>
> 实际MTU变化
> = 首交流入 + 召回流入 - 转沉默 + ε

## MTU 下滑原因分析

### W16→W17三个组成项的变化

```
SELECT
week_num,
SUM(first_trade_uv) as first_trade_cnt,
SUM(recall_uv) as recall_cnt,
SUM(churn_uv) as churn_cnt,
(SUM(first_trade_uv)-LAG(SUM(first_trade_uv),1) over(ORDER BY week_num)) as first_trade_change,
(SUM(recall_uv)-LAG(SUM(recall_uv),1) over(ORDER BY week_num)) as recall_uv_change,
(SUM(churn_uv)-LAG(SUM(churn_uv),1) over(ORDER BY week_num)) as churn_uv_change
FROM
daily_funnel 
GROUP BY
week_num 
```

![image-20260807010251418](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260807010251418.png)

- **主因：转沉默增加**
  W17 比 W16 多转沉默 **10,109 人**，形成最大的负向压力。
- **次因：召回减少**
  召回减少 **3,828 人**，进一步削弱流入。
- **抵消因素：首交增加**
  首交增加 **5,380 人**，部分抵消了流失压力，但不足以扭转下降。
- 总流入14935+10832=25767
- 总流出38744
- 净缺口12977

> W17相较W16，首交增加5,380人形成正向抵消，但召回减少3,828人、转沉默增加10,109人，两项负向因素合计超过首交增量，使理论净变化进一步恶化8,557人。
>
> W17的MTU恶化主要由转沉默用户激增驱动，召回能力下降进一步加剧缺口；同期首交用户虽明显增长，但只能部分抵消负向影响。

### W17→W18三个组成项的变化

- **首交减少**

  W18比W17首交减少2667人

- **召回减少607人**
- **转沉默减少7722人**

- 总流入12268+10225=22493
- 总流出31022
- 净缺口8529

### 净流入/净流出对比

```
SELECT
week_num,
(SUM(first_trade_uv)+SUM(recall_uv)) as user_inflow,
SUM(churn_uv) as user_outflow,
(SUM(first_trade_uv)+SUM(recall_uv)-SUM(churn_uv)) as user_change
FROM
daily_funnel 
GROUP BY
week_num 
```

![image-20260808003352799](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260808003352799.png)

可以看出W16净流出达到了4420，W17突然净流出恶化到12977，W18也有较大的流出量。

> 可以看出W16开始有下滑趋势，W17突然恶化，W18也有较大的恶化。

### 组成项环比变化率

```
SELECT
week_num,
(SUM(first_trade_uv)-LAG(SUM(first_trade_uv),1) over(ORDER BY week_num))/NULLIF(LAG(SUM(first_trade_uv),1) OVER(ORDER BY week_num),0) as mom_first_trade_uv_rate,
(SUM(recall_uv)-LAG(SUM(recall_uv),1) over(ORDER BY week_num))/NULLIF(LAG(SUM(recall_uv),1) OVER(ORDER BY week_num),0) as mom_recall_uv_rate,
(SUM(churn_uv)-LAG(SUM(churn_uv),1) over(ORDER BY week_num))/NULLIF(LAG(SUM(churn_uv),1) OVER(ORDER BY week_num),0) as mom_churn_uv_rate
FROM
daily_funnel 
GROUP BY
week_num 
```

![image-20260808004306042](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260808004306042.png)

> 转沉默从W16开始已出现明显恶化，W16环比增长49.4%；W17在高基数基础上进一步增长35.3%，转沉默人数继续增加10,109人并达到38,744人的阶段峰值。与此同时，W17召回用户环比下降26.1%，进一步扩大净流出缺口。

> **W16可视为流失侧预警点。** 当周转沉默用户环比增长约49.4%，已经出现明显异常；虽然当周MTU整体降幅还没有像W17那样剧烈，但流失端的风险已经提前暴露。到了W17，转沉默继续在高位增长，同时召回明显下降，最终导致MTU出现断崖式恶化。

### 阶段结论

>  MTU下滑并非由拉新不足单独导致。流失侧风险从W16开始暴露，W17转沉默用户进一步激增，同时召回能力下降，使净流出缺口迅速扩大并形成核心拐点；W18虽然转沉默有所缓解，但流入端同步走弱，整体仍未恢复至健康状态。因此，后续分析应重点围绕“哪些用户在转沉默”展开。

## 下钻流失客群

### 按tier拆

```
SELECT
*
FROM
weekly_tier_events
WHERE
week_num = 'W17'
AND
event = '转沉默'

```

![image-20260808010147104](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260808010147104.png)

> 从流失规模看，W17中度用户转沉默人数最高，为18,499人；其次为重度用户10,900人，轻度用户7,178人。中度用户是当前流失规模最大的客群。
>
> 但流失人数最多不等于业务损失最大，因此暂时不能直接认定中度用户为核心责任客群，还需要结合交易频次和交易金额进一步判断各层级用户的价值损失。

**但是去掉W17这个限制条件会发现，中度用户一直都是转沉默最多的人群，所以不能说他是W17恶化的主要原因。**

```
SELECT
week_num,
tier,
user_count
- LAG(user_count) OVER(
    PARTITION BY tier
    ORDER BY week_num
) AS churn_change
FROM
weekly_tier_events
WHERE
event = '转沉默'
GROUP BY
week_num,
tier
```

![image-20260808124911799](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20260808124911799.png)

> 虽然中度用户在W17的转沉默绝对人数最高，但从W16→W17的增量来看，重度用户转沉默增加6,594人，明显高于中度用户的3,403人，而轻度用户反而减少1,287人。因此，**W17流失异常并非主要由中度用户规模扩大导致，而更集中地体现在重度用户的异常流失上。**