library(readr)
library(dplyr)
library(tidyr)
library(igraph)
library(graphlayouts)
library(ggraph)
library(ggplot2)

extraction <- read_csv("data/cost.csv", 
                            col_types = cols(`Avg. Cost / Instance Ex` = col_number(), 
                                             `One Time Cost` = col_number(),
                                             `Year` = col_date(format = "%Y")), 
                            skip = 1) %>%
  filter(Included == TRUE) %>%
  filter(Cost == TRUE)

gasprice <- read_csv("data/gasprice.csv",
                     col_types = cols(`Date(UTC)` = col_date(format = "%m/%d/%Y")))
eth_usd <- read_csv("data/eth-usd.csv",
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

# We're only interested in the yearly prices
gasprice$`Year` <- strftime(gasprice$`Date(UTC)`, "%Y")
gasprice <- aggregate(`Value (Eth)` ~ Year,
                        gasprice,
                        FUN = mean)

eth_usd$Year <- strftime(eth_usd$Date, "%Y")
eth_usd <- aggregate(`Open` ~ Year,
                     eth_usd,
                     FUN = mean)

extraction_cost$Date <- extraction_cost$Year
extraction_cost$Year <- strftime(extraction_cost$Date, "%Y")

# Calculate Ex price in ETH
extraction_cost <- merge(extraction_cost, gasprice, by.x = "Year", by.y = "Year")
extraction_cost$`Ex Cost (Eth)` <- extraction_cost$`Avg. Cost / Instance Ex` * extraction_cost$`Value (Eth)`

# Calculate Ex price in $
extraction_cost <- merge(extraction_cost, eth_usd, by.x = "Year", by.y = "Year")
extraction_cost$`Ex Cost ($)` <- extraction_cost$`Ex Cost (Eth)` * extraction_cost$Open

# Calculate Ex price in $ today
eth_usd_today <- eth_usd %>% 
  filter(Year == "2021")
gasprice_today <- gasprice %>% 
  filter(Year == "2021")
extraction_cost$`Ex Cost Today ($)` <- extraction_cost$`Avg. Cost / Instance Ex` * gasprice_today$`Value (Eth)` * eth_usd_today$Open

# Plotting
ggplot(extraction_cost, aes(x=Date, y=`Ex Cost ($)`)) +
  geom_linerange(aes(ymin = `Ex Cost ($)`, ymax = `Ex Cost Today ($)`), 
                 position = position_dodge2(width=250)) +
  geom_point( aes(x=Date, y=`Ex Cost ($)`, color="Cost at Publication", shape="Cost at Publication"), 
              size=3, 
              position = position_dodge2(width=250)) +
  geom_point( aes(x=Date, y=`Ex Cost Today ($)`, color="Cost Today", shape="Cost Today"), 
              size=2,
              shape=17,
              position = position_dodge2(width=250)) + 
  scale_y_continuous(trans = "log10") +
  scale_x_date(date_labels = "%Y", breaks = "1 year", minor_breaks = NULL) +
  scale_color_manual(name = element_blank(),
               values = c("Cost at Publication" = colors[1], "Cost Today" = "red")) +
  scale_shape_manual(name = element_blank(), values = c("Cost at Publication" = 16, "Cost Today"= 17)) +
  theme(legend.position = "bottom") +
  xlab(label = 'Publication Year') +
  ylab(label = 'Execution Cost ($)')
ggsave("cost.pdf", width = 5, height = 4)