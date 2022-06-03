# Replication package for _Blockchain for Business Process Enactment: A Taxonomy and Systematic Literature Review_. 

This package contains the data sets and scripts used for the _Blockchain for Business Process Enactment:
A Taxonomy and Systematic Literature Review_ paper, in submission at the BPM 2022 Blockchain Forum. It contains the classification result in `csv` and each phase of the systematic literature review in `xlsx` and `ods` format. The paper reviews the current state-of the-art in blockchain-based business process enactment.

## Content

- **`cost.R`**: Script to calculate and create Figure 2 in the paper, where we compare execution costs at the time of publication and in 2021. The calculation is based on the following data sets: 
  - `data/cost.csv`: the extracted cost taken from the primary studies,
  - `data/gasprice.csv`: histroical data of gas prices, taken from Etherscan (https://etherscan.io/chart/gasprice), and
  -  `data/eth-usd.csv`: historical data of ETH US$ exchange rates, taken from Yahoo Finance (https://finance.yahoo.com/quote/ETH-USD/).
-  **`data/extraction.csv`**: Result of our classification of primary studies in `.csv` format; the classification is according to the dimension of our taxonomy (see our paper). 
-  **`data/slr.xlsx` and `data/slr.ods`**: Interactive spreadsheet containing each phase of the performed systematic literature review, including the reasoning behind the exclusion of papers. For convenience, we also include a hosted interactive spreadsheet of
our SLR at https://tubcloud.tu-berlin.de/s/M8JQtaRX5JkjXXZ.
-  **`publication_trends.R`**: Script to evaluate the publication trends and author networks, not featured in the paper. 
