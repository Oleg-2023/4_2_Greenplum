-- public.fact_sales definition - factes

-- Drop table

DROP TABLE IF EXISTS public.fact_sales;

CREATE TABLE public.fact_sales (
	date_id bigserial NOT NULL,
	sale_date date NOT NULL,
	good_id int8 NOT NULL,
	amount numeric NOT NULL
)
DISTRIBUTED BY (date_id)
PARTITION BY RANGE(sale_date) 
          (
          DEFAULT PARTITION def
          );

-- public.goods definition -  dimensions

-- Drop table

DROP TABLE  IF EXISTS public.goods;

CREATE TABLE public.goods (
	good_id bigserial NOT NULL,
	good_name varchar NOT NULL,
	price numeric NOT NULL
)
DISTRIBUTED RANDOMLY;

