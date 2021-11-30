select *
from PortofolioProject..CovidDeaths
order by 3,4

--select *
--from PortofolioProject..CovidVaccination
--order by 3,4

-- selecting data that we are going to use
select 
	date, 
	location, 
	total_cases, 
	total_deaths, 
	new_cases, 
	population
from PortofolioProject..CovidDeaths
where continent is not null
order by location asc

--checking total cases vs total deaths
select
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as death_percentage
from PortofolioProject..CovidDeaths
where continent is not null
order by location asc
--this will shows likelihood of dying if you are contracted by covid

--Checking total cases vs population
select
	location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 as infection_rate
from PortofolioProject..CovidDeaths
where continent is not null
order by location asc
--this will shows how many percent of population that got covid

--looking at the country at the highest infection rate
select
	location,
	max(total_cases) as highest_infection_count,
	population,
	max((total_cases/population))*100 as infection_rate
from PortofolioProject..CovidDeaths
where continent is not null
group by location, population
order by infection_rate desc

--looking at the country at the highest death count per population
select
	location,
	population,
	max(total_deaths) as total_death_count,
	max((total_deaths/population))*100 as death_rate
from PortofolioProject..CovidDeaths
where continent is not null
group by location, population
order by death_rate desc

--looking at the continents with the highest death count per population
select
	continent,
	max(total_deaths) as total_death_count,
	max((total_deaths/population))*100 as death_rate
from CovidDeaths
where continent is not null
group by continent
order by death_rate desc

--Global Numbers
select
	date,
	sum(new_cases) as total_cases,
	sum(new_deaths) as total_deaths,
	(sum(new_deaths)/sum(new_cases))*100 as death_rate 
from CovidDeaths
where continent is not null
group by date

--we are going to join the coviddeaths table and the covidvaccination table
--then we are going to see total population vs total vaccination
--we are going to use CTE to make a temporary name so that we could calculate the increment of the vaccination rate
with popvsvac (continent, location, date, population, new_vaccination, vaccination_done)
as
(
select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as vaccination_done
from CovidDeaths as dea
join CovidVaccination as vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)
select * , (vaccination_done/population)*100 as vaccination_rate
from popvsvac

--we could also make a temporary table to calculate the increment of the vaccination rate
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccination numeric,
vaccination_done numeric
)
insert into #PercentPopulationVaccinated
select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as vaccination_done
from CovidDeaths as dea
join CovidVaccination as vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
select * , (vaccination_done/population)*100 as vaccination_rate
from #PercentPopulationVaccinated

--creating a view to store for data visualization later
create view PercentPopulationVaccinated as
select
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as vaccination_done
from CovidDeaths as dea
join CovidVaccination as vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null