CREATE DATABASE nhs_ae;
USE nhs_ae;


-- Create a staging table matching the CSV 
CREATE TABLE stg_ae (
    Code VARCHAR(20),
    Region VARCHAR(100),
    Name VARCHAR(255),
    Attend_Type1 INT,
    Attend_Type2 INT,
    Attend_Type3 INT,
    Attend_Total INT,
    Within4Hr_Type1 INT,
    Within4Hr_Type2 INT,
    Within4Hr_Type3 INT,
    Within4Hr_Total INT,
    Over4Hr_Type1 INT,
    Over4Hr_Type2 INT,
    Over4Hr_Type3 INT,
    Over4Hr_Total INT,
    Adm_AE_Type1 INT,
    Adm_AE_Type2 INT,
    Adm_AE_Type3 INT,
    Adm_AE_Total INT,
    Adm_Other INT,
    Adm_Total INT,
    DecisionToAdm_Wait_4to12Hr INT,
    DecisionToAdm_Wait_Over12Hr INT,
    Month VARCHAR(20),
    Year INT
);

SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/master_dataset.csv'
INTO TABLE stg_ae
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(Code, Region, Name,
 Attend_Type1, Attend_Type2, Attend_Type3, Attend_Total,
 Within4Hr_Type1, Within4Hr_Type2, Within4Hr_Type3, Within4Hr_Total,
 Over4Hr_Type1, Over4Hr_Type2, Over4Hr_Type3, Over4Hr_Total,
 Adm_AE_Type1, Adm_AE_Type2, Adm_AE_Type3, Adm_AE_Total,
 Adm_Other, Adm_Total,
 DecisionToAdm_Wait_4to12Hr, DecisionToAdm_Wait_Over12Hr,
 Month, Year);
 
 SELECT * from stg_ae LIMIT 50;

 -- Date dimension (Month + Year → a date)
CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    date_val DATE UNIQUE,
    year_val INT,
    month_num INT,
    month_name VARCHAR(20),
    year_month_str VARCHAR(7)
);

INSERT INTO dim_date (date_val, year_val, month_num, month_name, year_month_str)
SELECT DISTINCT
    STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%M-%d') AS date_val,
    Year AS year_val,
    MONTH(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%M-%d')) AS month_num,
    Month AS month_name,
    DATE_FORMAT(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%M-%d'), '%Y-%m') AS year_month_str
FROM stg_ae;

select * from dim_date;

-- Provider dimension (Code + Name + Region)
CREATE TABLE dim_provider (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,
    Code VARCHAR(20),
    Name VARCHAR(255),
    Region VARCHAR(100)
);
-- INSERT INTO dim_provider (Code, Name, Region)
-- SELECT Code, Name, Region
-- FROM stg_ae
-- GROUP BY Code,Name,Region;

INSERT INTO dim_provider (Code, Name, Region)
SELECT
    Code,
    MAX(Name)  AS Name,
    MAX(Region) AS Region
FROM stg_ae
WHERE Code IS NOT NULL
GROUP BY Code;

select * from dim_provider;

-- Fact table (one row per provider-month)

CREATE TABLE fact_ae (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id INT,
    provider_id INT,
    Attend_Type1 INT,
    Attend_Type2 INT,
    Attend_Type3 INT,
    Attend_Total INT,
    Within4Hr_Type1 INT,
    Within4Hr_Type2 INT,
    Within4Hr_Type3 INT,
    Within4Hr_Total INT,
    Over4Hr_Type1 INT,
    Over4Hr_Type2 INT,
    Over4Hr_Type3 INT,
    Over4Hr_Total INT,
    Adm_AE_Type1 INT,
    Adm_AE_Type2 INT,
    Adm_AE_Type3 INT,
    Adm_AE_Total INT,
    Adm_Other INT,
    Adm_Total INT,
    DecisionToAdm_Wait_4to12Hr INT,
    DecisionToAdm_Wait_Over12Hr INT,
    CONSTRAINT fk_fact_date FOREIGN KEY (date_id)
        REFERENCES dim_date (date_id),
    CONSTRAINT fk_fact_provider FOREIGN KEY (provider_id)
        REFERENCES dim_provider (provider_id)
);

select * from fact_ae;

INSERT INTO fact_ae (
    date_id, provider_id,
    Attend_Type1, Attend_Type2, Attend_Type3, Attend_Total,
    Within4Hr_Type1, Within4Hr_Type2, Within4Hr_Type3, Within4Hr_Total,
    Over4Hr_Type1, Over4Hr_Type2, Over4Hr_Type3, Over4Hr_Total,
    Adm_AE_Type1, Adm_AE_Type2, Adm_AE_Type3, Adm_AE_Total,
    Adm_Other, Adm_Total,
    DecisionToAdm_Wait_4to12Hr, DecisionToAdm_Wait_Over12Hr
)
SELECT
    d.date_id,
    p.provider_id,
    s.Attend_Type1, s.Attend_Type2, s.Attend_Type3, s.Attend_Total,
    s.Within4Hr_Type1, s.Within4Hr_Type2, s.Within4Hr_Type3, s.Within4Hr_Total,
    s.Over4Hr_Type1,  s.Over4Hr_Type2,  s.Over4Hr_Type3,  s.Over4Hr_Total,
    s.Adm_AE_Type1, s.Adm_AE_Type2, s.Adm_AE_Type3, s.Adm_AE_Total,
    s.Adm_Other, s.Adm_Total,
    s.DecisionToAdm_Wait_4to12Hr, s.DecisionToAdm_Wait_Over12Hr
FROM stg_ae s
JOIN dim_date d
  ON d.date_val = STR_TO_DATE(CONCAT(s.Year, '-', s.Month, '-01'), '%Y-%M-%d')
JOIN dim_provider p
  ON p.Code = s.Code;
  
select * from fact_ae limit 50;

-- Create views with useful metrics
-- 4 hour performance and admissions ratios
CREATE VIEW vw_ae_metrics AS
SELECT
    f.fact_id,
    d.date_val,
    d.year_val,
    d.month_num,
    d.month_name,
    d.year_month_str,
    p.provider_id,
    p.Code,
    p.Name,
    p.Region,
    f.Attend_Type1,
    f.Attend_Type2,
    f.Attend_Type3,
    f.Attend_Total,
    f.Within4Hr_Total,
    f.Over4Hr_Total,
    f.Adm_AE_Total,
    f.Adm_Other,
    f.Adm_Total,
    f.DecisionToAdm_Wait_4to12Hr,
    f.DecisionToAdm_Wait_Over12Hr,
    CASE
        WHEN f.Attend_Total > 0
        THEN ROUND(100.0 * f.Within4Hr_Total / f.Attend_Total, 2)
        ELSE NULL
    END AS Pct_Within4Hr,
    CASE
        WHEN f.Attend_Total > 0
        THEN ROUND(100.0 * f.Adm_AE_Total / f.Attend_Total, 2)
        ELSE NULL
    END AS Pct_Attendances_Admitted,
    CASE
        WHEN f.Adm_AE_Total > 0
        THEN ROUND(100.0 * f.DecisionToAdm_Wait_4to12Hr / f.Adm_AE_Total, 2)
        ELSE NULL
    END AS Pct_Adm_Wait_4to12Hr,
    CASE
        WHEN f.Adm_AE_Total > 0
        THEN ROUND(100.0 * f.DecisionToAdm_Wait_Over12Hr / f.Adm_AE_Total, 2)
        ELSE NULL
    END AS Pct_Adm_Wait_Over12Hr
FROM fact_ae f
JOIN dim_date d     ON f.date_id = d.date_id
JOIN dim_provider p ON f.provider_id = p.provider_id;

select * from vw_ae_metrics;

-- Time series for a single trust
SELECT
    year_month_str,
    Attend_Total,
    Pct_Within4Hr,
    Pct_Adm_Wait_4to12Hr,
    Pct_Adm_Wait_Over12Hr
FROM vw_ae_metrics
ORDER BY date_val;

-- London region monthly totals
SELECT
    year_month_str,
    SUM(Attend_Total) AS London_Attendances,
    ROUND(
        100.0 * SUM(Within4Hr_Total) / NULLIF(SUM(Attend_Total), 0),
        2
    ) AS London_Pct_Within4Hr
FROM vw_ae_metrics
WHERE Region LIKE 'NHS England London%' OR Region LIKE 'London Commissioning%'
GROUP BY year_month_str
ORDER BY year_month_str;

-- Provider table (average performance, last 12 months)
SELECT
    Name,
    Region,
    AVG(Attend_Total) AS Avg_Monthly_Attendances,
    ROUND(
        100.0 * SUM(Within4Hr_Total) / NULLIF(SUM(Attend_Total), 0),
        2
    ) AS Pct_Within4Hr_LastYear
FROM vw_ae_metrics
WHERE year_val = 2025  
GROUP BY Name, Region
HAVING SUM(Attend_Total) > 0
ORDER BY Pct_Within4Hr_LastYear DESC;

-- Volume vs performance 
SELECT 
    Name, year_month_str, Attend_Total, Pct_Within4Hr
FROM
    vw_ae_metrics;


