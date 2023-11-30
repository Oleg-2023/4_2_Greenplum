SET optimizer = on;
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


