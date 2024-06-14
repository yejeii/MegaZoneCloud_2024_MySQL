-- New script in sakila.
-- Date: 2024. 6. 12.
-- Time: 오후 3:40:19

/* ---------------------- 쿼리 입문 ---------------------- */

SELECT FIRST_NAME , last_name
FROM CUSTOMER C 
WHERE LAST_NAME LIKE '%Z%';

SELECT * FROM CATEGORY C ;

SELECT * FROM `language` l;

SELECT UPPER(name), name 
FROM `language` l ;

SELECT USER(), DATABASE();

SELECT actor_id
FROM FILM_ACTOR FA 
    USE INDEX (PRIMARY);

/*
 * 테이블 유형(from 절에 올 수 있는 대상)
 * 
 * 영구 테이블 : CREATE TABLE 문으로 생성된 것
 * 파생 테이블 : 서브 쿼리에서 반환된 결과가 메모리에 보관된 것
 *      서브 쿼리 : SELECT sql 문 안에 
 * 임시 테이블 : 
 * 가상 테이블
 *  
 */

-- 고객의 이름을 합쳐서 출력 
SELECT CONCAT(LAST_NAME, ',', FIRST_NAME) 
FROM CUSTOMER C ;

-- 고객의 이름을 합쳐서 출력 - from 절에 select 문
SELECT CONCAT(a.LAST_NAME, ',', a.FIRST_NAME) 
    , a.email
    FROM (
            SELECT c.FIRST_NAME , c.LAST_NAME , c.EMAIL 
            FROM CUSTOMER C 
            WHERE c.FIRST_NAME = 'JESSIE'
        ) a;

-- 중복 제거
SELECT DISTINCT(ACTOR_ID), FILM_ID 
FROM FILM_ACTOR FA ;

-- 테이블 생성시, select 활용 - 테이블 생성과 동시에 데이터 입력
-- 임시 테이블
CREATE TEMPORARY TABLE actor_j (
    actor_id SMALLINT(5),
    first_name varchar(45),
    last_name varchar(45)
);

SELECT * FROM actor_j;

INSERT INTO actor_j
SELECT ACTOR_ID , FIRST_NAME , LAST_NAME 
    FROM ACTOR 
WHERE LAST_NAME LIKE 'J%';

/* 가상 테이블 - View 생성 */
CREATE VIEW cust_v AS 
SELECT customer_id, first_name, last_name, active
    FROM CUSTOMER C;

SELECT * FROM CUST_V CV ;

/* 
 * Join 
 * 대상 테이블 : Customer, Rental
 * */
SELECT * FROM CUSTOMER C ;
SELECT * FROM RENTAL R ;

/* 
 * 등가 조인(equi join) : 교집합
 * 고객별 DVD 대여 현황 정보 조회
 */
SELECT c.FIRST_NAME , c.LAST_NAME 
    , r.RENTAL_DATE , r.RETURN_DATE 
    , count(*) OVER() cnt
    FROM CUSTOMER C 
        INNER JOIN RENTAL R 
        ON c.CUSTOMER_ID = r.CUSTOMER_ID
    WHERE c.FIRST_NAME = 'MARY'
    AND date(r.RENTAL_DATE ) = '2005-05-25';
    
/* 
 * where 절 - 조건절
 * film table : 출시되어 대여할 수 있는 DVD
 * 
 * rating : 등급
 * rental_duration : 최소 대여 기간
 *  인기가 높으면 대여 기간이 짧음
 */
SELECT * FROM FILM F 
WHERE RATING = 'G'
AND RENTAL_DURATION >= 7;

SELECT title
FROM FILM F
WHERE ( RATING = 'G' AND RENTAL_DURATION >= 7 ) 
OR ( RATING = 'PG-13' AND RENTAL_DURATION  < 4 );
    
/* 
 * 고객별 대여 횟수()를 계산한 다음, 대여 횟수가 40회 이상인 고객 리스트 작성
 * 횟수 : count(*)
 */
-- SELECT /*+ INDEX (CUSTOMER_ID idx_fk_customer_id) */ CUSTOMER_ID , count(*)
SELECT CUSTOMER_ID , count(*) AS cnt
FROM RENTAL R 
GROUP BY CUSTOMER_ID 
HAVING count(*) >= 40

SELECT c.FIRST_NAME , c.LAST_NAME , count(*)
    FROM CUSTOMER C     
    JOIN RENTAL R 
    ON c.CUSTOMER_ID  = r.CUSTOMER_ID 
GROUP BY c.FIRST_NAME , c.LAST_NAME    /* 고객별 */
HAVING COUNT(*) >= 40;

SELECT c.CUSTOMER_ID , c.FIRST_NAME , c.LAST_NAME , a.cnt
    FROM CUSTOMER C 
    JOIN (
            SELECT CUSTOMER_ID , count(*) AS cnt
            FROM RENTAL R 
            GROUP BY CUSTOMER_ID 
            HAVING count(*) >= 40
        ) a
    ON c.CUSTOMER_ID = a.customer_id
ORDER BY LAST_NAME , FIRST_NAME ;

/* 
 * 고객명, 대여일로 조회가 되도록 하고,
 * 정렬 추가 : 최근에 대여한 고객순으로 조회가 되도록 SQL 작성
 */
SELECT /*+ INDEX_DESC (RENTAL rental_date)  */ 
    c.FIRST_NAME
    , c.LAST_NAME 
    , r.RENTAL_DATE 
    FROM RENTAL R 
    JOIN CUSTOMER C 
    ON r.CUSTOMER_ID = c.CUSTOMER_ID 
-- ORDER BY RENTAL_DATE DESC;

    