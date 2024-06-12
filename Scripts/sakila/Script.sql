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


/* View 생성 */
CREATE VIEW cust_v AS 
SELECT customer_id, first_name, last_name, active
    FROM CUSTOMER C;

SELECT * FROM CUST_V CV ;

/* Join 
 * 대상 테이블 : Customer, Rental
 * */
SELECT * FROM CUSTOMER C ;
SELECT * FROM RENTAL R ;

SELECT c.FIRST_NAME , c.LAST_NAME 
    , r.RENTAL_DATE , r.RETURN_DATE 
    , count(*) OVER() cnt
    FROM CUSTOMER C 
        INNER JOIN RENTAL R 
        ON c.CUSTOMER_ID = r.CUSTOMER_ID
    WHERE c.FIRST_NAME = 'MARY'
    AND date(r.RENTAL_DATE ) = '2005-05-25';

    
    
    
    
    
    
    
    