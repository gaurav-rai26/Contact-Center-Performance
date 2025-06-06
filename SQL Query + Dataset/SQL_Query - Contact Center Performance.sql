-- Database Creation

create database Contact_Center;

-- Imported CSV using Table Import Wizard

-- Using Database

use Contact_Center;

-- Viewing Tables - contact_raw, query and channel

select *
from contact_raw; -- main dataset

select *
from query; -- types of query (contact reason)

select *
from channel; -- channel used

-- Joining Tables - contact_raw, query and channel

select *
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID;

-- C-Sat Score for each Channel


   -- Using CTE


select cn.Channel_Name, round(avg(nullif(cr.csat_score, '')),2) as Average_C_Sat
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID
group by cn.Channel_Name
order by Average_C_Sat;  -- Without CTE


-- % of calls resolved Within SLA for each query type

select q.query_type as Query_Type, (count(cr.id)/(select count(*) from contact_raw))*100 as Call_Percentage
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID
where response_time = 'Within SLA'
group by q.query_type;


select 
  q.query_type as Query_Type, 
  round(count(*) * 100.0 / (select count(*) from contact_raw), 2) as Call_Percentage
from contact_raw cr
left join query q on cr.reason = q.Query_ID
where cr.response_time = 'Within SLA'
group by q.query_type;


-- average CSAT per channel per sentiment

select cn.Channel_Name as Channel_Name, cr.sentiment as Sentiment, round(avg(nullif(cr.csat_score, '')),2) as Average_CSat
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID
group by cn.Channel_Name, cr.sentiment
order by Average_CSat desc; 


 -- channel with the highest number of contacts for each day.
 
select call_timestamp, channel_name, number_of_contacts
from
(
select cr.call_timestamp, cn.channel_name, count(id) as number_of_contacts, dense_rank() over(partition by cr.call_timestamp order by count(id) desc) as ranking
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID
group by cr.call_timestamp, cn.channel_name
) as contact_table
where ranking = 1;

-- number of ‘Very Negative’ sentiment contacts per call center

select call_center as Contact_Center, count(id) as Number_of_Contacts
from contact_raw
where sentiment = 'Very Negative'
group by Contact_Center
order by Number_of_Contacts desc;


-- average call duration for each query type

ALTER TABLE contact_raw
CHANGE `call duration in minutes` call_duration_minutes INT; -- changed column name

select q.Query_Type as Query_Type, round(avg(cr.call_duration_minutes),2) as Avg_Call_Duration
from contact_raw cr left join query q
on cr.reason = q.Query_ID 
group by Query_Type
order by Avg_Call_Duration;

-- Average Contact Duration by Channel

select cn.Channel_Name as Channel_Name, round(avg(cr.call_duration_minutes),2) as Avg_Contact_Duration
from contact_raw cr left join query q
on cr.reason = q.Query_ID left join channel cn
on cr.channel_id = cn.Channel_ID
group by Channel_Name
order by Avg_Contact_Duration;


--  Number of Contacts per Response_Time (SLA) per Channel

select cn.Channel_Name, cr.response_time as SLA, count(*) as Number_of_Contacts
from contact_raw cr left join channel cn
on cr.channel_id = cn.Channel_ID
group by cn.Channel_Name, cr.response_time
order by cr.response_time;
