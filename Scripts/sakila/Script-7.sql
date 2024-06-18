-- New script in sakila.
-- Date: 2024. 6. 18.
-- Time: 오전 11:43:47

/* ---------------------- 조건식 ---------------------- */

/*
 * CASE 표현식
 * 
 * 문법
 *  CASE
 *      WHEN 조건 THEN 반환할 표현식
 *      ...
 *      ELSE 
 *  END
 * 
 * CASE 표현식 장점
 *  - SQL 표준(SQL 92). 대부분의 DB 제품에 구현되어 있음
 *  - DML 문에서 사용 가능
 * 
 */

/*
 * 고객 정보 조회 : 활성화 고객, 비활성화 고객 구분해서 출력
 * 
 * CUSTOMER.active : 1 (활성화 고객  - active)
 * CUSTOMER.active : 0 (비활성화 고객 - inactive)
 * 
 */
DESC CUSTOMER ;

SELECT 
    FIRST_NAME 
    , LAST_NAME 
    , CASE ACTIVE   /* 조건식 시작 */
        WHEN 1 THEN 'ACTIVE'
        ELSE 'INACTIVE'
      END AS active_type
    FROM CUSTOMER C ;
    
/*
 * 활성화 고객에 대해서 대여 횟수가 출력되도록 하고,
 * 비활성화 고객에 대해선 대여 횟수가 0 이 출력되도록 sql 작성
 * 
 * FIRST_NAME, LAST_NAME, 대여 횟수로 출력되도록 함
 * 단, CASE 문 사용
 * 
 * 사용 테이블 : customern, rental
 * 대여 횟수 계산 : active = 0, 0 으로 출력
 *              active = 1, rental table 상관관계 조건 -> 대여 횟수
 * 
 * Main query : customer table 지정
 * Sub query : 스칼라 sub query 내에 대여 횟수 계산 처리
 */
-- 내가 한 쿼리
SELECT c.first_name
    , c.last_name
    , CASE ACTIVE 
        WHEN 1 THEN (
                        SELECT count(*)
                            FROM RENTAL R 
                        WHERE r.customer_id = c.customer_id
                    )
        ELSE 0
      END AS rent_cnt
    FROM CUSTOMER C ;

/*
 * 2005 년 5월, 6월, 7월 의 월별 영화 대여 횟수를 출력하는 SQL 작성.
 * 
 * 조회결과는 대여월, 대여횟수 로 출력이 되도록 하고,
 * 단, case 표현식을 사용한 경우와 사용하지 않은 경우 모두 SQL 로 작성.
 * 
 * 그리고, case 표현식을 사용하지 않은 경우 결과는 3행으로 출력되도록 하고,
 * case 표현식을 사용한 경우는 1행으로 5월, 6월, 7월 의 월별 영화 대여 횟수가 출력이 되도록 함.
 * 
 */
-- 1. CASE 문 사용 X : 결과가 3 rows 임
-- SELECT EXTRACT(YEAR_MONTH FROM rental_date) AS "대여 월"
SELECT MONTHNAME(rental_date) AS "대여 월"
    , count(rental_id) AS "대여 횟수"
    FROM RENTAL R 
WHERE rental_date BETWEEN '2005-01-01' AND '2005-08-01'
-- GROUP BY EXTRACT(YEAR_MONTH FROM rental_date);
GROUP BY MONTHNAME(rental_date);

-- 2. 강사님이 한 코드 : 결과가 1 row 임
/* 1 단계 : 5, 6, 7월에 대한 각 한건에 대한 대여 정보 */
SELECT MONTHNAME(RENTAL_DATE), 1
    FROM RENTAL R
WHERE rental_date BETWEEN '2005-01-01' AND '2005-08-01';

/* 2 단계 : 5월에 대한 대여 정보만 sum 이 되도록 */
SELECT 
    sum(
        CASE 
            WHEN MONTHNAME(rental_date) = 'May' THEN 1 ELSE 0
        END
    ) may_rental
    FROM RENTAL R
WHERE rental_date BETWEEN '2005-01-01' AND '2005-08-01';

/* 3 단계 : 2 단계 검증 */
SELECT count(*) -- 1156
    FROM RENTAL R
WHERE rental_date BETWEEN '2005-01-01' AND '2005-06-01';    

/* 4 단계 : 6, 7월 추가 */
SELECT 
    sum(
        CASE 
            WHEN MONTHNAME(rental_date) = 'May' THEN 1 ELSE 0
        END
    ) may_rental
    , sum(
        CASE 
            WHEN MONTHNAME(rental_date) = 'June' THEN 1 ELSE 0
        END
    ) june_rental
    , sum(
        CASE 
            WHEN MONTHNAME(rental_date) = 'July' THEN 1 ELSE 0
        END
    ) july_rental
    FROM RENTAL R
WHERE rental_date BETWEEN '2005-01-01' AND '2005-08-01';


/*
 * 영화의 재고 수량에 따라 품절, 부족, 여유, 충분 으로 분류되어 출력이 되도록 SQL 을 작성.
 * 출력은 영화 제목, 재고 수량에 따른 분류명으로 출력이 되도록 함.
 * case 표현식을 사용해서 SQL 작성.
 * 
 * 분류 기준은
 *   - 품절 : 재고수량 0
 *   - 부족 : 재고수량 1 or 2
 *   - 여유 : 재고수량 3 or 4
 *   - 충분 : 재고수량 5 이상
 * 
 * 사용 테이블 : film, inventory
 * 
 * 분류 기준 정보는 테이블의 칼럼처럼 출력되어야 함 -> 스칼라 서브쿼리.
 * -> 스칼라 서브쿼리에 CASE-WHEN 문 사용하면 되지 않을까?
 * 
 * Main Query : film
 * 스칼라 Sub query : inventory
 * 
 */
-- 내가 한 쿼리
-- 시도 1. "품절" 이 보이지 않음
-- 원인 : INVENTORY 테이블에 있는 FILM 정보만 대상으로 조회를 했기 때문에 품절된 영화 정보는 아예 나타나지 않는 것.
--       추출하고자 하는 목적을 파악한 후, 논리 관계를 따져보자.
SELECT 
    ( SELECT f.title
        FROM FILM F 
        WHERE f.film_id = i.FILM_ID 
    ) AS title
    , CASE 
        WHEN count(film_id) >= 5 THEN "충분"
        WHEN count(film_id) BETWEEN 3 AND 4 THEN "여유"
        WHEN count(film_id) BETWEEN 1 AND 2 THEN "부족"
        ELSE "품절"
      END AS "재고 수량"
    FROM INVENTORY I
GROUP BY FILM_ID ;

-- 검증
SELECT f.TITLE 
    FROM FILM F 
WHERE ( SELECT count(*)
            FROM INVENTORY I 
        WHERE f.FILM_ID = i.film_id
        ) = 0;

SELECT f.FILM_ID , f.TITLE, i.INVENTORY_ID
    FROM FILM F 
    JOIN INVENTORY I 
    ON f.FILM_ID = i.FILM_ID 
WHERE f.TITLE = 'ANTITRUST TOMATOES';

-- 시도 2. Good
SELECT f.TITLE 
    , CASE 
          WHEN (
                    SELECT count(*)
                        FROM INVENTORY I 
                    WHERE f.FILM_ID = i.film_id
                ) >= 5 THEN "충분"
          WHEN (
                    SELECT count(*)
                        FROM INVENTORY I 
                    WHERE f.FILM_ID = i.film_id
                ) BETWEEN 3 AND 4 THEN "여유"
          WHEN (
                    SELECT count(*)
                        FROM INVENTORY I 
                    WHERE f.FILM_ID = i.film_id
                ) BETWEEN 1 AND 2 THEN "부족"
          ELSE "품절"
      END AS "재고 수량"
    FROM FILM F; 

-- 강사님이 한 쿼리 : 나와 같지만 CASE 문 가시성이 좋아서 합격
SELECT f.TITLE 
    , CASE (
                SELECT count(*)
                    FROM INVENTORY I 
                WHERE f.FILM_ID = i.film_id
            )
          WHEN 0 THEN "품절"
          WHEN 1 THEN "부족"
          WHEN 2 THEN "부족"
          WHEN 3 THEN "여유"
          WHEN 4 THEN "여유"
          ELSE "충분"
      END AS "재고 수량"
    FROM FILM F
-- WHERE f.FILM_ID IN (6, 15);    -- 검증용 sql

/* 
 * 검증용 sql (film_id)
 *  - 재고가 1인 경우 : X
 *  - 재고가 2인 경우 : 29, 30    -> "부족" : OK
 *  - 재고가 3인 경우 : 2, 5      -> "여유" : OK
 *  - 재고가 4인 경우 : 3, 8      -> "여유" : OK
 *  - 재고가 5인 경우 : 7, 9      -> "충분" : OK
 *  - 재고가 6인 경우 : 6, 15     -> "충분" : OK
 */
SELECT FILM_ID 
    FROM INVENTORY I 
GROUP BY FILM_ID 
HAVING count(*) = 1;

