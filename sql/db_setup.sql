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
DROP TABLE IF EXISTS Reiv.Results;
DROP TABLE IF EXISTS Reiv.PrelimResults;
DROP TABLE IF EXISTS Reiv.StagingResults;
DROP TABLE IF EXISTS Reiv.SoldUnsoldMapping;
DROP PROCEDURE IF EXISTS Reiv.usp_DeleteStagingDuplicates;
DROP PROCEDURE IF EXISTS Reiv.usp_UpdatePrelimResults;
DROP PROCEDURE IF EXISTS Reiv.usp_UpdateResults;
DROP SCHEMA IF EXISTS Reiv;
GO

-- Create ReslEstate schema
CREATE SCHEMA Reiv;
GO

-- Main results table: RealEstate.Results
CREATE TABLE Reiv.Results
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
INTO Reiv.PrelimResults
FROM Reiv.Results
WHERE 1 = 2;
GO

-- Rename the ID column in Prelim table and then make it the primary key
EXEC sys.sp_rename 'Reiv.PrelimResults.ResultId', 'PrelimId', 'COLUMN';
GO
ALTER TABLE Reiv.PrelimResults
ADD CONSTRAINT PK_PrelimId PRIMARY KEY (PrelimId);
GO

-- Staging table for real estate results, gets loaded into RealEstate.PrelimResults
SELECT *
INTO Reiv.StagingResults
FROM Reiv.Results
WHERE 1 = 2;
GO

-- Rename the ID column in Staging table and then make it the primary key
EXEC sys.sp_rename 'Reiv.StagingResults.ResultId', 'StagingId', 'COLUMN';
GO
ALTER TABLE Reiv.StagingResults
ADD CONSTRAINT PK_StagingId PRIMARY KEY (StagingId);
GO

-- Table used to map outcomes to sold/unsold
CREATE TABLE Reiv.SoldUnsoldMapping
(
	MapId			INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Outcome			NVARCHAR(30) NOT NULL,
	SoldOrUnsold	NVARCHAR(6) NOT NULL
);
GO
INSERT INTO Reiv.SoldUnsoldMapping (Outcome, SoldOrUnsold)
VALUES
	('passed in at auction', 'Unsold'),
	('passed in vendor bid', 'Unsold'),
	('sale by tender', 'Sold'),
	('sold before auction', 'Sold'),
	('auction sale', 'Sold'),
	('expression of interest', 'Unsold'),
	('sold after auction', 'Sold'),
	('private sale', 'Sold');
GO
