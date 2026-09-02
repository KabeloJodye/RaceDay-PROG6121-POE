# RaceDay-PROG6121-POE
# RaceDay Event Management System

## Project Overview

RaceDay is a comprehensive event management system designed for organising and managing running events, including marathons, 10K races, and fun runs. The system supports multiple user roles (Organisers, Participants, and Admins) and handles the complete lifecycle of events from creation through to results management.

## Table of Contents
- [Project Overview](#project-overview)
- [Part 1: System Planning](#part-1-system-planning)
  - [Database Design](#database-design)
  - [API Architecture](#api-architecture)
  - [Technology Stack](#technology-stack)
- [Database Schema](#database-schema)
- [API Endpoints](#api-endpoints)
- [Installation & Setup](#installation--setup)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Part 1: System Planning

### Database Design

The RaceDay database consists of **8 entities** (exceeding the minimum requirement of 6) that model the complete event management domain:

#### Entity Relationship Diagram (ERD)

![ERD Diagram](./ERD_RaceDay_System.png)

*Location: `/docs/ERD_RaceDay_System.png`*

#### Core Entities:

1. **User** (Superclass)
   - Manages all system users
   - Supports role-based access (Organiser, Participant, Admin)
   - Stores authentication credentials

2. **Organiser** (Subclass of User)
   - Extended user profile for event organisers
   - Contains organisation details and verification status

3. **Participant** (Subclass of User)
   - Extended user profile for race participants
   - Stores emergency contact and medical information

4. **Event**
   - Central entity for all races and competitions
   - Manages event lifecycle (Draft → Open → Closed → Completed → Cancelled)

5. **Category**
   - Defines race categories within an event
   - Includes age groups, gender categories, and fee amounts

6. **EventEnrolment**
   - Associative entity linking Participants to Event Categories
   - Tracks enrolment status and payment information

7. **Result**
   - Stores race results for each enrolment
   - Includes finish times, positions, and points awarded

8. **Payment** (Bonus Entity)
   - Tracks financial transactions for enrolments
   - Supports multiple payment methods

#### Relationship Summary:

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| User → Organiser | 1:1 | One User extends to one Organiser |
| User → Participant | 1:1 | One User extends to one Participant |
| Organiser → Event | 1:Many | One Organiser creates many Events |
| Event → Category | 1:Many | One Event has many Categories |
| Category → EventEnrolment | 1:Many | One Category has many Enrolments |
| Participant → EventEnrolment | 1:Many | One Participant has many Enrolments |
| EventEnrolment → Result | 1:1 | One Enrolment has one Result |
| EventEnrolment → Payment | 1:Many | One Enrolment can have many Payments |

### API Architecture

The RESTful API follows these architectural principles:

- **Resource-Based**: Endpoints represent resources (events, categories, enrolments)
- **Stateless**: Each request contains all necessary authentication information
- **Consistent**: Follows standard HTTP methods and status codes
- **Role-Based Access**: Endpoints are secured based on user roles
- **Versioned**: API versioning through route structure (`/api/v1/...`)

#### Authentication Strategy

- JWT (JSON Web Tokens) for stateless authentication
- Token includes user ID and role for authorization decisions
- Tokens expire after 24 hours
- Refresh tokens for extended sessions (optional)

#### API Endpoint Documentation

Complete API endpoint specifications are available at: `/docs/API_Endpoints.md`

**Summary of Endpoint Categories:**

| Category | Endpoints | Description |
|----------|-----------|-------------|
| Authentication | `/api/auth/register`, `/api/auth/login`, `/api/auth/logout` | User registration and login |
| User Profile | `/api/users/profile`, `/api/users/profile/*` | User profile management |
| Events | `/api/events`, `/api/events/{id}` | Event CRUD operations |
| Categories | `/api/categories`, `/api/categories/{id}` | Category management |
| Enrolments | `/api/enrolments`, `/api/enrolments/*` | Participant enrolment |
| Results | `/api/results`, `/api/results/*` | Result management |

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| Database | Microsoft SQL Server | Relational database |
| Backend | Node.js / Express.js | RESTful API server |
| ORM/Query | SQL Server Management Studio (SSMS) | Database management |
| Authentication | JWT (jsonwebtoken) | User authentication |
| Validation | Joi / express-validator | Request validation |
| Documentation | Swagger/OpenAPI | API documentation |
| Version Control | Git / GitHub | Source control |
| CI/CD | GitHub Actions (planned) | Automated deployment |

---

## Database Schema

### SQL Scripts

The database schema is defined in: `/docs/RaceDay_Database_Schema.sql`

#### Key Features:

1. **Referential Integrity**: All foreign key relationships enforce cascade rules
2. **Data Validation**: CHECK constraints enforce domain integrity
3. **Performance**: Indexes on foreign keys and frequently queried columns
4. **Timestamps**: Audit columns (`created_at`, `updated_at`) on all tables
5. **UUID Primary Keys**: Using `NEWID()` for distributed identity

#### Sample Data Included:

- 2 Organisers (Marathon Masters, City Running Club)
- 2 Participants (Michael Brown, Emma Davis)
- 3 Events (Cape Town Marathon, Summer 10K, Spring 5K)
- 6 Categories across events
- Sample enrolments with payments
- Sample results for completed events

#### Running the Script:

```sql
-- Connect to SQL Server Management Studio (SSMS)
-- Execute the script:
USE master;
GO
EXEC RaceDay_Database_Schema.sql;
-- Or open the file in SSMS and execute
