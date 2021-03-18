-- 11.1 액션 수와 비율을 계산하는 쿼리
-- action | action_uu | action_cnt | total_uu | usage_rate | count_per_user
-- cross join ; A table row 수 * B table row 수
WITH stats AS (
	-- 로그 전체의 유니크 사용자 수 구하기
	SELECT COUNT(DISTINCT session) AS total_uu
	  FROM action_log
)
SELECT T1.action
	 , COUNT(DISTINCT T1.session) AS action_uu
	 , COUNT(1) AS action_count
	 , T2.total_uu
	 , 100.0 * COUNT(DISTINCT T1.session) / T2.total_uu AS usage_rate
	 , COUNT(1) / COUNT(DISTINCT T1.session) AS count_per_user
  FROM action_log T1
       CROSS JOIN stats T2 -- action_log 테이블로 결합
	 GROUP BY T1.action, T2.total_uu;
	 
-- 11.2 로그인 상태를 판별하는 쿼리
WITH login_stats AS (
	SELECT session
		 , user_id
		 , action
	     , CASE WHEN COALESCE(user_id, '') <> '' THEN 'login' ELSE 'guest' END AS login_status 	
	  FROM action_log
)
SELECT *
  FROM login_stats;

-- 11.2/3 로그인 상태를 판별하는 쿼리
-- ROLLUP()
WITH login_stats AS (
	SELECT session
		 , user_id
		 , action
	     , CASE WHEN COALESCE(user_id, '') <> '' THEN 'login' ELSE 'guest' END AS login_status 	
	  FROM action_log
)
SELECT COALESCE(action, 'all') AS action
     , COALESCE(login_status, 'all') AS login_status
	 , COUNT(DISTINCT session) AS action_uu
	 , COUNT(1) AS action_count
  FROM login_stats
 GROUP BY ROLLUP(action, login_status);

-- 11.4 회원 상태를 판별하는 쿼리
WITH login_stats AS (
	SELECT session
		 , user_id
		 , action 
	    -- 이전에 한번이라도 로그인했다면 member로!
		 , CASE WHEN COALESCE(MAX(user_id) OVER(partition by session order by stamp ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), '') <> ''
	 			THEN 'member' ELSE 'none' END AS member_status
	     ,stamp
	FROM action_log
)
SELECT *
  FROM login_stats;

-- 11.5 사용자의 생일을 계산하는 쿼리
-- 11.6 성별과 연령으로 연령별 구분을 계산하는 쿼리
-- 11.7 연령별 구분의 사람 수 계산하는 쿼리
WITH mst_date AS (
	SELECT *
		 , CAST('20210316' AS integer) AS std_date
		 , CAST(replace(birth_date,'-','') AS integer) AS int_date
	  FROM mst_users
)
, calc_age AS (
	SELECT T1.*
	      ,floor((std_date - int_date) / 10000) AS age
	  FROM mst_date T1
)
, age_sex_cate AS (
	SELECT user_id
	     , sex
	     , age
	     , CONCAT(CASE WHEN age >= 20 THEN sex ELSE '' END ,
				  CASE WHEN age BETWEEN 4 AND 12 THEN 'C'
				       WHEN age BETWEEN 13 AND 19 THEN 'T'
				  	   WHEN age BETWEEN 20 AND 34 THEN '1'
				       WHEN age BETWEEN 35 AND 49 THEN '2'
				       WHEN age >= 50 THEN '3' ELSE '' END) AS  category
	  FROM calc_age
)	SELECT category
         , COUNT(1) AS cate_num 
	  FROM age_sex_cate
	 GROUP BY category
	 
-- 11.8 연령별 구분과 카테고리를 집계하는 쿼리
WITH mst_date AS (
	SELECT *
		 , CAST('20210316' AS integer) AS std_date
		 , CAST(replace(birth_date,'-','') AS integer) AS int_date
	  FROM mst_users
)
, calc_age AS (
	SELECT T1.*
	      ,floor((std_date - int_date) / 10000) AS age
	  FROM mst_date T1
)
, age_sex_cate AS (
	SELECT user_id
	     , sex
	     , age
	     , CONCAT(CASE WHEN age >= 20 THEN sex ELSE '' END ,
				  CASE WHEN age BETWEEN 4 AND 12 THEN 'C'
				       WHEN age BETWEEN 13 AND 19 THEN 'T'
				  	   WHEN age BETWEEN 20 AND 34 THEN '1'
				       WHEN age BETWEEN 35 AND 49 THEN '2'
				       WHEN age >= 50 THEN '3' ELSE '' END) AS  category
	  FROM calc_age
)
SELECT T1.category AS product_cate
     , T2.category AS user_cate
	 , COUNT(1) AS purchase_count
  FROM action_log AS T1 JOIN
       age_sex_cate AS T2
	   ON T1.user_id = T2.user_id
  WHERE T1.action = 'purchase'
 GROUP BY T1.category, T2. category
	   
-- 11.9 한 주에 며칠 사용되었는지 집계하는 쿼리
WITH action_log_with_dt AS (
	SELECT *
		 ,substr(stamp,1,10) AS dt
	  FROM action_log
), action_day_count_per_user AS (
	SELECT user_id 
	      ,COUNT(distinct dt) AS action_day_count 
	  FROM action_log_with_dt -- 1주에 대한 조건 걸기
    GROUP BY user_id
) 
SELECT action_day_count,
       COUNT(DISTINCT user_id) AS user_cnt,
-- 11.10 구성비/구성비누계 산출
		100.0 * COUNT(DISTINCT user_id) / SUM(COUNT(DISTINCT user_id)) OVER() AS compos_ratio, -- 구성비
		100.0 * SUM(COUNT(DISTINCT user_id)) OVER(ORDER BY action_day_count 
							ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / 
				SUM(COUNT(DISTINCT user_id)) OVER() AS cum_ratio -- 구성비누계
 FROM action_day_count_per_user
GROUP BY action_day_count;

-- 11.11/12 사용자들의 액션 플래그를 집게하는 쿼리
-- CUBE() ; 모든 조합에 대한 수 집계
WITH user_action_flag AS (
	-- 사용자가 액션했으면 1, 안했으면 0으로 플래그 붙이기
	SELECT user_id
		 , SIGN(SUM(CASE WHEN action='purchase' THEN 1 ELSE 0 END)) AS has_purchase
		 , SIGN(SUM(CASE WHEN action='review' THEN 1 ELSE 0 END)) AS has_review
		 , SIGN(SUM(CASE WHEN action='favorite' THEN 1 ELSE 0 END)) AS has_favorite
	  FROM action_log
	GROUP BY user_id
), action_venn_diagram AS (
	-- CUBE를 사용해서 모든 액션 조합 구하기
	SELECT has_purchase
	     , has_review
	     , has_favorite
	     , COUNT(1) AS users
	  FROM user_action_flag
	GROUP BY CUBE(has_purchase
				 , has_review
				 , has_favorite)	
)
-- 11.15 벤 다이어그램을 만들기 위해 데이터 가공하는 쿼리
SELECT CASE has_purchase WHEN 1 THEN 'purchase' WHEN 0 THEN 'not purchase' ELSE 'any' END AS has_purchase
     , CASE has_review WHEN 1 THEN 'review' WHEN 0 THEN 'not review' ELSE 'any' END AS has_review
	 , CASE has_favorite WHEN 1 THEN 'favorite' WHEN 0 THEN 'not favorite' ELSE 'any' END AS has_favorite
	 , users
	 -- 모든 액션이 null인 사용자 수  = 전체 사용자 수
	 , ROUND(100.0 * users / NULLIF(SUM(CASE WHEN has_purchase IS NULL AND has_review IS NULL AND has_favorite IS NULL THEN users ELSE 0 END) OVER(), 0), 2) AS ratio
  FROM action_venn_diagram;

