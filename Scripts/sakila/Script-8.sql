-- New script in sakila.
-- Date: 2024. 6. 18.
-- Time: 오후 2:43:49

/* ---------------------- View ---------------------- */

/*
 * View
 * 
 * 1. 사용 목적
 *  - 데이터 보안
 *  - 사용자 친화적 SQL 이 되도록 
 *  - 재사용성, 유지보수성
 *  - 복잡도 낮추기 위함
 * 
 * 2. 생성 빙법
 *  - CREATE VIEW view_name( col1, col2 ...) as
 *    SELECT ( col1, col2 ...)
 *    FROM table_name;
 * 
 * 3. View 에 대한 사용 권한 제어
 *  - 현재는 root 유저
 *  - 업무에선 스키마 별로 유저를 생성하여 스키마 별로 사용 권한을 부여함
 *  
 *  - marketing_user, insa_user, other_user 등으로 생성
 *    customer_v 고객 table 뷰를 생성해서 other_user 에게 접근 권한 부여(GRANT)
 *    customer table 접근 권한 회수(REVOKE)
 * 
 *  - 경우에 따라 갱신 view 를 생성해 제공하는 경우도 있음
 */

/*
 * 고객 정보 table 을 기준으로 view 생성
 * 고객Id, first_name, last_name 항목은 그대로 다 보여지도록 하고,
 * 단, 이메일 주소는 부분 * 로 마킹해서 보여지도록 함
 * 
 * 이메일 주소 마킹처리된 예 : MA****.org
 */
DROP VIEW IF EXISTS mask_custom_v;
CREATE VIEW mask_custom_v AS 
SELECT CUSTOMER_ID 
    , FIRST_NAME 
    , LAST_NAME 
    , REGEXP_REPLACE(EMAIL, '^([[:alpha:]]{2})([[:alpha:]]+\\.[[:alpha:]]+@[[:alpha:]]+)(\\.org)$', 
                        concat(SUBSTR(email, 1, 2), '*****.org')
                    ) AS mask_email 
    FROM CUSTOMER C ;
SELECT * FROM mask_custom_v;

/* 
 * 2번째 인자 : 치환하려는 데이터 자체를 나타내어야 함(대상 데이터)
 * 3번재 인자 : 치환 데이터
 * 4번째 인자 : 1번째 인자로 들어온 데이터에서 검색을 시작할 위치
 * REGEXP_REPLACE(EMAIL, '([[:alpha:]]+\\.[[:alpha:]]+@[[:alpha:]]+)', '*****', 3)
 *
 * EMAIL 에서, 
 * 3번째 자리 이후부터 정규표현식에 해당하는 데이터를 '*****'로 치환하라.
 */
SELECT CUSTOMER_ID 
    , FIRST_NAME 
    , LAST_NAME 
    , EMAIL 
    , REGEXP_REPLACE(EMAIL, '([[:alpha:]]+\\.[[:alpha:]]+@[[:alpha:]]+)', '*****', 3) AS mask_email 
    FROM CUSTOMER C ;

/*
 * 각 영화 정보에 대해서 
 * film_id, title, description, rating 가 출력이 되고,
 * 추가적으로 각 영화에 대한 영화 카테고리, 영화 출연 배우의 수,
 * 총 재고수, 각 영화의 대여횟수가 조회되도록 view 를 생성.
 * 
 * film 의 기본 칼럼을 제외하고 나머지 4개의 데이터는 스칼라 서브쿼리.
 * 그리고, 이 스칼라 서브쿼리는 연관 관계의 조건 설정이 필요.
 * 
 */
SELECT f.FILM_ID , f.TITLE , f.DESCRIPTION , f.RATING 
    , ( SELECT c.name
            FROM FILM_CATEGORY FC 
            JOIN CATEGORY C 
            ON fc.category_id = c.category_id
            WHERE f.FILM_ID = fc.film_id
        ) AS name
    , ( SELECT count(*)
            FROM FILM_ACTOR FA 
        WHERE f.FILM_ID = fa.film_id
        ) AS actor_cnt
    , ( SELECT count(*)
            FROM INVENTORY I 
        WHERE f.FILM_ID = i.film_id
        ) AS inven_cnt
    , ( SELECT count(*) 
            FROM INVENTORY I
            JOIN RENTAL R 
            ON i.inventory_id = r.inventory_id
        WHERE f.FILM_ID = i.film_id
        ) AS rent_cnt
    FROM FILM F ;

-- 검증
-- 1 ACADEMY DINOSAUR Documentary 10  8   23

-- 1. 카테고리
SELECT fc.FILM_ID , c.NAME      -- Documentary : OK
    FROM CATEGORY C
    JOIN FILM_CATEGORY FC 
    ON fc.CATEGORY_ID= c.CATEGORY_ID 
WHERE fc.FILM_ID = 1;

-- 2. 영화 출연 배우의 수
SELECT count(*)                 -- count : OK
    FROM FILM_ACTOR FA 
WHERE fa.FILM_ID = 1;

-- 3. 총 재고수
SELECT count(*)                 -- count : OK
    FROM INVENTORY I 
WHERE i.FILM_ID = 1;

-- 4. 각 영화의 대여횟수
SELECT count(*)                 -- count : OK
    FROM RENTAL R 
    JOIN INVENTORY I 
    ON r.INVENTORY_ID = i.INVENTORY_ID 
WHERE i.FILM_ID = 1;


/*
 * 영화 카테고리별 총 대여량을 조회하는 View 생성
 */
CREATE VIEW film_cat_rentTot_v as
SELECT c.NAME ,
    (
        SELECT count(*)
            FROM FILM_CATEGORY FC 
            JOIN FILM F 
            ON fc.FILM_ID = f.FILM_ID 
            JOIN INVENTORY I 
            ON f.FILM_ID = i.FILM_ID 
            JOIN RENTAL R 
            ON i.INVENTORY_ID = r.INVENTORY_ID 
        WHERE c.CATEGORY_ID = fc.CATEGORY_ID 
    ) AS cat_rental_tot
FROM CATEGORY C;

-- 검증
-- Action 1112
SELECT count(*) -- 1112
    FROM RENTAL R 
    JOIN INVENTORY I 
    ON r.INVENTORY_ID = i.INVENTORY_ID 
    JOIN FILM F 
    ON i.FILM_ID = f.FILM_ID 
    JOIN FILM_CATEGORY FC 
    ON f.FILM_ID = fc.FILM_ID 
    JOIN CATEGORY C 
    ON fc.CATEGORY_ID = c.CATEGORY_ID 
WHERE c.NAME = 'Action';























