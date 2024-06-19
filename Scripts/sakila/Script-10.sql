-- New script in sakila.
-- Date: 2024. 6. 19.
-- Time: 오후 2:04:05

/* ---------------------- Stored Function ---------------------- */

-- 전역 환경변수 설정
SET GLOBAL log_bin_trust_function_creators = 1;

DROP FUNCTION IF EXISTS userfunc1;

SELECT userfunc1(100, 200);

/* 태어난 년도를 매개변수로 받아, 현재 나이를 계산 및 반환 */
SELECT getagefunc(2000);

-- 함수를 SQL 에 적용
SELECT USERID , NAME , getAgeFunc(u.birthYear) AS "현재 나이"
    FROM USERTBL U ;