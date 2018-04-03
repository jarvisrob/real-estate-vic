/* ---------------------------------------------------
SET-UP: DROP EVERYTHING THEN CREATE SCHEMAS AND TABLES
------------------------------------------------------
This is SQL code for setting up the database.
It creates the schema(s) and tables, first dropping
them if they already exist.
WARNING: Running this will delete/drop any data that
currently exists in teh database! This is intended for
set-up only (or a complete restart).
-----------------------------------------------------*/

-- Make sure using the RealEstateVicDb database
USE RealEstateVicDb;
GO

-- Kill any existing schemas or tables if exists
DROP TABLE IF EXISTS RealEstate.Results;
DROP TABLE IF EXISTS RealEstate.PrelimResults;
DROP TABLE IF EXISTS RealEstate.StagingResults;
DROP PROCEDURE IF EXISTS RealEstate.DeleteStagingDuplicates;
DROP PROCEDURE IF EXISTS RealEstate.UpdatePrelimResults;
DROP PROCEDURE IF EXISTS RealEstate.UpdateResults;
DROP SCHEMA IF EXISTS RealEstate;
GO

-- Create ReslEstate schema
CREATE SCHEMA RealEstate;
GO

-- Main results table: RealEstate.Results
CREATE TABLE RealEstate.Results
(
	ResultId			INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Suburb				NVARCHAR(50) NOT NULL,
	AddressLine			NVARCHAR(80) NOT NULL,
	Classification		NVARCHAR(80) NOT NULL,
	NumberOfBedrooms	TINYINT NULL,
	Price				INT NULL,
	OutcomeDate			DATE NOT NULL,
	Outcome				NVARCHAR(50) NOT NULL,
	Agent				NVARCHAR(100) NOT NULL,  -- Assumes that Agent is always recorded
	WebUrl				NVARCHAR(200) NULL
);
GO

-- Prelim table for results early in week: RealEstate.PrelimResults
-- Created as copy of main results table, WHERE 1 = 2 ensures no rows are copied, just column names
SELECT *
INTO RealEstate.PrelimResults
FROM RealEstate.Results
WHERE 1 = 2;
GO

-- Rename the ID column in Prelim table and then make it the primary key
EXEC sys.sp_rename 'RealEstate.PrelimResults.ResultId', 'PrelimId', 'COLUMN';
GO
ALTER TABLE RealEstate.PrelimResults
ADD CONSTRAINT PK_PrelimId PRIMARY KEY (PrelimId);
GO

-- Staging table for real estate results, gets loaded into RealEstate.PrelimResults
SELECT *
INTO RealEstate.StagingResults
FROM RealEstate.Results
WHERE 1 = 2;
GO

-- Rename the ID column in Staging table and then make it the primary key
EXEC sys.sp_rename 'RealEstate.StagingResults.ResultId', 'StagingId', 'COLUMN';
GO
ALTER TABLE RealEstate.StagingResults
ADD CONSTRAINT PK_StagingId PRIMARY KEY (StagingId);
GO
