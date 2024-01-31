--SELECT TOP(10) * FROM PortfolioProject..CovidDeaths
--ORDER BY 3, 4

--SELECT TOP(10) * FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM PortfolioProject..CovidDeaths
--ORDER BY 1, 2 

-- Total cases vs Total deaths
-- Likelihood of dying if you contract covid in certain country
SELECT location, date, total_cases, ISNULL(total_deaths, 0) AS total_deaths,
	   CONCAT(ISNULL(ROUND((total_deaths / total_cases) * 100, 2), 0), '%') AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Uzbekistan'
ORDER BY 1, 2 

-- Total cases vs Population
-- Percent of population that got Covid
SELECT location, date, population, total_cases,
	   CONCAT(ROUND((total_cases / population) * 100, 2), '%') AS Percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2 

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, ISNULL(MAX(total_cases), 0) AS current_total_cases,
	   MAX(ISNULL(ROUND((total_cases / population) * 100, 2), 0)) AS Percentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY Percentage DESC

-- Countries with Highest Death Counts
SELECT location, MAX(cast(total_deaths AS int)) AS HighestDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeaths DESC

-- Countries with Highest Death Rates compared to Population
SELECT location, population, MAX(cast(total_deaths AS int)) AS HighestDeaths, 
	   MAX(ISNULL(ROUND((total_deaths / population) * 100, 2), 0)) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathPercentage DESC

-- Death Counts by Continents
SELECT location, MAX(cast(total_deaths AS int)) AS HighestDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeaths DESC

-- GLOBAL NUMBERS
-- World data by date
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths,
	   ROUND((SUM(cast(new_deaths AS int)) / SUM(new_cases)) * 100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date

-- Total numbers in the World
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths,
	   ROUND((SUM(cast(new_deaths AS int)) / SUM(new_cases)) * 100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL


-- Common Table Expression 
WITH PopvsVac (continent, location, date, population, new_vaccinations, TotalPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (
										PARTITION BY dea.location
										ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidVaccinations vac
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, ROUND((TotalPeopleVaccinated / population) * 100, 2) AS PercentageVaccinated
FROM PopvsVac


-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
TotalPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (
										PARTITION BY dea.location
										ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidVaccinations vac
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, ROUND((TotalPeopleVaccinated / population) * 100, 2) AS PercentageVaccinated
FROM #PercentPopulationVaccinated


-- Creating Views to store data for later visualizations in Tableau
USE PortfolioProject
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (
										PARTITION BY dea.location
										ORDER BY dea.location, dea.date) AS TotalPeopleVaccinated
FROM PortfolioProject..CovidVaccinations vac
JOIN PortfolioProject..CovidDeaths dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated

USE PortfolioProject
GO
CREATE VIEW InfectionRate AS
SELECT location, population, ISNULL(MAX(total_cases), 0) AS current_total_cases,
	   MAX(ISNULL(ROUND((total_cases / population) * 100, 2), 0)) AS Percentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population

USE PortfolioProject
GO
CREATE VIEW DeathCount AS
SELECT location, MAX(cast(total_deaths AS int)) AS HighestDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location

USE PortfolioProject
GO
CREATE VIEW DeathRate AS
SELECT location, population, MAX(cast(total_deaths AS int)) AS HighestDeaths, 
	   MAX(ISNULL(ROUND((total_deaths / population) * 100, 2), 0)) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

SELECT * 
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME = 'DeathRate';