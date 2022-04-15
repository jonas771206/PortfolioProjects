/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (5) *
--FROM [PortfolioProject].[dbo].[CovidDeaths]
--WHERE [continent] IS NOT NULL
--ORDER BY [location]

--SELECT TOP (5) *
--FROM [PortfolioProject].[dbo].[CovidVaccinations]
--WHERE [continent] IS NOT NULL
--ORDER BY [location]


-- SELECT the data we are going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortfolioProject].[dbo].[CovidDeaths]
ORDER BY [location], [date]

-- Looking at Total cases vs Total Death
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'DeathPercentage'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [location] LIKE '%United States%'
ORDER BY [location], [date]

-- Looking at total cases vs populations
-- Shows what percentage of population got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS 'CovidPercentage'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [location] LIKE '%United States%'
ORDER BY [location], [date]

-- Looking at countries with Hightest Infection Rate compared to Population
SELECT location, MAX(total_cases) AS 'HighestInfectionCount', population, MAX((total_cases/population))*100 AS 'PercentPopulationInfected'
FROM [PortfolioProject].[dbo].[CovidDeaths]
GROUP BY [location], [population]
ORDER BY PercentPopulationInfected DESC

-- Looking at countries with Hightest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS 'TotalDeathCount'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT


--Showing the continent with the highest death count
SELECT [continent], MAX(CAST(total_deaths AS INT)) AS 'TotalDeathCount'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

-- Global Numbers Daily
SELECT date, SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths AS INT)) AS 'Total Death', (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS 'Death Percentage'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL
GROUP BY date
ORDER BY date

-- Global Numbers Total
SELECT SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths AS INT)) AS 'Total Death', (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS 'Death Percentage'
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] IS NOT NULL


-- Looking at Total Population vs Vaccinations
SELECT Death.continent, Death.location, Death.date, Death.population, Vacc.new_vaccinations
	,SUM(CONVERT(BIGINT, Vacc.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS 'Rolling Ppl Vaccinations'
FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vacc
  ON Death.location = Vacc.location
  AND Death.date = Vacc.date
WHERE Death.[continent] IS NOT NULL
ORDER BY Death.location, Death.date

-- With CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPplVaccinations)
AS (
	SELECT Death.continent, Death.location, Death.date, Death.population, Vacc.new_vaccinations
		,SUM(CONVERT(BIGINT, Vacc.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS 'RollingPplVaccinations'
	FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
	JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vacc
	  ON Death.location = Vacc.location
	  AND Death.date = Vacc.date
	WHERE Death.[continent] IS NOT NULL
)
SELECT *, (RollingPplVaccinations/population)*100
FROM PopvsVac
--WHERE location LIKE '%Albania'
ORDER BY location, date

-- Temp Table Method
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent NVARCHAR(255),
	location NVARCHAR(255), 
	date DATETIME, 
	population NUMERIC, 
	new_vaccinations NUMERIC, 
	RollingPplVaccinations NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT Death.continent, Death.location, Death.date, Death.population, Vacc.new_vaccinations
	,SUM(CONVERT(BIGINT, Vacc.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS 'RollingPplVaccinations'
FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vacc
	ON Death.location = Vacc.location
	AND Death.date = Vacc.date
WHERE Death.[continent] IS NOT NULL

SELECT *, (RollingPplVaccinations/population)*100
FROM #PercentPopulationVaccinated
ORDER BY location, date


-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vacc.new_vaccinations
	,SUM(CONVERT(BIGINT, Vacc.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS 'RollingPplVaccinations'
FROM [PortfolioProject].[dbo].[CovidDeaths] AS Death
JOIN [PortfolioProject].[dbo].[CovidVaccinations] AS Vacc
	ON Death.location = Vacc.location
	AND Death.date = Vacc.date
WHERE Death.[continent] IS NOT NULL


SELECT *
FROM PercentPopulationVaccinated