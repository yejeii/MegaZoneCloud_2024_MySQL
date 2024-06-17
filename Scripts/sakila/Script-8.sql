-- New script in sakila.
-- Date: 2024. 6. 17.
-- Time: 오전 11:35:12

/*
 * 상관관계 서브쿼리 사용
 * R 등급 영화에 출연한 적이 한 번도 없는 모든 배우명 검색
 * 
 * - 영화 배우 한 명만을 생각해보는 것으로 논리적으로 접근
 *   A 영화배우 10편에 출연 -> 10편 영화가 R 등급 영화에 출연 여부
 * 
 *   Main Query           Sub Query
 * 
 *   영화배우 테이블에 영화배우가 100명이라면, 위의 처리 방법을 100 번 수행
 * 
 *   => 상관관계 쿼리
 *      Main query 에서 조회된 데이터를 Sub Query 에서 조건으로 사용하고,
 *      Sub Query 결과를 Main Query 로 반환
 */

select a.actor_id, a.first_name ,a.last_name 
from actor a /*배우 데이터를 sub query의 검색 조건으로 사용*/
where exists (
        select fa.actor_id, f.film_id, f.rating
        from film_actor fa 
        join film f 
            on fa.film_id = f.film_id
        where f.rating <>'R'
        );

SELECT *
    FROM FILM F 
    JOIN FILM_ACTOR FA 
    ON f.FILM_ID = fa.FILM_ID 
WHERE fa.ACTOR_ID = 1;
-- AND f.RATING = 'R';

SELECT count(*) FROM ACTOR A ;
select a.actor_id, first_name ,last_name 
from actor a /*배우 데이터를 sub query의 검색 조건으로 사용*/
where exists (
        select *
        from film_actor fa 
        join film f 
            on fa.film_id = f.film_id
        where  fa.actor_id = a.actor_id 
        and f.rating <>'R'
        );
    
/*-----------------위에꺼는 where절만 다름 내가 쓴거---------*/
/*----------------밑에꺼는 강사님이 적은거-----------*/
//다른점 : 강사님 : not exists 쓰고 where절에 f.rating='R'    
//      나 : exists 쓰고 where절에 f.rating<>'R' 왜 값이 다르게 나오징 ㅜ

select fa.actor_id, f.film_id, f.rating
from film_actor fa 
join film f 
    on fa.film_id = f.film_id
where f.rating ='R';

select first_name , last_name 
from actor a 
where NOT exists (
            select 1
            from film_actor fa 
            inner join film f 
                on fa.film_id = f.film_id
            where fa.actor_id = a.actor_id /*메인 쿼리 데이터*/ 
            and f.rating ='R'
            );
            
            
/*영화 배우를 조회 . 영화 배우 ID, 영화 배우명(first_name, last_name) 
 * 단, 정렬 조건은 영화 배우가 출연한 영화수로 내림차순 정렬이 되도록하고, 정렬 조건은 sub query로 작성할 것. 
*/
select ac.actor_id , ac.first_name , ac.last_name , a.cnt
from (
        select fa.actor_id, count(*) AS cnt
        from film_actor fa 
        group by fa.actor_id
    ) a
JOIN actor ac
ON a.actor_id = ac.ACTOR_ID
ORDER BY 4 DESC;


/* 고객정보(first/last_name, 도시명), 총 대여 지불 금액, 총 대여 횟수를 조회하는 SQL 작성 */
SELECT c.CUSTOMER_ID , c.FIRST_NAME , c.LAST_NAME , c2.CITY , a.amt AS "총 대여 지불 금액", a.cnt AS "총 대여 횟수"
    FROM (
            SELECT p.CUSTOMER_ID, sum(p.amount) amt, count(*) cnt
                FROM PAYMENT P 
                JOIN RENTAL R 
                ON p.customer_id = r.customer_id
            GROUP BY p.CUSTOMER_ID 
        ) a
    JOIN CUSTOMER C 
    ON a.customer_id = c.CUSTOMER_ID 
    JOIN ADDRESS AD
    ON c.ADDRESS_ID = ad.ADDRESS_ID 
    JOIN CITY C2 
    ON ad.CITY_ID = c2.CITY_ID ;



SELECT p.CUSTOMER_ID , p.PAYMENT_ID , p.RENTAL_ID , p.AMOUNT 
    , r.RENTAL_DATE 
    FROM PAYMENT P 
    JOIN rental r
    ON p.RENTAL_ID = r.RENTAL_ID 
-- GROUP BY p.CUSTOMER_ID;


SELECT p.CUSTOMER_ID, sum(p.amount) amt, count(*) cnt
    FROM PAYMENT P 
    JOIN RENTAL R 
    ON p.CUSTOMER_ID = r.CUSTOMER_ID 
GROUP BY p.CUSTOMER_ID 

SELECT p.CUSTOMER_ID , p.RENTAL_ID , p.AMOUNT , sum(amount) OVER()
-- SELECT count(*) -- 1024
    FROM PAYMENT P 
    JOIN RENTAL R 
    ON p.customer_id = r.customer_id
WHERE r.CUSTOMER_ID = 1;

-- SELECT count(*)  -- 32
SELECT *
FROM PAYMENT P 
WHERE CUSTOMER_ID = 1;  

-- SELECT count(*) -- 32
SELECT *
FROM RENTAL R 
WHERE CUSTOMER_ID = 1; 

