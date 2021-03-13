-- 9.1 날짜별 매출과 평균 구매액을 집계하는 쿼리
SELECT T1.dt
     , COUNT(T1.dt) AS purchase_count
	 , SUM(T1.purchase_amount) AS total_amount
	 , TRUNC(AVG(T1.purchase_amount),2) AS avg_amount
  FROM purchase_log T1
 GROUP BY T1.dt
 ORDER BY T1.dt;
 
-- 9.2 날짜별 매출과 7일 이동평균을 집계하는 쿼리
SELECT T1.dt
     , SUM(T1.purchase_amount) AS total_amount
	 -- 7일 이동평균(과거 7일분의 데이터가 있는 경우에만 평균 구하도록 CASE문에 담기)
	 , CASE WHEN 7 = COUNT(*) OVER(ORDER BY dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
	   THEN
	    TRUNC(AVG(SUM(T1.purchase_amount)) OVER(ORDER BY dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) END 
	     AS seven_days_avg
  FROM purchase_log T1
 GROUP BY T1.dt
 ORDER BY T1.dt;
 
-- 9.3 날짜별 매출과 월별 누계 매출을 집계하는 쿼리
-- "2014-01-01"	"2014-01"	13900	13900
-- "2014-01-10"	"2014-01"	10000	23900
-- "2014-02-08"	"2014-02"	28469	28469
-- "2014-02-10"	"2014-02"	30000	58469
SELECT T1.dt
     , substring(T1.dt,1,7) AS year_month
	 , SUM(T1.purchase_amount) AS total_amount
	 -- 당월 누계 매출 합계
     , SUM(SUM(T1.purchase_amount)) OVER(PARTITION BY substring(T1.dt, 1, 7) ORDER BY dt ROWS UNBOUNDED PRECEDING) AS agg_amount
  FROM purchase_log T1
 GROUP BY T1.dt
 ORDER BY T1.dt;
 
-- 9.4 날짜별 매출을 WITH절로 빼기
WITH daily_purchase AS (
   SELECT dt
	    , substring(dt, 1, 4) AS year
	    , substring(dt, 6, 2) AS month
	    , substring(dt, 9, 2) AS date
	    , SUM(purchase_amount) AS purchase_amount
	    , COUNT(order_id) AS orders
 	 FROM purchase_log
	GROUP BY dt
)
SELECT * FROM daily_purchase ORDER BY dt;

-- 9.5 daily_purchase 테이블에 대해 당월 누계 매출을 집계하는 쿼리W
WITH daily_purchase AS (
   SELECT dt
	    , substring(dt, 1, 4) AS year
	    , substring(dt, 6, 2) AS month
	    , substring(dt, 9, 2) AS date
	    , SUM(purchase_amount) AS purchase_amount
	    , COUNT(order_id) AS orders
 	 FROM purchase_log
	GROUP BY dt
)
SELECT dt
     , year || '-' || month AS year_month
	 , purchase_amount AS purchase_amount
	 , SUM(purchase_amount) OVER(PARTITION BY year, month ORDER BY dt ROWS UNBOUNDED PRECEDING) AS agg_amount
  FROM daily_purchase
 ORDER BY dt;

-- 9.6 월별 매출과 작대비(작년 대비 비율)을 계산하는 쿼리
WITH daily_purchase AS (
   SELECT dt
	    , substring(dt, 1, 4) AS year
	    , substring(dt, 6, 2) AS month
	    , substring(dt, 9, 2) AS date
	    , SUM(purchase_amount) AS purchase_amount
	    , COUNT(order_id) AS orders
 	 FROM purchase_log
	GROUP BY dt
	ORDER BY dt
)
SELECT month
     , SUM(CASE year WHEN '2014' THEN purchase_amount END) AS sum_2014
     , SUM(CASE WHEN year = '2015' THEN purchase_amount END) AS sum_2015
	 , TRUNC(100.0 * SUM(CASE WHEN year = '2015' THEN purchase_amount END) / 
	   SUM(CASE WHEN year = '2014' THEN purchase_amount END),2) AS rate
  FROM daily_purchase
 GROUP BY month
 ORDER BY month;

-- 9.7 2015 매출에 대한 Z차트를 작성하는 쿼리
-- Z차트 ; 월차매출 / 매출누계(단기적 추이) / 이동년계(장기적 추이)
WITH daily_purchase AS (
   SELECT dt
	    , substring(dt, 1, 4) AS year
	    , substring(dt, 6, 2) AS month
	    , substring(dt, 9, 2) AS date
	    , SUM(purchase_amount) AS purchase_amount
	    , COUNT(order_id) AS orders
 	 FROM purchase_log
	GROUP BY dt
	ORDER BY dt
)
-- 월별 매출 집계하기
, monthly_amount AS (
	SELECT year 
	     , month
	     , SUM(purchase_amount) AS month_amount
      FROM daily_purchase
     GROUP BY year, month
)
-- 누계매출, 이동년계 집계하기
, calc_index AS (
    SELECT year
	     , month
	     , month_amount
	     -- 2015년의 누계 매출 
	     , SUM(CASE WHEN year = '2015' THEN month_amount END) OVER(ORDER BY year, month ROWS UNBOUNDED PRECEDING) AS agg_amount
	     -- 당월부터 11개월 이전까지의 이동년계
	     , SUM(month_amount) OVER(ORDER BY year, month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS year_avg_amount
	  FROM monthly_amount
)
SELECT concat(year, '-', month) AS year_month
     , month_amount
	 , agg_amount
	 , year_avg_amount
  FROM calc_index
 WHERE year = '2015'
 ORDER BY year;
 
-- 9.8 매출과 관련된 지표를 집계하는 쿼리
WITH daily_purchase AS (
   SELECT dt
	    , substring(dt, 1, 4) AS year
	    , substring(dt, 6, 2) AS month
	    , substring(dt, 9, 2) AS date
	    , SUM(purchase_amount) AS purchase_amount
	    , COUNT(order_id) AS orders
 	 FROM purchase_log
	GROUP BY dt
	ORDER BY dt
),
monthly_purchase AS (
   SELECT year
	    , month
	    , SUM(orders) AS orders
	    , SUM(purchase_amount) AS monthly
	    , AVG(purchase_amount) AS avg_amount
	 FROM daily_purchase
    GROUP BY year, month
	ORDER BY year, month
)
SELECT T1.year || '-' || T1.month AS year_month
     , T1.orders
	 , T1.avg_amount
	 , T1.monthly
	 , SUM(T1.monthly) OVER(PARTITION BY T1.year ORDER BY year ROWS UNBOUNDED PRECEDING) AS agg_amount
	 -- 12개월전(1년전) 매출 구하기
	 , LAG(T1.monthly,12) OVER(ORDER BY year, month ROWS BETWEEN 12 PRECEDING AND 12 PRECEDING) AS last_year
	 -- 12개월 전의 매출과 비교해서 비율 구하기(작대비)
	 , 100.0 * T1.monthly / LAG(T1.monthly,12) OVER(ORDER BY year, month ROWS BETWEEN 12 PRECEDING AND 12 PRECEDING) AS rate
  FROM monthly_purchase AS T1

