SET LANGUAGE hrvatski;
GO

CREATE OR ALTER FUNCTION dbo.VratiDatumUskrsa (@godina INT) -- function from: https://medium.com/@diangermishuizen/calculate-easter-sunday-dynamically-using-sql-447235cb8906
RETURNS DATE
AS
BEGIN
    DECLARE @varA TINYINT, @varB TINYINT, @varC TINYINT, @varD TINYINT, @varE TINYINT, @varF TINYINT, @varG TINYINT
		  , @varH TINYINT, @varI TINYINT, @varK TINYINT, @varL TINYINT, @varM TINYINT,  @datumUskrsa DATE;    
	SELECT @varA = @godina % 19, @varB = FLOOR(1.0 * @godina / 100), @varC = @godina % 100;
    SELECT @varD = FLOOR(1.0 * @varB / 4), @varE = @varB % 4, @varF = FLOOR((8.0 + @varB) / 25);
    SELECT  @varG = FLOOR((1.0 + @varB - @varF) / 3);
    SELECT @varH = (19 * @varA + @varB - @varD - @varG + 15) % 30, @varI = FLOOR(1.0 * @varC / 4), @varK = @godina % 4;
    SELECT  @varL = (32.0 + 2 * @varE + 2 * @varI - @varH - @varK) % 7;
    SELECT @varM = FLOOR((1.0 * @varA + 11 * @varH + 22 * @varL) / 451);
    SELECT  @datumUskrsa = DATEADD(dd, (@varH + @varL - 7 * @varM + 114) % 31, DATEADD(mm, FLOOR((1.0 * @varH + @varL - 7 * @varM + 114) / 31) - 1, DATEADD(yy, @godina - 2000, {d '2000-01-01' })));
    RETURN @datumUskrsa;
END;
GO
DECLARE @start DATE=dateadd(year, datediff(year, 0, getdate()), 0);
DECLARE @end DATE=dateadd(year, datediff(year, 0, getdate()), 364);

--NEPOMIČNI PRAZNICI
DECLARE
	@NovaGodina date = DATEFROMPARTS(YEAR(GETDATE()), 1, 1),
	@SvetaTriKralja date = DATEFROMPARTS(YEAR(GETDATE()), 1, 6),
	@PraznikRada date = DATEFROMPARTS(YEAR(GETDATE()), 5, 1),
	@DanDržavnosti date = DATEFROMPARTS(YEAR(GETDATE()), 5, 30),
	@DanAntifaBorbe date = DATEFROMPARTS(YEAR(GETDATE()), 6, 22),
	@DanPobjede date = DATEFROMPARTS(YEAR(GETDATE()), 8, 5),
	@VelikaGospa date = DATEFROMPARTS(YEAR(GETDATE()), 8, 15),
	@SviSveti date = DATEFROMPARTS(YEAR(GETDATE()), 11, 1),
	@DanSjecanjaNaVukovar date = DATEFROMPARTS(YEAR(GETDATE()), 11, 18),
	@Bozic date = DATEFROMPARTS(YEAR(GETDATE()), 12, 25),
	@SvetiStjepan date = DATEFROMPARTS(YEAR(GETDATE()), 12, 26);

--POMIČNI PRAZNICI
DECLARE 
	@Uskrs date;
	SELECT @Uskrs= dbo.VratiDatumUskrsa(YEAR(GETDATE()));
DECLARE
	@UskrsniPonedjeljak date = dateadd(day, 1, @Uskrs),
	@Tijelovo date = dateadd(day, 60, @Uskrs);

DECLARE @datumi TABLE (
    Dat DATE PRIMARY KEY,
    [Dan u godini] INT,
    [Dan u tjednu] NVARCHAR(20),
    [Radni dan] NVARCHAR(20),
	ObracunskiDan NVARCHAR(20)
);

INSERT INTO @datumi (Dat, [Dan u godini], [Dan u tjednu], [Radni dan], ObracunskiDan)
SELECT
    Dat
    , ROW_NUMBER() OVER (ORDER BY Dat)
    , DATENAME(weekday, Dat)
	, CASE
        WHEN Dat IN (@NovaGodina, @SvetaTriKralja, @Uskrs, @UskrsniPonedjeljak,
						@PraznikRada, @DanDržavnosti,@Tijelovo, @DanAntifaBorbe, @DanPobjede, @VelikaGospa,
						@SviSveti, @DanSjecanjaNaVukovar, @Bozic, @SvetiStjepan
        ) THEN 'praznik'
        WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
        ELSE 'RADNI DAN'
    END
	, ObracunskiDan=
	 CASE
     	WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
     	ELSE 'obračunski dan'
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
    --, [Radni dan]
	--, ObracunskiDan
    , [Obračunski dan u godini]=
        CASE
        	WHEN ObracunskiDan='obračunski dan' THEN CONVERT(nvarchar, ROW_NUMBER() OVER (PARTITION BY ObracunskiDan ORDER BY Dat))
        	ELSE 'vikend'
        END
	, [Radni dan u godini]=
		CASE
			WHEN [Radni dan]='RADNI DAN' THEN CONVERT(NVARCHAR, ROW_NUMBER() OVER (PARTITION BY [Radni dan] ORDER BY Dat))
			WHEN [Radni dan]='praznik' THEN 'praznik'
			ELSE 'vikend'
		END
	, [Obračunski dan u mjesecu]=
		CASE
			WHEN ObracunskiDan='obračunski dan' THEN CONVERT(nvarchar, ROW_NUMBER() OVER (PARTITION BY ObracunskiDan, MONTH(dat) ORDER BY Dat))
			ELSE 'vikend'
		END
	, [Radni dan u mjesecu]=
		CASE
			WHEN [Radni dan]='RADNI DAN' THEN CONVERT(NVARCHAR, ROW_NUMBER() 
				OVER (PARTITION BY [Radni dan], month(dat) ORDER BY Dat))
			WHEN [Radni dan]='praznik' THEN 'praznik'
			ELSE 'vikend'
		END
FROM @datumi
ORDER BY Dat;
