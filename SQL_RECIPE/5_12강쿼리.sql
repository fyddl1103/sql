-- 12.1 날짜별 등록 수의 추이를 집계하는 쿼리
SELECT register_date
     , COUNT(DISTINCT user_id) AS register_count
  FROM mst_users
 GROUP BY register_date
 ORDER BY register_date;

-- 12.2 매달 등록 수와 전월비 계산하는 쿼리
WITH mst_users_with_year_month AS (
  SELECT user_id
	   , substring(register_date,1,7) AS year_month
	FROM mst_users
) 
SELECT T1.*
	 , ROUND(T1.register_count / T1.last_month_count * 1.0, 2) AS month_over_ratio 
  FROM ( SELECT year_month
		 , COUNT(DISTINCT user_id) AS register_count
		 , LAG(COUNT(DISTINCT user_id)) OVER(ORDER BY year_month) AS last_month_count
  FROM mst_users_with_year_month
 GROUP BY year_month ) T1;
 
  