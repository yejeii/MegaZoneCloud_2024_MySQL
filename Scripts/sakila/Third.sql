-- New script in sakila.
-- Date: 2024. 6. 13.
-- Time: 오전 11:37:31

/* ---------------------- 필터링(조건절 활용) ---------------------- */

/* 동등 조건 */
SELECT *
    FROM RENTAL R 
WHERE date(RENTAL_DATE) = '2005-06-14'; 

/* 비동등 조건 */
SELECT *
    FROM RENTAL R 
WHERE date(RENTAL_DATE) <> '2005-06-14'; 

/* 범위 조건 */
SELECT *
    FROM RENTAL R 
WHERE date(RENTAL_DATE) < '2005-05-28'; 

SELECT *
    FROM RENTAL R 
WHERE date(RENTAL_DATE) <= '2005-06-16'
AND date(RENTAL_DATE) >= '2005-06-14';

SELECT *
    FROM RENTAL R 
WHERE date(RENTAL_DATE) BETWEEN '2005-06-14' AND '2005-06-16';

/* payment : DVD 대여 정보 중 결제와 관련된 정보 */
SELECT CUSTOMER_ID , PAYMENT_DATE , AMOUNT 
    FROM PAYMENT P 
WHERE AMOUNT BETWEEN 10.0 AND 11.99;

/* in */
SELECT TITLE , RATING 
    FROM FILM F 
WHERE RATING IN('G', 'PG');

/* not in */
SELECT TITLE , RATING 
    FROM FILM F 
WHERE RATING NOT IN('G', 'PG');

/* 문자열 함수를 활용한 등가 조인 */
SELECT LAST_NAME , LEFT(LAST_NAME, 1)
    FROM CUSTOMER C 
WHERE LEFT(LAST_NAME , 1) = 'Q';

/* like 연산자 */
SELECT LAST_NAME , FIRST_NAME 
    FROM CUSTOMER C 
WHERE LAST_NAME LIKE '_A%S'; /* _ : 문자 한자리 */

/* 정규 표현식 : 고객의 last_name 가 Q / Y 로 시작하는 고객 리스트 */
SELECT LAST_NAME , FIRST_NAME 
    FROM CUSTOMER C
WHERE LAST_NAME REGEXP '^[QY]';

/* null 조건 검색 : 반납되지 않은 대여 정보 조회 */
SELECT *
    FROM RENTAL R 
WHERE RETURN_DATE IS NULL ;


/* ---------------------- 다중 테이블 활용 ---------------------- */

/*
 * 카테시안 product(데카르트 곱)
 * 
 * 2개 이상의 테이블을 사용해서 데이터 조회시,
 * 두 테이블의 관계를 설정하지 않고 조회하면 서로 연결할 수 있는 조건으로 연결된 모든 데이터가 조회됨
 * 
 * 일반적으로는 전혀 의미가 없지만,
 * 특별한 경우(테스트 데이터, dummy 데이터 용)에는 사용할 수 있음
 * 
 * 따라서, 반드시 두 테이블간의 관계 설정을 해야 함
 * 
 */

CREATE TABLE EMP
       (EMPNO int NOT NULL,
        ENAME VARCHAR(10),
        JOB VARCHAR(9),
        MGR int,
        HIREDATE DATE,
        SAL int,
        COMM int,
        DEPTNO int);

INSERT INTO EMP VALUES
        (7369, 'SMITH',  'CLERK',     7902,
        date('1980-12-17'),  800, NULL, 20);
INSERT INTO EMP VALUES
        (7499, 'ALLEN',  'SALESMAN',  7698,
        '1981-02-20', 1600,  300, 30);
INSERT INTO EMP VALUES
        (7934, 'MILLER', 'CLERK',     7782,
        '1982-01-23', 1300, NULL, 10);
INSERT INTO EMP VALUES
        (7521, 'WARD',   'SALESMAN',  7698,
        '1981-02-22', 1250,  500, 30);
INSERT INTO EMP VALUES
        (7566, 'JONES',  'MANAGER',   7839,
        '1981-04-02',  2975, NULL, 20);
INSERT INTO EMP VALUES
        (7654, 'MARTIN', 'SALESMAN',  7698,
        '1981-09-28', 1250, 1400, 30);
INSERT INTO EMP VALUES
        (7698, 'BLAKE',  'MANAGER',   7839,
        '1981-05-01',  2850, NULL, 30);
INSERT INTO EMP VALUES
        (7782, 'CLARK',  'MANAGER',   7839,
        '1981-06-09',  2450, NULL, 10);
INSERT INTO EMP VALUES
        (7788, 'SCOTT',  'ANALYST',   7566,
        '1982-12-09', 3000, NULL, 20);
INSERT INTO EMP VALUES
        (7839, 'KING',   'PRESIDENT', NULL,
        '1981-11-17', 5000, NULL, 10);
INSERT INTO EMP VALUES
        (7844, 'TURNER', 'SALESMAN',  7698,
        '1981-09-08',  1500, NULL, 30);
INSERT INTO EMP VALUES
        (7876, 'ADAMS',  'CLERK',     7788,
        '1983-01-12', 1100, NULL, 20);
INSERT INTO EMP VALUES
        (7900, 'JAMES',  'CLERK',     7698,
        '1981-12-03',   950, NULL, 30);
INSERT INTO EMP VALUES
        (7902, 'FORD',   'ANALYST',   7566,
        '1981-12-03',  3000, NULL, 20);

SELECT count(*)
FROM EMP E ;

/* 데카르트 곱 */
SELECT COUNT(*) FROM CUSTOMER C ;   -- 599
SELECT COUNT(*) FROM ADDRESS A ;   -- 603

SELECT c.FIRST_NAME , c.LAST_NAME , a.ADDRESS , count(*) OVER() -- 361,197
    FROM CUSTOMER C JOIN ADDRESS A ;

-- 588, 603, 361197 결과가 한 번의 SQL 실행으로 모두 조회되도록 
SELECT COUNT(*) FROM CUSTOMER C
UNION 
SELECT COUNT(*) FROM ADDRESS A
UNION
SELECT count(*) OVER() -- 361,197
    FROM CUSTOMER C JOIN ADDRESS A

SELECT customer_cnt.customer_cnt, address_cnt.address_cnt, cartesian_cnt.cartesian_cnt
    FROM 
        (SELECT COUNT(*) customer_cnt FROM CUSTOMER C) AS customer_cnt,
        (SELECT COUNT(*) address_cnt FROM ADDRESS A) AS address_cnt,
        (SELECT count(*) cartesian_cnt
            FROM CUSTOMER C JOIN ADDRESS A) AS cartesian_cnt;
        
/* 
 * 데카르트 곱을 회피 -> 관계 설정 
 * address_id 로 관계 설정
 * 
 * 실행하면 599 건이 확인됨
 * 
 * 599 건은 현재 CUSTOMER 테이블의 고객 수
 * 고객이 599 명인데, 아래의 문장을 실행해서 598 건이 나온다면, 주소 마스터 테이블의 주소 정보에 문제가 있다고 생각, 확인해야 함
 * 
 */        
        
/* ANSI join 문법 - SQL92 버전 
 * 
 * 표준 SQL 의 장점
 *  - 조인 조건과 추가적인 필터 조건이 구분되어 가독성이 높음
 *  - 조인 조건에 대한 누락될 가능성이 낮음
 *  - 표준 SQL이 다른 벤더의 DB로의 이식성이 높음
 */
SELECT c.FIRST_NAME , c.LAST_NAME , a.ADDRESS , count(*) OVER()
    FROM CUSTOMER C 
    JOIN ADDRESS A 
    ON c.ADDRESS_ID = a.ADDRESS_ID 
WHERE a.POSTAL_CODE = 52137;

/* 
 * 비 ANSI(비표준) 
 * 
 * 비표준 SQL 에는 벤더 지향 SQL이 있음 -> 고급 기능
 * */
SELECT c.FIRST_NAME , c.LAST_NAME , a.ADDRESS , count(*) OVER() -- 599
    FROM CUSTOMER C, ADDRESS A 
WHERE c.ADDRESS_ID = a.ADDRESS_ID;

SELECT c.FIRST_NAME , c.LAST_NAME , a.ADDRESS , count(*) OVER() 
    FROM CUSTOMER C, ADDRESS A 
WHERE c.ADDRESS_ID = a.ADDRESS_ID
AND a.POSTAL_CODE = 52137;


/*
 * 세 테이블 조인
 * 
 * 고객명, 도시명 조회
 * customer, city, address
 * 
 * 1. 표준 SQL 사용해서 3 테이블 관계
 * 2. 서브 쿼리
 * 3. 그래서 어떤 SQL 이 더 가독성 있는지 비교
 * 4. 2번에서 서브쿼리로 사용한 SQL 을 View 로 생성
 *    서브쿼리 대신에 View 를 사용한 SQL 로 작성
 */
SELECT count(*) FROM CUSTOMER C ;   -- 599

-- 1.
SELECT c.FIRST_NAME , c.LAST_NAME 
    , a.ADDRESS , a.ADDRESS2 , a.DISTRICT , a.POSTAL_CODE 
    , c2.CITY , count(*) OVER() toal_cnt
    FROM CUSTOMER C 
    JOIN ADDRESS A 
    ON c.ADDRESS_ID = a.ADDRESS_ID
    JOIN CITY C2 
    ON a.CITY_ID = c2.CITY_ID ;
-- 2.
SELECT x.FIRST_NAME , x.LAST_NAME 
    , x.ADDRESS , x.ADDRESS2 , x.DISTRICT , x.POSTAL_CODE , c2.CITY , count(*) OVER() toal_cnt
    FROM CITY C2
    JOIN (
            SELECT c.FIRST_NAME , c.LAST_NAME 
                    , a.ADDRESS , a.ADDRESS2 , a.DISTRICT , a.POSTAL_CODE , a.CITY_ID
            FROM CUSTOMER C 
            JOIN ADDRESS A 
            ON c.ADDRESS_ID = a.ADDRESS_ID 
        ) x
    ON c2.CITY_ID = x.CITY_ID;
-- 4. 
CREATE VIEW cust_add_v AS
    SELECT c.FIRST_NAME , c.LAST_NAME 
        , a.ADDRESS , a.ADDRESS2 , a.DISTRICT , a.POSTAL_CODE , a.CITY_ID
        FROM CUSTOMER C 
        JOIN ADDRESS A 
        ON c.ADDRESS_ID = a.ADDRESS_ID ;

SELECT CAV.*, c2.CITY , count(*) OVER() toal_cnt
    FROM CITY C2
    JOIN CUST_ADD_V CAV 
    ON C2.CITY_ID = CAV.CITY_ID 


/*
 * 프로젝트시 기능분석이 완료됨. ERD 가 어느정도 완성됨
 * 
 * 각 기능별 예상 SQL 을 작성
 * -> 공통 SQL 문이 나올 것 : 특히 SELECT.
 * SELECT 문장 중, 공통 부분 추출, VIEW 가 될 대상에 대해 어떻게 구현할 것인지를 고려
 * 
 * function 대상 , 트랜잭션과 관련된 SQL 그룹핑(select, update, insert, procedure) 
 * 
 * 트랜잭션과 관련된 SQL은 성능적 문제가 없을까.. 고민.  
 * 
 * 성능테스트 진행 후, scale in, scale out 범위 설정 -> 시스템 아키텍처 고려..
 */

    
/*
 * self join 
 * 
 * 테이블 하나로 마치 두 개의 테이블처럼 사용해서 조인하는 경우
 * 
 * emp table 의 사번과 관련된 칼럼이 empno, mgr 이 있고, 
 * mgr 칼럼은 자기 참조 외래키라고 명명함
 * 
 * 상사 정보가 없는 사원 : 사장님 또는 회장님
 */
SELECT *
FROM EMP e
WHERE JOB = 'PRESIDENT';

/* 
 * 사원과 그 사원의 상사 정보를 함께 조회하는 SQL 작성 
 * 
 * 누락된 데이터까지 조회되록 하려면 어떻게 해야할까?
 * 
 * outer join(외부 조인) 사용
 * 
 * 동일한 테이블 간의 조인ㄴ 수행에서 어느 한쪽이 null 이라도 강제로 출력하는 join 방식
 * 
 * left outer join
 * 왼쪽 열을 기준으로 오른쪽 열의 데이터 존재 여부와 상관없이 출력
 * */
SELECT count(*) FROM EMP E ;

/* self join : 13건, 사장님 누락 */
SELECT e.empno, e.ENAME, e.job
    , m.ENAME mgr_ename, count(*) OVER()
    FROM EMP E 
    JOIN EMP M
    ON e.mgr = m.EMPNO; 

/* left outer join  : 14 건, 사장님 포함 */
SELECT e.empno, e.ENAME, e.job
    , m.ENAME mgr_ename, count(*) OVER()
    FROM EMP E 
    LEFT OUTER JOIN EMP M
    ON e.mgr = m.EMPNO; 

SELECT e.empno, e.ENAME, e.job
    , m.ENAME mgr_ename, count(*) OVER()
    FROM EMP E 
    JOIN EMP M
    ON IFNULL(e.mgr, (SELECT EMPNO FROM emp WHERE mgr IS NULL)) = m.EMPNO; 

/*
 * 한 쪽은 14건, 한 쪽은 13건..
 * 
 * 차이가 나는 데이터를 어떻게 하면 알아낼 수 있을까?
 * 
 * 데이터가 100,000,000 건일 때는 어떻게 확인할래?
 * 
 * except ( 차집합 ) 연산자 사용의 제한
 * => except 를 사용한 결과를 in 연산자와 함께 사용할 경우
 *   제대로 된 결과를 예상할 수 없음.
 * => MySQL 8.4 공식 문서에서 이에 대한 설명이 현재는 없는 상태.
 */
SELECT *
FROM EMP E 
WHERE EMPNO IN (
                SELECT e.EMPNO FROM EMP E     -- 14
                EXCEPT   /* 차집합 연산자 */
                SELECT e.empno              -- 13
                    FROM EMP E 
                    JOIN EMP M
                    ON e.mgr = m.EMPNO
                );
                

