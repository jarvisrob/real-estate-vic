
-- TODO: Also want a proc to list all duplicates, need to write this. Idea is to check what the del proc is doing.
--SELECT ROW_NUMBER() OVER(PARTITION BY Suburb, AddressLine, Classification, OutcomeDate, Outcome, Agent  -- Assumes these features are unique for each activity
--						  ORDER BY StagingID DESC) AS DuplicateNumber
--	, *
--FROM Reiv.StagingResults
--ORDER BY StagingId
-- This query requires you to manually search through the list. Need to write a better one.

-- This query works (!), but likely expensive with two temp tables
-- Probably a more elegant way exists, but it works
DROP TABLE IF EXISTS #AppendDuplicateNumber;
DROP TABLE IF EXISTS #AppendNumberOfDuplicates;

SELECT *
		, ROW_NUMBER() OVER(PARTITION BY Suburb, AddressLine, Classification, OutcomeDate, Outcome, Agent  -- Assumes these features are unique for each activity
						  --ORDER BY StagingID DESC) AS DuplicateNumber
						  ORDER BY PrelimID DESC) AS DuplicateNumber
INTO #AppendDuplicateNumber
--FROM Reiv.StagingResults;
FROM Reiv.PrelimResults;

SELECT *
	, MAX(DuplicateNumber) OVER(PARTITION BY Suburb, AddressLine, Classification, OutcomeDate, Outcome, Agent) AS NumberOfDuplicates
INTO #AppendNumberOfDuplicates
FROM #AppendDuplicateNumber

SELECT *
FROM #AppendNumberOfDuplicates
WHERE NumberOfDuplicates > 1
--ORDER BY Suburb, AddressLine, Classification, StagingId;
ORDER BY Suburb, AddressLine, Classification, PrelimId;

GO



-- Duplicates are removed from Staging table
-- Assumes the most recent record, which should have the greatest StagingID, has the best info so far
DROP PROCEDURE IF EXISTS Reiv.usp_DeleteStagingDuplicates;
GO

CREATE PROCEDURE Reiv.usp_DeleteStagingDuplicates
AS
WITH cte_AppendDuplicateNumber
AS
(
	SELECT Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl,
		ROW_NUMBER() OVER(PARTITION BY Suburb, AddressLine, Classification, OutcomeDate, Outcome, Agent  -- Assumes these features are unique for each activity
						  ORDER BY StagingID DESC) AS DuplicateNumber
	FROM Reiv.StagingResults
)
DELETE
FROM cte_AppendDuplicateNumber
WHERE DuplicateNumber > 1;
GO

