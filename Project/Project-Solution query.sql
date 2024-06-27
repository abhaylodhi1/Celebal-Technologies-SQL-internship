--Abhay Lodhi
-- Step 1: Create the table to store results
USE Abhay;  -- Replace with your database name

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'counttotalworkinhours') AND type in (N'U'))
BEGIN
    CREATE TABLE counttotalworkinhours (
        START_DATE DATETIME,
        END_DATE DATETIME,
        NO_OF_HOURS INT
    );
END
GO

-- Step 2: Create the stored procedure to calculate working hours
IF EXISTS (SELECT * FROM sys.procedures WHERE object_id = OBJECT_ID(N'CalculateWorkingHours'))
    DROP PROCEDURE CalculateWorkingHours;
GO

CREATE PROCEDURE CalculateWorkingHours
    @StartDate DATETIME,
    @EndDate DATETIME
AS
BEGIN
    -- Temp table to hold the date range and their day numbers
    DECLARE @DateRange TABLE (
        Date DATETIME,
        DayOfWeek INT
    );

    -- Insert dates into the temp table
    DECLARE @CurrentDate DATETIME = @StartDate;
    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO @DateRange (Date, DayOfWeek)
        VALUES (@CurrentDate, DATEPART(WEEKDAY, @CurrentDate));
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END

    -- Calculate working hours excluding Sundays and 1st and 2nd Saturdays
    SELECT 
        @StartDate AS START_DATE,
        @EndDate AS END_DATE,
        SUM(CASE 
            WHEN (DATEPART(WEEKDAY, Date) = 1) OR 
                 (DATEPART(WEEKDAY, Date) = 7 AND DAY(Date) <= 14) THEN 0
            ELSE 24
        END) AS NO_OF_HOURS
    INTO #WorkingHours
    FROM @DateRange
    WHERE 
        Date NOT IN (SELECT Date FROM @DateRange WHERE (DATEPART(WEEKDAY, Date) = 1) OR 
                     (DATEPART(WEEKDAY, Date) = 7 AND DAY(Date) <= 14))
        OR Date IN (@StartDate, @EndDate);

    -- Insert the result into counttotalworkinhours table
    INSERT INTO counttotalworkinhours (START_DATE, END_DATE, NO_OF_HOURS)
    SELECT START_DATE, END_DATE, NO_OF_HOURS FROM #WorkingHours;

    -- Clean up temp table
    DROP TABLE #WorkingHours;
END;
GO

-- Step 3: Execute the stored procedure for the given sample input parameters
EXEC CalculateWorkingHours '2023-07-01', '2023-07-17';
EXEC CalculateWorkingHours '2023-07-12', '2023-07-13';

-- Step 4: Select the results from counttotalworkinhours table
SELECT * FROM counttotalworkinhours;
--LMS_ID- CT_CSI_SQ_2899