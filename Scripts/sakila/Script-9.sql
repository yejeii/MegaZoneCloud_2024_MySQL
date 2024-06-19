-- New script in sakila.
-- Date: 2024. 6. 19.
-- Time: 오전 10:12:01

/* ---------------------- Stored Procedure ---------------------- */

-- 스키마 생성
CREATE DATABASE shoppingmall;

-- 스키마 지정
USE shoppingmall;

-- 테스트용 테이블 : 도메인 테이블 X
CREATE TABLE shoppingmall.usertbl (
    userid varchar(8) NOT NULL COMMENT '쇼핑몰 사용자 ID, PK',
    name varchar(30) NOT NULL COMMENT '회원명',
    birthyear int NOT NULL COMMENT '출생년도',
    addr varchar(8) NOT NULL COMMENT '지역(경기, 서울, 경남  등)',
    mobile1 varchar(3) NULL COMMENT '휴대폰 국번(010, 011 등)',
    mobile2 varchar(8) NULL COMMENT '휴대폰 나머지 번호',
    height INT NULL COMMENT '신장',
    mdate DATE NULL COMMENT '회원 가입일',
    CONSTRAINT usertbl_pk PRIMARY KEY (userid)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci;

-- 회원 구매 테이블 생성
CREATE TABLE shoppingmall.buytbl (
    num int AUTO_INCREMENT NOT NULL comment '순번' ,
    userId varchar(8) NOT NULL comment '회원 아이디' ,
    prodName varchar(8) NOT NULL comment '구매한 제품명' ,
    groupName varchar(4) NULL comment '구매 재품 분류명' ,
    price int NOT NULL comment '단가' ,
    amount int NOT NULL comment '수량' ,
    CONSTRAINT buytbl_pk PRIMARY KEY (num) ,
    CONSTRAINT buytbl_userId_fk FOREIGN KEY (userId) REFERENCES userTbl (userId)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_0900_ai_ci
COMMENT='회원 구매 테이블';

-- 데이터 삽입
INSERT INTO usertbl VALUES('LSG', '이승훈', 1987, '서울', '010', '1111111', 182, '2008-8-8');
INSERT INTO usertbl VALUES('KBS', '김범수', 1990, '경남', '010', '2222222', 173, '2012-4-4');
INSERT INTO usertbl VALUES('KKH', '김경호', 2000, '전남', '010', '3333333', 177, '2007-7-7');
INSERT INTO usertbl VALUES('JYP', '조용수', 2005, '경기', '010', '4444444', 166, '2009-4-4');
INSERT INTO usertbl VALUES('SSK', '하준경', 1979, '서울', NULL  , NULL      , 186, '2013-12-12');
INSERT INTO usertbl VALUES('LJB', '임재호', 1999, '서울', '010', '6666666', 182, '2009-9-9');
INSERT INTO usertbl VALUES('YJS', '윤호신', 1987, '경남', 010  , NULL      , 170, '2005-5-5');
INSERT INTO usertbl VALUES('EJW', '은지효', 1997, '경북', '010', '8888888', 174, '2014-3-3');
INSERT INTO usertbl VALUES('JKW', '조현우', 2002, '경기', '010', '9999999', 172, '2010-10-10');
INSERT INTO usertbl VALUES('BBK', '하준희', 2001, '서울', '010', '0000000', 176, '2013-5-5');


INSERT INTO buytbl VALUES(NULL, 'KBS', '운동화', NULL, 30,   2);
INSERT INTO buytbl VALUES(NULL, 'KBS', '노트북', '전자', 1000, 1);
INSERT INTO buytbl VALUES(NULL, 'JYP', '모니터', '전자', 200,  1);
INSERT INTO buytbl VALUES(NULL, 'BBK', '모니터', '전자', 200,  5);
INSERT INTO buytbl VALUES(NULL, 'KBS', '청바지', '의류', 50,   3);
INSERT INTO buytbl VALUES(NULL, 'BBK', '메모리', '전자', 80,  10);
INSERT INTO buytbl VALUES(NULL, 'SSK', '책'    , '서적', 15,   5);
INSERT INTO buytbl VALUES(NULL, 'EJW', '책'    , '서적', 15,   2);
INSERT INTO buytbl VALUES(NULL, 'EJW', '청바지', '의류', 50,   1);
INSERT INTO buytbl VALUES(NULL, 'BBK', '운동화', NULL   , 30,   2);
INSERT INTO buytbl VALUES(NULL, 'EJW', '책'    , '서적', 15,   1);
INSERT INTO buytbl VALUES(NULL, 'BBK', '운동화', NULL   , 30,   2);

SELECT * FROM USERTBL U ;
SELECT * FROM BUYTBL B ;


/* ---------------------- Stored Procedure ---------------------- */

/* 
 * 개요
 *  - 쿼리문의 집합. 특별한 동작을 처리하기 위한 용도로 사용
 *  - 재사용, 모듈화 개발이 됨
 * 
 * 특징
 *  - 프로시저는 현장에 따라 취사 선택 사항
 * 
 *  - 성능 향상
 *    몇 백 라인의 SQL 문장이 문자열로 네트워크를 경유해 서버로 전송하면 
 *    경우에 따라(수 많은 유저, 수 많은 데이터) 네트워크 부하가 발생할 수 있음
 * 
 *    이런 문제점에 대해서 필요한 기능에 따른 SQL 문장들을 서버에 보관해서 호출, 사용하는 형태가 되면 
 *    네트워크 부하를 낮추는데 도움이 될 수 있음
 * 
 *    SQL 파싱, 실행 계획 등의 전처리 작업이 캐싱된 상태이므로 재사용하게 되어 성능이 높아지게 됨
 * 
 *  - 유지 관리가 편리 
 *    기존 방법의 경우, 관리 포인트가 경유하는 곳마다 많아지게 됨(JAVA, MiddleWare, DB) 
 *    -> JAVA 쪽에서 개발을 하지 않고, 필요한 기능을 DB 서버에 두게 되어 관리포인트를 하나로 둘 수 있게 됨
 * 
 *    JAVA 의 백엔드 딴에 SQL 을 작성해서 운영중인데, 
 *    SQL 문장에 칼럼을 추가 & WHERE 문장 수정이 발생하게 되면...
 *    수정 -> 테스트 -> 빌드 -> 배포 등의 단계를 수행해야 함..
 * 
 *    이것을 Stored Procedure 를 사용하게 되면 JAVA 딴에서 수정해야 하는 부분이 줄어들게 됨.
 * 
 *  - 모듈식 개발이 가능해짐
 *    함수처럼 사용할 수 있게 되어 다른 프로시저에서도 호출해서 사용할 수 있음
 * 
 *  - 보안 강화
 *    테이블에 직접 접근 대신 프로시저를 통해 접근하게 됨
 * 
 * 문법
 *  CREATE PROCEDURE 프로시저명 (IN , OUT , INOUT 매개변수) IN : 입력 / OUT : 출력(결과)
 *  BEGIN
 *      sql...
 *      조건문...
 *      반복문...
 *      함수...
 *      프로시저...
 *  END;
 * 
 * 사용
 *  CALL 프로시저명(매개변수);
 * 
 * */



/* ---------------------- 매개변수가 없는 프로시저 ---------------------- */
DROP PROCEDURE IF EXISTS userProc;
CREATE PROCEDURE shoppingmall.userproc()
BEGIN
    SELECT * FROM usertbl;
END;

CALL USERPROC(); 


/* ---------------------- in 매개변수가 있는 프로시저 ---------------------- */
CREATE PROCEDURE shoppingmall.userproc1(IN userName varchar(10))
BEGIN
    SELECT * FROM usertbl WHERE name = userName;
END;

CALL USERPROC1('은지효'); 


/* ---------------------- in 매개변수가 2개인 프로시저 ---------------------- */
CREATE PROCEDURE shoppingmall.userProc2(    IN userBirthYear int,
                                            IN userHeight int )
BEGIN
    SELECT * 
    FROM usertbl 
    WHERE birthyear > userBirthYear
    AND height > userHeight;
END;


/* ---------------------- in, out 매개변수가 2개인 프로시저 ---------------------- */
DROP PROCEDURE IF EXISTS userProc3;

CREATE TABLE IF NOT EXISTS testtbl (
    id int AUTO_INCREMENT , 
    txt varchar(10) ,
    CONSTRAINT testtbl_pk PRIMARY KEY (id)
);

CREATE PROCEDURE userProc3 (    IN textValue varchar(10),
                                OUT outValue int
                            )
BEGIN
    INSERT INTO testtbl VALUES (NULL, textValue);
    SELECT MAX(id) INTO outValue FROM TESTTBL T; 
END;

CALL USERPROC3('테스트값', @outValue);  -- @ : 현재 세션의 지역변수 
SELECT * FROM TESTTBL T ;
SELECT @outValue;

CALL USERPROC3('테스트값2', @outValue);
SELECT * FROM TESTTBL T ;
SELECT @outValue;


/* ---------------------- in 매개변수, if 조건절이 있는 프로시저 ---------------------- */
DROP PROCEDURE IF EXISTS userProc4;

CREATE PROCEDURE IFELSEPROC(VARCHAR(10)) (IN userName varchar(10))
BEGIN
    DECLARE address varchar(8); -- 프로시저의 지역변수
    
    SELECT addr INTO address 
    FROM USERTBL U 
    WHERE name = userName;

    IF(address = '서울' OR address = '경기') THEN 
        SELECT '수도권 거주';
    ELSE 
        SELECT '지방 거주';
    END IF;
END;

CALL IFELSEPROC('김경호');
CALL IFELSEPROC('하준경');


/* ---------------------- in 매개변수, 반복문이 있는 프로시저 ---------------------- */
CREATE TABLE gugudantbl (
    txt varchar(100)
);

CREATE PROCEDURE shoppingmall.gugudanProc ()
BEGIN
    DECLARE dan int DEFAULT 2;
    DECLARE i int DEFAULT 1;
    DECLARE str varchar(100) DEFAULT '';

    WHILE (dan < 10) do
        WHILE (i < 10) do
            SET str = concat(dan, '*', i, '=', dan * i);
            INSERT INTO GUGUDANTBL VALUES (str); 
            SET i = i+1;
        END WHILE;
        SET dan = dan+1;
        SET i = 1;
    END WHILE;

    SELECT * FROM GUGUDANTBL;
END;

CALL gugudanProc();


/* ---------------------- 동적(dynamic) SQL 이 있는 프로시저 ---------------------- */
/*
 * 상황에 따라 SQL 변경이 실시간으로 필요한 경우,
 * 동적 SQL 을 사용하여 실시간으로 수정 및 실행해서 사용
 */
DROP PROCEDURE IF EXISTS dynamicSqlProc;

CALL DYNAMICSQLPROC('usertbl'); 
CALL DYNAMICSQLPROC('buytbl'); 


/* ---------------------- 커서를 활용한 프로시저 ---------------------- */
/*
 * 커서(cursor)
 *  - 테이블에서 여러 개의 행을 쿼리한 후, 쿼리의 결과인 행 집합에서 한 행씩 처리하기 위한 방식
 * 
 * 커서 처리 단계
 *  1. 커서 선언 (DECLARE)
 *  2. 커서 열기 (OPEN)
 *  3. 커서에서 행 가져오기 (FETCH) : 가져온 한 row 에 대해 데이터 처리를 수행
 *  4. 커서 닫기 (CLOSE)
 * 
 * 실습 내용
 *  대량의 고객 정보를 업데이트하기 위한 프로시저를 개발
 *  
 *  고객 정보 테이블에 고객 등급 칼럼을 추가한 후, 등급 관리를 하려고 함
 *  ( 최우수 고객, 우수 고객, 일반 고객, 유령 고객 )
 *  
 */

ALTER TABLE USERTBL ADD grade varchar(10);
DESC USERTBL ;
ALTER TABLE USERTBL MODIFY COLUMN grade varchar(10) AFTER height;

DROP PROCEDURE IF EXISTS gradeProc;

CALL GRADEPROC();

select * FROM USERTBL U ;



