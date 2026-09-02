/* ============================================================
   RaceDay Database - Part 1: System Planning and Database
   SQL Server / SSMS
   ============================================================ */

IF DB_ID('RaceDayDB') IS NULL
BEGIN
    CREATE DATABASE RaceDayDB;
END;
GO

USE RaceDayDB;
GO

/* Clean re-run support: drop tables in dependency order. */
DROP TABLE IF EXISTS Results;
DROP TABLE IF EXISTS EventEnrolments;
DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS Events;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Roles;
GO

/* 1. Roles */
CREATE TABLE Roles
(
    RoleID INT IDENTITY(1,1) NOT NULL,
    RoleName VARCHAR(30) NOT NULL,

    CONSTRAINT PK_Roles PRIMARY KEY (RoleID),
    CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName),
    CONSTRAINT CK_Roles_RoleName CHECK (RoleName IN ('Organiser', 'Participant'))
);
GO

/* 2. Users */
CREATE TABLE Users
(
    UserID INT IDENTITY(1,1) NOT NULL,
    RoleID INT NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(120) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(20) NULL,
    DateCreated DATETIME2(0) NOT NULL
        CONSTRAINT DF_Users_DateCreated DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Users PRIMARY KEY (UserID),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT FK_Users_Roles
        FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
GO

/* 3. Events */
CREATE TABLE Events
(
    EventID INT IDENTITY(1,1) NOT NULL,
    OrganiserID INT NOT NULL,
    EventName VARCHAR(120) NOT NULL,
    Description VARCHAR(500) NULL,
    EventDate DATETIME2(0) NOT NULL,
    Location VARCHAR(200) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    EventType VARCHAR(10) NOT NULL,
    DateCreated DATETIME2(0) NOT NULL
        CONSTRAINT DF_Events_DateCreated DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Events PRIMARY KEY (EventID),
    CONSTRAINT FK_Events_Organiser
        FOREIGN KEY (OrganiserID) REFERENCES Users(UserID),
    CONSTRAINT CK_Events_DistanceKm CHECK (DistanceKm > 0),
    CONSTRAINT CK_Events_EventType CHECK (EventType IN ('Run', 'Walk', 'Cycle'))
);
GO

/* 4. Categories
   Each category belongs to one event, matching the requirement that
   organisers define age or distance categories for each event. */
CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) NOT NULL,
    EventID INT NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    CategoryType VARCHAR(10) NOT NULL,
    MinAge INT NULL,
    MaxAge INT NULL,
    DistanceKm DECIMAL(6,2) NULL,
    Description VARCHAR(300) NULL,

    CONSTRAINT PK_Categories PRIMARY KEY (CategoryID),
    CONSTRAINT UQ_Categories_Event_Name UNIQUE (EventID, CategoryName),
    CONSTRAINT UQ_Categories_Event_Category UNIQUE (EventID, CategoryID),
    CONSTRAINT FK_Categories_Events
        FOREIGN KEY (EventID) REFERENCES Events(EventID),
    CONSTRAINT CK_Categories_CategoryType
        CHECK (CategoryType IN ('Age', 'Distance')),
    CONSTRAINT CK_Categories_MinAge CHECK (MinAge IS NULL OR MinAge >= 0),
    CONSTRAINT CK_Categories_MaxAge CHECK (MaxAge IS NULL OR MaxAge >= 0),
    CONSTRAINT CK_Categories_AgeRange
        CHECK (MinAge IS NULL OR MaxAge IS NULL OR MinAge <= MaxAge),
    CONSTRAINT CK_Categories_DistanceKm
        CHECK (DistanceKm IS NULL OR DistanceKm > 0),
    CONSTRAINT CK_Categories_TypeValues
        CHECK (
            (CategoryType = 'Age' AND (MinAge IS NOT NULL OR MaxAge IS NOT NULL) AND DistanceKm IS NULL)
            OR
            (CategoryType = 'Distance' AND DistanceKm IS NOT NULL AND MinAge IS NULL AND MaxAge IS NULL)
        )
);
GO

/* 5. EventEnrolments
   Explicitly links a participant, an event and the selected category. */
CREATE TABLE EventEnrolments
(
    EnrolmentID INT IDENTITY(1,1) NOT NULL,
    EventID INT NOT NULL,
    ParticipantID INT NOT NULL,
    CategoryID INT NOT NULL,
    EnrolmentDate DATETIME2(0) NOT NULL
        CONSTRAINT DF_EventEnrolments_EnrolmentDate DEFAULT (SYSDATETIME()),
    Status VARCHAR(15) NOT NULL
        CONSTRAINT DF_EventEnrolments_Status DEFAULT ('Active'),

    CONSTRAINT PK_EventEnrolments PRIMARY KEY (EnrolmentID),
    CONSTRAINT UQ_EventEnrolments_Event_Participant UNIQUE (EventID, ParticipantID),
    CONSTRAINT FK_EventEnrolments_Events
        FOREIGN KEY (EventID) REFERENCES Events(EventID),
    CONSTRAINT FK_EventEnrolments_Participants
        FOREIGN KEY (ParticipantID) REFERENCES Users(UserID),
    CONSTRAINT FK_EventEnrolments_EventCategory
        FOREIGN KEY (EventID, CategoryID)
        REFERENCES Categories(EventID, CategoryID),
    CONSTRAINT CK_EventEnrolments_Status
        CHECK (Status IN ('Active', 'Cancelled'))
);
GO

/* 6. Results
   One result is recorded for one enrolment. The enrolment already identifies
   the participant, event and category, avoiding duplicate data. */
CREATE TABLE Results
(
    ResultID INT IDENTITY(1,1) NOT NULL,
    EnrolmentID INT NOT NULL,
    FinishTime TIME(3) NOT NULL,
    Position INT NOT NULL,
    DateRecorded DATETIME2(0) NOT NULL
        CONSTRAINT DF_Results_DateRecorded DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_Results PRIMARY KEY (ResultID),
    CONSTRAINT UQ_Results_Enrolment UNIQUE (EnrolmentID),
    CONSTRAINT FK_Results_EventEnrolments
        FOREIGN KEY (EnrolmentID) REFERENCES EventEnrolments(EnrolmentID),
    CONSTRAINT CK_Results_Position CHECK (Position > 0)
);
GO

/* ============================================================
   Seed / Sample Data
   ============================================================ */
INSERT INTO Roles (RoleName)
VALUES ('Organiser'), ('Participant');
GO

INSERT INTO Users (RoleID, FirstName, LastName, Email, PasswordHash, PhoneNumber)
VALUES
(1, 'Olivia', 'Ndlovu', 'olivia.organiser@raceday.test', 'DEMO_HASH_ONLY_NOT_A_REAL_PASSWORD', '0710000001'),
(2, 'Kabelo', 'Mokoena', 'kabelo.participant@raceday.test', 'DEMO_HASH_ONLY_NOT_A_REAL_PASSWORD', '0710000002'),
(2, 'Naledi', 'Molefe', 'naledi.participant@raceday.test', 'DEMO_HASH_ONLY_NOT_A_REAL_PASSWORD', '0710000003');
GO

INSERT INTO Events
    (OrganiserID, EventName, Description, EventDate, Location, DistanceKm, EventType)
VALUES
(1, 'Kimberley City Run', 'Community road-running event.', '2026-10-10T08:00:00', 'Kimberley', 10.00, 'Run'),
(1, 'Bloemfontein Cycle Challenge', 'Regional cycling event.', '2026-11-15T07:00:00', 'Bloemfontein', 21.00, 'Cycle');
GO

INSERT INTO Categories
    (EventID, CategoryName, CategoryType, MinAge, MaxAge, DistanceKm, Description)
VALUES
(1, 'Under 20', 'Age', 0, 19, NULL, 'Participants aged under 20.'),
(1, 'Senior', 'Age', 20, NULL, NULL, 'Participants aged 20 and above.'),
(1, '10km', 'Distance', NULL, NULL, 10.00, '10 kilometre category.'),
(2, '21km', 'Distance', NULL, NULL, 21.00, '21 kilometre category.');
GO

INSERT INTO EventEnrolments (EventID, ParticipantID, CategoryID)
VALUES
(1, 2, 2),
(2, 3, 4);
GO

INSERT INTO Results (EnrolmentID, FinishTime, Position)
VALUES
(1, '00:47:32.250', 1);
GO

/* ============================================================
   Verification Queries
   ============================================================ */
SELECT * FROM Roles;
SELECT * FROM Users;
SELECT * FROM Events;
SELECT * FROM Categories;
SELECT * FROM EventEnrolments;
SELECT * FROM Results;
GO

/* Useful joined verification */
SELECT
    ee.EnrolmentID,
    u.FirstName + ' ' + u.LastName AS Participant,
    e.EventName,
    c.CategoryName,
    ee.Status,
    r.FinishTime,
    r.Position
FROM EventEnrolments ee
INNER JOIN Users u ON u.UserID = ee.ParticipantID
INNER JOIN Events e ON e.EventID = ee.EventID
INNER JOIN Categories c ON c.CategoryID = ee.CategoryID
LEFT JOIN Results r ON r.EnrolmentID = ee.EnrolmentID;
GO
