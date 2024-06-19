-- New script in sakila.
-- Date: 2024. 6. 19.
-- Time: 오후 2:12:40

/* ---------------------- Trigger ---------------------- */
/*
 * 개요
 *  테이블에 INSERT, UPDATE, DELETE 작업(event)이 발생할 때 자동으로 작동되는 객체
 * 
 *  테이블에 부착되는 이벤트 프로그램 코드라고 생각하면 됨
 * 
 * 대표적인 용도
 *  - 백업용 : ex. 삭제 시 원본 데이터 보관해야 하는 경우
 *  - 모니터링용 : ex. 급여 테이블 수정 시 전후 데이터에 대한 이력 확인해야 하는 경우
 *  - 비즈니스 프로세스 처리 단계용 : ex. [ 구입 -> 재고 계산 -> 배송 ] 을 하나의 비즈니스 프로세스로 동작시켜야 하는 경우
 * 
 * 형식
 *  - trigger time : 이벤트 발생 전 또는 발생 후
 *  - event : insert / update / delete
 *  - data 지시자 : old( event 발생 전 데이터 ) / new( event 발생 후 데이터 )
 */

CREATE TABLE backup_userTbl
( userID  varchar(8) NOT NULL, 
  name    varchar(10) NOT NULL, 
  birthYear   int NOT NULL,  
  addr    varchar(2) NOT NULL, 
  mobile1   varchar(3), 
  mobile2   varchar(8), 
  height    int,  
  mDate    date,
  modType  varchar(2),                      -- 변경된 타입. '수정' 또는 '삭제'
  modDate  date,                            -- 변경된 날짜
  modUser  varchar(256)                     -- 변경한 사용자
);

/* 비즈니스 프로세스 단계 처리용 */
-- 구매 테이블
CREATE TABLE orderTbl ( 
    orderNo INT AUTO_INCREMENT PRIMARY KEY, -- 구매 일련번호
    userID VARCHAR(5),                      -- 구매한 회원아이디
    prodName VARCHAR(5),                    -- 구매한 물건
    orderamount INT                         -- 구매한 개수
);  

-- 물품 테이블
CREATE TABLE prodTbl (                      
    prodName VARCHAR(5),                    -- 물건 이름
    account INT                             -- 남은 물건수량
);

-- 배송 테이블
CREATE TABLE deliverTbl (
    deliverNo  INT AUTO_INCREMENT PRIMARY KEY,  -- 배송 일련번호
    prodName VARCHAR(5),                        -- 배송할 물건          
    account INT UNIQUE                          -- 배송할 물건개수
);


/* 고객 정보 신규 등록시 경고 메세지 출력 : insert event */
DROP TRIGGER IF EXISTS usertbl_insertTrg_err_msg;

CREATE TRIGGER usertbl_insertTrg_err_msg
    AFTER INSERT    -- INSERT 가 발생한 후
    ON usertbl      -- 트리거가 부착될 대상
    FOR EACH ROW    -- 모든 행 대상
BEGIN
    -- 경고 메세지 출력
    SIGNAL SQLSTATE '45000'
        SET message_text = '신규 데이터 입력됨';
END;

SHOW triggers FROM SHOPPINGMALL;

INSERT INTO USERTBL VALUES ('AAB', 'AAB', 2004, 'AA', '010', '12344564', 170, '2024-06-10', DEFAULT);
SELECT * FROM USERTBL U WHERE USERID = 'AAB';

/* 고객 정보 신규 등록 시 태어난 연도 검증용 트리거 : insert event */
DROP TRIGGER IF EXISTS usertbl_insertTrg_chk_birthYr;
CREATE TRIGGER usertbl_insertTrg_chk_birthYr 
    BEFORE INSERT 
    ON usertbl
    FOR EACH ROW 
BEGIN
    -- 검증
    IF NEW.birthYear < 1900 THEN 
        SET NEW.birthYear = 0;
    ELSEIF NEW.birthYear > YEAR(curdate()) THEN
        SET NEW.birthYear = YEAR(curdate());
    END IF;
END;

SHOW triggers FROM SHOPPINGMALL;

-- usertbl_insertTrg_err_msg 삭제 후 시도
INSERT INTO USERTBL VALUES ('AAB', 'AAB', 1800, 'AA', '010', '12344564', 170, '2024-06-10', DEFAULT);
SELECT * FROM USERTBL U WHERE USERID = 'AAB';
INSERT INTO USERTBL VALUES ('BBA', '비비에이', 2026, 'AA', '010', '12344564', 170, '2024-06-10', DEFAULT);
SELECT * FROM USERTBL U WHERE USERID = 'BBA';

/* 고객 정보 수정 시 백업 및 모니터링용 트리거 : update event */
DROP TRIGGER IF EXISTS usertbl_updateTrg_backup;
CREATE TRIGGER usertbl_updateTrg_backup
    AFTER UPDATE 
    ON usertbl
    FOR EACH ROW 
BEGIN
    -- 변경 전 데이터를 백업T 에 저장
    INSERT INTO BACKUP_USERTBL 
    VALUES ( OLD.userId, OLD.name, OLD.birthYear, OLD.addr, 
            OLD.mobile1, OLD.mobile2, OLD.height, OLD.mDate, '수정', now(), current_user());
END;

SHOW triggers FROM SHOPPINGMALL;

SELECT * FROM USERTBL U WHERE USERID = 'BBK';
SELECT * FROM BACKUP_USERTBL BU WHERE USERID = 'BBK';

UPDATE USERTBL 
SET addr = '부산'
WHERE USERID = 'BBK';

/* 고객 정보 삭제 시 백업 및 모니터링용 트리거 : delete event */
DROP TRIGGER IF EXISTS usertbl_delTrg_backup;
CREATE TRIGGER usertbl_delTrg_backup
    AFTER DELETE
    ON usertbl
    FOR EACH ROW 
BEGIN
    -- 삭제 전 데이터를 백업T 에 저장
    INSERT INTO BACKUP_USERTBL 
    VALUES ( OLD.userId, OLD.name, OLD.birthYear, OLD.addr, 
            OLD.mobile1, OLD.mobile2, OLD.height, OLD.mDate, '삭제', now(), current_user());
END;

SHOW triggers FROM SHOPPINGMALL;

SELECT * FROM USERTBL U WHERE USERID = 'AAB';

DELETE FROM USERTBL WHERE userid = 'AAB';

SELECT * FROM BACKUP_USERTBL BU ;

/* 
 * 비즈니스 프로세스 단계 처리용 트리거 
 * 
 * 주문(ordertbl) -> 재고 계산(prodtbl) -> 배송(delivertbl)
 * 
 * insert        -> update          -> insert 
 * */
DROP TRIGGER busin_prcsTrg;
CREATE TRIGGER busin_prcsTrg
    AFTER INSERT
    ON ordertbl
    FOR EACH ROW 
BEGIN
    UPDATE PRODTBL 
    SET account := account - NEW.orderamount
    WHERE prodName = NEW.prodName;

    INSERT delivertbl(prodName, account) 
    VALUES (NEW.prodName, NEW.orderamount);
END;

truncate TABLE orderTbl;
truncate TABLE prodTbl;
truncate TABLE DELIVERTBL ;

-- 재고 테이블에 테스트용 데이터 등록
insert into prodTbl values('사과', 100);
insert into prodTbl values('배', 100);
insert into prodTbl values('귤', 100);

insert into orderTbl values (null, 'cus1', '배', 5);

SELECT * FROM ORDERTBL O ;
SELECT * FROM PRODTBL P ;
SELECT * FROM DELIVERTBL D ;




















