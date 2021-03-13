-- 7.1 집약함수 이용하여 review 테이블 전체의 특징량을 계산하는 쿼리
SELECT COUNT(*) AS total_count
     , COUNT(DISTINCT user_id) AS user_count
	 , COUNT(DISTINCT product_id) AS product_count
	 , SUM(score) AS sum
	 , AVG(score) AS avg
	 , MAX(score) AS max
	 , MIN(score) AS min
  FROM review;
  
-- 7.2 데이터를 분할하고 집약 함수를 적용하는 쿼리(그루핑)
SELECT user_id
     , COUNT(*) AS total_count
     , COUNT(DISTINCT user_id) AS user_count
	 , COUNT(DISTINCT product_id) AS product_count
	 , SUM(score) AS sum
	 , AVG(score) AS avg
	 , MAX(score) AS max
	 , MIN(score) AS min
  FROM review
GROUP BY user_id;

-- 7.3 윈도우 함수를 사용해 집약 함수의 결과와 원래 값을 동시에 다루는 쿼리 
-- 윈도함수 이용 (GROUP BY 사용대신, OVER(), PARTITION BY <컬럼이름> 사용)
-- 개별리뷰점수(avg_score)와 사용자평균리뷰점수(user_avg_score) 차이 구하기
SELECT user_id
     , product_id
	 , score -- 개별점수
	 , ROUND(AVG(score) OVER(),2) AS avg_score -- 전체 평균 리뷰 점수
	 , ROUND(AVG(score) OVER(PARTITION BY user_id),2) user_avg_score -- 사용자의 평균 리뷰 점수
	 , ROUND(score - AVG(score) OVER(PARTITION BY user_id),2) AS user_avg_score_diff
  FROM review;
  
-- 7.4 윈도함수 이용하여 순서 다루기
-- OVER(ORDER BY ___)
-- ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD()
SELECT product_id
     , score
	 , ROW_NUMBER()  OVER(ORDER BY score DESC) AS row
	 , RANK()        OVER(ORDER BY score DESC) AS rank
	 , DENSE_RANK()        OVER(ORDER BY score DESC) AS dense_rank
	 , LAG(product_id)     OVER(ORDER BY score DESC) AS lag1
	 , LAG(product_id, 2)     OVER(ORDER BY score DESC) AS lag2
	 , LEAD(product_id)    OVER(ORDER BY score DESC) AS lead1
	 , LEAD(product_id, 2)    OVER(ORDER BY score DESC) AS lead2
  FROM popular_products
 ORDER BY row;
 
-- 7.5 ORDER BY + 분석함수 조합해서 계산하는 쿼리
SELECT product_id
     , score
	 , ROW_NUMBER()  OVER(ORDER BY score DESC) AS row -- 점수 순서로 유일한 순위 매기기
	 , SUM(score) OVER(ORDER BY score DESC 
					   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_score -- 상위 순위부터의 누계 점수 계산하기
	 , ROUND(AVG(score) OVER(ORDER BY score DESC
					   		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS local_avg -- 현재 행과 앞 뒤의 행이 가진 값을 기반으로 평균 점수 계산하기
	 , FIRST_VALUE(product_id) OVER(ORDER BY score DESC
									ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_value -- 순위가 높은 상품 ID 추출
	 , LAST_VALUE(product_id) OVER(ORDER BY score DESC
								  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_value -- 순위가 낮은 상품 ID 추출
FROM popular_products
 ORDER BY row;
 
-- 7.6 윈도 프레임 지정별 상품ID를 집약하는 쿼리
-- 프레임 지정 ; 현재 레코드 위치를 기반으로 상대적인 윈도를 정의하는 구문
-- ROWS BETWEEN start AND end > start 와 end에 올수 있는 것들
-- > 1. CURRENT ROW (현재의 행)
-- > 2. n PRECEDING (n행 앞)
-- > 3. n FOLLOWING (n행 뒤)
-- > 4. UNBOUNDED PRECEDING (이전 행 전부)
-- > 5. UNBOUNDED FOLLOWING (이후 행 전부)
-- ARRAY_AGG 함수는 요소 세트를 배열로 집계합니다. / ARRAY_AGG 집계 함수의 호출은 결과 배열 유형을 기반으로 합니다.
-- ex) {A001,A002,A003,A004}
SELECT product_id
	 , ROW_NUMBER()  OVER(ORDER BY score DESC) AS row 
	 , array_agg(product_id) OVER(ORDER BY score DESC 
					   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS whole_agg 
	 , array_agg(product_id) OVER(ORDER BY score DESC
					   		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_agg 
	 , array_agg(product_id) OVER(ORDER BY score DESC
									ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS local_agg 
FROM popular_products
WHERE category = 'action'
 ORDER BY row;

-- 7.7 윈도 함수를 사용해 카테고리들의 순위를 계산하는 쿼리
SELECT category
     , product_id
	 , score
	 -- 카테고리별로 점수 순서로 정렬하고 유일한 순위를 붙임
	 , ROW_NUMBER() OVER(PARTITION BY category ORDER BY score DESC) AS row
	 -- 카테고리별로 같은 순위를 허가하고 순위를 붙임 (1-1-3)
	 , RANK() OVER(PARTITION BY category ORDER BY score DESC) AS rank
	 -- 카테고리별로 같은 순위가 있을 때, 같은 순위 다음에 있는 순위를 건너 뛰지 않고 순위를 붙임(1-1-2)
	 , DENSE_RANK() OVER(PARTITION BY category ORDER BY score DESC) AS dense_rank
FROM popular_products
ORDER BY category, row;

-- 7.8 카테고리들의 순위 상위 2개까지의 상품을 추출하는 쿼리
SELECT *
  FROM (SELECT category
     , product_id
	 , score
	 -- 카테고리별로 점수 순서로 정렬하고 유일한 순위를 붙임
	 , ROW_NUMBER() OVER(PARTITION BY category ORDER BY score DESC) AS rank
FROM popular_products ) AS popular_products_with_rank WHERE rank <= 2;

-- 7.9 카테고리별 순위 최상위 상품을 추출하는 쿼리
SELECT DISTINCT category
	 , FIRST_VALUE(product_id) OVER(PARTITION BY category ORDER BY score DESC
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS rank
FROM popular_products;

-- 7.10 행으로 저장된 값 > 열로 변환하는 쿼리
SELECT dt
     , MAX(CASE WHEN indicator = 'impressions' THEN val END) AS impressions
	 , MAX(CASE WHEN indicator = 'sessions' THEN val END) AS sessions
	 , MAX(CASE WHEN indicator = 'users' THEN val END) AS users
 FROM daily_kpi
GROUP BY dt;

-- 7.11 행으로 저장된 값 > 쉼표로 구분한 문자열로 집약하는 쿼리
SELECT purchase_id
     , string_agg(product_id, ',') AS product_ids
	 , SUM(price) AS amount
  FROM purchase_detail_log
 GROUP BY purchase_id
 ORDER BY purchase_id

-- 7.12 열로 표현된 데이터 > 행으로 바꾸기 (피벗테이블형식으로)
-- 년도, 분기레이블, 매출
SELECT year
     , (CASE WHEN p.idx = 1 THEN 'q1' 
	         WHEN p.idx = 2 THEN 'q2'
	         WHEN p.idx = 3 THEN 'q3'
	         WHEN p.idx = 4 THEN 'q4'
	     END) AS quarter
	 , (CASE WHEN p.idx = 1 THEN q.q1  
	         WHEN p.idx = 2 THEN q.q2
	         WHEN p.idx = 3 THEN q.q3
	         WHEN p.idx = 4 THEN q.q4
	     END) AS sales_amount
  FROM quarterly_sales q
 CROSS JOIN
  -- 행으로 전개하고 싶은 열의 수만큼 순번 테이블 만들기
  ( SELECT 1 AS idx UNION ALL 
    SELECT 2 AS idx UNION ALL
    SELECT 3 AS idx UNION ALL
    SELECT 4 AS idx ) p
	
-- 7.13 테이블 함수를 사용하여 배열을 행으로 전개하는 쿼리
-- 테이블함수 ? 함수의 리턴값이 테이블인 함수
-- (PostgreSQL ; unnest / Hive, SparkSQL ; explode)
SELECT unnest(ARRAY['A001','A002','A003']) AS product_id;

-- 7.14 테이블함수를 이용하여 쉼표로 구분된 문자열 데이터를 행으로 전개하는 쿼리
SELECT p.purchase_id
     , product_id
  FROM purchase_log AS p
 CROSS JOIN unnest(string_to_array(product_ids,',')) AS product_id;

-- 7.15 PostgreSQL은 SELECT 구문 내부에 스칼라 값과 테이블 함수를 동시에 지정가능
SELECT purchase_id
     , regexp_split_to_table(product_ids, ',') AS product_id
  FROM purchase_log;