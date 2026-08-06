WITH first_step AS (
    -- CTE 1: Extract raw month and isolate remaining text 
	-- How this works step-by-step:
	-- instr(text_column, '/')+ 1: Finds the position right after the first slash.
	-- substr(text_column, ... ): Cuts the string from that point forward 
	-- (e.g., '23/2023').The nested 
	-- 'instr(...) - 1': Finds the position of the next slash in that new substring to know exactly where to stop cutting.
    SELECT 
        date,
        substr(date, 1, instr(date, '/') - 1) AS month,
        substr(date, instr(date, '/') + 1) AS remaining_text
    FROM layoffs_staging2
    -- %: A wildcard that matches any number of characters (including zero characters)./: Matches the literal slash character.
	-- Therefore, %/%/% means: "Match any text, followed by a slash, followed by any text, followed by a second slash, followed by any text."	
	WHERE date LIKE '%/%/%' 
),
second_step AS (
    -- CTE 2: Create columns (month, day, year) with proper padding
    SELECT 
        date,
        CASE WHEN length(month) = 1 THEN '0' || month ELSE month END AS month,
        CASE WHEN length(substr(remaining_text, 1, instr(remaining_text, '/') - 1)) = 1 
             THEN '0' || substr(remaining_text, 1, instr(remaining_text, '/') - 1) 
             ELSE substr(remaining_text, 1, instr(remaining_text, '/') - 1) 
			 
			/* First Part: Fixing the Month
			   length(month) = 1:  Checks if the month has only one character or digit.
			   '0'||month:  Adds a zero to the front of the month if it is single-digit.
			   ELSE month:  Keeps the original month if it is already two digits.
			   The =1 checks if the character length of the text before the first slash (/) is equal to one. 
			   If the length is one, it adds a leading zero to that text (turning '5' into '05'). If it is not one, it leaves the text as it is.
			   
			   Second Part: Fixing the Day 
			   substr(...):  Cuts out a piece of the remaining_text string up to the / symbol to find the day value.
			   length(...) = 1:  Checks if that day number has only one digit.
			   '0' || ...:  Adds a zero to the front if the day is a single digit.
			   ELSE ...:  Keeps the original day if it is already two digits.
		       1 removes the / to extract only the character */
			
			
        END AS day,
        substr(remaining_text, instr(remaining_text, '/') + 1) AS year
    FROM first_step
)
-- Main Query: Assemble columns using year - month - day
SELECT 
    year || '-' || month || '-' || day AS formatted_date
FROM second_step
order by formatted_date DESC

--table needs to be set up to accept new column

ALTER TABLE layoffs_staging2 
ADD COLUMN formatted_date TEXT;




UPDATE layoffs_staging2
SET formatted_date = (
    SELECT year || '-' || month || '-' || day
    FROM (
        SELECT 
            -- Step 2: Pad the month and day with zeros
            CASE WHEN length(month) = 1 THEN '0' || month ELSE month END AS month,
            CASE WHEN length(raw_day) = 1 THEN '0' || raw_day ELSE raw_day END AS day,
            substr(remaining_text, instr(remaining_text, '/') + 1) AS year
        FROM (
            -- Step 1: Break apart the string based on slashes
            SELECT 
                substr(date, 1, instr(date, '/') - 1) AS month,
                substr(date, instr(date, '/') + 1) AS remaining_text,
                substr(substr(date, instr(date, '/') + 1), 1, instr(substr(date, instr(date, '/') + 1), '/') - 1) AS raw_day
        )
    )
)
WHERE date LIKE '%/%/%';




SELECT *
from layoffs_staging2


SELECT *
from layoffs_staging2
order by total_laid_off DESC

UPDATE layoffs_staging2
SET formatted_date = 'b'
WHERE formatted_date IS " b";

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
order by funds_raised_millions desc

SELECT company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc


SELECT min(formatted_date), max(formatted_date)
from layoffs_staging2






SELECT country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc


SELECT *
from layoffs_staging2


SELECT strftime('%Y', formatted_date), sum(total_laid_off)
FROM layoffs_staging2
group by strftime('%Y', formatted_date)
order by 1 desc


SELECT year(formatted_date), sum(total_laid_off)
from layoffs_staging2
group by year(formatted_date)
order by 1 desc


SELECT company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc

SELECT substr(formatted_date,1,7) As MONTH, sum(total_laid_off) as total
from layoffs_staging2
WHERE substr(formatted_date,1,7) is not NULL
group by MONTH
order by 1 asc


with Rolling_Total AS 
(
SELECT substr(formatted_date,1,7)AS MONTH, sum(total_laid_off) as total_off
from layoffs_staging2
WHERE substr(formatted_date,1,7) is not NULL
group by MONTH
order by 1 asc
) 
SELECT MONTH, total_off
, sum(total_off) over(order by MONTH) as rolling_total
from Rolling_Total;





SELECT 	company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc





SELECT company, strftime('%Y', formatted_date),sum(total_laid_off)
from layoffs_staging2
group by company, strftime('%Y', formatted_date)
order by 3 desc







with Company_Year (company, years, total_laid_off) AS 
(
SELECT company, strftime('%Y', formatted_date),sum(total_laid_off)
from layoffs_staging2
group by company, strftime('%Y', formatted_date)
order by 3 desc
), company_year_rank AS (
SELECT *, dense_rank() over(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
where years is not null
)
SELECT *
FROM Company_Year_Rank
where ranking <= 5
