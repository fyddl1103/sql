-- 5-1.
SELECT user_id, 
       CASE 
         WHEN register_device = 1 THEN '데스크톱' 
         WHEN register_device = 2 THEN '스마트폰' 
         WHEN register_device = 3 THEN '앱' 
         ELSE '' 
       END AS device_name 
FROM   mst_users; 

-- 5-2.
-- 레퍼러 도메인을 추출하는 쿼리(정규표현식 이용)
SELECT stamp
	  ,substring(referrer from 'https?://([^/]*)') AS referrer_host
	  ,referrer
  FROM access_log
 
-- 5-3.
-- URL 경로와 GET 매개변수에 있는 특정 키 값 추출
SELECT stamp
     , url
	 , substring(url from '//[^/]+([^?#]+)') AS path
	 , substring(url from 'id=([^&]*)') AS id
  FROM access_log;
  
-- 5-4.
-- Path 경로를 슬래쉬(/)로 분할해서 계층 추출
SELECT stamp
     , url
	 , substring(url from '//[^/]+([^?#]+)') AS path
-- 	 , substring(url from 'id=([^&]*)') AS id
     , split_part(substring(url from '//[^/]+([^?#]+)'), '/', 2) AS path1
     , split_part(substring(url from '//[^/]+([^?#]+)'), '/', 3) AS path2
FROM access_log;

-- 5.5.
-- 현재 날짜와 타임스탬프 추출하는 쿼리
SELECT CURRENT_DATE AS dt
     , CURRENT_TIMESTAMP AS stamp
	 , LOCALTIMESTAMP AS notimezone;
	
-- 5-6.
-- 문자열을 날짜자료형, 타임스탬프 자료형으로 변환하는 쿼리
SELECT 
      -- 'value::type'
	  '2016-03-14'::date
      -- CAST(value AS type)
	  ,CAST('2010-10-24' AS date)
	  -- 'type value'
	  ,date '2016-12-14'
	  ,CAST(CURRENT_TIMESTAMP AS timestamp);	
	  
-- 5-7.
-- 타임스탬프 자료형의 데이터에서 연,월,일 추출하는 쿼리
SELECT EXTRACT(year FROM T1.stamp)
	 , EXTRACT(month FROM T1.stamp)
	 , EXTRACT(day FROM T1.stamp)
	 , EXTRACT(hour FROM T1.stamp)
	 , EXTRACT(minute FROM T1.stamp)
  FROM (SELECT CURRENT_TIMESTAMP AS stamp) AS T1;
  
-- 5-9.
-- 결측값을 디폴트값으로 대치하기 
SELECT purchase_id
      ,amount
	  ,amount - coupon AS amount1
	  ,amount - COALESCE (coupon, 0) AS amount2      
  FROM purchase_log_with_coupon;