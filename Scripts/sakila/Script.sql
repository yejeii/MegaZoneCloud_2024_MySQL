-- New script in sakila.
-- Date: 2024. 6. 13.
-- Time: 오전 11:46:30
-- Site : https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html#function_date

/* ----------------------- Date and Time Functions ------------------------ */

-- selects all rows with a RETURN_DATE value from within the last 20 years
-- DATE_SUB(날짜, interval day/month/year) : 날짜에서 시간 값(간격) 빼기
-- CURDATE() : 현재 날짜 반환
SELECT *
    FROM RENTAL R 
WHERE DATE_SUB(CURDATE(), INTERVAL 20 YEAR) <= RETURN_DATE; 

-- “zero” dates or incomplete dates such as '2001-11-00' 
-- return 0
SELECT DAYOFMONTH('2001-11-00'), MONTH('2005-00-00');

-- expect complete dates and return NULL for incomplete dates
-- DATE_ADD(날짜, interval day/month/year) : 날짜 값에 시간 값(interval) 추가
-- ADDDATE(날짜, interval day/month/year) 와 동일
SELECT DATE_ADD('2006-05-00', INTERVAL 1 DAY);
SELECT DAYNAME('2006-05-54'); 

SELECT DATE_ADD('2008-01-02', INTERVAL 31 DAY); 
SELECT ADDDATE('2008-01-02', INTERVAL 31 DAY); 

-- ADDTIME(expr1,expr2)
SELECT ADDTIME('2007-12-31 23:59:59.999999', '1 1:1:1.000002');
SELECT ADDTIME('01:00:00.999999', '02:00:00.999998');



