# 4_2_Greenplum
## перенос базы в новей кластер

### 1. Пордключение к базе выполнено по адресу хоста 146.120.224.166  

### 2. Создание таблицы фактов  
_Скрипты создания таблиц в полном варианте расположены в файле init.sql_

CREATE TABLE public.fact_sales (  
	date_id bigserial NOT NULL,  
	sale_date date NOT NULL,  
	good_id int8 NOT NULL,  
	amount numeric NOT NULL -- количество товара 
)  
___--Сегментирование___  
DISTRIBUTED BY (date_id)  
___--Партицирование по дате___  
PARTITION BY RANGE(sale_date)   
          (  
          DEFAULT PARTITION def  
          );  

### 3. Создание таблицы измерений 
CREATE TABLE public.goods (  
	good_id bigserial NOT NULL,  
	good_name varchar NOT NULL,  
	price numeric NOT NULL  
)
DISTRIBUTED RANDOMLY;  
#### создана виртуальная связь таблиц фактов и измерений по полю good_id  

### 4. Таблицы заполнены данными о продаже комплектующих. Включена оптимизация.  
SET optimizer = on;  

### 5. Запрос рассчитывает сумму продаж определенного товара за определеннуй месяц.
SELECT f.good_id,   
       g.good_name,   
       EXTRACT(MONTH FROM f.sale_date) AS sale_month,  
       EXTRACT(YEAR FROM f.sale_date) AS sale_year,  
       SUM(f.amount)*g.price AS total_sum  
FROM public.fact_sales f  
   JOIN goods g ON g.good_id=f.good_id  
WHERE f.sale_date BETWEEN to_date('20220901', 'YYYYMMDD')  AND  to_date('20220930', 'YYYYMMDD')  
GROUP BY f.good_id, g.good_name, f.sale_date, g.price  
ORDER BY total_sum DESC;  

### 6. Статистика и план запроса  

Execute time (ms)	100  
Fetch time (ms)	0  
Total time (ms)	100  
Start time	2023-11-29 17:51:25.422  
Finish time	2023-11-29 17:51:25.711  

|QUERY PLAN                                                                                                                                                          |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Gather Motion 4:1  (slice3; segments: 4)  (cost=0.00..862.00 rows=1 width=40)                                                                                       |
|  ->  Result  (cost=0.00..862.00 rows=1 width=40)                                                                                                                   |
|        ->  GroupAggregate  (cost=0.00..862.00 rows=1 width=36)                                                                                                     |
|              Group Key: fact_sales.good_id, goods.good_name, fact_sales.sale_date, goods.price                                                                     |
|              ->  Sort  (cost=0.00..862.00 rows=1 width=36)                                                                                                         |
|                    Sort Key: fact_sales.good_id, goods.good_name, fact_sales.sale_date, goods.price                                                                |
|                    ->  Redistribute Motion 4:4  (slice2; segments: 4)  (cost=0.00..862.00 rows=1 width=36)                                                         |
|                          Hash Key: fact_sales.good_id, goods.good_name, fact_sales.sale_date, goods.price                                                          |
|                          ->  Result  (cost=0.00..862.00 rows=1 width=36)                                                                                           |
|                                ->  GroupAggregate  (cost=0.00..862.00 rows=1 width=36)                                                                             |
|                                      Group Key: fact_sales.good_id, goods.good_name, fact_sales.sale_date, goods.price                                             |
|                                      ->  Sort  (cost=0.00..862.00 rows=1 width=95)                                                                                 |
|                                            Sort Key: fact_sales.good_id, goods.good_name, fact_sales.sale_date, goods.price                                        |
|                                            ->  Hash Join  (cost=0.00..862.00 rows=1 width=95)                                                                      |
|                                                  Hash Cond: (goods.good_id = fact_sales.good_id)                                                                   |
|                                                  ->  Seq Scan on goods  (cost=0.00..431.00 rows=1 width=83)                                                        |
|                                                  ->  Hash  (cost=431.00..431.00 rows=1 width=20)                                                                   |
|                                                        ->  Broadcast Motion 4:4  (slice1; segments: 4)  (cost=0.00..431.00 rows=1 width=20)                        |
|                                                              ->  Sequence  (cost=0.00..431.00 rows=1 width=20)                                                     |
|                                                                    ->  Partition Selector for fact_sales (dynamic scan id: 1)  (cost=10.00..100.00 rows=25 width=4)|
|                                                                          Partitions selected: 1 (out of 1)                                                         |
|                                                                    ->  Dynamic Seq Scan on fact_sales (dynamic scan id: 1)  (cost=0.00..431.00 rows=1 width=20)    |
|                                                                          Filter: ((sale_date >= '2022-09-01'::date) AND (sale_date <= '2022-09-30'::date))         |
|Optimizer: Pivotal Optimizer (GPORCA)                                                                                                                               |
