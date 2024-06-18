-- New script in sakila.
-- Date: 2024. 6. 14.
-- Time: 오전 11:38:52

/* ---------------------- 서브 쿼리 ---------------------- */

/*
 * DB 내부 구조
 * 
 * 1. 데이터 캐시(버퍼 캐시) (정리 필요)
 *  1.1 위치
 *      DB 인스턴스 SGA 에 존재
 *    
 *  1.2 용도
 *      DB 서버 프로세스, SQL 클라이언트의 SELECT 요청에 대한 데이터가 메모리에 없는 경우 속도가 느린 디스크 파일에서 읽어온다.
 *      -> 처리 속도가 느려짐 (디스크 I/O 발생함으로 속도 저하)
 *    
 *      -> 성능상 문제 개선을 위해 한 번 조회된 데이터는 데이터 캐시에 저장해두고 재활용한다.
 *      내부 알고리즘에 의해 캐시가 갱신된다.
 *    
 *  1.3 검색 결과 반환 단계(간단하게 설명)
 *      1. SQL 클라이언트가 SELECT 문을 DB 서버로 문자열 전송
 *      2. DB 서버 프로세스, 메모리(데이터 캐시/버퍼 캐시)에 데이터가 있는지 확인
 *      3. 캐시된 데이터가 없는 경우, 디스크에서 직접 읽어와서 메모리에 캐싱
 *      4. 결과 반환 
 * 
 * 2. 딕셔너리 캐시, 라이브러리 캐시 (참고, SQL 성능이라는 부분이 이런 거구나..)
 *  2.1 위치
 *      DB 의 고유 메모리 내에 존재
 * 
 *  2.2 용도
 *      딕셔너리 캐시 : 주로 SQL 의 실행에 필요한 메타 데이터 보관
 *      라이브러리 캐시 : 실행 계획 등의 SQL 정보가 저장됨
 * 
 *      SQL 문에는 구체적인 처리방법이 적혀있지 않기 때문에 DB 가 처리방법(실행 계획)을 스스로 생성해야 할 필요가 없음
 *      따라서, 실행 계호기의 좋고 나쁨에 따라 성능이 크게 변할 수 있음
 *      ( Oracle 기준 : Rule based, Cost based )
 *      
 *      단순한 예로 1,000 만건의 데이터가 있는 table A 와 100 만컨의 데이터가 있는 table B 가 있고,
 *      table A 에 value 칼럼에 값은 99% 가 1 로 저장되어 있는 상태
 * 
 *      select * 
 *          from A
 *          join B
 *          on A.id = B.id
 *      where A.value = 1
 *      and B.value = 1;
 * 
 *      두 가지의 경우
 *      - table A -> table B(cost 가 높다)
 *        최악의 경우, 1,000 만 번의 디스크 I/O 발생 가능
 * 
 *      - table B -> table A(cost 가 낮다)
 *        B.value = 1 인 데이터에 대한 I/O 만 발생
 * 
 *  2.3 실행계획의 수립에 필요한 정보
 *      옵티마이저가 실행 계획을 세우기 위해 3가지 정보를 활용, 비용을 계산하여 최적의 실행 계획을 세우게 됨
 * 
 *      - SQL 문의 정보
 *        어떤 테이블의 어떤 데이터인지, 어떤 검색조건인지, 테이블 간의 관계 등
 *      - 초기화 파라미터
 *        세션에서 사용할 수 있는 메모리의 크기, 단일 I/O 로 읽어올 수 있는 블록 수 등
 *        ( cost 비용 산출 시 필요한 정보 )
 *      - 옵티마이저 통계( 시계열 정보 )
 *        테이블 통계, 칼럼 통계(데이터 값, 데이터 분포도 등), 인덱스 통계(인덱스 깊이 등), 시스템 통계(OS 입장. I/O, CPU, 메모리 등)
 */

DESC CUSTOMER ;

/*
 * 마지막으로 가입한 고객 정보
 *
 * customer_id : smallint unsigned auto_increment -> 가장 큰 값이 최근 가입고객
 */

SELECT /*+ INDEX_DESC(CUSTOMER, CUSTOMER_ID) */ CUSTOMER_ID , FIRST_NAME , LAST_NAME 
    FROM CUSTOMER C 
LIMIT 1;

/* in 연산자 subquery */
SELECT CITY_ID , CITY 
    FROM CITY C 
WHERE COUNTRY_ID IN (
                        SELECT COUNTRY_ID 
                            FROM COUNTRY C2 
                        WHERE country IN ('Canada', 'Mexico')
                    );
                    
/* DVD 대여시 실제 결제를 한 고객 정보 - in 연산자 */
SELECT FIRST_NAME , LAST_NAME 
    FROM CUSTOMER C 
WHERE CUSTOMER_ID NOT IN (
                            SELECT CUSTOMER_ID 
                                FROM PAYMENT P 
                            WHERE amount = 0
                        ); -- 576
                        
/* 무료 DVD 대여한 고객 정보 */
SELECT FIRST_NAME , LAST_NAME 
    FROM CUSTOMER C 
WHERE CUSTOMER_ID IN (
                        SELECT CUSTOMER_ID 
                            FROM PAYMENT P 
                        WHERE amount = 0
                    );  -- 23
                    
/* 
 * all 연산자 : 서크쿼리에서 반환되는 여러개의 결과에서 모두 만족해야 함
 * 
 * any 연산자 : 서브쿼리에서 반환되는 여러개의 결과중 한 가지만 만족해도 됨
 * */

/* 
 * All 연산자
 * 
 * DVD 대여시 실제 결제를 한 고객 정보 
 */
SELECT FIRST_NAME , LAST_NAME 
    FROM CUSTOMER C 
WHERE CUSTOMER_ID <> All (
                            SELECT CUSTOMER_ID 
                                FROM PAYMENT P 
                            WHERE amount = 0
                        ); -- 576

/*
 * any 연산자
 * 
 * 
 * 볼리비아, 파라과이 또는 칠레의 모든 고객에 대한 총 영화 대여료를 초과하는
 * 총 결제금액을 가진 모든 고객 정보를 조회
 * 
 * payment, customer, address, city, country
 */
SELECT CUSTOMER_ID , sum(p.amount)
    FROM PAYMENT P 
GROUP BY p.CUSTOMER_ID 
HAVING SUM(p.AMOUNT) > ANY (
                            SELECT sum(p.AMOUNT)
--                             SELECT c3.customer_id, c3.first_name, c3.last_name  -- 8명
                                FROM COUNTRY C 
                                JOIN CITY C2 
                                ON c.COUNTRY_ID = c2.COUNTRY_ID 
                                JOIN ADDRESS A 
                                ON c2.CITY_ID = a.CITY_ID 
                                JOIN CUSTOMER C3 
                                ON a.ADDRESS_ID = c3.ADDRESS_ID 
                                JOIN PAYMENT P  
                                ON c3.CUSTOMER_ID = p.CUSTOMER_ID
                            WHERE c.COUNTRY IN ('Bolivia', 'Paraguay', 'Chile')
                            GROUP BY c.COUNTRY
                        );

/* 
 * 다중 열 서브쿼리 : 반환되는 결과가 다중 열인 서브쿼리
 */
SELECT ACTOR_ID , FILM_ID 
    FROM FILM_ACTOR FA 
WHERE (ACTOR_ID , FILM_ID ) IN (
                                /* 카테시안 프러덕트 : cross join */
                                SELECT a.ACTOR_ID , f.FILM_ID 
                                    FROM ACTOR A 
                                    CROSS JOIN FILM F 
                                WHERE a.last_name = 'MONROE'
                                AND f.rating = 'PG'
                                )
                                
/* 
 * 상관관계 서브쿼리
 * 
 * 메인 쿼리에서 사용한 데이터를 서브쿼리에서 사용하고 
 * 서브쿼리의 결과값을 다시 메인 쿼리로 반환하는 방식
 * -> 비상관 서브쿼리에서는 서브쿼리가 독립적으로 실행되지만,
 *    상관 서브쿼리는 메인 쿼리에 종속적이다.
 * 
 * 아래 상관관계 sql 의 동작 순서
 * 
 * 1. Main sql 에서 customer_id 를 모두 구함. 599 명의 고객 ID 조회
 * 2. customier_id 를 sub_query 에 제공
 * 3. sub query 에서 제공받은 customer_id 로 실행
 * 4. sub query 의 결과를 Main query 로 반환
 * 5. Main query 20번 대여 횟수가 동일한지 확인
 * 
 */           
SELECT c.CUSTOMER_ID, c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE 20 = (
                SELECT count(*)
                    FROM RENTAL R
                WHERE r.CUSTOMER_ID = c.CUSTOMER_ID 
            );
               
select count(*) from rental r where r.customer_id = 191;     

SELECT c.CUSTOMER_ID, c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
    JOIN RENTAL R 
    ON r.CUSTOMER_ID = c.CUSTOMER_ID 
GROUP BY r.CUSTOMER_ID 
HAVING count(*) = 20;


                                
/*
 * 상관관계 Query 를 이용해서 SQL 작성
 * 
 * 대여 총 지불액이 180 달러에서 240 달러 사이인 모든 고객 리스트
 */
SELECT c.CUSTOMER_ID, c.FIRST_NAME, c.LAST_NAME 
    FROM CUSTOMER C 
WHERE ( 
        SELECT sum(p.AMOUNT)
            FROM PAYMENT P 
        WHERE p.CUSTOMER_ID = c.CUSTOMER_ID
    ) /* 상관관계 sub query 가 599 번 실행, 599 번 반환 */
    BETWEEN 180 AND 240;    

/* 
 * exists 연산자
 * 
 * exists 연산자 다음에 sub query 가 위치하고,
 * 그 sub query 의 결과가 row 수에 관계없이 존재 자체만 확인하고자 하는 경우에 사용
 */

/* 2005-05-25 일 이전에 한 편 이상의 영화를 대여한 모든 고객 */
SELECT c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE EXISTS (
                SELECT 1    /* WHERE 절이 TRUE 인 경우 SELECT 절이 읽어질 때 1 을 반환하기 위함. 1 은 TRUE 의 의미 -> WHERE 절의 전체가 TRUE 가 되는 효과 */
                    FROM RENTAL R 
                WHERE r.CUSTOMER_ID = c.CUSTOMER_ID 
                AND r.RENTAL_DATE < '2005-05-25'
            );

/*
 * EXISTS 문에서 "SELECT 1" 을 하는 이유가 뭘까?
 * 
 * 디스크 I/O 발생을 일으키지 않기 위한 조치
 * SELECT 문에 올라온 데이터를 가져오기 위해 버퍼를 뒤적이는데, 
 * 버퍼에 없으면 디스크에 무조건적으로 접근해야 하므로..
 * -> 성능 속도를 위한 조치!
 */
        
/*
 * 상관관계 서브쿼리 사용
 * R 등급 영화에 출연한 적이 한 번도 없는 모든 배우명 검색
 * 
 * - 영화 배우 한 명만을 생각해보는 것으로 논리적으로 접근
 *   A 영화배우 10편에 출연 -> 10편 영화가 R 등급 영화에 출연 여부
 * 
 *   Main Query           Sub Query
 * 
 *   영화배우 테이블에 영화배우가 100명이라면, 위의 처리 방법을 100 번 수행
 * 
 *   => 상관관계 쿼리
 *      Main query 에서 조회된 데이터를 Sub Query 에서 조건으로 사용하고,
 *      Sub Query 결과를 Main Query 로 반환
 */
-- 실패 1.                 
SELECT 
    DISTINCT a.FIRST_NAME , a.LAST_NAME 
    FROM FILM_ACTOR fa
    JOIN ACTOR A 
    ON fa.ACTOR_ID = a.ACTOR_ID 
WHERE NOT EXISTS (
                       SELECT 1 
                            FROM FILM F 
                        WHERE fa.FILM_ID = f.film_id
                        AND f.rating = 'R'
                );

-- 내가 한 쿼리 : 비 상관관계 쿼리
SELECT 
    DISTINCT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A 
WHERE a.ACTOR_ID <> ALL (
                           SELECT DISTINCT fa.ACTOR_ID
                                FROM FILM F 
                                JOIN FILM_ACTOR FA 
                                ON f.FILM_ID = fa.FILM_ID 
                            WHERE f.rating = 'R'
                        );

-- 강사님이 한 쿼리
SELECT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A    /* 배우 데이터를 Sub Query 의 검색조건으로 사용 */ 
WHERE NOT EXISTS (  /* Sub Query 로 R 등급으로 조회 */
                    SELECT 1
                        FROM FILM_ACTOR fa
                        JOIN FILM F 
                        ON f.FILM_ID = fa.FILM_ID 
                    WHERE fa.actor_id = a.ACTOR_ID  /* Main query 의 데이터 */
                    AND f.rating = 'R'
                );

/*
 * SUB QUERY 사용.
 * 고객별 고객정보(first_name, last_name), 대여횟수, 대여결체총액 을 조회.
 * 
 * 고객별 고객정보(first_name, last_name) : 고객 정보 -> 고객 정보 전용 SQL
 * 대여횟수, 대여결체총액 : 대여 정보                   -> 대여 정보 전용 SQL
 * 
 * 향후에 함수 또는 프로시저(function, procedure 등) 가 될 후보군이 보임...
 * 
 * inner join 문에 사용되는 SUB Query
 * 대여횟수, 대여결제총액은 집계 함수
 */
-- 내가 한 쿼리
SELECT c.FIRST_NAME , c.LAST_NAME
    , a.cnt , a.amt
    FROM (
            SELECT COUNT(*) AS cnt, sum(amount) AS amt, CUSTOMER_ID
                FROM PAYMENT P 
            GROUP BY p.CUSTOMER_ID 
        ) a         /* 대여 정보 전용 SQL */
    JOIN CUSTOMER C /* 고객정보 전용 */
    ON a.CUSTOMER_ID = c.CUSTOMER_ID ;

  
/* 난이도가 있음.
 * 대여 결제 총액 기준으로 크게 3개 그룹의 고객을 분류
 * 낮은 결제 고객 : 0 ~ 74.99
 * 중간 결제 고객 : 75 ~ 149.99
 * 높은 결제 고객 : 150 ~ 9,999,999.99
 * 
 * 낮은 결제 고객 : 0(log_lmt) ~ 74.99(high_lmt)
 * 중간 결제 고객 : 75(log_lmt) ~ 149.99(high_lmt)
 * 높은 결제 고객 : 150(log_lmt) ~ 9,999,999.99(high_lmt)
 * 
 * 상기의 기준으로 해달 그룹에 속하는 고객수를 조회.
 * 
 * -> 분류 테이블처럼 생각(실제 테이블 X)
 *  -> 마치 테이블처럼 되도록만 하면, 관계를 맺어주게 되면 해결
 *   -> 마스트 코드 및 분류 테이블이 될 후보군이 보임..  
 */
-- 내가 한 코드
SELECT a.cnt, count(*)
FROM (
        SELECT 
            CASE 
                WHEN sum(amount) BETWEEN 0 AND 74.99 THEN "small"
                WHEN sum(amount) BETWEEN 75 AND 149.99 THEN "average"
                ELSE "heavy"
            END AS cnt
            FROM PAYMENT P 
        GROUP BY CUSTOMER_ID 
    ) a
GROUP BY a.cnt;

-- 강사님이 작성한 코드
/* 1. 논리적인 테이블이 되도록 함 */
select 1, 'ABC'    
union all    
select 2, 'DEF'
union all
select 3, 'GHI';

SELECT 'small', 0 low_limit, 74.99 high_limit
UNION ALL
SELECT 'average', 75 low_limit, 149.99 high_limit
UNION ALL
SELECT 'heavy', 150 low_limit, 9999999.99 high_limit;

/* 2. 논리적인 테이블과의 관계 설정 
 *    논리적인 테이블이 inner join 에 들어가고 관계를 맺어주면 됨.
 */
SELECT payGroupInfo.name, count(*) num_cs
    FROM (
            SELECT p.customer_id, COUNT(*) pay_cnt, SUM(amount) AS total_tot 
                FROM PAYMENT P 
            GROUP BY p.CUSTOMER_ID 
        ) payInfo       /* 고객 정보 + 결제 정보 */
    JOIN (
            SELECT 'small' name, 0 low_limit, 74.99 high_limit
            UNION ALL
            SELECT 'average' name, 75 low_limit, 149.99 high_limit
            UNION ALL
            SELECT 'heavy' name, 150 low_limit, 9999999.99 high_limit
        ) payGroupInfo  /* 결제 분류 논리 테이블 */
    ON payInfo.total_tot BETWEEN low_limit AND high_limit
GROUP BY payGroupInfo.name;

/*
 * SQL 을 작성하되, 가독성이 높은 SQL 로 작성할 것
 * 
 * 고객정보(first/last_name, 도시명), 총 대여 지불 금액, 총 대여 횟수를 조회하는 SQL 작성
 */
-- 내가 한 코드
SELECT c.FIRST_NAME , c.LAST_NAME , c2.CITY , a.amt AS "총 대여 지불 금액", a.cnt AS "총 대여 횟수"
    FROM (
            SELECT p.CUSTOMER_ID, sum(p.amount) amt, count(*) cnt
                FROM PAYMENT P 
            GROUP BY p.CUSTOMER_ID 
        ) a
    JOIN CUSTOMER C 
    ON a.customer_id = c.CUSTOMER_ID 
    JOIN ADDRESS AD
    ON c.ADDRESS_ID = ad.ADDRESS_ID 
    JOIN CITY C2 
    ON ad.CITY_ID = c2.CITY_ID ;

-- 잘못된 코드 : 잘못된 on 조건 컬럼 사용(조인을 맺은 customer_id 는 다:다 관계 -> 카타시안 곱이 됨) 
SELECT p.CUSTOMER_ID, sum(p.amount) amt, count(*) cnt
    FROM PAYMENT P 
    JOIN RENTAL R 
    ON p.CUSTOMER_ID = r.CUSTOMER_ID 
GROUP BY p.CUSTOMER_ID 

-- SELECT p.PAYMENT_ID , p.RENTAL_ID , p.AMOUNT , sum(amount) OVER()
SELECT count(*) -- 1024
    FROM PAYMENT P 
    JOIN RENTAL R 
    ON p.customer_id = r.customer_id
WHERE r.CUSTOMER_ID = 1;

-- SELECT count(*)  -- 32
SELECT *
FROM PAYMENT P 
WHERE CUSTOMER_ID = 1;  

-- SELECT count(*) -- 32
SELECT *
FROM RENTAL R 
WHERE CUSTOMER_ID = 1;  

/* 
 * 공통 테이블 표현식 : CTE, with 절
 * 
 * CTE : Common Table Expression'
 * 
 * 서브 쿼리의 규모가 큰 경우, 실제 수행해야 할 Main Query 와 Sub Query 를 구분할 때 유용
 */

/* 
 * 성이 'S'로 시작하는 배우가 출연하는 'PG' 등급 영화 대여로 발생한
 * 총 수익(대여료) 조회
 * 
 * 영화 배우명(first_name, last_name), 총 수익 으로 조회
 */
-- 내가 한 쿼리
WITH cte_a (actor_id, first_name, last_name, rating, film_id, rental_id) AS 
    (
--         SELECT DISTINCT f.film_id     -- 48
        SELECT a.ACTOR_ID , a.FIRST_NAME , a.LAST_NAME 
            , f.RATING , f.FILM_ID 
            , r.RENTAL_ID 
            FROM ACTOR A 
            JOIN FILM_ACTOR FA 
            ON fa.ACTOR_ID = a.ACTOR_ID 
            JOIN FILM F 
            ON f.FILM_ID = fa.FILM_ID 
            JOIN INVENTORY I 
            ON f.FILM_ID = i.FILM_ID
            JOIN RENTAL R 
            ON i.inventory_id = r.inventory_id
        WHERE f.RATING = 'PG'
        AND a.LAST_NAME LIKE 'S%'
    )
SELECT cte_a.first_name, cte_a.last_name, 
    sum(p.amount) AS actor_sum
    FROM PAYMENT P 
    JOIN cte_a
    ON p.rental_id = cte_a.rental_id
GROUP BY cte_a.actor_id;

-- CTE 설명
/* 1. 성이 'S'로 시작하는 배우 */
WITH actors_s AS 
(
    SELECT actor_id, first_name, last_name
        FROM ACTOR A 
    WHERE last_name LIKE 'S%'
),

/* 2. 배우 및 필름정보 - 1번 SQL 사용 */
actors_s_pg AS 
(
    SELECT s.actor_id , s.first_name , s.last_name
        , f.film_id , f.title
        FROM actors_s s
        JOIN FILM_ACTOR FA 
        ON s.actor_id = fa.actor_id
        JOIN FILM F 
        ON f.FILM_ID = fa.FILM_ID 
        WHERE f.RATING = 'PG'
),

/* 3. 영화 배우명(first_name, last_name), 총 수익 조회 : 2번의 SQL 사용 */
actors_s_pg_income AS 
(
    SELECT spg.first_name , spg.last_name , p.amount
        FROM actors_s_pg spg
        JOIN INVENTORY I 
        ON spg.FILM_ID = i.FILM_ID
        JOIN RENTAL R 
        ON i.inventory_id = r.inventory_id
        JOIN PAYMENT P 
        ON r.rental_id = p.rental_id
)
SELECT spg_income.first_name , spg_income.last_name ,
    , sum(spg_income.amount) AS tot_income
FROM actors_s_pg_income spg_income
GROUP BY spg_income.first_name , spg_income.last_name
ORDER BY 3 DESC;
        

/* 4. 1,2,3 연결 */
WITH actors_s AS 
(
    SELECT actor_id, first_name, last_name
        FROM ACTOR A 
    WHERE last_name LIKE 'S%'
),
actors_s_pg AS 
(
    SELECT s.actor_id , s.first_name , s.last_name
        , f.film_id , f.title
        FROM actors_s s
        JOIN FILM_ACTOR FA 
        ON s.actor_id = fa.actor_id
        JOIN FILM F 
        ON f.FILM_ID = fa.FILM_ID 
        WHERE f.RATING = 'PG'
),
actors_s_pg_income AS 
(
    SELECT spg.first_name , spg.last_name , p.amount
        FROM actors_s_pg spg
        JOIN INVENTORY I 
        ON spg.FILM_ID = i.FILM_ID
        JOIN RENTAL R 
        ON i.inventory_id = r.inventory_id
        JOIN PAYMENT P 
        ON r.rental_id = p.rental_id
)
SELECT spg_income.first_name , spg_income.last_name 
    , sum(spg_income.amount) AS tot_income
FROM actors_s_pg_income spg_income
GROUP BY spg_income.first_name , spg_income.last_name
ORDER BY 3 DESC;

/* 
 * 영화 배우 조회. 영화 배우 ID, 영화 배우명(first_name, last_name) 
 * 
 * 단, 정렬 조건은 영화 배우가 출연한 영화수로 내림차순 정렬이 되도록 하고,
 * 정렬 조건을 Sub Query로 작성할 것.
 * */
-- 내가 한 코드 : 비용이 세다..
SELECT a.FIRST_NAME , a.LAST_NAME 
    , actor_cnt.cnt
    FROM ACTOR A 
    JOIN (
            SELECT fa.ACTOR_ID , count(*) AS cnt
                FROM FILM_ACTOR FA 
                JOIN FILM F ON fa.FILM_ID = f.FILM_ID 
            GROUP BY fa.ACTOR_ID 
        ) actor_cnt
    ON a.ACTOR_ID = actor_cnt.actor_id
ORDER BY 3 DESC;

-- 강사님이 한 코드 : 연관 관계 subQuery
SELECT a.actor_id, a.first_name, a.last_name
    FROM ACTOR A 
ORDER BY (
            SELECT COUNT(*)
                FROM FILM_ACTOR FA 
            WHERE fa.ACTOR_ID = a.ACTOR_ID
        ) DESC;
    
/*
 * 스칼라 서브쿼리
 * 
 * SELECT 절에 사용되는 서브 쿼리
 * - 칼럼의 형태 -> 하나의 열로 사용할 수 있도록 해야 함
 * - 반드시 하나의 결과만 반환되도록 해야 함 -> 연관 관계임을 나타냄
 */

SELECT 
    c.FIRST_NAME , c.LAST_NAME , c2.CITY , a.amt AS "총 대여 지불 금액", a.cnt AS "총 대여 횟수"
    FROM (
            SELECT p.CUSTOMER_ID, sum(p.amount) amt, count(*) cnt
                FROM PAYMENT P 
            GROUP BY p.CUSTOMER_ID 
        ) a
    JOIN CUSTOMER C 
    ON a.customer_id = c.CUSTOMER_ID 
    JOIN ADDRESS AD
    ON c.ADDRESS_ID = ad.ADDRESS_ID 
    JOIN CITY C2 
    ON ad.CITY_ID = c2.CITY_ID ; 

/*
 * 위 쿼리를 스칼라 형식으로 변경해보기
 * 
 * 1. Main Query 의 from 절에 사용할 테이블 결정
 *    PAYMENT : 한 번이라도 결제한 고객이 대상
 * 2. first_name : 서브 쿼리 + 조건(연관 관계 - PAYMENT)
 * 3. last_name : 서브 쿼리 + 조건(연관 관계 - PAYMENT)
 * 4. city 
 *    서브 쿼리(CUSTOMER, ADDRESS, CITY) + 조건(연관 관계 - PAYMENT)
 * 5. 총 대여 지불 금액, 총 대여 횟수
 *    Main Query 의 from 절 테이블 이용, 집계 함수로 통계 처리
 * 6. Main Query 에 group by 적용
 */    
SELECT (   
        SELECT c.first_name
            FROM CUSTOMER C 
        WHERE c.customer_id = p.CUSTOMER_ID 
        ) AS first_name 
    , (
        SELECT c.last_name
            FROM CUSTOMER C 
        WHERE c.customer_id = p.CUSTOMER_ID
        ) AS last_name
    , (
        SELECT cc.city
            FROM CUSTOMER C 
            JOIN ADDRESS A 
            ON c.address_id = a.address_id
            JOIN CITY CC
            ON a.city_id = cc.city_id
        WHERE c.customer_id = p.CUSTOMER_ID
        ) AS city
    , sum(p.amount) AS "총 대여 지불 금액"
    , count(*) AS "총 대여 횟수"
    FROM PAYMENT P 
GROUP BY p.CUSTOMER_ID;

/* 
 * 대여 가능한 DVD 영화 리스트를 조회.
 * film id, 제목, 재고수가 조회도록 SQL 작성. 
 * 
 * 단, 모든 영화가 빠짐없이 조회가 되도록 해야 함
 * -> film 에는 데이터가 있지만, inventory 에는 데이터가 없는 경우 -> outer join 
 * 
 * */
SELECT count(*) FROM FILM F ;   -- 1000

/*
 * COUNT() 의 값이 NULL -> 0 으로 처리함
 * INVENTORY 테이블의 film_id = 14 인 데이터는 존재하지 않음
 */
SELECT f.FILM_ID , f.TITLE , count(i.INVENTORY_ID)
    FROM FILM F 
    LEFT OUTER JOIN INVENTORY I 
    ON f.FILM_ID = i.film_id
GROUP BY f.FILM_ID, f.TITLE ;

SELECT * FROM INVENTORY I WHERE FILM_ID = 14;   -- X
        
/* 
 * 대여 가능한 DVD 영화 리스트를 조회.
 * film id, 제목, 재고번호, 대여일이 조회도록 SQL 작성. 
 * 
 * 단, 모든 영화가 빠짐없이 조회가 되도록 해야 하며
 * film_id 는 13,14,15 로 한정
 * 
 * 필요한 테이블 : film, inventory, rental
 * film 정보가 inventory 뿐만 아니라, rental 에도 없는 경우가 있음
 * 이런 경우의 join 은...?
 * */
SELECT f.FILM_ID , f.TITLE , i.INVENTORY_ID, r.RENTAL_DATE 
-- SELECT count(*) -- 31
    FROM FILM F 
    LEFT OUTER JOIN INVENTORY I /* film 테이블 기준 : left */
    ON f.FILM_ID = i.film_id
    LEFT OUTER JOIN RENTAL R    /* inventory 테이블 기준 : left */
    ON i.inventory_id = r.INVENTORY_ID 
WHERE f.FILM_ID BETWEEN 13 AND 15;

/* 
 * cross join(교차 조인) : 카타시안 프러덕트, 임시 테스트용 데이터 생성 
 * 
 * 0 ~ 399 : DATE_ADD() , interval 용 데이터(DAY, MONTH, YEAR)
 * */
CREATE VIEW calendat_v AS 
(
    SELECT ones.num + tens.num + hundreds.num AS nm
     FROM
     (SELECT 0 num UNION ALL
     SELECT 1 num UNION ALL
     SELECT 2 num UNION ALL
     SELECT 3 num UNION ALL
     SELECT 4 num UNION ALL
     SELECT 5 num UNION ALL
     SELECT 6 num UNION ALL
     SELECT 7 num UNION ALL
     SELECT 8 num UNION ALL
     SELECT 9 num) ones
     CROSS JOIN
     (SELECT 0 num UNION ALL
     SELECT 10 num UNION ALL
     SELECT 20 num UNION ALL
     SELECT 30 num UNION ALL
     SELECT 40 num UNION ALL
     SELECT 50 num UNION ALL
     SELECT 60 num UNION ALL
     SELECT 70 num UNION ALL
     SELECT 80 num UNION ALL
     SELECT 90 num) tens
     CROSS JOIN
     (SELECT 0 num UNION ALL
     SELECT 100 num UNION ALL
     SELECT 200 num UNION ALL
     SELECT 300 num) hundreds
     ORDER BY 1
 );
 
 /* 
  * DATE_ADD(), INTERVAL()
  * 
  * 생성되는 날짜 범위 : 2005-01-01 ~ 2005-12-31
  */
-- 임시 테이블 생성
DROP TEMPORARY TABLE IF EXISTS cal_temp;
CREATE TEMPORARY TABLE cal_temp (
    new_date date
);

CALL ADDCALENDAR();
SELECT * FROM cal_temp;


-- 방법 2.
SELECT DATE_ADD('2005-01-01', INTERVAL(ones.num + tens.num + hundreds.num) DAY) dt
FROM 
     (SELECT 0 num UNION ALL
     SELECT 1 num UNION ALL
     SELECT 2 num UNION ALL
     SELECT 3 num UNION ALL
     SELECT 4 num UNION ALL
     SELECT 5 num UNION ALL
     SELECT 6 num UNION ALL
     SELECT 7 num UNION ALL
     SELECT 8 num UNION ALL
     SELECT 9 num) ones
     CROSS JOIN
     (SELECT 0 num UNION ALL
     SELECT 10 num UNION ALL
     SELECT 20 num UNION ALL
     SELECT 30 num UNION ALL
     SELECT 40 num UNION ALL
     SELECT 50 num UNION ALL
     SELECT 60 num UNION ALL
     SELECT 70 num UNION ALL
     SELECT 80 num UNION ALL
     SELECT 90 num) tens
     CROSS JOIN
     (SELECT 0 num UNION ALL
     SELECT 100 num UNION ALL
     SELECT 200 num UNION ALL
     SELECT 300 num) hundreds
WHERE DATE_ADD('2005-01-01', INTERVAL(ones.num + tens.num + hundreds.num) DAY) < '2006-01-01'
ORDER BY 1;

/*
 * 상기의 달력을 만든 후, RENTAL 테이블의 rental_date(대여일)별로 대여 수 조회
 * 단, 검색 기간은 2005 년도에 한해서만 조회
 * 
 * Main query : rental 테이블  (left)
 * Sub queryy : 달력 테이블      (right)
 * 
 * 두 테이블의 관계 : 달력의 데이터가 RENTAL 테이블엔 없을 수 있음 
 *                -> right outer join (가독성을 위한 right 조인)
 */
SELECT date(r.RENTAL_DATE) AS rent_date
    , count(*) AS tot_day_rental
    FROM RENTAL R 
    RIGHT OUTER JOIN cal_temp cal
    ON date(r.RENTAL_DATE) = cal.new_date
WHERE r.RENTAL_DATE IS NOT NULL
GROUP BY date(r.RENTAL_DATE);
 
SELECT calendar.new_date
    , count(r.rental_id) tot_day_rental
    FROM RENTAL R 
    RIGHT OUTER JOIN cal_temp calendar
    ON calendar.new_date = date(r.RENTAL_DATE)
GROUP BY calendar.new_date
ORDER BY 1;







                                