library(readr)
library(dplyr)
library(tidyr)
library(igraph)
library(graphlayouts)
library(ggraph)
library(ggplot2)

extraction <- read_csv("Projects/Puffin/SLR Analysis/data/extraction.csv",
                       col_types = cols(...35 = col_skip(), 
                                        Year = col_date(format = "%Y"),
                                        Comments = col_skip()), 
                       skip = 1) %>%
  filter(Included == TRUE)

colors = c("#724073", "#1E2759", "#124019", "#F2DC6D", "#000000")

# Investigating the publication interest over the years 
#######################################################
extraction_years <- extraction %>%
  select(Year) %>%
  filter(Year != as.Date("2022-01-01")) %>%
  count(Year) %>%
  drop_na 

ggplot(extraction_years, aes(x=Year, y=n)) +
  geom_line(color=colors[1]) +
  geom_point(color=colors[3], size=3) + 
  scale_x_date(date_labels = "%Y", breaks = "1 year") +
  scale_y_continuous(breaks=seq(1,11, by = 1)) +
  #geom_smooth(method=lm, color=colors[4], se=FALSE, alpha=0.2) +
  labs(x = "Year", y ="Number")

# Investigating the social network of authors
#######################################################
bibliography <- read_csv("Projects/Puffin/SLR Analysis/data/bibliography.csv")
extraction_authors <- bibliography %>%
  select(Author, Key) %>%
  separate(
    Author,
    c("A","B","C","D","E","F","G","H","I","J"),
    sep = "; ",
  ) %>%
  gather(author_pos, name, 0:10) %>%
  drop_na %>% 
  separate(
    name,
    c("Surname","Firstname"),
    sep = ", ",
  )

connections <- extraction_authors %>% 
  group_by(Key) %>%
  summarize(n=n()) %>%
  filter(n > 2) %>%
  select(Key)

rm(tmp)
for (key in connections$Key) {
  combinations <- extraction_authors %>% 
    filter(Key == key) %>%
    select(Surname) %>% t %>% combn(2) %>% t
  if (exists("tmp")) {tmp <- rbind(tmp, combinations)} else {tmp <- combinations}
}
edges <- tmp %>% 
  as.data.frame %>% 
  group_by(V1, V2) %>% 
  summarise(n=n()) %>%
  filter(n > 1)

nodes <- edges %>% 
  gather(V1,Surname,0:2) %>%
  select(Surname) %>% 
  unique 

authors <- extraction_authors %>% 
  group_by(Surname) %>%
  summarise(n=n()) %>%
  filter(Surname %in% nodes$Surname) 
 
network <- graph_from_data_frame(edges, vertices=authors, directed=FALSE)
V(network)$size = authors$n
E(network)$width = edges$n

ggraph(network, layout="kk") +
  geom_edge_link(aes(edge_width = edges$n), alpha = 0.9, edge_colour = colors[1]) +
  geom_node_point(aes(size = size), colour=colors[3]) +
  geom_node_label(aes(label = authors$Surname), 
                  size = 3.5, 
                  colour=colors[5],
                  alpha=0.8, 
                  repel=TRUE,
                  label.size = 0) +
  scale_edge_width(range = c(0.5, 2.5)) +
  scale_size(range = c(2, 11)) +
  theme_graph() +
  theme(legend.position = "none")
