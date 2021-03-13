-- 10.1 카테고리별 매출과 소계를 동시에 구하는 쿼리
WITH sub_category_amount AS
(
  SELECT category AS category
	    , sub_category AS sub_category
	   , SUM(price) AS amount
	FROM purchase_detail_log
   GROUP BY category 
	      , sub_category
)
, category_amount AS
(
	SELECT category AS category
	     , 'all'::text AS sub_category
	     , SUM(price) AS amount
	FROM purchase_detail_log
   GROUP BY category 
)
, total_amount AS
(
	SELECT 'all'::text AS category
	      , 'all'::text AS sub_category
	      , SUM(price) AS amount
	FROM purchase_detail_log
)
SELECT category, sub_category, amount FROM sub_category_amount
 UNION ALL SELECT category, sub_category, amount FROM category_amount
 UNION ALL SELECT category, sub_category, amount FROM total_amount ;

-- 10.2 ROLLUP을 사용하여 카테고리별 매출과 소계를 동시에 구하는 쿼리
 SELECT COALESCE(category, 'all') AS category
      , COALESCE(sub_category, 'all') AS sub_category
	  , SUM(price) as amount
  FROM purchase_detail_log
 GROUP BY ROLLUP(category, sub_category)
 ORDER BY category, sub_category DESC;

-- 10.3 매출 구성비누계 구하기
-- 1. 매출이 높은 순서로 데이터 정렬 (purchase_log)
-- 2. 매출 합계 집계
-- 3. 매출 합계로 각 데이터가 차지하는 비율 계산, 구성비 구함
-- 4. 구성비를 기반으로 구성비누계 구함

WITH monthly_sales AS (
 SELECT category, SUM(price) AS amount 
   FROM purchase_detail_log
GROUP BY category
)
, sales_ratio AS (
  SELECT category
	   , amount
	   , TRUNC(100.0 * amount / SUM(amount) OVER()) AS ratio_purchase -- 구성비
	   , TRUNC(100.0 * SUM(amount) OVER(order by amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / SUM(amount) OVER()) AS cumm_purchase
	FROM monthly_sales
)
SELECT *
     , CASE WHEN cumm_purchase BETWEEN 0 AND 70 THEN 'A'
			WHEN cumm_purchase BETWEEN 70 AND 90 THEN 'B'
			WHEN cumm_purchase BETWEEN 90 AND 100 THEN 'C' END AS rank
FROM sales_ratio;

 -- 10.4 팬차트 (기준점을 100%로 잡고 비교)
 WITH daily_cate_amount AS (
	SELECT dt
	 	 , category
	     , substring(dt, 1, 4) AS year
	     , substring(dt, 6, 2) AS month
	 	 , substring(dt, 9, 2) AS date
	 	 , sum(price) AS amount
	  FROM purchase_detail_log
	GROUP BY dt, category
 )
 , monthly_cate_amount AS (
	SELECT concat(year, '-', month) AS year_month
	 	 , category
	 	 , SUM(amount) AS amount
	  FROM daily_cate_amount
	GROUP BY year, month, category 	
 )
 SELECT year_month
     , category
	 , amount
	 , FIRST_VALUE(amount) OVER(PARTITION BY category ORDER BY year_month, category ROWS UNBOUNDED PRECEDING) AS base_amount
	 , 100.0 * amount / FIRST_VALUE(amount) OVER(PARTITION BY category ORDER BY year_month, category ROWS UNBOUNDED PRECEDING) AS rate
  FROM monthly_cate_amount
 ORDER BY year_month, category

 -- 10.5 (히스토그램) 최대값, 최소값, 범위구하기
 -- 정규화 ? x - min / max - min
 -- 최대값 ; max+1로 해야 모든 값이 범위 안에 들어옴 (1~10 계층)
 WITH stats AS (
 	SELECT MAX(price)+1 AS max_price
	 	 , MIN(price) AS min_price
	 	 , MAX(price)+1 - MIN(price) AS range_price
	 	 , 10 AS bucket_num
	 FROM purchase_detail_log
 )
 , purchase_log_with_bucket AS (
 	SELECT price
	     , min_price
	     -- 정규화 금액 ; 대상금액 - 최소금액
	     , price - min_price AS diff
	     -- 계층 범위 ; Max - Min / 계층수
	     , 1.0 * range_price / bucket_num AS bucket_range
	     -- 계층 판정 : FLOOR(정규화금액 /계층범위)
	     , FLOOR( 1.0 * (price - min_price) / (1.0 * range_price / bucket_num)) +1 AS bucket
	     -- 내장함수 width_bucket()
	     , width_bucket(price, min_price, max_price, bucket_num) AS buckets
	 FROM purchase_detail_log, stats
 ) 
 SELECT bucket
      , min_price + bucket_range * (bucket - 1) AS lower_limit
	  , min_price + bucket_range * bucket AS upper_limit
	  , COUNT(price) AS num
	  , SUM(price) AS total_amount 
   FROM purchase_log_with_bucket
  GROUP BY bucket, min_price, bucket_range
  ORDER BY bucket;