DELETE FROM film_actor WHERE film_id = 1002;

DELETE FROM film_actor WHERE film_id = 1003;

DELETE FROM film_actor WHERE film_id = 1004;

delete from payment_p2017_02 pp 
where rental_id in (32295, 32296, 32297);

delete from rental 
where inventory_id in (4585, 4586, 4587);

delete from inventory 
where film_id in (1002, 1003, 1004);

delete from film 
where title in ('INCEPTION', 'TOURIST', 'THE BOY IN THE STRIPED PYJAMAS');






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
JOIN language l ON l.name = new_movies.language_name
where not exists (
	select 1 from film f where f.title = new_movies.title
)
returning film_id, title, language_id, rental_rate, rental_duration;

commit;

--Added actor names to actor table
----I didn't add last_update column because as shown in actor DDL, it has a constraint of default now()
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
	select 1 from actor a where lower(a.first_name) = lower(new_actors.first_name) 
	and lower(a.last_name) = lower(new_actors.last_name) 
)
returning actor_id, first_name, last_name;

commit;
		
--Added actors' names and film_ids to film_actor
----I didn't add last_update column because as shown in film_actor DDL, it has a constraint of default now()
begin;

insert into public.film_actor (actor_id, film_id)
select a.actor_id, f.film_id
from actor a
join film f on f.film_id in (
    select film_id from film where title in (
        select distinct title from film_actor fa
        join film on fa.film_id = film.film_id
    )
)
where not exists (
    select 1 from film_actor fa 
    where fa.actor_id = a.actor_id 
      and fa.film_id = f.film_id
)
returning actor_id, film_id;

commit; 

--Added favourite movies to inventory table
----I didn't add last_update column because as shown in inventory DDL, it has a constraint of default now()
--here I assumed store_id to be 1
begin;    
  
insert into public.inventory (film_id, store_id)
select f.film_id, 1
from film f
where exists (
	select 1 from film_actor fa
	where fa.film_id = f.film_id
)
and not exists (
    select 1 from inventory i 
    where i.film_id = f.film_id and i.store_id = 1
)
returning inventory_id, film_id, store_id;

commit;

--introduced cte, in which found a customer with 43 payment and rental records each by joining rental and payment to customer
--Updated the designated customer with my personal details and assigned a random existing address
begin;

with designated_customer as(
	select c.customer_id, c.first_name, c.last_name, 
	count(r.rental_id) as rental_count, 
	count(p.payment_id) as payment_count
	from customer c
	join rental r on c.customer_id = r.customer_id
	join payment p on c.customer_id = p.customer_id
	group by c.customer_id, c.first_name, c.last_name
	having count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by rental_count, payment_count
	limit 1
)
update public.customer
set first_name = 'MADINA',
    last_name = 'BALTAYEVA',
    email = 'MADINA.BLTV@gmail.com',
    address_id = (select address_id from address order by random() limit 1)
where customer_id in (select customer_id
					from designated_customer)
returning customer_id, first_name, last_name, email, address_id; 

commit; 

--checked the updated customer
select customer_id from customer
where first_name = 'MADINA' and last_name = 'BALTAYEVA';

--removed records related to me as a customer from payment table
begin;

with designated_customer as(
	select c.customer_id, c.first_name, c.last_name, 
	count(r.rental_id) as rental_count, 
	count(p.payment_id) as payment_count
	from customer c
	join rental r on c.customer_id = r.customer_id
	join payment p on c.customer_id = p.customer_id
	group by c.customer_id, c.first_name, c.last_name
	having count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by rental_count, payment_count
	limit 1
)
delete from public.payment
where customer_id in (select customer_id
					from designated_customer);

commit;

--removed records related to me as a customer from rental table
begin;

with designated_customer as(
	select c.customer_id, c.first_name, c.last_name, 
	count(r.rental_id) as rental_count, 
	count(p.payment_id) as payment_count
	from customer c
	join rental r on c.customer_id = r.customer_id
	join payment p on c.customer_id = p.customer_id
	group by c.customer_id, c.first_name, c.last_name
	having count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	order by rental_count, payment_count
	limit 1
)
delete from public.rental
where customer_id in (select customer_id
					from designated_customer) ;

commit;

DELETE FROM payment_p2017_01 
WHERE rental_id IN (SELECT rental_id FROM rental WHERE rental_id = 650);

SELECT * FROM rental WHERE rental_id = 650

delete from payment_p2017_01 pp 
where rental_id in (32295, 32296, 32297);

--checked the deleted customer
select * from rental where customer_id = 318;

--checked the deleted customer
select  * from payment where customer_id = 318;

--found inventory_id and store_id for my favourite movies
select i.inventory_id, i.film_id, f.title, i.store_id 
from inventory i
join film f on i.film_id = f.film_id
where f.title IN ('INCEPTION','TOURIST', 'THE BOY IN THE STRIPED PYJAMAS');

--added invented values to rental table  
insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
values 
('2017-02-01 10:00:00', (select i.inventory_id from inventory i join film f on i.film_id = f.film_id where f.title = 'INCEPTION'), 318, NULL, 1),
('2017-02-02 14:30:00', (select i.inventory_id from inventory i join film f on i.film_id = f.film_id where f.title = 'TOURIST'), 318, NULL, 1),
('2017-02-03 09:45:00', (select i.inventory_id from inventory i join film f on i.film_id = f.film_id where f.title = 'THE BOY IN THE STRIPED PYJAMAS'), 318, NULL, 1)
returning rental_id, inventory_id, customer_id;

--inserted payment records for each rental, for payment_date 
insert into public.payment (customer_id, staff_id, rental_id, amount, payment_date)
values
(318, 1, (select r.rental_id from rental r join inventory i on r.inventory_id = i.inventory_id join film f on f.film_id = i.film_id where f.title = 'INCEPTION') , 4.99, '2017-02-01 11:00:00'),
(318, 1, (select r.rental_id from rental r join inventory i on r.inventory_id = i.inventory_id join film f on f.film_id = i.film_id where f.title = 'TOURIST'), 9.99, '2017-02-02 15:00:00'),
(318, 1, (select r.rental_id from rental r join inventory i on r.inventory_id = i.inventory_id join film f on f.film_id = i.film_id where f.title = 'THE BOY IN THE STRIPED PYJAMAS'), 19.99, '2017-02-03 10:30:00')
returning customer_id, staff_id, rental_id;
