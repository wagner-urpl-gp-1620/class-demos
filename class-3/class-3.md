---
title: "Plotting charts in RStudio, cleaning data with janitor"
description: |
  A set of examples for simple charting in R, and cleaning data with janitor
---


```{r setup, include=FALSE}
knitr::opts_chunk$set(
	echo = TRUE,
	message = FALSE,
	warning = FALSE,
	rows.print=5
)
options(tibble.max_extra_cols = 5, tibble.print_max = 5)
library(fs) # cross-platform file system operations
```

# Plotting charts in RStudio

This document provides an overview of plotting charts with ggplot and using tidyr to clean/prep data.

The content was adapted from this [Intro to R for Data Analysis workshop](https://github.com/wagner-mspp-2020/r-demos/blob/master/r-demo.Rmd) by Maxwell Austensen  



# Making graphs with `ggplot2`

Now let's visualize this new dataset we've created using the package `ggplot2`.

ggplot2 is designed to work with dataframe inputs, so the first step is always to use `ggplot(data = your_dataframe)`. You can build plots step by step by adding layers with `+`. The second step is always `aes()`, which establishes the *aes*thetics of the plot by mapping columns from the dataframe to aesthetic elements of the plot. For example, here we are setting the `x` axis values to landlord names and `y` to the total number of HPD violations. After the `aes` is set, you can use one of the many `geom_*()` functions to transform the aesthetics into a type of plot. In this case we want a column plot, so we use `geom_column()`. Finally, we can label any part of our graph with `labs()`.
```{r, layout="l-body-outset"}
ggplot(data = bk_landlords) +
  aes(x = landlord_name, y = total_viol) +
  geom_col() +
  labs(
    title = '"Worst" Landlords in Brooklyn',
    subtitle = "Total HPD Violations in All Buildings for 2017",
    x = NULL,
    y = "Number of Violations",
    caption = "Source: NYC Public Advocate's Landlord Watchlist"
  )
```

With only the defaults ggplot2 graphs tend to look pretty good, and are not too difficult to create. However, there are definitely some things we'll want to improve with this graph. Luckily, there is a near-infinite amount of customization possible with ggplot2 to get the plot looking exactly the way you want.

To start, there are clearly too many landlords to display clearly in a graph like this, so we can use dplyr to`arrange` the data by violations and `filter` to keep only the top 10 landlords. The first landlord name doesn't match the same format as the other, so let's remove the `" Properties"` part using `str_remove` from the `stringr` package. It would also be nice if the landlords were sorted in order of the number of violations. To achieve this we can change the `landlord_name` column from a string to instead use R's `factor` datatype, which allows us to specify an ordering to the values. Specifically, we'll use the function `fct_reorder()` from the package `forcats` to make the column a factor and put the values in order based on the values of the `total_viol` column.

Now we can use this new dataframe with ggplot2 and make a few more changes to improve the graph further. One obvious problem with our initial graph is that the landlord names are completely illegible due to overlap. To solve this we can use the ggplot2 function `coord_flip()` to flip our bars sideways so we can read the labels more cleanly. Another smaller adjustment we can make it to format the violation count labels on our y-axis. To make changes to anything related to one of the *aes*thetic elements of a plot we can use one of the many `scale_*_*` functions. The first `*` is always one of the `aes` element types, and the second `*` indicates the type of data that is mapped to it. In our case we want to make a change to the y axis and we've mapped our count of violations to `y` so it a continuous scale, so the function we'll want to use is `scale_y_continuous()`. Now within that function we'll want to use the formatting function `comma` from the `scales` package on our axis labels. Lastly, we can use one of the `theme_*` functions to apply some alternative styling to the plot. These functions provide you some helpful preset styling, but you can make your own fine-tuned adjustments using `theme()`. This can get a bit overwhelming, but just to illustrate what's possible, here we'll remove the unnecessary lines on the plot, move the landlord name labels over a bit, and change the font of the caption.

<aside>
If you have a package already installed, you can use a function from it without loading it with `library()` by using `package::function()`. Here we are doing this for `scales::comma` because we only use this single function from the package once.
</aside>

```{r layout="l-body-outset"}
landlord_bk_10_worst <- bk_landlords %>%
  arrange(desc(total_viol)) %>%
  filter(row_number() <= 10) %>%
  mutate(
    landlord_name = str_remove(landlord_name, " Properties"),
    landlord_name = fct_reorder(landlord_name, total_viol)
  )
ggplot(data = landlord_bk_10_worst) +
  aes(x = landlord_name, y = total_viol) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  theme_minimal() +
  theme(
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(margin = margin(r = -15)),
    plot.caption = element_text(face = "italic", color = "darkgrey", margin = margin(t = 10))
  ) +
  labs(
    title = '10 "Worst" Landlords in Brooklyn',
    subtitle = "Total HPD Violations in All Buildings for 2017",
    x = NULL,
    y = "Number of Violations",
    caption = "Source: NYC Public Advocate's Landlord Watchlist"
  )
```

---

# Cleaning data with `janitor`

## clean_names() to handle column names that aren't code-friendly

You can pipe your dataframe from read_csv() into clean_names() and get a dataframe with cleaner column names.

```{r layout="l-body-outset"}
library(janitor)

your_data <- read_csv("path/to/data.csv") %>% clean_names()
```

This example is from student Renata Hegyi's work-in-progress homework assignment.

Here's a dataset of energy and water disclosure, `Energy_and_Water_Data_Disclosure_for_Local_Law_84_2020__Data_for_Calendar_Year_2019.csv`

If you open the CSV you will see that the column headers are human-friendly, and contain titlecase words separated by spaces, such as "NYC Building Identification Number (BIN)".  This column name is not so friendly for computers and code, and you may have issue referring to it.

Janitor's `clean_names()` function makes your column names more computer/code-friendly.  


```{r layout="l-body-outset"}
full_data <- read_csv(
  file="Energy_and_Water_Data_Disclosure_for_Local_Law_84_2020__Data_for_Calendar_Year_2019.csv",
  col_types = cols(
    'Postal Code'=col_character(),
    'Total GHG Emissions (Metric Tons CO2e)'= col_double(),
    'Site EUI (kBtu/ft²)'= col_double()
  )

) %>% clean_names ()
```

Piping the output of read_csv() into clean_names() turns `NYC Building Identification Number (BIN)` into `nyc_building_identificiation_number_bin`, stripping away the parentheses, spaces, and capital letters.

`janitor` has other functions too, such as `remove_empty()`, `get_dupes()`. Read more at [https://garthtarr.github.io/meatR/janitor.html](https://garthtarr.github.io/meatR/janitor.html)
