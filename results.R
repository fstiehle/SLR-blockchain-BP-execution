library(readr)
library(dplyr)
library(tidyr)
library(igraph)
library(graphlayouts)
library(ggraph)
library(ggplot2)
library(stringr)

extraction <- read_csv("data/extraction.csv", 
                       col_types = cols(`Avg. Cost / Instance Ex` = col_number(), 
                                        `One Time Cost` = col_number(),
                                        `Year` = col_date(format = "%Y")), 
                       skip = 1) %>%
  filter(Included == TRUE)

build_result <- function(data, column_name, group_name) {
  tmp <- separate_rows(data, {{ column_name }}, sep = ",")
  tmp <- tmp %>% 
    group_by({{ column_name }}) %>%
    summarize(value=n()) %>%
    rename(c = {{ column_name }})
  tmp$group=group_name
  tmp
}

###############
tmp = extraction %>%
  filter(Enforcement == TRUE) %>%
  count()

data <- build_result(extraction, Model...11, "Model Support") %>% 
  filter(value >= 3)

tmp <- build_result(extraction, Strategy, "Resource Allocation Capability")
data <- rbind(data, tmp)

tmp <- build_result(extraction, `Process Evolution`, "Process Flexibility Capability")
data <- rbind(data, tmp)

data <- data %>%
  drop_na %>% 
  arrange(group, value)
# Make the plot

plt <- ggplot(data) +
  # Make custom panel grid
  geom_hline(
    aes(yintercept = y), 
    data.frame(y = c(0:3)),
    color = "lightgrey"
  ) + 
  # Add bars to represent the cumulative track lengths
  # str_wrap(region, 5) wraps the text so each line has at most 5 characters
  # (but it doesn't break long words!)
  geom_col(
    aes(
      x = reorder(str_wrap(c, 10), value),
      y = value,
      fill = group
    ),
    position = "dodge2",
    show.legend = TRUE,
    alpha = .9
  ) +
  # Make it circular!
  coord_polar()

plt