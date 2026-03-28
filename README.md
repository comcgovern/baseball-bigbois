Markdown
# MLB & MiLB Player Data Scraper

This R script pulls physical data (height and weight) for active baseball players across all levels of an MLB organization's system, from the major league club down to the Rookie/DSL levels. It queries the public (but undocumented) MLB Stats API and exports a clean, unified CSV dataset.

## Features
* **Full Organizational Depth:** Pulls data for MLB, AAA, AA, High-A, Single-A, Rookie, and DSL/ACL affiliations.
* **Data Cleaning:** Automatically converts raw string heights (e.g., `"6' 2\""`) into a clean `height_in` integer column (e.g., `74`).
* **Org Mapping:** Maps minor league players to their parent MLB organization for easy grouping and analysis.

## Prerequisites

This script requires R and the following packages:

* `httr` - For making API requests.
* `jsonlite` - For parsing the JSON responses.
* `dplyr` - For data manipulation.
* `purrr` - For mapping over the different sport/level IDs.
* `readr` - For writing the final CSV.

You can install any missing packages using:
```
install.packages(c("httr", "jsonlite", "dplyr", "purrr", "readr"))
```

## How to use
Clone this repository to your local machine.

Open the R script (e.g., baseball_bigbois.R) in RStudio or your preferred environment.

Run the script.

The script will fetch the data level by level, printing progress messages to the console.

## Output
The script generates a CSV file named mlb_milb_players_2026.csv in your working directory.

## Data Dictionary:
| Column | Type | Description |
| :--- | :--- | :--- |
| player_id | Integer | The MLB Stats API unique identifier for the player. |
| full_name | String | The player's first and last name. |
| position | String | The player's primary position abbreviation (e.g., "P", "SS"). |
| height_in | Integer | The player's height in total inches. |
| weight | Integer | The player's weight in pounds. |
| team | String | The specific team the player is currently assigned to (e.g., "Norfolk Tides"). |
| organization | String | The parent MLB organization (e.g., "Baltimore Orioles"). |

## Notes on the MLB Stats API
This script relies on the MLB Stats API (statsapi.mlb.com/api/v1). Because this API is largely undocumented and subject to change by MLB Advanced Media, endpoints or data structures could shift over time. Currently, the script is configured to pull rosters for the 2026 season.
