
DROP VIEW IF EXISTS Reiv.v_AllResults;
GO

CREATE VIEW Reiv.v_AllResults
AS
	WITH cte_UnionWithoutDuplicates
	AS
	(
		SELECT 0 AS IsPrelim, ResultId AS Id, Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl
		FROM [Reiv].[Results]
		WHERE ResultId NOT IN
		(
			SELECT r.ResultId
			FROM [Reiv].[Results] AS r
			INNER JOIN [Reiv].[PrelimResults] AS p
				ON r.Suburb = p.Suburb and r.AddressLine = p.AddressLine and r.Classification = p.Classification and r.OutcomeDate = p.OutcomeDate and r.Outcome = p.Outcome and r.Agent = p.Agent
		)
		UNION ALL
		SELECT 1 AS IsPrelim, PrelimId AS Id, Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl
		FROM [Reiv].[PrelimResults]
	)
	SELECT uwod.*, su.SoldOrUnsold
	FROM cte_UnionWithoutDuplicates AS uwod
	LEFT JOIN Reiv.SoldUnsoldMapping AS su
		ON uwod.Outcome = su.Outcome;


DROP VIEW IF EXISTS Reiv.v_AllResultsOfInterestInclPrelim
GO

CREATE VIEW Reiv.v_AllResultsOfInterestInclPrelim
AS
	WITH cte_UnionWithoutDuplicates
	AS
	(
		SELECT 0 AS IsPrelim, ResultId AS Id, Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl
		FROM [Reiv].[Results]
		WHERE ResultId NOT IN
		(
			SELECT r.ResultId
			FROM [Reiv].[Results] AS r
			INNER JOIN [Reiv].[PrelimResults] AS p
				ON r.Suburb = p.Suburb and r.AddressLine = p.AddressLine and r.Classification = p.Classification and r.OutcomeDate = p.OutcomeDate and r.Outcome = p.Outcome and r.Agent = p.Agent
		)
		UNION ALL
		SELECT 1 AS IsPrelim, PrelimId AS Id, Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl
		FROM [Reiv].[PrelimResults]
	)
	SELECT uwod.*, su.SoldOrUnsold
	FROM cte_UnionWithoutDuplicates AS uwod
	LEFT JOIN Reiv.SoldUnsoldMapping AS su
		ON uwod.Outcome = su.Outcome
	WHERE Classification IN
	(
		'house - semi-detached',
		'flat',
		'flat/unit/apartment',
		'house',
		'apartment',
		'house - terrace',
		'townhouse',
		'strata unit/flat',
		'villa',
		'unit',
		'house - duplex',
		'residential warehouse',
		'stratum flat',
		'stratum unit',
		'house & granny flat'
	)
		AND Suburb IN
		(
			SELECT Suburb
			FROM cte_UnionWithoutDuplicates
			GROUP BY Suburb
			HAVING COUNT(*) >= 20
		);

