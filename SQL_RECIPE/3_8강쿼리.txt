-- 8.1 UNION ALL 구문을 사용해 테이블을 세로로 결합
SELECT 'app1' AS app_name, user_id, name, email, NULL AS phone FROM app1_mst_users
UNION ALL
SELECT 'app2' AS app_name, user_id, name, NULL AS email, phone FROM app2_mst_users;

-- 8.2 단순JOIN을 이용하여 여러 개의 테이블을 결합해서 가로로 정렬하는 쿼리
-- book 데이터 없어지고, p테이블에 같은 category_id가 부여된 dvd, cd는 가격이 중복되어 출력됨
-- 1	"dvd"	850000	"D001"
-- 1	"dvd"	850000	"D002"
-- 1	"dvd"	850000	"D003"
-- 2	"cd"	500000	"C001"
-- 2	"cd"	500000	"C002"
-- 2	"cd"	500000	"C003"
SELECT m.category_id
     , m.name
	 , s.sales
	 , p.product_id AS sale_product
  FROM mst_categories AS m
  JOIN category_sales AS s
    ON m.category_id = s.category_id
  JOIN product_sale_ranking AS p
    ON m.category_id = p.category_id;
	
-- 8.3 LEFT JOIN 이용 > category_id = 3 레코드 유지 & rank=1인 상품만이라는 조건을 걸어 카테고리가 여러 행이 안되도록 함
-- 마스터테이블(mst_categories) category_id = 1,2,3 유지
-- 1	"dvd"	850000	"D001"
-- 2	"cd"	500000	"C001"
-- 3	"book"		
SELECT m.category_id
     , m.name
	 , s.sales
	 , r.product_id AS sale_product
  FROM mst_categories AS m 
  LEFT JOIN 
    category_sales AS s
  ON m.category_id = s.category_id
  LEFT JOIN
    product_sale_ranking AS r
  ON m.category_id = r.category_id
  AND r.rank = 1;

-- 8.4 상관 서브쿼리로 여러개의 테이블 가로로 정렬 
-- ORDER BY, LIMIT 구문 사용함
SELECT 
    m.category_id
  , m.name
    -- 상관 서브쿼리를 사용해 카테고리별로 매출액 추출
  , (
	  SELECT s.sales
	    FROM category_sales AS s
	    WHERE m.category_id = s.category_id
    ) AS sales
	-- 카테고리별로 최고 매출 상품을 하나 추출하기(순위로 따로 압축하지 않아도 됨)
  , (
	  SELECT r.product_id
	    FROM product_sale_ranking AS r
	   WHERE m.category_id = r.category_id
	   ORDER BY sales DESC
	   LIMIT 1
    ) AS top_sale_product
  FROM mst_categories AS m;

-- 8.5 신용카드등록과 구매이력유무를 0,1이라는 플래그로 나타내기 (CASE문 / SIGN함수)
SELECT A.user_id
     , A.card_number
     , MAX(CASE WHEN A.card_number IS NOT NULL THEN '1' ELSE '0' END) AS card_YN
	 , COUNT(B.user_id) AS purchase_cnt
	 , CASE WHEN COUNT(B.user_id) <> 0 THEN '1' ELSE '0' END AS purchase_YN
	 , SIGN(COUNT(B.user_id)) AS purchase_YN2 -- 0이상의 숫자면 '0'은 0, '1이상'은 1로 변환
  FROM mst_users_with_card_number AS A
  LEFT JOIN purchase_log AS B
  ON A.user_id = B.user_id
 GROUP BY A.user_id, A.card_number
 ORDER BY A.user_id;
 
-- 8.6 카테고리별 순위를 윈도함수로 계산, JOIN을 사용해 같은순위의 상품을 가로로 나타내기
SELECT category_name, 
       product_id,
	   sales,
	   RANK() OVER(PARTITION BY category_name ORDER BY sales DESC) AS rank 
  FROM product_sales;
  
-- with절 이용
WITH product_rank AS
( 
SELECT category_name, 
       product_id,
	   sales,
	   ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY sales DESC) AS rank 
  FROM product_sales
)
SELECT T1.*
  FROM product_rank AS T1;

-- 8.8 카테고리별 순위를 윈도함수로 계산, JOIN을 사용해 같은순위의 상품을 가로로 나타내기
-- 1	"B001"	20000	"C001"	30000	"D001"	50000
-- 2	"B002"	15000	"C002"	20000	"D002"	20000
-- 3	"B003"	10000	"C003"	10000	"D003"	10000
-- 4	"B004"	5000				
SELECT category_name, 
       product_id,
	   sales,
	   RANK() OVER(PARTITION BY category_name ORDER BY sales DESC) AS rank 
  FROM product_sales;
  
-- with절 이용
WITH product_rank AS
( 
SELECT category_name, 
       product_id,
	   sales,
	   ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY sales DESC) AS rank 
  FROM product_sales
)
-- , mst_rank AS
-- (
-- SELECT DISTINCT rank
--   FROM product_rank
--  ORDER BY rank
-- )
SELECT T0.rank
      ,T1.product_id AS book
	  ,T1.sales AS book_sales
	  ,T2.product_id AS cd
	  ,T2.sales AS cd_sales
	  ,T3.product_id AS dvd
	  ,T3.sales AS dvd_sales
  FROM (
		SELECT DISTINCT rank
		  FROM product_rank
		 ORDER BY rank
		) AS T0 -- 인라인뷰로 빼기
  LEFT JOIN product_rank AS T1 
  ON T1.rank = T0.rank
  AND T1.category_name = 'book'
  LEFT JOIN product_rank AS T2
  ON T2.rank = T0.rank
  AND T2.category_name = 'cd'
  LEFT JOIN product_rank AS T3 
  ON T3.rank = T0.rank
  AND T3.category_name = 'dvd';
 
-- 8.9 디바이스ID와 이름의 마스터 테이블을 만드는 쿼리
WITH mst_devices AS
(
  SELECT 1 AS device_id, 'PC' AS device_name
  UNION ALL
  SELECT 2 AS device_id, 'SP' AS device_name
  UNION ALL
  SELECT 3 AS device_id, '애플리케이션' AS device_name
)
SELECT * FROM mst_devices;

-- 8.11 VALUES 구문을 사용해 동적으로 테이블 만드는 쿼리
WITH mst_devices(device_id, device_name) AS
(
  VALUES 
	 ('1', 'PC')
	,('2', 'SP')
	,('3', '애플리케이션')
)
SELECT * 
  FROM mst_devices;

-- (Hive) 8.12 배열형 테이블 함수(explode)를 사용한 유사 테이블 만들기
WITH mst_devices AS
(
	SELECT 
	  d[0] AS device_id
	, d[1] AS device_name
	FROM (
	     SELECT explode(
		     array(array('1','PC'), array('2','SP'),array('3','애플리케이션'))
		 )d ) AS t
)
SELECT * 
  FROM mst_devices;

-- 8.14 순번을 가진 유사 테이블 작성하는 쿼리 
-- generate_series(start, stop, step)
-- SELECT generate_series( '2019-01-01'::date , '2019-12-31'::date, '1 day'::interval)::date;
WITH series AS (
  SELECT generate_series(1,5) AS idx
)
SELECT * 
  FROM series;