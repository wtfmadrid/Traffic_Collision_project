DECLARE @StartDate DATE = (SELECT DATEFROMPARTS(YEAR(MIN(A.DATE_EVENT)),1,1) FROM [dbo].[FCT_Traffic_Collisions] A);
DECLARE @EndDate DATE = (SELECT DATEFROMPARTS (YEAR(MAX(A.DATE_EVENT)),12,31) FROM [dbo].[FCT_Traffic_Collisions] A);
SET DATEFIRST 1;

IF EXISTS (SELECT * FROM information_schema.tables WHERE Table_Name = 'DIM_Date' and TABLE_SCHEMA='dbo') TRUNCATE TABLE dbo.DIM_Date;

ELSE
CREATE TABLE dbo.DIM_Date
(
    CalendarDate DATE,
    Year INT,
    StartOfYear VARCHAR(20),
    EndOfYear VARCHAR(20),
    Month INT,
	MonthName VARCHAR(20),
    StartOfMonth VARCHAR(20),
    EndOfMonth VARCHAR(20),
    DaysInMonth INT,
	Quarter INT,
    StartOfQuarter VARCHAR(20),
    EndOfQuarter VARCHAR(20),
    Day INT,
    DayName VARCHAR(20),
    DayOfWeek INT,
	DayOfYear INT,
	IsWeekend BIT,
	NumWeek INT
);

WHILE @StartDate <= @EndDate
BEGIN
  INSERT INTO dbo.DIM_Date (
    CalendarDate, Year, StartOfYear, EndOfYear,
    Month, MonthName, StartOfMonth, EndOfMonth, DaysInMonth,
	Quarter, StartOfQuarter, EndOfQuarter,
    Day, DayName, DayOfWeek, DayOfYear, IsWeekend, 
	NumWeek
    
  )
  VALUES (
    @StartDate, 
    YEAR(@StartDate), -- Year
    DATEFROMPARTS(YEAR(@StartDate), 1, 1), -- StartOfYear
    DATEFROMPARTS(YEAR(@StartDate), 12, 31), -- EndOfYear
    MONTH(@StartDate), -- Month
	DATENAME(MONTH, @StartDate), --MonthName
    DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1), -- StartOfMonth
    EOMONTH(@StartDate), -- EndOfMonth
    DAY(EOMONTH(@StartDate)), -- DaysInMonth
	DATEPART(QUARTER, @StartDate), -- Quarter
    CAST(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @StartDate), 0) AS DATE), -- StartOfQuarter
    EOMONTH(DATEFROMPARTS(YEAR(@StartDate), DATEPART(QUARTER, @StartDate) * 3, 1)), -- EndOfQuarter
    DAY(@StartDate), -- Day
    DATENAME(WEEKDAY, @StartDate), -- DayName
    DATEPART(weekday, @StartDate), -- DayOfWeek
    DATEPART(dayofyear, @StartDate), -- DayOfYear
	CASE
           WHEN (((DATEPART(weekday, @StartDate) - 1 ) + @@DATEFIRST ) % 7) IN (0,6)
           THEN 1
           ELSE 0
    END, -- IsWeekend
	DATEPART(week, @StartDate) -- NumWeek
  );

SET @StartDate = DATEADD(day, 1, @StartDate);
END;