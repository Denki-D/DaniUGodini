SET LANGUAGE hrvatski;
SET LANGUAGE hrvatski;
DECLARE @start DATE=dateadd(year, datediff(year, 0, getdate()), 0);
DECLARE @end DATE=dateadd(year, datediff(year, 0, getdate()), 364);

DROP TABLE IF EXISTS #datumi;

WITH datumi(dat) AS (
      SELECT Datum=DATEADD(day, number, @start)
      FROM master..spt_values
      WHERE type = 'P' AND number <= datediff(day, @start, @end)
)
SELECT
      Dat
      , [Dan u godini]=ROW_NUMBER() OVER (ORDER BY Dat)
      , [Dan u tjednu]=DATENAME(weekday, Dat)
      , [Radni dan]=
            CASE
                  WHEN Dat IN ('2023/01/01', '2023/01/06','2023/04/09','2023/04/10'                   --prilagoditi
                  , '2023/05/01','2023/05/30', '2023/06/08', '2023/06/22', '2023/08/05','2023/08/15',
                  '2023/11/01','2023/11/18','2023/12/25','2023/12/26') THEN 'praznik'
                  WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
                  ELSE 'RADNI DAN'
            END
INTO #datumi
FROM datumi

SELECT Datum=CONVERT(varchar, Dat, 104)+'.'
      , [Dan u godini], [Dan u tjednu], [Radni dan]
      , [Radni dan u godini]=
            CASE
                  WHEN [Radni dan]='RAdni dan' THEN CONVERT(nvarchar, ROW_NUMBER() OVER (PARTITION BY [Radni dan] ORDER BY Dat))
                  ELSE 'neradan'
            END
	, [Radni dan u mjesecu]=
		CASE
			WHEN [Radni dan]='RADNI DAN' THEN CONVERT(NVARCHAR, ROW_NUMBER() 
				OVER (PARTITION BY [Radni dan], month(dat) ORDER BY Dat))
			ELSE 'neradan'
		END
FROM #datumi
order by dat


