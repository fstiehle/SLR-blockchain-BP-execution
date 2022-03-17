library(readr)
library(dplyr)
library(tidyr)
library(igraph)
library(graphlayouts)
library(ggraph)
library(ggplot2)

extraction <- read_csv("Projects/Puffin/SLR Analysis/SLR_Blockchain_BP_Execution/data/extraction_cost.csv", 
                            col_types = cols(`Avg. Cost / Instance Ex` = col_number(), 
                                             `One Time Cost` = col_number(),
                                             `Year` = col_date(format = "%Y")), 
                            skip = 1) %>%
  filter(Included == TRUE)

gasprice <- read_csv("Projects/Puffin/SLR Analysis/SLR_Blockchain_BP_Execution/data/gasprice.csv",
                     col_types = cols(`Date(UTC)` = col_date(format = "%m/%d/%Y")))
eth_usd <- read_csv("Projects/Puffin/SLR Analysis/SLR_Blockchain_BP_Execution/data/eth-usd.csv",
                    col_types = cols(Date = col_date(format = "%Y-%m-%d")))


colors = c("#724073", "#1E2759", "#124019", "#F2DC6D", "#000000")
cost_column_name <- "Avg. Cost / Instance Ex"
wei_to_eth <- function(wei) {
  wei / 10^18
}
stopifnot(all.equal(wei_to_eth(1000000000000000000), 1))
          
# Cost
#######################################################
extraction_cost <- extraction %>%
  filter(Cost == TRUE) %>%
  filter(Unit == 'Gas') %>%
  select(Year, Title, cost_column_name, "One Time Cost", "Case", "Unit") %>%
  drop_na(cost_column_name) 

# Convert Wei to ETH
gasprice$`Value (Eth)` <- gasprice$`Value (Wei)` %>% 
  wei_to_eth

# We're only interested in the yearly price
# gasprice <- gasprice %>% filter(`Date(UTC)` %in% extraction_cost$Year) 

# Calculate Ex price in ETH
extraction_cost <- merge(extraction_cost, gasprice, by.x = "Year", by.y = "Date(UTC)")
extraction_cost$`Ex Cost (Eth)` <- extraction_cost$`Avg. Cost / Instance Ex` * extraction_cost$`Value (Eth)`

# Calculate Ex price in $
extraction_cost <- merge(extraction_cost, eth_usd, by.x = "Year", by.y = "Date")
extraction_cost$`Ex Cost ($)` <- extraction_cost$`Ex Cost (Eth)` * extraction_cost$Open

# Calculate Ex price in $ today
eth_usd_today <- eth_usd %>% 
  filter(Date == as.Date("2022-01-01"))
gasprice_today <- gasprice %>% 
  filter(`Date(UTC)` == as.Date("2022-01-01"))
extraction_cost$`Ex Cost Today ($)` <- extraction_cost$`Avg. Cost / Instance Ex` * gasprice_today$`Value (Eth)` * price_today$Open

# Plotting
ggplot(extraction_cost, aes(x=Year, y=`Ex Cost ($)`)) +
  geom_linerange(aes(ymin = `Ex Cost ($)`, ymax = `Ex Cost Today ($)`), 
                 position = position_dodge2(width=200)) +
  geom_point( aes(x=Year, y=`Ex Cost ($)`), 
              color=colors[1], 
              size=3, 
              position = position_dodge2(width=200)) +
  geom_point( aes(x=Year, y=`Ex Cost Today ($)`), 
              color='red', 
              alpha=0.5, 
              size=3, 
              position = position_dodge2(width=200)) + 
  scale_y_continuous(trans = "log10")