-- 6-1.
-- 문자열을 연결하는 쿼리
SELECT user_id,
       pref_name || city_name AS pref_city1,
	   CONCAT(pref_name,' ',city_name) AS pref_city2
  FROM mst_user_location;

-- 6-2. 같은 row의 컬럼을 비교하는 쿼리
SELECT year,
       q1,
	   q2,
	   -- q1과 q2의 매출 변화 평가하기
	   CASE WHEN q1 < q2 THEN '+'
	        WHEN q1 = q2 THEN ' '
			ELSE '-'
		END AS judge_q1_q2,
	   -- q1과 q2의 매출액 차이 계산하기
	   q2 - q1 AS diff_q2_q1,
	   -- q1과 q2의 매출변화를 1, 0, -1로 표현하기
	   SIGN(q2-q1) AS sign_q2_q1
  FROM quarterly_sales
 ORDER BY year;

-- 6.3 연간 최대/최소 4분기 매출을 찾는 쿼리
-- 컬럼 값에서 greatest, least 함수 이용
SELECT year
	  ,greatest(q1, q2, q3, q4) AS greatest_sales
	  ,least(q1, q2, q3, q4) AS least_sales
  FROM quarterly_sales;
  
-- 6.6 연간 평균 4분기 매출 계산하기
SELECT year
	  ,(COALESCE(q1,0) + COALESCE(q2,0) + COALESCE(q3,0) + COALESCE(q4,0)) / 
	   (SIGN(COALESCE(q1,0)) + SIGN(COALESCE(q2,0)) + SIGN(COALESCE(q3,0)) + SIGN(COALESCE(q4,0)))AS Average
  FROM quarterly_sales;
  
-- 6.7 정수 자료형의 데이터를 나누는 쿼리
-- CTR (=clicks/impressions)
SELECT dt 
     , ad_id
	 , CAST(clicks AS double precision) / impressions AS ctr
	 , 100 * clicks / impressions AS ctr_as_percent
  FROM advertising_stats
 WHERE dt = '2017-04-01';

-- 6.8 0으로 나누는 것을 피해 CTR을 계산하는 쿼리 (0이면 계산결과가 아예 안나옴)
SELECT dt
	  ,ad_id
	  --CASE식으로 분모가 0인 경우를 분기해서 0으로 나누지 않게 만드는 방법
	  ,CASE WHEN impressions > 0 THEN 100.0 * clicks / impressions END AS ctr_as_percent_by_case
	  --NULLIF(1,2) 1과 2가 동일하면 NULL, 그렇지 않으면 1 반환
	  , 100.0 * clicks / NULLIF(impressions,0) AS ctr_as_percent_by_case2
  FROM advertising_stats
 ORDER BY dt, ad_id;

-- 6.9 일차원 데이터의 절대값과 제곱평균제곱근을 계산하는 쿼리
SELECT abs(x1 - x2) AS abs
     , sqrt(power(x1-x2, 2)) AS rms
  FROM location_1d

-- 6.10 유클리드거리(이차원 데이터)를 구하는 쿼리
SELECT sqrt(power(x1-x2, 2) + power(y1-y2, 2)) AS dist
     , point(x1, y1) <-> point(x2, y2) AS dist
  FROM location_2d;

-- 6.11 미래 또는 과거의 날짜/시간을 계산하는 쿼리
-- (날짜타입 ; 5.6 참고 / value:type, type value, CAST(value AS type) )
SELECT user_id 
    , register_stamp::timestamp AS register_stamp
	, register_stamp::timestamp + '1 hour'::interval AS after_1_hour
	, register_stamp::timestamp - '30 minutes'::interval AS before_30_minutes
	, register_stamp::date AS register_date
	, (register_stamp::date + '1 day'::interval)::date AS after_1_day
	, (register_stamp::date - '1 month'::interval)::date AS before_1_month
  FROM mst_users_with_dates;  
  
--  SELECT now()
--       , now() - '1 months'::interval AS Asd;

-- 6.12 두 날짜의 차이 구하기
SELECT user_id
     -- 날짜 자료형끼리 빼기
	 , CURRENT_DATE AS today
	 , register_stamp::date AS register_date
	 , CURRENT_DATE - register_stamp::date AS diff_days
  FROM mst_users_with_dates;
  
-- 6.13 나이 계산하는 쿼리 (age(), EXTRACT()이용 - PostgreSQL만!)
-- 한국식 나이) 현재년도 - 태어난년도 + 1
SELECT user_id
	 , CURRENT_DATE AS today
	 , register_stamp::date AS register_date
	 , birth_date::date AS birth_date
	 , EXTRACT(YEAR FROM age(birth_date::date)) AS current_age
	 , EXTRACT(YEAR FROM age(register_stamp::date, birth_date::date)) AS register_age
  FROM mst_users_with_dates;

-- 전용함수 안쓰고 계산(TO_CHAR())
SELECT floor((CAST(TO_CHAR(now(), 'YYYYMMDD') AS integer) - CAST(TO_CHAR(birth_date::date, 'YYYYMMDD') AS integer))/10000) AS current_age
     , floor((CAST(TO_CHAR(register_stamp::date, 'YYYYMMDD') AS integer) - CAST(TO_CHAR(birth_date::date, 'YYYYMMDD') AS integer))/10000) AS register_age
  FROM mst_users_with_dates;

-- 전용함수 안쓰고 계산(replace+substring)
SELECT floor((CAST(REPLACE(substring(CAST(now() AS text),1,10),'-','') AS integer) - CAST(REPLACE(birth_date, '-', '') AS integer))/10000) AS current_age
     , floor((CAST(REPLACE(substring(register_stamp,1,10),'-','') AS integer) - CAST(REPLACE(birth_date, '-', '') AS integer))/10000) AS register_age
  FROM mst_users_with_dates;
  
-- 6.17 inet자료형을 사용한 IP주소 비교 , IP주소 범위 다루는 쿼리
SELECT CAST('127.0.0.1' AS inet) < CAST('127.0.0.2' AS inet) AS lt
     , CAST('127.0.0.1' AS inet) > CAST('192.168.0.1' AS inet) AS gt
	 , CAST('127.0.0.1' AS inet) << CAST('127.0.0.0/8' AS inet) AS is_contained;

-- 6.19/6.20/6.21 IP주소에서 4개의 10진수 부분을 추출하는 쿼리(정수형)
SELECT T1.ip
     , (T1.ip_part_1 * 2^24) + (T1.ip_part_2 * 2^16) + (T1.ip_part_3 * 2^8) + (T1.ip_part_4 * 2^0) AS ip_integer 
	 , lpad(split_part(T1.ip, '.', 1), 3, '0') || lpad(split_part(T1.ip, '.', 2), 3, '0') || lpad(split_part(T1.ip, '.', 3), 3, '0') || lpad(split_part(T1.ip, '.', 4), 3, '0') AS ip_padding
  FROM ( SELECT ip
     , CAST(split_part(ip, '.', 1) AS integer) AS ip_part_1
     , CAST(split_part(ip, '.', 2) AS integer) AS ip_part_2
     , CAST(split_part(ip, '.', 3) AS integer) AS ip_part_3
     , CAST(split_part(ip, '.', 4) AS integer) AS ip_part_4
FROM (SELECT CAST('192.168.0.1' AS text) AS ip) AS t ) T1