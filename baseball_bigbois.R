library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)

BASE <- "https://statsapi.mlb.com/api/v1"

# ── Helper ────────────────────────────────────────────────────────────────────
height_to_inches <- function(h) {
  h <- as.character(h)
  parsed <- regmatches(h, regexec("(\\d+)[^\\d]+(\\d+)", h))
  map_int(parsed, \(m) {
    if (length(m) < 3) return(NA_integer_)
    as.integer(m[2]) * 12L + as.integer(m[3])
  })
}

# ── 1. Build team → parent org lookup ────────────────────────────────────────
# Sport IDs: 1=MLB, 11=AAA, 12=AA, 13=High-A, 14=A, 16=Rookie, 17=DSL/ACL
SPORT_IDS <- c(1, 11, 12, 13, 14, 16, 17)

get_teams <- function(sport_id) {
  resp <- GET(BASE, path = "api/v1/teams",
              query = list(sportId = sport_id, season = 2026, activeStatus = "Y"))
  stop_for_status(resp)
  teams <- content(resp, as = "text", encoding = "UTF-8") |>
    fromJSON(flatten = TRUE) |>
    pluck("teams")

  if (is.null(teams) || nrow(teams) == 0) return(NULL)

  teams |>
    select(
      teamId      = id,
      teamName    = name,
      parentOrgId = any_of("parentOrgId"),
      parentOrg   = any_of("parentOrgName")
    ) |>
    mutate(sportId = sport_id)
}

message("Fetching team/org lookup...")
team_lookup <- map(SPORT_IDS, get_teams) |>
  bind_rows() |>
  # MLB teams are their own parent org
  mutate(parentOrg = if_else(sportId == 1, teamName, parentOrg))

# ── 2. Pull all active players per sport ─────────────────────────────────────
get_players <- function(sport_id) {
  resp <- GET(BASE, path = paste0("api/v1/sports/", sport_id, "/players"),
              query = list(season = 2026, gameType = "R"))
  stop_for_status(resp)
  people <- content(resp, as = "text", encoding = "UTF-8") |>
    fromJSON(flatten = TRUE) |>
    pluck("people")

  if (is.null(people) || nrow(people) == 0) return(NULL)

  message(sprintf("  Sport %d: %d players", sport_id, nrow(people)))

  # Normalize columns that may or may not exist
  safe_col <- function(df, col) if (col %in% names(df)) df[[col]] else NA_character_

  tibble(
    playerId         = people$id,
    fullName         = people$fullName,
    position         = safe_col(people, "primaryPosition.abbreviation"),
    height           = safe_col(people, "height"),
    weight           = as.integer(safe_col(people, "weight")),
    currentTeamId    = people$currentTeam.id,
    sportId          = sport_id
  )
}

message("Fetching players by sport level...")
players_raw <- map(SPORT_IDS, get_players) |> bind_rows()

# ── 3. Join org info ──────────────────────────────────────────────────────────
players <- players_raw |>
  left_join(
    team_lookup |> select(teamId, teamName, parentOrg),
    by = c("currentTeamId" = "teamId")
  ) |>
  mutate(height_in = height_to_inches(height)) |>
  select(
    player_id    = playerId,
    full_name    = fullName,
    position,
    height_in,
    weight,
    team         = teamName,
    organization = parentOrg
  ) |>
  arrange(organization, team, full_name)

# ── 4. Write output ───────────────────────────────────────────────────────────
out_path <- "mlb_milb_players_2026.csv"
write_csv(players, out_path)

message(sprintf("\nDone. %d players written to %s", nrow(players), out_path))
glimpse(players)
