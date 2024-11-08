-- SUBMISSION BY: SARAN ARUL YOGAN
-- PROJECT: CHINOOK MUSIC
-- SKILL USED: MYSQL WORKBENCH
-- BATCH: DATA SCIENCE COURSE JULY 2024

select * from employee;
select * from customer;
select * from invoice;
select * from invoice_line;
select * from track;
select * from genre;
select * from playlist;
select * from playlist_track;
select * from album;
select * from artist;
select * from media_type;
use chinook;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------OBJECTIVE QUESTIONS----------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q1. Does any table have missing values or duplicates? If yes how would you handle it ?

-- Checking for Null Values in employee table -- --
select * 
from employee
where last_name is null 
   or first_name is null 
   or title is null 
   or reports_to is null 
   or birthdate is null 
   or hire_date is null 
   or address is null 
   or city is null 
   or state is null 
   or country is null 
   or postal_code is null 
   or phone is null 
   or fax is null 
   or email is null;
-- -- Handling Null Values -- --
select 
	employee_id, 
	coalesce(reports_to, 'N/A') as reports_to 
from employee;
-- -- Checking for Null Values in customer table-- --
select *
from customer
where 
    first_name is null or 
    last_name is null or
	company is null or
    address is null or
    city is null or
	state is null or
    country is null or
    postal_code is null or
    phone is null or
	fax is null or
    email is null or
    support_rep_id is null;
-- -- Handling Null Values -- --     
select 
	customer_id,
    first_name,
    last_name,
    coalesce(company,'N/A') AS company,
    address,
    city,
    coalesce(state,'Unknown') AS state,
    country,
    coalesce(postal_code,'N/A') as postal_code,
    coalesce(phone,'Not Provided') as phone,
    coalesce(fax,'N/A')AS fax,
    email,
    support_rep_id
from customer;
-- -- Checking for Null Values in track table-- --
select * 
from track 
where  
	name is null or 
    album_id is null or
    media_type_id is null or
    genre_id is null or 
    composer is null or 
    milliseconds is null or
    bytes is null or 
    unit_price is null;
-- -- Handling Null Values -- --
select
	track_id,
	name,
    album_id,
    media_type_id,
    genre_id,
    coalesce(composer,'N/A') as composer,
    milliseconds,
    bytes,
    unit_price
from track;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.	Find the top-selling tracks and top artist in the USA and identify their most famous genres.

-- --The top-selling tracks in USA-- 
select 
	t.track_id,
	t.name as track_name,
	sum(il.quantity) as Top_Selling_quantity
from track as t 
join invoice_line as il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
where c.country = 'USA'
group by t.name,t.track_id
order by Top_Selling_quantity desc
limit 15;

-- --Top artist in the USA--
select 
	ar.artist_id,
	ar.name as artist_name,
	sum(il.quantity) as total_quantity_sold
from track as t
join album al on t.album_id = al.album_id
join artist ar on al.artist_id = ar.artist_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
where c.country = 'USA'
group by ar.artist_id,artist_name
order by total_quantity_sold desc
limit 1;

-- --Most Famous Genres of the Top Artist -- --	
select
	g.genre_id,
    g.name as genre,
    sum(il.quantity) as total_quantity_sold
from track t 
join genre g on t.genre_id = g.genre_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on i.customer_id = c.customer_id
join album al on t.album_id = al.album_id
join artist ar on al.artist_id = ar.artist_id
where c.country ='USA' and ar.artist_id = (
											select artist_id 
                                            from(
													select 
														ar.artist_id,
														sum(il.quantity) over(partition by ar.artist_id) as total_quantity_sold
													from track as t
													join album al on t.album_id = al.album_id
													join artist ar on al.artist_id = ar.artist_id
													join invoice_line il on t.track_id = il.track_id
													join invoice i on il.invoice_id = i.invoice_id
													join customer c on i.customer_id = c.customer_id
													where c.country = 'USA'
													order by total_quantity_sold desc
													limit 1
												) as famous_artist
                                            ) 
group by g.genre_id,genre
order by total_quantity_sold desc
limit 15;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.	What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?

select 
	country,
    coalesce(state,'Not Available') as state,
    city,
    count(customer_id) as total_customer
from customer
group by country,state,city
order by country,state,city;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.	Calculate the total revenue and number of invoices for each country, state, and city:

select
	c.country,
    coalesce(c.state,'Not Available') as state,
    c.city,
    sum(i.total) as total_revenue,
    count(i.invoice_id) as number_of_invoice
from customer as c
join invoice i on c.customer_id = i.customer_id
group by c.country,state,c.city
order by total_revenue desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5.	Find the top 5 customers by total revenue in each country

with country_wise_revenue as(
	select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
		c.country,
        sum(i.total) as total_revenue
	from customer as c
    join invoice as i on c.customer_id = i.customer_id
    group by c.country,c.customer_id,customer_name
),
top_customers as(
select 
	customer_id,
    customer_name,
    country,
    total_revenue,
    rank() over(partition by country order by total_revenue desc) as ranking
from country_wise_revenue
order by country
)
select 
	customer_id,
    customer_name,
    country,
    total_revenue
from top_customers
where ranking <= 5
order by country,ranking;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6.	Identify the top-selling track for each customer

with total_track_customer as (
	select 
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        sum(il.quantity) as total_quantity
	from customer as c 
    join invoice i on c.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    group by c.customer_id,customer_name
),
 top_track_customer as (
	select 
		ttc.customer_id,
        ttc.customer_name,
        ttc.total_quantity,
        row_number() over(partition by ttc.customer_id order by ttc.total_quantity desc) as top_rank,
        t.track_id,
        t.name as track_name
	from total_track_customer ttc
    join invoice i on ttc.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    join track t on il.track_id = t.track_id
)
select
	customer_id,
    customer_name,
    track_name,
    total_quantity
from top_track_customer
where top_rank = 1
order by customer_id;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7.	Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?

-- -- Frequency of Purchases -- --
select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    year(i.invoice_date) as year,
    count(i.invoice_id) as purchase_count
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id,customer_name,year
order by c.customer_id,year desc;

-- -- Calculate the Average order value of each customer -----
select
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    round(avg(i.total),2) average_order_value
from customer c 
join invoice i on c.customer_id = i.customer_id
group by c.customer_id
order by average_order_value desc;

-- -- Calculate the total revenue generated by each customer -- --
select 
	c.customer_id,
    concat(c.first_name,' ',c.last_name) as customer_name,
    sum(i.total) as total_revenue
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id,customer_name
order by total_revenue desc; 
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8.	What is the customer churn rate?

with Churn_checking_date as (
	select
		date_sub(recent_date,interval 1 year) as checking_date
	from (
			select
				max(invoice_date) as recent_date
			from invoice
		) as checking
),
churn_customer as (
	select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        max(i.invoice_date) as customer_last_date
	from customer as c
    join invoice as i on c.customer_id = i.customer_id
    group by c.customer_id,customer_name	
    having max(i.invoice_date) is null or max(i.invoice_date) < (
																select * from churn_checking_date
                                                                )
)
select 
	(select count(*) from churn_customer)/(select count(*) from customer)*100 as churn_rate;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9.	Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
-- -- The percentage of total sales contributed by each genre in the USA
with genre_wise_contribution_in_USA as (
	select
		sum(il.quantity*t.unit_price) as sales,
        g.name as genre_name
	from invoice_line as il
    join track as t on il.track_id = t.track_id
    join genre as g on t.genre_id = g.genre_id
    join invoice as i on il.invoice_id = i.invoice_id
    join customer as c on i.customer_id = c.customer_id
    where c.country = 'USA'
    group by genre_name
    order by sales desc
    ),
each_genre_contributed_percentage as (
	select 
		sum(sales) as total_sales
	from genre_wise_contribution_in_USA
    )
select 
	genre_name,
    sales,
    round(sales/(select * from each_genre_contributed_percentage)*100,2) as percentage_of_genre
from genre_wise_contribution_in_USA ;

-- --The best-selling genres and artists
with selling_count as (
	select
		sum(il.quantity*t.unit_price) as sales,
        g.name as genre_name,
        a.name as artist_name
	from invoice_line as il
    join track as t on il.track_id = t.track_id
    join genre as g on t.genre_id = g.genre_id
    join invoice as i on il.invoice_id = i.invoice_id
    join customer as c on i.customer_id = c.customer_id
    join album as al on t.album_id = al.album_id
    join artist as a on al.artist_id = a.artist_id
    where c.country = 'USA'
    group by genre_name,artist_name
    order by sales desc
    )
    
    select 
        genre_name,
        artist_name,
        sales,
        dense_rank() over(partition by genre_name order by sales desc) as artist_rank
	from selling_count;
 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
-- 10. Find customers who have purchased tracks from at least 3 different genres    
    
    select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        count(distinct g.genre_id) as genre_count
	from customer as c
    join invoice i on c.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    join track as t on il.track_id = t.track_id
    join genre as g on t.genre_id = g.genre_id
	group by c.customer_id,customer_name
    having genre_count >=3
    order by genre_count desc;
 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
-- 11.	Rank genres based on their sales performance in the USA
    
    with SalesPerformance as (
    select
		g.name as genre_name,
        sum(il.quantity * t.unit_price) as Sales_Performance
	from track t 
    join invoice_line il on t.track_id = il.track_id
    join invoice i on il.invoice_id = i.invoice_id
    join customer c on i.customer_id = c.customer_id
    join genre g on t.genre_id = g.genre_id
    where c.country = "USA"
    group by genre_name
    order by Sales_Performance desc
    )
    select 
		genre_name,
        Sales_Performance,
        dense_rank() over(order by Sales_Performance desc) as Ranking 
	from SalesPerformance;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------    
-- Q12. Identify customers who have not made a purchase in the last 3 months --

		select 
			distinct c.customer_id,
            concat(c.first_name,' ',c.last_name) as customer_name
		from customer c 
        join invoice i on c.customer_id = i.customer_id
        where i.invoice_date <= curdate() - interval 3 month
        order by c.customer_id;
	
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------SUBJECTIVE QUESTIONS---------------------------------------------------------------------------------- --
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.	Recommend the three albums from the new record label that should be 
-- prioritised for advertising and promotion in the USA based on genre sales analysis.
    
	select
		g.name as genre_name,
		al.title as new_record_lable,
		sum(il.quantity * t.unit_price) Sales_Analysis,
		dense_rank() over(order by sum(il.quantity * t.unit_price) desc) as ranking
	from track t 
	join album al on t.album_id = al.album_id
	join invoice_line il on t.track_id = il.track_id
	join invoice i on il.invoice_id = i.invoice_id
	join customer c on i.customer_id = c.customer_id
	join genre g on t.genre_id = g.genre_id
	where c.country = "USA"
	group by genre_name,al.title
	order by ranking
    limit 3;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
-- Q2. Determine the top-selling genres in countries other than the USA 
-- and identify any commonalities or differences ?

-- The top-selling genres in countries other than the USA
	select
		g.name as genre_name,
        sum(il.quantity) as total_Quantity_Sold
	from track t
    join invoice_line il on t.track_id = il.track_id
    join invoice i on il.invoice_id = i.invoice_id
    join customer c on i.customer_id = c.customer_id
    join genre g on t.genre_id = g.genre_id
    where c.country <> "USA"
    group by genre_name
    order by total_Quantity_Sold desc;

-- Commonalities or differences between USA and other country 
	with USA as (
		select
			g.genre_id,
			g.name as genre_name,
			sum(il.quantity) as total_Quantity_Sold
		from track t
		join invoice_line il on t.track_id = il.track_id
		join invoice i on il.invoice_id = i.invoice_id
		join customer c on i.customer_id = c.customer_id
		join genre g on t.genre_id = g.genre_id
		where c.country = "USA"
		group by g.genre_id,genre_name
		order by total_Quantity_Sold desc
        ),
	Not_USA as (
		select
			g.genre_id,
			g.name as genre_name,
			sum(il.quantity) as total_Quantity_Sold
		from track t
		join invoice_line il on t.track_id = il.track_id
		join invoice i on il.invoice_id = i.invoice_id
		join customer c on i.customer_id = c.customer_id
		join genre g on t.genre_id = g.genre_id
		where c.country <> "USA"
		group by g.genre_id,genre_name
		order by total_Quantity_Sold desc
        )
	select 
		a.genre_id,
		a.genre_name,
		sum(a.Total_Quantity_Sold + b.Total_Quantity_Sold) over(partition by a.genre_id) as Each_genre_total,
        round(a.Total_Quantity_Sold /sum(a.Total_Quantity_Sold + b.Total_Quantity_Sold) over(partition by a.genre_id)*100,2) as USA_Percentage,
        round(b.Total_Quantity_Sold /sum(a.Total_Quantity_Sold + b.Total_Quantity_Sold) over(partition by a.genre_id)*100,2) as NON_USA_Percentage
        from USA a
        join Not_USA b on a.genre_id = b.genre_id
        order by Each_genre_total desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------        
-- 3.	Customer Purchasing Behavior Analysis:
--  	How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers?
-- 		What insights can these patterns provide about customer loyalty and retention strategies?

with customerPurchaseStats as (
	select 
		c.customer_id,
        count(il.invoice_id) as purchase_frequency,
        sum(il.quantity) as total_item_purchased,
        sum(i.total) as total_amount_spend,
        avg(i.total) as Avg_amount_spend,
        datediff(max(i.invoice_date),min(i.invoice_date)) as customer_tenure_days
	from customer c 
    join invoice i on c.customer_id = i.customer_id
    join invoice_line il on i.invoice_id = il.invoice_id
    group by c.customer_id
),
CustomerSegment as (
	select
		customer_id,
        purchase_frequency,
        total_item_purchased,
        total_amount_spend,
        Avg_amount_spend,
        customer_tenure_days,
        case
			when customer_tenure_days < 365 then 'New' else 'Long_Term' end
		as customer_segment
	from customerPurchaseStats
)
select
	customer_segment,
    round(avg(purchase_frequency),2) as avg_purchase_frequency,
    round(avg(total_item_purchased),2) as avg_basket_size,
    round(avg(total_amount_spend),2) as avg_spending_amount,
    round(avg(Avg_amount_spend),2) as avg_order_value
from CustomerSegment
group by customer_segment;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.	Product Affinity Analysis:
--      Which music genres, artists, or albums are frequently purchased together by customers?
-- 		How can this information guide product recommendations and cross-selling initiatives?
    
-- (i) Genre Affinity Analysis
with track_combination as(
	select
		il1.track_id as track1,
        il2.track_id as track2,
        count(*) time_purchased_together
	from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
    group by track1,track2
),
genre_combination as (
	select 
		t1.genre_id as genre_id_1,
        t2.genre_id as genre_id_2,
        count(*) times_purchased_together
	from track_combination tc 
    join track t1 on tc.track1 = t1.track_id
    join track t2 on tc.track2  = t2.track_id
    where t1.genre_id <>  t2.genre_id
    group by t1.genre_id,t2.genre_id
)
select
	g1.name as genre_1,
    g2.name as genre_2,
    gc.times_purchased_together
from genre_combination gc
join genre g1 on gc.genre_id_1 = g1.genre_id
join genre g2 on gc.genre_id_2 = g2.genre_id
order by gc.times_purchased_together desc;

-- (ii) Artist Affinity Analysis --
with track_combination as(
	select
		il1.track_id as track1,
        il2.track_id as track2,
        count(*) time_purchased_together
	from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
    group by track1,track2
),
artist_combination as (
	select
		a1.artist_id as artist1,
        a2.artist_id as artist2,
        count(*) as time_purchased_together
	from track_combination tc
    join track t1 on tc.track1 = t1.track_id
    join album al1 on t1.album_id = al1.album_id
    join artist a1 on al1.artist_id = a1.artist_id
    join track t2 on tc.track2 = t2.track_id
    join album al2 on t2.album_id = al2.album_id
    join artist a2 on al2.artist_id = a2.artist_id
    where a1.artist_id <> a2.artist_id
    group by a1.artist_id,a2.artist_id
)
select 
	a1.name as artist_name,
    a2.name as artist_name,
    ac.time_purchased_together
from artist_combination ac
join artist a1 on ac.artist1 = a1.artist_id
join artist a2 on ac.artist2 = a2.artist_id
order by ac.time_purchased_together desc;

-- (iii) Album Affinity Analysis --

with track_combination as(
	select
		il1.track_id as track1,
        il2.track_id as track2,
        count(*) time_purchased_together
	from invoice_line il1
    join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
    group by track1,track2
),
album_combination as (
	select
		al1.album_id as album_1,
        al2.album_id as album_2,
        count(*) as time_purchased_together
    from track_combination tc
    join track t1 on tc.track1 = t1.track_id
    join album al1 on t1.album_id = al1.album_id
    join track t2 on tc.track2 = t2.track_id
    join album al2 on t2.album_id = al2.album_id
    where al1.album_id <> al2.album_id
    group by al1.album_id,al2.album_id
)

select
	al1.title as album_name,
    al2.title as album_name,
    ac.time_purchased_together
from album_combination ac
join album al1 on ac.album_1 = al1.album_id
join album al2 on ac.album_2 = al2.album_id
order by ac.time_purchased_together desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q5.	Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different 
-- 		geographic regions or store locations? How might these correlate with local demographic or economic factors?

-- Customer purchasing behaviors by region 
	
	with purchase_frequency as (
		select
			c.customer_id,
            count(i.invoice_id) as total_purchase_frequency,
            sum(i.total) as total_Spending,
            avg(i.total) as avg_order_value
		from invoice i 
        join customer c on i.customer_id = c.customer_id
        group by c.customer_id
	),
    customer_region as (
		select
			c.customer_id,
            c.country,
            coalesce(c.state,'Not Available') as state,
            c.city,
            pf.total_purchase_frequency,
            pf.total_Spending,
            pf.avg_order_value
		from customer c 
        join  purchase_frequency pf on c.customer_id = pf.customer_id
	)
	select
		country,
		state,
		city,
		round(count(distinct customer_id),2) as total_Customer,
        round(sum(total_purchase_frequency),2) as total_purchase,
        round(sum(total_Spending),2) as total_spending,
        round(avg(avg_order_value),2) as avg_order_value,
        round(avg(total_spending),2) as avg_purchase_frequency
	from customer_region
    group by country,state,city
    order by total_spending desc;
    
    -- -- Churn Rate by Region -- --
    
    with region_churn_rate as (
		select 
			c.customer_id,
            c.country,
            coalesce(c.state,"Not Available") as state,
            c.city,
            max(i.invoice_date) as latest_date_purchased
		from customer c 
        join invoice i on c.customer_id = i.customer_id
        group by c.customer_id,c.country,state,c.city
	),
    churn_customer as (
		select
			country,
			state,
			city,
            count(customer_id) as churn_customer
		from region_churn_rate        
        where latest_date_purchased < date_sub(curdate() , interval 1 year)
        group by country,state,city
	)
    select
		cc.country,
        cc.state,
        cc.city,
        cc.churn_customer,
        count(c.customer_id) as total_customer,
        cc.churn_customer/count(c.customer_id)*100 as churn_rate
	from churn_customer cc
    join customer c on cc.country = c.country and cc.state = c.state and cc.city = c.city
    group by cc.country,cc.state,cc.city
    order by churn_rate desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------        
-- --   Q6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
-- 		which customer segments are more likely to churn or pose a higher risk of reduced spending? 
-- 		What factors contribute to this risk?

with customer_profile as (
	select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        c.country,
        coalesce(c.state,"Not Available") as state,
        c.city,
        max(i.invoice_date) as last_purchase_date,
        count(i.invoice_id) as purchase_frequency,
        sum(i.total) as total_spending,
        avg(i.total) as avg_order_value,
        case 
			when max(i.invoice_date) < date_sub(curdate(),interval 1 year) then 'High Rick'
			when sum(i.total) < 100 then 'Medium Risk'
            Else 'Low Risk'
		end as risk_profile
    from customer c 
    join invoice i on c.customer_id = i.customer_id
    group by c.customer_id,customer_name,c.country,state,c.city
	order by total_spending desc
),
risk_summary as (
	select
		country,state,city,risk_profile,
        count(customer_id) as num_customer,
        round(avg(total_spending),2) as avg_total_spending,
        round(avg(purchase_frequency),2) as avg_purchase_frequency,
        round(avg(avg_order_value),2) as avg_order_value
	from customer_profile
    group by country,state,city,risk_profile
)
select * 
from risk_summary
order by risk_profile,avg_total_spending desc;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 	Q7. Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement) 
-- 	to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. 
-- 	Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
    
with customer_lifeStyle_analysis as (
	select
		c.customer_id,
        concat(c.first_name,' ',c.last_name) as customer_name,
        c.country,
        coalesce(c.state,'Not Available')as state,
        c.city,
        min(i.invoice_date) as first_purchase_date,
        max(i.invoice_date) as last_purchse_date,
        datediff(max(i.invoice_date),min(i.invoice_date)) as customer_tenure_days,
        count(i.invoice_id) as total_purchase,
        sum(i.total) as total_spending,
        avg(i.total) as avg_order_value,
        case 
			when max(i.invoice_date) < date_sub(curdate(),interval 1 year) then 'Churn' else 'Active' 
		end as status,
        case
			when datediff(max(i.invoice_date),min(i.invoice_date)) >= 365 then 'Long term' else 'short term'
		end as customer_segment,
		sum(i.total)/greatest(datediff(max(i.invoice_date),min(i.invoice_date)),1)* 365 as predicted_annual_value,
        sum(i.total) as lifetime_value
	from customer c
    join invoice i on c.customer_id = i.customer_id
    group by customer_id
),

segment_analysis as (
	select
		customer_segment,
        customer_status,
        count(customer_id) as num_customer,
        avg(customer_tenure_days) as avg_tenure_days,
        avg(total_spending) as avg_lifetime_value,
        avg(predicted_annual_value) as avg_predicted_annual_value
	from customer_lifeStyle_analysis 
    group by customer_segment,customer_status
),

churn_analysis as (
	select
		country,
        state,city,
        customer_segment,
        count(customer_id) churned_customer,
        avg(total_spending) avg_lifetime_value
	from customer_lifeStyle_analysis
    where status = 'churn'
    group by country,state,city,customer_segment
)
-- To get customer lifeStyle analysis
select * from customer_lifeStyle_analysis;

-- To get customer Segment analysis
select * from segment_analysis;

-- To get Customer churn analysis
select * from churn_analysis;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q8. 	If data on promotional campaigns (discounts, events, email marketing) is available, 
-- 		how could you measure their impact on customer acquisition, retention, and overall sales?
-- --   Answered in Word File
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q9. 	How would you approach this problem, if the objective and subjective questions weren't given?
-- -- 	Answered in Word File
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q10. How can you alter the "Albums" table to add a new column named 
-- "ReleaseYear" of type INTEGER to store the release year of each album?

alter table album
add column releaseyear int;

select * from album;

update album
set releaseyear = 2017
where album_id = 1;

update album
set releaseyear = 2017
where album_id = 2;

update album
set releaseyear = 2017
where album_id = 3;

update album
set releaseyear = 2017
where album_id = 4;

update album
set releaseyear = 2017
where album_id = 5;

update album
set releaseyear = 2018
where album_id = 6;

update album
set releaseyear = 2018
where album_id = 7;

update album
set releaseyear = 2018
where album_id = 8;

update album
set releaseyear = 2018
where album_id = 9;

update album
set releaseyear = 2018
where album_id = 10;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q11. Chinook is interested in understanding the purchasing behaviour of customers based on their geographical location. 
-- 		They want to know the average total amount spent by customers from each country, 
-- 		along with the number of customers and the average number of tracks purchased per customer. 
-- 		Write an SQL query to provide this information.

with tracks_per_customer as (
    select 
        i.customer_id,
        sum(il.quantity) as total_tracks
    from invoice i
    join invoice_line il on i.invoice_id = il.invoice_id
    group by i.customer_id
),
customer_spending as (
    select 
        c.country,
        c.customer_id,
        sum(i.total) as total_spent,
        tpc.total_tracks
    from customer c
    join invoice i on c.customer_id = i.customer_id
    join tracks_per_customer tpc on c.customer_id = tpc.customer_id
    group by c.country, c.customer_id, tpc.total_tracks
)
select 
    cs.country,
    count(distinct cs.customer_id) as number_of_customers,
    round(avg(cs.total_spent), 2) as average_amount_spent_per_customer,
    round(avg(cs.total_tracks), 2) as average_tracks_purchased_per_customer
from customer_spending cs
group by cs.country
order by average_amount_spent_per_customer desc;
-- --------------------------------------------------------------------------------END----------------------------------------------------------------------------------------------------------