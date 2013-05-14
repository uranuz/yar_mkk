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

	   select pohod.num, (coalesce(kod_mkk,'')||'<br>'||coalesce(nomer_knigi,'')) as nomer_knigi,    
      (coalesce(begin_date::text,'')||'<br>'||coalesce(finish_date::text,'')) as date ,   
      ( coalesce( vid::text, '' )||'<br>'|| coalesce( ks::text, '' )||coalesce( element::text, '' ) ) as vid, 

      region_pohod , 
      (tourist.family_name||'<br>'||coalesce(tourist.given_name,'')||'<br>'||coalesce(tourist.patronymic,'')||'<br>'||coalesce(tourist.birth_year::text,'')),  
      (pohod.unit||'title="'||coalesce(gr,'')||'"'||'>'||pohod.unit),  
     
      (coalesce(organization,'')||'<br>'||coalesce(region_group,'')), 
      (coalesce(marchrut,'')||'<br>'||coalesce(chef_coment,'')), 
      (coalesce(prepare::text,'')||'<br>'||coalesce(status::text,''))   
      from pohod 
      JOIN tourist  
      on pohod.chef_grupp = tourist.num
      join U
      on U.num = pohod.num
                         