use sales;

-- View data
select *
from dirty_cafe_sales;

-- (1) check for duplicates using transaction id
with cte as (select *,
row_number() over(partition by `Transaction ID`) as rep
from dirty_cafe_sales)

select *
from cte
where rep = 2;

-- (2) fix total spent column
select *, cast(`Price Per Unit`* Quantity as decimal(10,1)) as Total_Spent_New
from dirty_cafe_sales;

-- allows us to update data
set sql_safe_updates = 0;

start transaction;

update dirty_cafe_sales
set `Total Spent` = cast(`Price Per Unit`* Quantity as decimal(10,1))
where `Total Spent` = "ERROR" or `Total Spent` = "UNKNOWN" or `Total Spent` = "" or `Total Spent` is null ;

commit;

-- (3) fix Item column
select distinct Item
from dirty_cafe_sales;

start transaction;

update dirty_cafe_sales
set Item = "UNKNOWN"
where Item = "ERROR" or Item = "UNKNOWN" or Item = "" or Item is null ;

commit;

-- (4) Fix payment method
select distinct `Payment Method`
from dirty_cafe_sales;

start transaction;

update dirty_cafe_sales
set `Payment Method` = "UNKNOWN"
where `Payment Method` = "ERROR" or `Payment Method` = "UNKNOWN" or `Payment Method` = "" or `Payment Method` is null ;

commit;

-- (4) Fix location
select distinct Location
from dirty_cafe_sales;

start transaction;

update dirty_cafe_sales
set Location = "UNKNOWN"
where Location = "ERROR" or Location = "UNKNOWN" or Location = "" or Location is null ;

commit;

-- (5) Fix Transaction date
select distinct `Transaction Date`
from dirty_cafe_sales;

start transaction;

update dirty_cafe_sales
set `Transaction Date` = "UNKNOWN"
where `Transaction Date` = "ERROR" or `Transaction Date` = "UNKNOWN" or `Transaction Date` = "" or `Transaction Date` is null ;

commit;

select *
from dirty_cafe_sales;


-- ANALYSIS
-- (1) Most and least popular items and how much revenue each product brought in
select Item, count(Item) as Count, sum(`Total Spent`) as Total_Spent_Per_Product
from dirty_cafe_sales
group by Item
order by Count, Total_Spent_Per_Product DESC;

-- (2) Total Revenue
select sum(`Total Spent`) as Total_Revenue
from dirty_cafe_sales;

-- (3) Total Revenue per month
with cte as (select sum(`Total Spent`) as Revenue, month(`Transaction Date`) as mnth
			from dirty_cafe_sales
			group by mnth)

select Revenue, ifnull(mnth, "UNKNOWN") as mnth2
from cte
order by Revenue desc;

-- (4) Revenue by Location
select Location, sum(`Total Spent`) as Total_Revenue, count(Item) as Count
from dirty_cafe_sales
group by Location;

-- (5) Number of items solds aand revenue on each day of the week
-- This will tell us which days are busy and slow
-- dayofweek is to get the index, then we will use case when statement
with cte as (select *,
					case when dayofweek(`Transaction Date`) = 1 then'Sunday'
						 when dayofweek(`Transaction Date`) = 2 then 'Monday'
						 when dayofweek(`Transaction Date`) = 3 then 'Tuesday'
						 when dayofweek(`Transaction Date`) = 4 then 'Wednesday'
						 when dayofweek(`Transaction Date`) = 5 then 'Thursday'
						 when dayofweek(`Transaction Date`) = 6 then 'Friday'
						 when dayofweek(`Transaction Date`) = 7 then'Saturday'
						 else 'UNKNOWN' end as 'Day'
               
				from dirty_cafe_sales)
                
select Day, sum(`Total Spent`) as Total_Revenue, count(Item) as Count
from cte
group by Day
order by Total_Revenue desc;                