-- New script in sakila.
-- Date: 2024. 6. 14.
-- Time: 오전 9:35:50

/* ---------------------- 집합 연산 ---------------------- */

/*
 * 1. 합집합
 *    union 연산      : 중복을 제거한다.
 *    union all 연산  : 중복을 제거하지 않고, 원래 데이터 그대로 쌓여서 출력
 * 
 *    A union B     
 *    A union all B
 * 
 * 2. 교집합
 *    intersect 연산
 * 
 *    A intersect B
 * 
 * 3. 차집합
 *    except 연산
 *      
 *    A except B
 * 
 * 4. 조합 연산
 *    union, intersect, except 를 조합해서 사용
 * 
 *    (A union B) except (A intersect B)
 *    (A except B) union (B except A)
 * 
 * 5. 집합 연산시 고려사항
 *    대상이 테이블임으로 칼럼의 개수, 칼럼 데이터 타입 고려
 * 
 *    - 두 데이터셋 모두 같은 수의 열을 가져야 함
 *    - 두 데이터 셋의 각 열 자료형은 서로 동일해야 함
 */

/*
 * 합집합
 * 1. 데이터 출처를 구분할 필요
 * 2. 다중 복합 집합 연산시, 집합 연산 전후의 count(*) 값 비교해야 함!!!
 */

/* 예제 1 */
SELECT 'customer' TYP, first_name, last_name FROM CUSTOMER C 
UNION
SELECT 'actor' typ, FIRST_NAME , LAST_NAME FROM ACTOR A 
-- 798 : 동명이인이 존재 -> union all 사용

SELECT 'customer' TYP, first_name, last_name FROM CUSTOMER C 
UNION ALL 
SELECT 'actor' typ, FIRST_NAME , LAST_NAME FROM ACTOR A 
-- 799

/* 예제 2 */
SELECT c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE c.FIRST_NAME LIKE 'J%' 
AND c.LAST_NAME LIKE 'D%'
UNION ALL
SELECT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A  
WHERE a.FIRST_NAME LIKE 'J%' 
AND a.LAST_NAME LIKE 'D%';

/* 
 * 교집합 - intersect
 */
SELECT c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE c.FIRST_NAME LIKE 'J%' 
AND c.LAST_NAME LIKE 'D%'
INTERSECT 
SELECT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A  
WHERE a.FIRST_NAME LIKE 'J%' 
AND a.LAST_NAME LIKE 'D%';

/*
 * 차집합 - except
 * 
 * 똑같은 테이블 두 개를 서로 순서를 변경할 경우, 결과가 다름
 */
SELECT c.FIRST_NAME , c.LAST_NAME 
    FROM CUSTOMER C 
WHERE c.FIRST_NAME LIKE 'J%' 
AND c.LAST_NAME LIKE 'D%'
EXCEPT 
SELECT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A  
WHERE a.FIRST_NAME LIKE 'J%' 
AND a.LAST_NAME LIKE 'D%';

/*
 * 집합 연산의 정렬
 */
SELECT c.FIRST_NAME AS fname, c.LAST_NAME AS lname
    FROM CUSTOMER C 
WHERE c.FIRST_NAME LIKE 'J%' 
AND c.LAST_NAME LIKE 'D%'
UNION ALL
SELECT a.FIRST_NAME , a.LAST_NAME 
    FROM ACTOR A  
WHERE a.FIRST_NAME LIKE 'J%' 
AND a.LAST_NAME LIKE 'D%'
ORDER BY 2, 1 ;
























