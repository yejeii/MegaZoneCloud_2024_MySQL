-- New script in sakila.
-- Date: 2024. 6. 14.
-- Time: 오전 11:38:52

/* ---------------------- 서브 쿼리 ---------------------- */

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
 * 상관 서브쿼리
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
EXPLAIN
SELECT c.CUSTOMER_ID, c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE 20 = (
                SELECT count(*)
                    FROM RENTAL R
                WHERE r.CUSTOMER_ID = c.CUSTOMER_ID 
            );
               
select count(*) from rental r where r.customer_id = 191;                                
                                
/*
 * 상관관계 Query 를 이용해서 SQL 작성
 * 
 * 대여 총 지불액이 180 달러에서 240 달러 사이인 모든 고객 리스트
 */
-- EXPLAIN
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
                AND date(r.RENTAL_DATE) < '2005-05-25'
            );
                






    

                                
                                