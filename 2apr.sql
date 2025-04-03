--Added my top 3 movies
--I didn't add last_update column because as shown in film DDL, it has a constraint of default now()

begin;

insert into public.film(title, language_id, rental_duration, rental_rate)
select new_movies.title, l.language_id, new_movies.rental_duration, new_movies.rental_rate
from (
	values ('INCEPTION', 'English', 1, 4.99),
		('TOURIST', 'English', 2, 9.99),
		('THE BOY IN THE STRIPED PYJAMAS', 'English', 3, 19.99)
) as new_movies(title, language_name, rental_duration, rental_rate)
JOIN public.language l ON l.name = new_movies.language_name
where not exists (
	select 1 from public.film f where f.title = new_movies.title
)
returning film_id, title, language_id, rental_rate, rental_duration;

commit;

rollback;

--Added actor names to actor table
--I didn't add last_update column because as shown in actor DDL, it has a constraint of default now()
begin;

insert into public.actor(first_name, last_name)
select new_actors.first_name, new_actors.last_name
from (
	values ('LEONARDO', 'DICAPRIO'),
			('CILLIAN', 'MURPHY'),
			('JOHNNY', 'DEPP'),
			('ANGELINA', 'JOLIE'),
			('VERA', 'FARMIGA'),
			('ASA', 'BUTTERFIELD')
) as new_actors(first_name, last_name)
where not exists (
	select 1 from public.actor a where lower(a.first_name) = lower(new_actors.first_name) 
	and lower(a.last_name) = lower(new_actors.last_name) 
)
returning actor_id, first_name, last_name;

commit;

rollback;

--Added actors' names and film_ids to film_actor
--I didn't add last_update column because as shown in film_actor DDL, it has a constraint of default now()
begin;

insert into public.film_actor (actor_id, film_id)
select a.actor_id, f.film_id
from public.actor a
join public.film f on f.film_id in (
    select film_id from public.film where title in (
        select distinct title from public.film_actor fa
        join public.film on fa.film_id = film.film_id
    )
)
where not exists (
    select 1 from public.film_actor fa 
    where fa.actor_id = a.actor_id 
      and fa.film_id = f.film_id
)
returning actor_id, film_id;

commit; 

rollback;

--Added favourite movies to inventory table
--I didn't add last_update column because as shown in inventory DDL, it has a constraint of default now()
--here I assumed store_id to be 1
begin;    
  
insert into public.inventory (film_id, store_id)
select f.film_id, 1
from public.film f
where exists (
	select 1 from public.film_actor fa
	where fa.film_id = f.film_id
)
and not exists (
    select 1 from public.inventory i 
    where i.film_id = f.film_id and i.store_id = 1
)
returning inventory_id, film_id, store_id;

commit;

rollback;

--introduced 2 CTEs rental_count and payment_count and found a customer with 43 payment and rental records each by joining rental and payment to customer
--Updated the designated customer with my personal details and assigned a random existing address
begin;

with designated_customer as(
	select 
		c.customer_id, 
		c.first_name, 
		c.last_name, 
		r.rental_id, 
		count(r.rental_id) as rental_count, 
		count(p.payment_id) as payment_count
	from 
		public.customer c
	join 
		public.rental r on c.customer_id = r.customer_id
	join 
		public.payment p on r.rental_id = p.rental_id
	group by 
		c.customer_id, r.rental_id, c.first_name, c.last_name
	having 
		count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by 
		rental_count, payment_count
	limit 1
)
update public.customer
set first_name = lower('MADINA'),
    last_name = lower('BALTAYEVA'),
    email = lower('MADINA.BLTV@gmail.com'),
    address_id = (select address_id from address order by random() limit 1)
where customer_id in (select customer_id
					from designated_customer)
returning customer_id, first_name, last_name, email, address_id; 

commit;

rollback;

--checked the updated customer
select * 
from public.customer
where customer_id = 401

--removed records related to me as a customer from payment table
begin;

with designated_customer as(
	select 
		c.customer_id, 
		c.first_name, 
		c.last_name, 
		r.rental_id, 
		count(r.rental_id) as rental_count, 
		count(p.payment_id) as payment_count
	from 
		public.customer c
	join 
		public.rental r on c.customer_id = r.customer_id
	join 
		public.payment p on c.customer_id = p.customer_id
	group by 
		c.customer_id, r.rental_id, c.first_name, c.last_name
	having 
		count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by 
		rental_count, payment_count
	limit 1
)
delete from public.payment a
where a.customer_id in (select customer_id
					from designated_customer);

commit;

select*
from customer
where customer.customer_id = 110

with designated_customer as(
	select 
		c.customer_id, 
		c.first_name, 
		c.last_name, 
		r.rental_id, 
		count(r.rental_id) as rental_count, 
		count(p.payment_id) as payment_count
	from 
		public.customer c
	join 
		public.rental r on c.customer_id = r.customer_id
	join 
		public.payment p on c.customer_id = p.customer_id
	group by 
		c.customer_id, r.rental_id, c.first_name, c.last_name
	having 
		count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by 
		rental_count, payment_count
	limit 1
)
select*
from payment p 
where p.customer_id = (select customer_id from designated_customer);

with designated_customer as(
	select 
		c.customer_id, 
		c.first_name, 
		c.last_name, 
		r.rental_id, 
		count(r.rental_id) as rental_count, 
		count(p.payment_id) as payment_count
	from 
		public.customer c
	join 
		public.rental r on c.customer_id = r.customer_id
	join 
		public.payment p on c.customer_id = p.customer_id
	group by 
		c.customer_id, r.rental_id, c.first_name, c.last_name
	having 
		count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by 
		rental_count, payment_count
	limit 1
)
delete from payment_p2017_01 
where customer_id in (select customer_id
					from designated_customer);



--removed records related to me as a customer from rental table
begin;

with designated_customer as(
	select 
		c.customer_id, 
		c.first_name, 
		c.last_name, 
		r.rental_id, 
		count(r.rental_id) as rental_count, 
		count(p.payment_id) as payment_count
	from 
		public.customer c
	join 
		public.rental r on c.customer_id = r.customer_id
	join 
		public.payment p on c.customer_id = p.customer_id
	group by 
		c.customer_id, r.rental_id, c.first_name, c.last_name
	having 
		count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by 
		rental_count, payment_count
	limit 1
)
delete from public.rental
where customer_id in (select customer_id
					from designated_customer);

commit;

select*
from customer
where customer_id = 401

select*
from

select 
	c.customer_id, 
	c.first_name, 
	c.last_name, 
	r.rental_id, 
	count(r.rental_id) as rental_count, 
	count(p.payment_id) as payment_count
from 
	public.customer c
join 
	public.rental r on c.customer_id = r.customer_id
join 
	public.payment p on c.customer_id = p.customer_id
group by 
	c.customer_id, r.rental_id, c.first_name, c.last_name
having 
	count(r.rental_id) >= 43 and count(p.payment_id) >= 43
order by 
	rental_count, payment_count
limit 1


select*
from customer 
where customer_id = 401

update customer set first_name = upper('Brian'), last_name = upper('Wyman')
where customer_id = 318;

update customer set email = 'BRIAN.WYMAN@sakilacustomer.org'
where customer_id = 318;