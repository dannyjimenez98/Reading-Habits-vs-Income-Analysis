SELECT * FROM reading_habits;

-- Remove unused columns 
ALTER TABLE reading_habits
	DROP COLUMN Sex,
	DROP COLUMN Race, 
	DROP COLUMN `Marital status?`, 
	DROP COLUMN `Read any printed books during last 12months?`,
	DROP COLUMN `Read any audiobooks during last 12months?`,
	DROP COLUMN `Read any e-books during last 12months?`,
	DROP COLUMN `Last book you read, you...`,
	DROP COLUMN `Do you happen to read any daily news or newspapers?`,
	DROP COLUMN `Do you happen to read any magazines or journals?`;
    
SELECT DISTINCT incomes FROM reading_habits
ORDER BY incomes ASC;

-- rename columns
	-- Fix spelling error in employment column name
	-- lowercase all column names
	-- shorten  number of books read column name
ALTER TABLE reading_habits 
	CHANGE Age age int(2),
    CHANGE Education education text,
    CHANGE Employement employment text,
    CHANGE Incomes incomes text,
    CHANGE `How many books did you read during last 12months?` num_books_read int(2);
    
-- remove random "9" added before some of the "$100,000 to under $150,000" values
UPDATE reading_habits
SET incomes = SUBSTRING(incomes, 2)
WHERE incomes LIKE '9$%';

-- filters
DELETE FROM reading_habits
WHERE age < 30 OR 
	num_books_read > 30 OR
    incomes = "Refused" OR
    employment = "Student" OR
	employment = "Disabled" OR
    employment = "Not employed for pay" OR
	employment = "Other" OR
    employment = "Retired" OR
    education = "Don’t know" OR
    education = "None";
    
-- rename income ranges
UPDATE reading_habits
SET incomes = CASE 
    WHEN incomes = "Less than $10,000" THEN "Under 30k"
    WHEN incomes = "$10,000 to under $20,000" THEN "Under 30k"
    WHEN incomes = "$20,000 to under $30,000" THEN "Under 30k"
    WHEN incomes = "$30,000 to under $40,000" THEN "30k-50k"
    WHEN incomes = "$40,000 to under $50,000" THEN "30k-50k"
    WHEN incomes = "$50,000 to under $75,000" THEN "50k-75k"
    WHEN incomes = "$75,000 to under $100,000" THEN "75k-100k"
    WHEN incomes = "$100,000 to under $150,000" THEN "100k-150k"
    ELSE "0"
END;

-- rename education values to make more concise
UPDATE reading_habits
SET education = CASE 
    WHEN education = "Technical, trade or vocational school AFTER high school" THEN "Technical School"
    WHEN education = "Post-graduate training/professional school after college" THEN "Post Grad"
    WHEN education = "Some college, no 4-year degree" THEN "Some college"
    ELSE education
END;

-- drop age and employment columns, as they are no longer needed
ALTER TABLE reading_habits
	DROP COLUMN age,
	DROP COLUMN employment;
    

-- QUERIES FOR ANALYSIS --

-- get median books read for each income group
SELECT 
    incomes,
    CASE 
        WHEN COUNT(*) % 2 = 1 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', CEIL(COUNT(*) / 2)), ',', -1)
        ELSE
            (SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', COUNT(*) / 2 + 1), ',', -1) + 
             SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', COUNT(*) / 2), ',', -1)) / 2
    END AS median_num_books_read
FROM 
    reading_habits
GROUP BY 
    incomes;
    

-- get median books read for each education group
SELECT 
    education,
    CASE 
        WHEN COUNT(*) % 2 = 1 THEN 
            SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', CEIL(COUNT(*) / 2)), ',', -1)
        ELSE
            (SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', COUNT(*) / 2 + 1), ',', -1) + 
             SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(num_books_read ORDER BY num_books_read SEPARATOR ','), ',', COUNT(*) / 2), ',', -1)) / 2
    END AS median_num_books_read
FROM 
    reading_habits
GROUP BY 
    education;
    

-- income proportions by education level
SELECT
    incomes,
    ROUND(SUM(CASE WHEN education = "High school incomplete" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "High school incomplete") * 100, 1) AS hs_incomplete_incomes_pct,
    ROUND(SUM(CASE WHEN education = "High school graduate" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "High school graduate") * 100, 1) AS hs_grad_incomes_pct,
    ROUND(SUM(CASE WHEN education = "Technical School" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "Technical School") * 100, 1) AS tech_school_incomes_pct,
    ROUND(SUM(CASE WHEN education = "Some college" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "Some college") * 100, 1) AS some_college_incomes_pct,
    ROUND(SUM(CASE WHEN education = "College graduate" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "College graduate") * 100, 1) AS college_grad_incomes_pct,
    ROUND(SUM(CASE WHEN education = "Post Grad" THEN 1 ELSE 0 END) / (SELECT count(incomes) FROM reading_habits WHERE education = "Post Grad") * 100, 1) AS post_grad_incomes_pct
FROM
    reading_habits
GROUP BY
    incomes
ORDER BY CAST(SUBSTRING_INDEX(incomes, '-', 1) AS UNSIGNED);
