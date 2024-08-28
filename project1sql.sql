create database projects;
use projects;
select * from salaries;

/* 1. You are a compensation analyst employed by a multinational corporation .Your Assignment is to Pinpoint
countries who give work fully remotely,for the title 'managers'
paying salaries exceeding $90,000 USD */ 

select distinct company_location from salaries where job_title like '%Manager%' and salary_in_usd >90000 and remote_ratio = 100;

/* So Us and FR are the only countries provide these facilities */

/* 2. As a remote work advocate working for a progressive HR tech startup who place their freshers' clients In large tech firms .you are
tasked With identifying top 5 country having greatest count of large (company size ) number of companies */

-- ist method
select company_location ,count(*) as 'country' from
(
select * from salaries
where experience_level ='EN' and company_size = 'L' 
)t group by company_location order by country desc limit 5;

-- 2nd method
select company_location ,count(company_size) as cnt from
salaries where experience_level ='EN' and company_size = 'L' 
group by company_location order by cnt desc limit 5;

/* 3. Picture yourself as a data scientist working for a workforce management platform. Your objective is to calculate the percentage 
of employees. Who enjoy fully remote roles with salaries exceeding $100,000 USD ,shedding light on the attractiveness of high-paying 
remote positions IN today's job market */

-- ist method
set @count = (select count(*) from salaries where salary_in_usd >100000);
select remote_ratio , (count(*)/@count)*100 as percent from (
select * from salaries where salary_in_usd >100000)t
group by remote_ratio having remote_ratio =100 order by count(*) desc;

-- 2nd method
set @total = (select count(*) from salaries where salary_in_usd >100000);
set @count  = (select count(*) from salaries where salary_in_usd >100000 and remote_ratio =100);
set @percentage= ((select @count)/(select @total))*100;
select @percentage as 'Percentage' ;

/* 4. Imagine you 're a data analyst working for a global recruitment agency.Your Task is to identify the locations where
average salaries exceed the average salary for that job title in market for entry level,helping your agency guide candidates
towards lucrative opportunities. */

select t.job_title,t.Avg_salary ,company_location,s.Avg_salary_per_country from (
select job_title , avg(salary_in_usd) as Avg_salary from salaries group by 
job_title )t join 
(select company_location , job_title , avg(salary_in_usd) as Avg_salary_per_country from salaries group by 
job_title , company_location )s on t.job_title = s.job_title 
where Avg_salary  < Avg_salary_per_country;

/* 5. You 've been hired by a big hr consultancy to look at how much people get paid in different countries .Your job is to find for
each job title which country pays the maximum average salary .This helps you to place your candidates in  those countries. */

select * from
(
select * ,dense_rank() over(partition by job_title order by avg desc) as 'rank_country' from
(select company_location,job_title ,  avg(salary_in_usd) as 'avg' from salaries group by 
company_location , job_title )t 
)s where rank_country = 1;

/* 6. As a data driven consultant , you've been hired by a multinational corporation to analyze salary trends across different company
locations .Your goal is to pinpoint location where average salary has consistently increased over the past few years (country where
data is available for 3 years only (present year and past two years ) providing insights into locations experiencing sustained salary
growth . */ 

with cte as(
select * from salaries where company_location in
(
select company_location from(
select company_location,  avg(salary_in_usd),count(distinct work_year) as 'cnt' from salaries where work_year >= (year(current_date())-2) group by 
company_location having cnt=3
)t
)
)
select company_location , 
MAX(CASE WHEN work_year = 2022 THEN average END ) as avg_salary_2022,
MAX(CASE WHEN work_year = 2023 THEN average END ) as avg_salary_2023,
MAX(CASE WHEN work_year = 2024 THEN average END ) as avg_salary_2024
from (
select company_location ,work_year,avg(salary_in_usd) as 'average'from cte group by company_location ,work_year 
)t group by company_location having avg_salary_2024 > avg_salary_2023 and avg_salary_2023 > avg_salary_2022;

/*7. Picture yourself as a workforce strategist employed by a global HR tech startup .Your mission is to determine the percentage of fully
 remote work for each experience level in 2021 and comapre it with the corresponding figures for 2024 ,highligtening any significant 
 increases or decreases in remote work adoption over the years */
 
select * from (
 select * , ((cnt)/(total))*100 as 'remote_2021 'from (
 select t.experience_level,total,cnt from 
 (select experience_level ,count(*) as 'total' from salaries where work_year=2021 group by experience_level)t
 inner join 
 (
 select experience_level , count(*) 'cnt' from salaries where remote_ratio = 100 and work_year = 2021 group by experience_level)s
 on t.experience_level = s.experience_level
 )b
 
 )r inner join 
 (
 select * , ((cnt)/(total))*100 as 'remote_2024 'from (
 select t.experience_level,total,cnt from 
 (select experience_level ,count(*) as 'total' from salaries where work_year=2024 group by experience_level)t
 inner join 
 (
 select experience_level , count(*) 'cnt' from salaries where remote_ratio = 100 and work_year = 2024 group by experience_level)s
 on t.experience_level = s.experience_level
 )b
 )k on
 r.experience_level = k.experience_level;
 
 /* 8. As a Compensation specialist at a fortune 500 company , you're tasked with analyzing salary trends over time .Your objective 
 is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024 , helping 
 the company stay competitive in the talent market */
 
-- ist method
 select t.experience_level , t.job_title , avg_2023 ,avg_2024 , (((avg_2024 - avg_2023) / avg_2023 )*100) as 'change' from
 (select experience_level ,job_title ,avg(salary_in_usd) as 'avg_2023' from salaries where work_year=2023 group by experience_level,job_title
 )t inner join
(
select experience_level ,job_title ,avg(salary_in_usd) as 'avg_2024' from salaries where work_year=2024 group by experience_level,job_title
)s on
t.experience_level = s.experience_level and t.job_title = s.job_title ;

-- 2nd method
WITH t AS
(
SELECT experience_level, job_title ,work_year, round(AVG(salary_in_usd),2) AS 'average'  FROM salaries WHERE work_year IN (2023,2024) GROUP BY experience_level, job_title, work_year
)  -- step 1


SELECT *,round((((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100),2)  AS changes
FROM
(
	SELECT 
		experience_level, job_title,
		MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023,
		MAX(CASE WHEN work_year = 2024 THEN average END) AS AVG_salary_2024
	FROM  t GROUP BY experience_level , job_title -- step 2
)a WHERE (((AVG_salary_2024-AVG_salary_2023)/AVG_salary_2023)*100)  IS NOT NULL -- STEP 3

/* 9.	You are working with an consultancy firm, your client comes to you with certain data and preferences such as 
( their year of experience , their employment type, company location and company size )  and want to make an transaction into different domain in data industry
(like  a person is working as a data analyst and want to move to some other domain such as data science or data engineering etc.)
your work is to  guide them to which domain they should switch to base on  the input they provided, so that they can now update thier knowledge as  per the suggestion/.. 
The Suggestion should be based on average salary.*/

DELIMITER //
create PROCEDURE GetAverageSalary(IN exp_lev VARCHAR(2), IN emp_type VARCHAR(3), IN comp_loc VARCHAR(2), IN comp_size VARCHAR(2))
BEGIN
    SELECT job_title, experience_level, company_location, company_size, employment_type, ROUND(AVG(salary), 2) AS avg_salary 
    FROM salaries 
    WHERE experience_level = exp_lev AND company_location = comp_loc AND company_size = comp_size AND employment_type = emp_type 
    GROUP BY experience_level, employment_type, company_location, company_size, job_title order by avg_salary desc ;
END//
DELIMITER ;
-- Deliminator  By doing this, you're telling MySQL that statements within the block should be parsed as a single unit until the custom delimiter is encountered.

call GetAverageSalary('EN','FT','AU','M');

/*10.As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. Your Task is to know 
how many people were employed IN different types of companies AS per their size IN 2021.*/

SELECT company_size, COUNT(company_size) AS 'COUNT of employees' 
FROM salaries 
WHERE work_year = 2021 
GROUP BY company_size;

/*11.Imagine you are a talent Acquisition specialist Working for an International recruitment agency. Your Task is to identify the top
 3 job titles that command the highest average salary Among part-time Positions IN the year 2023.*/
 
 select job_title , avg(salary_in_usd) as 'average_salary'from salaries where employment_type = 'PT'and work_year=2023 group by job_title
 order by avg(salary_in_usd) desc limit 3;
 
 /*12.As a database analyst you have been assigned the task to Select Countries where average mid-level salary is higher than overall 
 mid-level salary for the year 2023.*/
 
 SET @average = (SELECT AVG(salary_IN_usd) AS 'average' FROM salaries WHERE experience_level='MI');

SELECT company_location, AVG(salary_IN_usd) 
FROM salaries 
WHERE experience_level = 'MI' AND salary_IN_usd > @average 
GROUP BY company_location;

/*13.As a database analyst you have been assigned the task to Identify the company locations with the highest and lowest average salary 
for senior-level (SE) employees in 2023.*/

select company_location , Max(salary_in_usd) as 'Max_salary'
,Min(salary_in_usd) as 'Min_salary'
from salaries
where experience_level ='SE' and
work_year=2023 
group by company_location ;

-- 2nd method 

DELIMITER //

CREATE PROCEDURE GetSeniorSalaryStats()
BEGIN
    -- Query to find the highest average salary for senior-level employees in 2023
    SELECT company_location AS highest_location, AVG(salary_in_usd) AS highest_avg_salary
    FROM  salaries
    WHERE work_year = 2023 AND experience_level = 'SE'
    GROUP BY company_location
    ORDER BY highest_avg_salary DESC
    LIMIT 1;

    -- Query to find the lowest average salary for senior-level employees in 2023
    SELECT company_location AS lowest_location, AVG(salary_in_usd) AS lowest_avg_salary
    FROM  salaries
    WHERE work_year = 2023 AND experience_level = 'SE'
    GROUP BY company_location
    ORDER BY lowest_avg_salary ASC
    LIMIT 1;
END //

-- Reset the delimiter back to semicolon
DELIMITER ;

-- Call the stored procedure to get the results
CALL GetSeniorSalaryStats();

/*14. You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the annual salary growth rate for 
various job titles. By Calculating the percentage Increase IN salary FROM previous year to this year, you aim to provide valuable 
Insights Into salary trends WITHIN different job roles.*/

with cte as
(
select t.job_title ,Avg_salary_2023 , Avg_salary_2024 from 
(
select job_title ,  avg(salary_in_usd) as 'Avg_salary_2023'  from salaries where work_year=2023 group by job_title
)t inner join
(
select job_title ,  avg(salary_in_usd) as 'Avg_salary_2024'  from salaries where work_year=2024 group by job_title
)s
on t.job_title = s.job_title 
)

SELECT *, ROUND((((Avg_salary_2024-Avg_salary_2023)/Avg_salary_2023)*100),2) AS 'percentage_change' FROM cte;

/*15. You've been hired by a global HR Consultancy to identify Countries experiencing significant salary growth for entry-level roles. 
Your task is to list the top three Countries with the highest salary growth rate FROM 2020 to 2023, helping multinational Corporations 
identify  Emerging talent markets.*/

with cte as (
select company_location ,work_year , avg(salary_in_usd)as 'average' from salaries where experience_level ='EN' and work_year in (2020,2023) 
group by company_location ,work_year )

SELECT *, (((AVG_salary_2023 - AVG_salary_2020) / AVG_salary_2020) * 100) AS changes
FROM
(SELECT company_location,MAX(CASE WHEN work_year = 2020 THEN average END) AS AVG_salary_2020,
        MAX(CASE WHEN work_year = 2023 THEN average END) AS AVG_salary_2023
    FROM cte GROUP BY company_location
) a 
WHERE (((AVG_salary_2023 - AVG_salary_2020) / AVG_salary_2020) * 100) IS NOT NULL  
ORDER BY 
    (((AVG_salary_2023 - AVG_salary_2020) / AVG_salary_2020) * 100) DESC 
    limit 3 ;
    
    
/* 16.Picture yourself as a data architect responsible for database management. Companies in US and AU(Australia) decided to create a 
hybrid model for employees they decided that employees earning salaries exceeding $90000 USD, will be given work from home. You now
need to update the remote work ratio for eligible employees,ensuring efficient remote work management while implementing appropriate 
error handling mechanisms for invalid input parameters.*/

create  table temp  as select * from   salaries; 
SET SQL_SAFE_UPDATES = 0;
update temp set remote_ratio = 100 where (company_location = 'AU' OR company_location ='US')AND salary_in_usd > 90000;
select * from temp where (company_location = 'AU' OR company_location ='US')AND salary_in_usd > 90000;

/* 17. In year 2024, due to increase demand in data industry , there was  increase in salaries of data field employees.
                   Entry Level-35%  of the salary.
                   Mid junior – 30% of the salary.
                   Immediate senior level- 22% of the salary.
                   Expert level- 20% of the salary.
                   Director – 15% of the salary.
you have to update the salaries accordingly and update it back in the original database. */

update temp set salary_in_usd = 
case when experience_level = 'EN' then  1.35*salary_in_usd 
when experience_level = 'MI' then  1.30*salary_in_usd 
when experience_level = 'SE' then  1.22*salary_in_usd 
when experience_level = 'EX' then  1.20*salary_in_usd 
when experience_level = 'DX' then  1.15*salary_in_usd 
end 
WHERE work_year = 2024;

select * from temp;

/*18. You are a researcher and you have been assigned the task to Find the year with the highest average salary for each job title.*/
with cte as (select job_title ,work_year , avg(salary_in_usd) as 'average' from salaries group by job_title , work_year)

select * from
(
select * , rank() over (partition by job_title order by average desc ) as rank_by_salary
FROM cte
)t where rank_by_salary = 1;

    
/*19. You have been hired by a market research agency where you been assigned the task to show the percentage of different employment 
type (full time, part time) in Different job roles, in the format where each row will be job title, each column will be type of 
employment type and  cell value  for that row and column will show the % value*/

select * from salaries;
select job_title , employment_type from salaries;
select job_title , (SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) / COUNT(*))* 100 AS PT_percentage,
(SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) / COUNT(*))* 100 AS FT_percentage,
(SUM(CASE WHEN employment_type = 'CT' THEN 1 ELSE 0 END) / COUNT(*))* 100 AS CT_percentage,
(SUM(CASE WHEN employment_type = 'FL' THEN 1 ELSE 0 END) / COUNT(*))* 100 AS FL_percentage
from salaries GROUP BY job_title;




