--Have the set name for the card appear
Select crd.artist, crd.name, crd.printings, crd.setCode, sts.name as SetName, sts.releaseDate, crd.uuid
From MagicTheGathering..cards$ crd
Join MagicTheGathering..sets$ sts
	on crd.setCode = sts.code
order by crd.artist, crd.name

---convert originalReleaseDate to date type
Create View ReleaseDate as
Select uuid, originalReleaseDate, SUBSTRING(originalReleaseDate,1,CHARINDEX('/',originalReleaseDate)-1) as releaseMonth, 
		SUBSTRING(originalReleaseDate,CHARINDEX('/',originalReleaseDate)+1,(LEN(originalReleaseDate)-4) - (CHARINDEX('/',originalReleaseDate)+1)) as releaseDay,
		SUBSTRING(originalReleaseDate,LEN(originalReleaseDate)-3,LEN(originalReleaseDate)) as releaseYear
From MagicTheGathering..cards$


Select uuid, originalReleaseDate, CAST(IIF(originalReleaseDate is null,NULL,CONCAT(releaseYear, '-' , releaseMonth, '-' , releaseDay)) as date) as correctDate
From ReleaseDate

---Add set name and release date to cards db---
ALTER TABLE MagicTheGathering..cards$
Add SetName nvarchar(255)

ALTER TABLE MagicTheGathering..cards$
Add SetReleaseDate Date

ALTER TABLE MagicTheGathering..cards$
Add TrueReleaseDate Date

Update crd
SET crd.SetName = sts.name
From MagicTheGathering..cards$ crd
Join MagicTheGathering..sets$ sts
	on crd.setCode = sts.code

Update crd
SET crd.SetReleaseDate = sts.releaseDate
From MagicTheGathering..cards$ crd
Join MagicTheGathering..sets$ sts
	on crd.setCode = sts.code

--Have the originalReleaseDate be incoorpertated with the release date of the card to remove the inconsitancy with sets like 'Secret Lair Drop'
With tempTable (UUID, correctDate)
as(
Select uuid, CAST(IIF(originalReleaseDate is null,NULL,CONCAT(releaseYear, '-' , releaseMonth, '-' , releaseDay)) as date) as correctDate
From ReleaseDate
)
Update crd
SET crd.TrueReleaseDate = IIF(rd.correctDate is not null,rd.correctDate,crd.SetReleaseDate)
From MagicTheGathering..cards$ crd
Join tempTable rd
	on crd.uuid = rd.UUID
------


--how many cards arts each artist made
--Visualizable
Select crd.artist, COUNT(Distinct crd.name) as CardsMade
From MagicTheGathering..cards$ crd
where crd.artist is not null and isOnlineOnly is null
group by crd.artist
order by CardsMade desc


--When the art was first made
Select Distinct name, artist, MIN(TrueReleaseDate) as FirstInstance
From MagicTheGathering..cards$
where isOnlineOnly is null
group by artist, name
order by artist, FirstInstance


--Months from first card made to last, w/ ratio for the number of arts made
--Visualizable
With ArtReleased (CardName, Artist, FirstReleased)
as
(
Select Distinct name, artist, MIN(TrueReleaseDate) as FirstInstance
From MagicTheGathering..cards$
where isOnlineOnly is null
group by artist, name
),
NumCardsByArtist(Artist, NumMade)
as
(
Select crd.artist, COUNT(Distinct crd.name) as CardsMade
From MagicTheGathering..cards$ crd
where crd.language = 'English' and isOnlineOnly is null
group by crd.artist
)
Select art.Artist, DATEDIFF(month, MIN(art.FirstReleased), MAX(art.FirstReleased)) as MonthDiff, num.NumMade as NumArtsMade
	,(cast(num.NumMade as float) / cast(NULLIF(DATEDIFF(month, MIN(art.FirstReleased), MAX(art.FirstReleased)),0) as float)) as Ratio
From ArtReleased art
Join NumCardsByArtist num
	on art.Artist = num.Artist
group by art.Artist, num.NumMade
order by MonthDiff desc



--number of new cards added by date
--Visualizable
With CardFirstReleased (CardName, ReleaseDate)
as(
Select Distinct name, MIN(TrueReleaseDate)
From MagicTheGathering..cards$
where isOnlineOnly is null
group by name
)
Select COUNT(CardName) as NumNewCards, ReleaseDate, sum(COUNT(CardName)) over (Order by ReleaseDate) as RollingCount
From CardFirstReleased
group by ReleaseDate
order by ReleaseDate


--number of new artists added by date
--Visualizable
Select artist, MIN(TrueReleaseDate) as FirstArtDate
From MagicTheGathering..cards$
where artist is not null and isOnlineOnly is null
group by artist
order by FirstArtDate, artist




--Test queries
Select *
From MagicTheGathering..cards$
where artist = 'Joe Torra'
order by TrueReleaseDate

Select *
From MagicTheGathering..sets$
order by releaseDate




