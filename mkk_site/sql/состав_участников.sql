with 
tourist_nums as (
  select num, unnest(unit_neim) as tourist_num from pohod
),
tourist_info as (
select tourist_nums.num, tourist_num, family_name, given_name, patronymic, birth_year from tourist_nums
  join tourist 
   on tourist_num = tourist.num
),
U as (
select num, string_agg(
  family_name||' '||given_name||' '||patronymic||', '||birth_year::text, '<br>') as gr
from tourist_info
group by num
)
select num, 'title="'||gr||'"' from U
