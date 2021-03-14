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
