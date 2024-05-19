-- COVID Deaths/Vaccinations analysis


select *
from PortfolioProject1..CovidVaccinations
order by 3,4


-- Select data that we are going to be using

Select continent, location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject1..CovidDeaths
Order By 2,3


-- Looking at TOTAL CASES vs TOTAL DEATHS in  Georgia

Select continent, location, date, population, total_cases,  total_deaths, Round((total_deaths / total_cases) * 100, 2) AS 'Death %'
From PortfolioProject1..CovidDeaths
Where location like '%georgia'
Order By 1,2

-- Looking at the TOTAL CASES vs POPULATION

Select location, population,  total_cases,  Round((total_cases / population),2) AS InfectionRate
From PortfolioProject1..CovidDeaths
Where continent is   not NULL
Order By 1,2, total_cases DESC

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, 
MAX(total_cases) as MaxInfected,  
Max((total_cases/population))*100 as InfectionRate
From PortfolioProject1..CovidDeaths
Where continent is   not NULL
Group by Location, Population
order by InfectionRate desc


-- Showing countries with highest DeathCount per Population

Select location, population,  
MAX(cast(total_deaths as int)) AS TotalCovidDeaths, 
MAX(ROUND((total_deaths/population)*100,2)) AS TotalCovidDeathRate
From PortfolioProject1..CovidDeaths
Where continent is not NULL
Group by location, population
Order By TotalCovidDeathRate DESC

-- Showing COVID DEATH RATE by Continents

Select location,  population, 
MAX(cast(total_deaths as int)) AS TotalCovidDeaths, 
MAX(ROUND((total_deaths/population)*100,3)) AS TotalCovidDeathRate
From PortfolioProject1..CovidDeaths
Where continent is   NULL
Group by location, population
Order By TotalCovidDeaths DESC

-- Country rating by total deaths

Select location,
SUM(CAST(new_deaths as int))  AS TotalCOVDeaths
FROM PortfolioProject1..CovidDeaths
Where continent is not NULL
GROUP BY location
Order By TotalCOVDeaths DESC


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject1..CovidDeaths dea
Join PortfolioProject1..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Inner Joined tables
-- Using TEMPORARY TABLE, to showcase use of inner created table
-- Showing: new cases, new deaths, new_vaccinations together with current TOTALS ordered by date, and vaccination rate 

DROP TABLE IF EXISTS #PopulVaccinated
CREATE TABLE #PopulVaccinated
(
location nvarchar(255),
date datetime,
population numeric,
NewDeaths numeric,
TotalDeaths numeric,
NewVaccinations numeric,
TotalVaccinations numeric
)

INSERT INTO #PopulVaccinated
Select 
death.location, 
death.date, 
death.population, 
CAST(new_deaths AS INT) AS NewDeaths,
SUM(CONVERT(int, death.new_deaths)) OVER (PARTITION by death.location ORDER by death.location, death.date) AS TotalDeaths,
CAST(vacc.new_vaccinations AS INT) AS NewVaccinations,
SUM(CONVERT(int, vacc.new_vaccinations)) OVER (PARTITION by death.location ORDER by death.location, death.date) AS TotalVaccinations
FROM PortfolioProject1..CovidDeaths as death
JOIN PortfolioProject1..CovidVaccinations as vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent is not null AND death.location like 'France'
ORDER BY location, date

SELECT *, ROUND((TotalVaccinations/population)*100,2) AS VaccinationRate
FROM #PopulVaccinated

-- Creating vie database

CREATE VIEW COVIDDeathRate AS
Select location,  population, 
MAX(cast(total_deaths as int)) AS TotalCovidDeaths, 
MAX(ROUND((total_deaths/population)*100,3)) AS TotalCovidDeathRate
From PortfolioProject1..CovidDeaths
Where continent is   NULL
Group by location, population

SELECT *
FROM COVIDDeathRate
ORDER BY population DESC

