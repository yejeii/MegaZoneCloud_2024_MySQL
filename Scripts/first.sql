SELECT *
FROM actor;

-- INSERT, UPDATE, DELETE -> transaction 종료 -> COMMIT, ROLLBACK 

/* 1:다 관계 */

-- 테이블 생성
-- UNSIGNED : 음수를 사용하지 않는 경우 해당 키워드를 추가하여 해당 범위를 0 ~ 음수값을 제외한 만큼의 정수 로 설정
-- 양수의 범위를 늘어나게 해준다.
-- 계속해서 축적하여 쌓아야 하는 데이터가 있다면 UNSIGNED 키워드를 추가하여 INSERT 할 수 있는 양수 범위를 늘어나게 할 수 있다.
-- AUTO_INCREMENT 설정하는 ID 칼럼에 유용           
CREATE TABLE person (
    person_id SMALLINT UNSIGNED,    
    fname varchar(20),
    lname varchar(20),
    eye_color enum("BR", "BL", "GR"),
    birth_date date,
    street varchar(20),
    city varchar(20),
    state varchar(20),
    country varchar(20),
    postal_code varchar(20),
    CONSTRAINT pk_person PRIMARY KEY (person_id)
);

SELECT *
FROM person ;

-- 테이블 생성 - FK 설정
CREATE TABLE favorite_food (
    person_id SMALLINT UNSIGNED,
    food varchar(20),
    CONSTRAINT pk_favorite_food PRIMARY KEY (person_id, food),
    CONSTRAINT fk_favorite_food_person_id FOREIGN KEY (person_id)
    REFERENCES person(person_id)
);

SELECT * FROM FAVORITE_FOOD ;

-- INSERT 
INSERT INTO PERSON 
(person_id, fname, lname, eye_color, birth_date)
VALUES
(1, 'William', 'Turner', 'BR', '1990-05-15');

INSERT INTO PERSON 
(person_id, fname, lname, eye_color, birth_date)
VALUES
(2, 'Mike', 'Willson', 'BR', '1980-08-15');


INSERT INTO FAVORITE_FOOD 
(PERSON_ID, FOOD)
VALUES 
(2, 'Fruit');

DROP TABLE FAVORITE_FOOD;
DROP TABLE person;

COMMIT;