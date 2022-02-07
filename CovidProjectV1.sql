Select *
From CovidProject..CovidDeaths$
Where continent is not null
order by 3,4


Select *
From CovidProject..CovidVaccinations$
order by 3,4

--Select data that we are gonna be using
Select location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths$
order by 1,2


--Looking at the Total Cases vs Total Deaths
--Shows the probability of dying if you contract covid-19 in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From CovidProject..CovidDeaths$
where (location like '%Nigeria%' AND continent is not null)
order by 1,2

--Looking at the Total Cases vs Population
--Shows the percentage of the population that got infected
Select location, date, total_cases, population, (total_cases/population)*100 as percentage_infected
From CovidProject..CovidDeaths$
where location like '%Nigeria%'
order by 1,2

--Looking at countries with the highest infection rate compared to their population
Select location, MAX(total_cases) as Highest_Infection_Rate, population, (MAX(total_cases)/population)*100 as percentage_HIR
From CovidProject..CovidDeaths$
Where continent is not null
Group by location, population
order by percentage_HIR desc
--desc = descending order (highest to lowest)

--Showing countries with highest total death counts per population
--I use CAST to change the data type to a numeric datatype
--Population and percentage column in the result is optional
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population, (MAX(cast(total_deaths as float))/population)*100 as percentage_HDC
From CovidProject..CovidDeaths$
Where continent is not null
Group by location, population
order by total_Death_Count desc

--The above but by the income rate
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
where location like '%income%'
Group by location, population
order by total_Death_Count desc

--The above but by continent
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
Where continent is null
Group by location, population
order by continent desc


--Continent with the highest death counts per population
Select continent, MAX(cast(total_deaths as float)) as total_Death_Count
From CovidProject..CovidDeaths$
Where continent is not null
Group by continent
order by total_Death_Count desc

--OR
--The above but by the variation in continent
Select continent, MAX(cast(total_deaths as float)) as total_Death_Count
From CovidProject..CovidDeaths$
where (continent like '%Europe%' OR continent like '%Africa%' OR continent like '%Asia%' OR continent like '%North America%' 
		OR continent like '%South America%' OR continent like '%Oceania%')
Group by continent
order by total_Death_Count desc


--The above but by the income rate
--Select continent, SUM(total_deaths) as total_Death_Count, population
--From CovidProject..CovidDeaths$
--where (continent like '%Europe%' OR continent like '%Africa%' OR continent like '%Asia%' OR continent like '%North America%' 
		--OR continent like '%South America%' OR continent like '%Oceania%')
--Group by continent, population
--order by total_Death_Count desc



--Showing country's  total death count per the poulation
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
Where location like '%Nigeria%'
Group by location, population

--Showing global on daily basis
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
			 SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths$
Where continent is not null
Group by date 
order by 1,2

--Total cases & deaths since inception
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths$
Where continent is not null 
order by 1,2



--Join the two tables
Select *
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date

--Showing total population VS new vaccination on daily basis
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null
order by 2,3

--Showing total population VS new vaccination on daily basis
--CONVERT function do same thing as CAST function
--In the conversion, do not use INT so as to avoid arithmetic or data overflow
--You cannot use a newly created column immediately
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	   SUM(convert(float, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as Vaccinated 
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null
order by 2,3

--You cannot use a newly created column immediately (in series/LOC)
--To solve this, you either use a CTE or TEMP
--Using CTE
--To get the percentage of vaccinated against population
With PopVsVac (continent, location, date, population, new_vaccinations, Vaccinated)
as (
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	   SUM(convert(float, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as Vaccinated 
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null
)
Select *, (Vaccinated/population)*100 as Vac_per_Pop
From PopVsVac

--Using TEMP table
--Add the DROP statement so that you can change anything within the below LOC
Drop Table if exists #PercentagePopulationVaccinated
Create table #PercentagePopulationVaccinated
	(
	  continent nvarchar (255), location nvarchar (255), date datetime, population numeric,
	  new_vaccination numeric, Vaccinated numeric
	)
Insert into #PercentagePopulationVaccinated
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	   SUM(convert(float, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as Vaccinated 
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null

Select *, (Vaccinated/population)*100 as Vac_per_Pop
From #PercentagePopulationVaccinated

---------------------------------------------------------------------------------------------

--CREATING VIEWS 

--Creating view to store data for later visualization
Create View PercentPopulationVaccinated as 
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	   SUM(convert(float, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as Vaccinated 
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null


--VIEWING total population VS new vaccination on daily basis
Create View NewlyVaccinated as 
Select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
	   SUM(convert(float, CV.new_vaccinations)) OVER (partition by CD.location order by CD.location, CD.date) as Vaccinated 
From CovidProject..CovidDeaths$ CD
Join CovidProject..CovidVaccinations$ CV
	on CD.location = CV.location
	and CD.date = CV.date
where CD.continent is not null


--Total cases & deaths since inception
Create View OverallCasesNDeath as 
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths$
Where continent is not null 


--Viewing the Total Cases vs Total Deaths
Create View CasesVsDeaths as 
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From CovidProject..CovidDeaths$
where (location like '%Nigeria%' AND continent is not null)


--Looking at the Total Cases vs Population
Create View TotalCasesVsPopulation as 
Select location, date, total_cases, population, (total_cases/population)*100 as percentage_infected
From CovidProject..CovidDeaths$
where location like '%Nigeria%'


--Viewing countries with the highest infection rate compared to their population
Create View InfectionRateByCountry as 
Select location, MAX(total_cases) as Highest_Infection_Rate, population, (MAX(total_cases)/population)*100 as percentage_HIR
From CovidProject..CovidDeaths$
Where continent is not null
Group by location, population


--Viewing countries with highest total death counts per population
Create View CountriesHighestDeath as 
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population, (MAX(cast(total_deaths as float))/population)*100 as percentage_HDC
From CovidProject..CovidDeaths$
Where continent is not null
Group by location, population


--Viewing by the income rate
Create View DeathByIncomeRate as 
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
where location like '%income%'
Group by location, population


--Viewing by continent
Create View DeathByContinent as 
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
Where continent is null
Group by location, population



--Continent with the highest death counts per population
Create View DeathCountsPerPopulation as 
Select continent, MAX(cast(total_deaths as float)) as total_Death_Count
From CovidProject..CovidDeaths$
Where continent is not null
Group by continent


--Showing country's  total death count per the poulation
Create View TotalDeathsPerPopulation as 
Select location, MAX(cast(total_deaths as float)) as total_Death_Count, population
From CovidProject..CovidDeaths$
Where location like '%Nigeria%'
Group by location, population

--Showing global on daily basis
Create View DailyGlobalDeaths as 
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
			 SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths$
Where continent is not null
Group by date 



---To show one of our views
Select *
From PercentPopulationVaccinated


