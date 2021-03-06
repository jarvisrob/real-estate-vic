
-- Ideally would like to make tables into variables, that way can merge staging -> prelim and then prelim -> results
-- And do this all with one procedure ...
-- But don't think this is possible :(

DROP PROCEDURE IF EXISTS Reiv.usp_UpdatePrelimResults;
GO

CREATE PROCEDURE Reiv.usp_UpdatePrelimResults
AS
BEGIN
	MERGE INTO Reiv.PrelimResults AS p
	USING Reiv.StagingResults AS s
	ON  -- Assumes these features are unique for each real estate activity (e.g. sale, passed in)
	(
		p.Suburb = s.Suburb AND
		p.AddressLine = s.AddressLine AND
		p.Classification = s.Classification AND
		p.OutcomeDate = s.OutcomeDate AND
		p.Outcome = s.Outcome AND
		p.Agent = s.Agent  -- Assumes there is always an Agent (not null)
	)
	WHEN MATCHED THEN
		UPDATE
		SET
			p.NumberOfBedrooms = s.NumberOfBedrooms,
			p.Price = s.Price,
			p.WebUrl = s.WebUrl
	WHEN NOT MATCHED THEN
		INSERT
		(
			Suburb,
			AddressLine,
			Classification,
			NumberOfBedrooms,
			Price,
			OutcomeDate,
			Outcome,
			Agent,
			WebUrl
		)
		VALUES
		(
			s.Suburb,
			s.AddressLine,
			s.Classification,
			s.NumberOfBedrooms,
			s.Price,
			s.OutcomeDate,
			s.Outcome,
			s.Agent,
			s.WebUrl
		);
	DELETE
	FROM Reiv.StagingResults;
END;
GO




DROP PROCEDURE IF EXISTS Reiv.usp_UpdateResults;
GO

CREATE PROCEDURE Reiv.usp_UpdateResults
AS
BEGIN
	MERGE INTO Reiv.Results AS r
	USING Reiv.PrelimResults AS p
	ON
	(
		r.Suburb = p.Suburb AND
		r.AddressLine = p.AddressLine AND
		r.Classification = p.Classification AND
		r.OutcomeDate = p.OutcomeDate AND
		r.Outcome = p.Outcome AND
		r.Agent = p.Agent
	)
	WHEN MATCHED THEN
		UPDATE
		SET
			r.NumberOfBedrooms = p.NumberOfBedrooms,
			r.Price = p.Price,
			r.WebUrl = p.WebUrl
	WHEN NOT MATCHED THEN
		INSERT
		(
			Suburb,
			AddressLine,
			Classification,
			NumberOfBedrooms,
			Price,
			OutcomeDate,
			Outcome,
			Agent,
			WebUrl
		)
		VALUES
		(
			p.Suburb,
			p.AddressLine,
			p.Classification,
			p.NumberOfBedrooms,
			p.Price,
			p.OutcomeDate,
			p.Outcome,
			p.Agent,
			p.WebUrl
		);
	DELETE
	FROM Reiv.PrelimResults;
END;
GO
