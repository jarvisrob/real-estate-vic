CREATE NONCLUSTERED INDEX ResultsUniqueRecordFields ON Reiv.Results (Suburb, AddressLine, Classification, OutcomeDate, Agent)
GO

CREATE NONCLUSTERED INDEX ResultsSuburb ON Reiv.Results (Suburb) INCLUDE (AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl)
GO

CREATE NONCLUSTERED INDEX ResultsClassification ON Reiv.Results (Classification) INCLUDE (Suburb, AddressLine, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl)
GO

CREATE NONCLUSTERED INDEX ResultsOutcome ON Reiv.Results (Outcome) INCLUDE (Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Agent, WebUrl)
GO


CREATE NONCLUSTERED INDEX PrelimResultsUniqueRecordFields ON Reiv.PrelimResults (Suburb, AddressLine, Classification, OutcomeDate, Agent)
GO

CREATE NONCLUSTERED INDEX PrelimResultsSuburb ON Reiv.PrelimResults (Suburb) INCLUDE (AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl)
GO

CREATE NONCLUSTERED INDEX PrelimResultsClassification ON Reiv.PrelimResults (Classification) INCLUDE (Suburb, AddressLine, NumberOfBedrooms, Price, OutcomeDate, Outcome, Agent, WebUrl)
GO

CREATE NONCLUSTERED INDEX PrelimResultsOutcome ON Reiv.PrelimResults (Outcome) INCLUDE (Suburb, AddressLine, Classification, NumberOfBedrooms, Price, OutcomeDate, Agent, WebUrl)
GO
