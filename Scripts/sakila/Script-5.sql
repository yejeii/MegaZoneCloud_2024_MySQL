-- New script in sakila.
-- Date: 2024. 6. 14.
-- Time: 오전 10:11:23

/* ---------------------- 그룹화와 집계 ---------------------- */

/* 
 * SELECT 칼럼명
 *  FROM 테이블명
 * GROUP BY 칼럼
 * HAVING 조건
 *
 */

DESC RENTAL ;   -- 대여정보 데이터를 관리하는 테이블 

SELECT count(*) FROM CUSTOMER C ; -- 599

-- 고객ID 별 그룹화
SELECT CUSTOMER_ID , count(*)
    FROM RENTAL R 
GROUP BY CUSTOMER_ID ;  -- 599 

/*
 * 위 결과를 비즈니스 로직으로 생각해보기
 * 
 * 599
 * 고객정보 수와 대여정보 수 모두 599 -> 유휴 고객이 없는 상태
 * 
 * 하지만, 한 번만 빌리고, 2년동안 빌리지 않는 고객도 있을 수 있음
 * 따라서, 유휴 고객에 대한 기준을 세워야 함
 * 
 * >의미있는 데이터로 추출하기<
 */ 

/* 대여 횟수에 대한 내림차순 정렬 : 충성도가 높은 고객 순으로 조회 */
SELECT CUSTOMER_ID , count(*)
    FROM RENTAL R 
GROUP BY CUSTOMER_ID 
ORDER BY 2 DESC;

/* 그룹핑 데이터에 그룹핑 조건 설정 : 초초충성고객 조회 */
SELECT CUSTOMER_ID , count(*)
    FROM RENTAL R 
GROUP BY CUSTOMER_ID 
HAVING count(*) >= 40
ORDER BY 2 DESC;

DESC PAYMENT ;  -- DVD 대여 결제 내역

/* 
 * 집계 함수
 * 
 * 현재 사업의 ROI( Return of Investment, 투자회수 )가 보임
 * 전체 결제 내역에 대한 summary.
 * 
 */
SELECT MAX(AMOUNT) max_amt
    , MIN(AMOUNT) min_amt   /* 0 인 경우, 무조건 횟수 확인 */
    , AVG(AMOUNT) avg_amt
    , SUM(AMOUNT) sum_amt
    , COUNT(AMOUNT) num_pay 
    FROM PAYMENT P ;    -- 16,044

SELECT count(*) 
    FROM PAYMENT P 
WHERE AMOUNT = 0;   -- 24

/*
 * 고객별 결제 내역에 대한 summary
 * 
 * 높은 결제 금액 == 최신 제품을 많이 본다 -> 대여 기간이 짧음 -> 대여 횟수가 높다면..? : 충쉉충쉉고객
 *                                -> AI 를 이 고객에게 추천 서비스를 제공토록 해야함.
 * 
 */
SELECT CUSTOMER_ID 
    , MAX(AMOUNT) max_amt
    , MIN(AMOUNT) min_amt   
    , AVG(AMOUNT) avg_amt
    , SUM(AMOUNT) sum_amt
    , COUNT(AMOUNT) num_pay 
    FROM PAYMENT P 
GROUP BY CUSTOMER_ID ;

/* 대여 후 반환까지 걸린 최대 일수 구하기 */
SELECT max(DATEDIFF(RETURN_DATE, RENTAL_DATE)) max_return
    FROM RENTAL R ;

/* 다중 그룹핑 
 * 
 * FILM_ACTOR
 * 정규화 후에 생성된 테이블처럼 보임
 * 
 */
DESC FILM_ACTOR ; 

/* 영화 배우별 출연 횟수 */
SELECT ACTOR_ID , count(*)
    FROM FILM_ACTOR FA 
GROUP BY ACTOR_ID ;

/* 위의 sql 에 영화 등급 정보까지 조회 */
SELECT fa.ACTOR_ID , f.RATING , count(*)
    FROM FILM_ACTOR FA 
    JOIN FILM F 
    ON fa.FILM_ID = f.FILM_ID 
GROUP BY fa.ACTOR_ID , f.RATING 
ORDER BY 1, 2;

/* 
 * 연도별 대여 수 
 * 
 * 예상 결과 : 
 *          2023 1000
 *          2024 500
 * */
SELECT YEAR(rental_date) Year
-- SELECT EXTRACT(YEAR FROM rental_date) YEAR
    , count(*) rental_cnt
    FROM RENTAL R 
-- GROUP BY EXTRACT(YEAR FROM rental_date)  ;
GROUP BY YEAR(rental_date) ;
    
-- 월 추출
SELECT EXTRACT(MONTH FROM rental_date) FROM RENTAL R ;

-- 년, 월 추출
SELECT EXTRACT(YEAR_MONTH FROM rental_date) FROM RENTAL R ;

-- 일, 시 추출
SELECT EXTRACT(DAY_HOUR FROM rental_date) FROM RENTAL R ;

/* 그룹필터 - 그룹핑 + 조건 검색 */
SELECT fa.ACTOR_ID , f.RATING , count(*)
    FROM FILM_ACTOR FA 
    JOIN FILM F 
    ON fa.FILM_ID = f.FILM_ID 
WHERE f.RATING IN ('G', 'PG')  /* 등급 조건 설정 */
GROUP BY fa.ACTOR_ID , f.RATING 
HAVING count(*) > 9
ORDER BY 1, 2;
























