SET LANGUAGE hrvatski;
GO
CREATE OR ALTER FUNCTION dbo.VratiDatumUskrsa (@godinaF INT)
RETURNS DATE
AS
BEGIN
    DECLARE @varA TINYINT, @varB TINYINT, @varC TINYINT, @varD TINYINT, @varE TINYINT, @varF TINYINT, @varG TINYINT
		  , @varH TINYINT, @varI TINYINT, @varK TINYINT, @varL TINYINT, @varM TINYINT,  @datumUskrsa DATE;    
	SELECT @varA = @godinaF % 19, @varB = FLOOR(1.0 * @godinaF / 100), @varC = @godinaF % 100;
    SELECT @varD = FLOOR(1.0 * @varB / 4), @varE = @varB % 4, @varF = FLOOR((8.0 + @varB) / 25);
    SELECT  @varG = FLOOR((1.0 + @varB - @varF) / 3);
    SELECT @varH = (19 * @varA + @varB - @varD - @varG + 15) % 30, @varI = FLOOR(1.0 * @varC / 4), @varK = @godinaF % 4;
    SELECT  @varL = (32.0 + 2 * @varE + 2 * @varI - @varH - @varK) % 7;
    SELECT @varM = FLOOR((1.0 * @varA + 11 * @varH + 22 * @varL) / 451);
    SELECT  @datumUskrsa = DATEADD(dd, (@varH + @varL - 7 * @varM + 114) % 31, DATEADD(mm, FLOOR((1.0 * @varH + @varL - 7 * @varM + 114) / 31) - 1, DATEADD(yy, @godinaF - 2000, {d '2000-01-01' })));
    RETURN @datumUskrsa;
END;
GO
DECLARE @start DATE=dateadd(year, datediff(year, 0, getdate()), 0);
DECLARE @end DATE=dateadd(year, datediff(year, 0, getdate()), 364);

--NEPOMIČNI PRAZNICI
DECLARE
	@NovaGodina date = DATEFROMPARTS(YEAR(getdate()), 1, 1),
	@SvetaTriKralja date = DATEFROMPARTS(YEAR(getdate()), 1, 6),
	@PraznikRada date = DATEFROMPARTS(YEAR(getdate()), 5, 1),
	@DanDržavnosti date = DATEFROMPARTS(YEAR(getdate()), 5, 30),
	@DanAntifaBorbe date = DATEFROMPARTS(YEAR(getdate()), 6, 22),
	@DanPobjede date = DATEFROMPARTS(YEAR(getdate()), 8, 5),
	@VelikaGospa date = DATEFROMPARTS(YEAR(getdate()), 8, 15),
	@SviSveti date = DATEFROMPARTS(YEAR(getdate()), 11, 1),
	@DanSjecanjaNaVukovar date = DATEFROMPARTS(YEAR(getdate()), 11, 18),
	@Bozic date = DATEFROMPARTS(YEAR(getdate()), 12, 25),
	@SvetiStjepan date = DATEFROMPARTS(YEAR(getdate()), 12, 26),
	@DanParlIzbora24 date = '2024/04/17';

--POMIČNI PRAZNICI
DECLARE 
	@Uskrs date;
	SELECT @Uskrs= dbo.VratiDatumUskrsa(YEAR(getdate()));
DECLARE
	@UskrsniPonedjeljak date = dateadd(day, 1, @Uskrs),
	@Tijelovo date = dateadd(day, 60, @Uskrs);

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
                  WHEN Dat IN (@NovaGodina, @SvetaTriKralja, @Uskrs, @UskrsniPonedjeljak,
						@PraznikRada, @DanDržavnosti,@Tijelovo, @DanAntifaBorbe, @DanPobjede, @VelikaGospa,
						@SviSveti, @DanSjecanjaNaVukovar, @Bozic, @SvetiStjepan) THEN 'praznik'
                  WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
				WHEN dat =@DanParlIzbora24 THEN 'Izbori 2024.'
                  ELSE 'RADNI DAN'
            END
	, ObracunskiDan=
		      CASE
                  WHEN DATENAME(weekday, Dat) IN ('subota', 'nedjelja') THEN 'vikend'
                  ELSE 'obračunski dan'
            END
INTO #datumi
FROM datumi
GO
DROP TABLE IF EXISTS #izracun
GO
SELECT Datum=Dat
      , [Dan u godini], [Dan u tjednu]--, [Radni dan], ObracunskiDan
	, [Obračunski dan u godini]=
            CASE
                  WHEN ObracunskiDan='obračunski dan' THEN CONVERT(nvarchar, ROW_NUMBER() OVER (PARTITION BY ObracunskiDan ORDER BY Dat))
                  ELSE 'vikend'
            END
      , [Radni dan u godini]=
            CASE
            	WHEN [Radni dan]='RAdni dan' THEN CONVERT(nvarchar, ROW_NUMBER() OVER (PARTITION BY [Radni dan] ORDER BY Dat))
				WHEN [Radni dan]='praznik' THEN 'praznik'
				WHEN [Radni dan] ='Izbori 2024.' THEN 'PARL. IZBORI ''24.'
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
				WHEN [Radni dan] ='Izbori 2024.' THEN 'PARL. IZBORI ''24.'
				ELSE 'vikend'
		END
into #izracun
FROM #datumi
order by dat
GO
SELECT Datum=CONVERT(varchar, Datum, 104)+'.'
, [Dan u godini], [Dan u tjednu]
, [Obračunski dan u godini], [Radni dan u godini],[Radni dan u mjesecu] 
FROM #izracun
ORDER BY [Dan u godini]
go 
WITH PoMjesecima AS(
	SELECT distinct MONTH(dat) as MjesecInt
		, SUM(CASE WHEN [Radni dan]='Radni dan' THEN 1 ELSE 0 END) OVER (PARTITION BY MONTH(dat) ORDER BY MONTH(dat)) AS 'Broj radnih dana'
		, SUM(CASE WHEN [ObracunskiDan]='obračunski dan' THEN 1 ELSE 0 END) OVER (PARTITION BY MONTH(dat) ORDER BY MONTH(dat)) AS 'Broj obračunskih dana'
		, SUM(CASE WHEN [Radni dan] IN ('praznik', 'Izbori 2024.') and [Dan u tjednu] not in ('subota','nedjelja') THEN 1 ELSE 0 END) OVER (PARTITION BY MONTH(dat) ORDER BY MONTH(dat)) AS 'Broj praznika'
	FROM #datumi)
, summaSummarumPoMjesecima as (
	SELECT mjesecint
		, [Broj obračunskih dana]
		, [Broj obračunskih dana]*8 AS 'Mjesečni fond sati'
		, [Broj radnih dana]
		, [Broj radnih dana]*8 AS 'Radnih sati'
		, [Broj praznika]
		, [Broj praznika]*8 AS 'Sati praznika'
	FROM PoMjesecima)
SELECT ISNULL( DATENAME(month, dateadd(month, MjesecInt, 0)-1) , 'UKUPNO') AS Mjesec
, [Broj obračunskih dana]=SUM([Broj obračunskih dana])
, [Broj radnih dana]=SUM([Broj radnih dana])
, [Broj praznika]=SUM([Broj praznika])
, [Mjesečni fond sati]=SUM([Mjesečni fond sati])
, [Radnih sati]=SUM([Radnih sati])
, [Sati praznika]=SUM([Sati praznika])
FROM summaSummarumPoMjesecima
GROUP BY Mjesecint WITH ROLLUP
