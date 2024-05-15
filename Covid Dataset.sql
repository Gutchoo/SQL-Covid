-- Checking all rows imported
SELECT COUNT(*) FROM covidvaccinations;
SELECT COUNT(*) FROM coviddeaths;

-- Checking data types
DESCRIBE covidvaccinations;
DESCRIBE coviddeaths;

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM coviddeaths
ORDER BY 1,2;

SELECT * FROM coviddeaths
WHERE continent is not NULL;

-- Many queries below will be looking at the United States but can be easily changed to check stats of other countries in the dataset

-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%States%'
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population contracted COVID-19
SELECT location, date, total_cases, population, (total_cases/population)*100 AS 'PercentContractedCovid'
FROM coviddeaths
WHERE location LIKE '%States%'
ORDER BY 1,2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX((total_cases) / population) * 100 AS 'PercentContractedCovid'
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentContractedCovid DESC;


-- Looking at countries with the highest death count per population
SELECT location, MAX(total_deaths) AS HighestDeathCount
FROM coviddeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY 2 DESC;

-- Breakdown by continent
SELECT continent, MAX(total_deaths) AS HighestDeathCount
FROM coviddeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY 2 DESC;

--Global total cases, deaths, and DeathPercentage
SELECT date, SUM(new_cases) AS 'SumNewCases', SUM(new_deaths) AS 'SumNewDeaths', 
    (SUM(new_deaths)/SUM(new_cases))*100 AS 'DeathPercentage'
FROM coviddeaths
where continent is not null
GROUP BY date
ORDER BY 1;

SELECT MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths, 
    MAX(total_deaths)/MAX(total_cases)*100 AS 'DeathPercentage'
FROM coviddeaths
where continent is not null;


-- Total population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinationTotal'
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL;


-- USING CTE
WITH PopvsVac(continent, location, date, population, new_vaccinations, RollingVaccinationTotal)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinationTotal'
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingVaccinationTotal/Population)*100
FROM PopvsVac;

-- USING TEMP TABLE
DROP TEMPORARY TABLE IF EXISTS PercentPopVaccinated;
CREATE TEMPORARY TABLE PercentPopVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rollingpeoplevaccinated numeric
);

INSERT INTO PercentPopvaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinationTotal'
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (rollingpeoplevaccinated/population)*100 AS 'RollingVacc/population'
FROM PercentPopvaccinated;


-- Creating View for later visualizations
CREATE VIEW RollingVaccinations AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinationTotal'
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Infection Count/population View
CREATE VIEW InfectionsOverPopulation AS 
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX((total_cases) / population) * 100 AS 'PercentContractedCovid'
FROM coviddeaths
GROUP BY location, population
ORDER BY PercentContractedCovid DESC;

--