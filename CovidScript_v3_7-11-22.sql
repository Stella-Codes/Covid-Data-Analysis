-- This project explores Global COVID-19 data for the year of 2021.

-- Part I: Covid Deaths Analysis:
-- Visualizing data import to verify data integrity:

SELECT * 
FROM covidporfolioproject.coviddeaths
WHERE continent > '' -- [This is to drop empty and null cells.]
ORDER BY 3,4;

-- Selecting the data that I will be using:

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covidporfolioproject.coviddeaths
WHERE continent > ''
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths:
-- Shows the daily reported death rate per country for the year 2021.

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covidporfolioproject.coviddeaths
WHERE location = "United States"
ORDER BY 1,2;

-- Looking at Total Cases vs Population:
-- Shows the daily reported percentage of the population that has gotten Covid for the year 2021.

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectedPopulationPercentage
FROM covidporfolioproject.coviddeaths
WHERE location = "United States"
      and continent > ''
ORDER BY 1,2;

-- Looking at Countries with highest Infection Rate compared to Population:

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS InfectedPopulationPercentage
FROM covidporfolioproject.coviddeaths
WHERE continent > ''
GROUP BY location, population
ORDER BY InfectedPopulationPercentage desc;

-- Looking at Countries with Highest Death Count per Population:

SELECT location, MAX(cast(total_deaths AS SIGNED)) as TotalDeathCount
FROM covidporfolioproject.coviddeaths
WHERE continent > ''
GROUP BY location
ORDER BY TotalDeathCount desc;

-- Let's now break the numbers down Worldwide instead:
-- Looking at Continents with the Highest Death Count per Population:

SELECT continent, MAX(cast(total_deaths AS SIGNED)) as TotalDeathCount
FROM covidporfolioproject.coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- Daily Numbers:
SELECT date, SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths AS SIGNED)) as TotalNewDeaths, SUM(cast(new_deaths AS SIGNED))/SUM(new_cases)*100 as GlobalDeathPercentage
FROM covidporfolioproject.coviddeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;

-- Total Numbers:
SELECT SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths AS SIGNED)) as TotalNewDeaths, SUM(cast(new_deaths AS SIGNED))/SUM(new_cases)*100 as GlobalDeathPercentage
FROM covidporfolioproject.coviddeaths
WHERE continent is not null
ORDER BY 1,2;

-- Part II: Covid Vaccinations Analysis:
-- Visualizing data import to verify data integrity:

SELECT * 
FROM covidporfolioproject.covidvaccinations
WHERE continent > ''
ORDER BY 3,4;

-- Joining both CovidDeaths and CovidVaccinations Tables:

SELECT *
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date;

-- Looking at Total Population vs Total Vaccinations:

SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent > ''
ORDER BY 2,3;

-- Calculating the Rolling Count of Vaccinated People by location and date:

SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS SIGNED)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeopleCount
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent > ''
ORDER BY 2,3;

-- Calculating the Rolling Percentage of People Vaccinated per Location:
-- Creating a Temp Table for further analysis:

DROP TEMPORARY TABLE IF EXISTS VacPop;
CREATE TEMPORARY TABLE VacPop
(
continent text,
location text,
date text,
population int,
new_vaccinations text,
RollingVaccinatedPeopleCount numeric
);

INSERT INTO VacPop
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeopleCount
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent is not null;

SELECT *,(RollingVaccinatedPeopleCount/Population)*100 AS PercentageVaccinatedPpl
FROM VacPop;

-- Creating Views to store data for later visualizations in Tableau:
-- These Views will now be able to be used for future queries to be pulled from as well.

-- Global % Of Vaccinated People per Location:
CREATE VIEW VacPop AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingVaccinatedPeopleCount
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent is not null;

-- Total Cases vs Total Deaths in the U.S.:
CREATE VIEW DeathPop AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covidporfolioproject.coviddeaths
WHERE location = "United States";

-- Countries with Highest Infection Rate per Population:
CREATE VIEW CountryInfectionRate AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS InfectedPopulationPercentage
FROM covidporfolioproject.coviddeaths
WHERE continent > ''
GROUP BY location, population
ORDER BY InfectedPopulationPercentage desc;

-- Countries with Highest Death Count per Population:
CREATE VIEW CountryDeathCount AS
SELECT location, MAX(cast(total_deaths AS SIGNED)) as TotalDeathCount
FROM covidporfolioproject.coviddeaths
WHERE continent > ''
GROUP BY location
ORDER BY TotalDeathCount desc;

-- Continents with Highest Death Count:
CREATE VIEW ContinentDeathCount AS
SELECT continent, MAX(cast(total_deaths AS SIGNED)) as TotalDeathCount
FROM covidporfolioproject.coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- Total Population VS Total Vaccinations:
CREATE VIEW PopulationVaccination AS
SELECT dea.continent, dea.location, dea.date, dea.population,  vac.new_vaccinations
FROM covidporfolioproject.coviddeaths dea
JOIN covidporfolioproject.covidvaccinations vac
     ON dea.location = vac.location
     and dea.date = vac.date
WHERE dea.continent > ''
