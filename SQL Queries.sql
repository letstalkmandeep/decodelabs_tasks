-- Create table

CREATE TABLE DATASET (
	ORDERID VARCHAR(50) NOT NULL,
	DATE DATE,
	CUSTOMERID VARCHAR(50) NOT NULL,
	PRODUCT VARCHAR(50),
	QUANTITY FLOAT,
	UNITPRICE VARCHAR(50),
	SHIPPINGADDRESS VARCHAR(50),
	PAYMENTMETHOD VARCHAR(50),
	ORDERSTATUS VARCHAR(50),
	TRACKINGNUMBER VARCHAR(50),
	ITEMSINCART INT,
	COUPONCODE VARCHAR(50),
	REFERRALSOURCE VARCHAR(50),
	TOTALPRICE FLOAT
);

select * from dataset;

-- Total Data

select
count(distinct orderid) as Total_orders,
count(distinct customerid) as Total_Customers,
count(distinct product) as total_products,
count(distinct shippingaddress) as Total_Locations,
count(distinct paymentmethod) as PaymentMethods,
count(distinct orderstatus) as StatusofOrders,
count(distinct trackingnumber) as Total_trackings,
count(distinct couponcode) as Total_Coupons,
count(distinct referralsource) as Sources,
sum(itemsincart) as Total_ItemsinCart,
sum(quantity) as Total_Quantity,
sum(totalprice) as Total_sales
from dataset;

-- Therefore, columns with unique value are Orderid and trackingnumber

-- Customer who ordered more than once

select * from(
select 
count(customerid) over(partition by customerid order by customerid) as OrdersbyCustomers,
customerid,
product,
couponcode,
referralsource,
quantity,
totalprice
from dataset
)
where OrdersbyCustomers > 1;

-- Handling Null Coupon Code

select couponcode from dataset
where couponcode is null;

update dataset
set couponcode = 'Without Coupon'
where couponcode is null;

-- Product Details

select
product,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by product
order by total_sales desc
;

-- Top 3 Products

select
product,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by product
order by total_sales desc
limit 3
;

-- AVG Unit Price of the Products

select
product,
round(avg(cast(unitprice as decimal)),2) as AVG_UnitPrice
from dataset
group by product
order by AVG_UnitPrice;

-- Payment Method Detials

select
paymentmethod,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by paymentmethod
order by total_sales desc
;

-- OrderStatus Details

select
orderstatus,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by orderstatus
order by total_sales desc
;

-- Coupon Code Details

select
couponcode,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by couponcode
order by total_sales desc
;

-- Refferal Source Details

select
referralsource,
count(orderid) as Orders,
sum(quantity) as Total_Quantity,
round(sum(cast(totalprice as decimal)),2) as Total_Sales
from dataset
group by referralsource
order by total_sales desc
;

-- Date Details
-- Sales by month

select
to_char(date,'Mon') as Month,
sum(cast(totalprice as decimal)) as Total_Sales
from dataset
group by to_char(date,'Mon')
order by Total_Sales desc;

-- Sales by Year

select
to_char(date,'YYYY') as Year,
sum(cast(totalprice as decimal)) as Total_Sales
from dataset
group by to_char(date,'YYYY')
order by Total_Sales desc;

-- Sales by Month-Year

select
to_char(date,'Mon-YY') as Month_Year,
sum(cast(totalprice as decimal)) as Total_Sales
from dataset
group by to_char(date,'Mon-YY')
order by Total_Sales desc;

-- TimeSeries analysis

select
to_char(eomonth,'Mon-YY') as Mon_Year,
current_sales,
round((current_sales-previous_sales)/previous_sales*100,2) as MoM_Change
from(
	select
	*,
	lag(current_sales) over(order by eomonth) as Previous_Sales
	from(
		select
				cast(date_trunc('month',date) + interval '1 month - 1 day' as date) as EOMONTH,
				sum(cast(totalprice as decimal)) as Current_sales
		from dataset
		group by cast(date_trunc('month',date) + interval '1 month - 1 day' as date)
	)
) order by eomonth
;

-- Comparative Analysis of Products

select
*,
concat(round(total_sales/sum(total_sales) over() *100,2),'%') as PercentageofSales,
total_sales - min(Total_sales) over() as Deviation_from_lowest,
max(Total_sales) over() - total_sales as Deviation_from_highest
from(
	select 
		product,
		sum(cast(totalprice as decimal)) as Total_Sales
	from dataset
	group by product
);

-- Categorisation of Sales

select
orderid,
date,
Product,
unitprice,
quantity,
totalprice,
case Delimeters
	when 1 then 'High'
	when 2 then 'Medium'
	else 'Low' end as Sales_category
from(
	select
		*,
		NTILE(3) over(order by totalprice desc) as Delimeters
	from dataset)
;

-- Top 20% orders

select * from(
	select
		*,
		cume_dist() over(order by totalprice desc) as PercentRank
	from dataset)
where percentrank <= 0.2;

-- Sales without any coupon

select
orderid,
date,
product,
couponcode,
unitprice,
quantity,
totalprice
from dataset
where couponcode = 'Without Coupon';


-- Sales greater than 1500

select
orderid,
date,
product,
referralsource,
unitprice,
quantity,
totalprice
from dataset
where totalprice >= 1500;