SET LANGUAGE hrvatski
DECLARE @start DATE=DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
DECLARE @end DATE=DATEFROMPARTS(YEAR(GETDATE()), 12, 31);

DECLARE @datumi TABLE (
    Dat DATE PRIMARY KEY,
    [Dan u godini] INT,
    [Dan u tjednu] NVARCHAR(20),
    [Radni dan] NVARCHAR(20)
);

INSERT INTO @datumi (Dat, [Dan u godini], [Dan u tjednu], [Radni dan])
SELECT
    Dat,
    ROW_NUMBER() OVER (ORDER BY Dat),
    DATENAME(weekday, Dat),
    CASE
        WHEN Dat IN ( --prilagoditi zbog pomiènih blagdana
            '2023/01/01', '2023/01/06', '2023/04/09', '2023/04/10', '2023/05/01',
            '2023/05/30', '2023/06/08', '2023/06/22', '2023/08/05', '2023/08/15',
            '2023/11/01', '2023/11/18', '2023/12/25', '2023/12/26'
        ) THEN 'praznik'
        WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
        ELSE 'RADNI DAN'
    END
FROM (
    SELECT TOP (DATEDIFF(day, @start, @end) + 1) Dat=DATEADD(day, ROW_NUMBER() OVER (ORDER BY a.object_id) - 1, @start)
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
) d;

SELECT
    Datum=CONVERT(varchar, Dat, 104) + '.'
    , [Dan u godini]
    , [Dan u tjednu]
    , [Radni dan]
    , [Radni dan u godini]=
		CASE
			WHEN [Radni dan]='RADNI DAN' THEN CONVERT(NVARCHAR, ROW_NUMBER() OVER (PARTITION BY [Radni dan] ORDER BY Dat))
			ELSE 'neradan'
		END
	, [Radni dan u mjesecu]=
		CASE
			WHEN [Radni dan]='RADNI DAN' THEN CONVERT(NVARCHAR, ROW_NUMBER() 
				OVER (PARTITION BY [Radni dan], month(dat) ORDER BY Dat))
			ELSE 'neradan'
		END
FROM @datumi
ORDER BY Dat;