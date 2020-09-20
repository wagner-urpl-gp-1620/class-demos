---
title: "Plotting charts in RStudio"
description: |
  A set of examples for simple charting in R
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

# Reshaping data with `tidyr`

> This demo for reshaping data was borrowed from [Sam Raby](https://github.com/sraby)
One of the core ideas of the tidyverse is ["tidy data"](https://tidyr.tidyverse.org/articles/tidy-data.html), which is a structure of datasets that facilitates analysis using the tools in tidyverse packages (`dplyr`, `ggplot2`, etc.). In tidy data:
1. Each variable forms a column.
2. Each observation forms a row.
3. Each type of observational unit forms a table.

> "Tidy datasets are all alike but every messy dataset is messy in its own way"
There are lots of common problems with datasets that make them untidy, and the package `tidyr` provides some powerful and flexible tools to help tidy them up into the standard format. Here's we'll focus on the most important of those tools, [`pivot_longer`](https://tidyr.tidyverse.org/reference/pivot_longer.html) and [`pivot_wider`](https://tidyr.tidyverse.org/reference/pivot_wider.html).

This annimation (from this [blog post](https://fromthebottomoftheheap.net/2019/10/25/pivoting-tidily/)) nicely captures the basic idea behind the `pivot_*` functions.

```{r echo=FALSE}
knitr::include_graphics(path("img", "tidyr-longer-wider.gif"))
```


<aside>
Reshaping data is one of the more complicated tasks in data cleaning, and in R there have been multiple attempts to create tools that make this process easier. You will surely come across a lot of the previous attempts at this, and this can often add to the confusion, but the current tidyverse standard is to use `tidyr` and the `pivot_*` functions. Below are some of the older packages and functions you may come across, but most/all of these have now been deprecated and you should instead use the newer `tidyr` methods: `base` R's `stack` and `unstack`, `reshape2`'s `melt` and `cast`, `tidyr`'s older `spread` and `gather`. You can read a more in depth article about all the ways to "pivot" your data in this [article](https://tidyr.tidyverse.org/articles/pivot.html) on the `tiyr` website.
</aside>

For this example of reshaping data we'll be working with a dataset of building in NYC that have rent stabilized units from http://taxbills.nyc/. This project scraped data from PDFs of property tax documents to get estimates for rent stabilized units counts in buildings across NYC. You can find a direct link to the data we're using and read up on the various field names at the [Github project page](https://github.com/talos/nyc-stabilization-unit-counts#user-content-data-usage)

In this separate script we download the file if we don't already have it.

```{r}
source(path("R", "download-rent-stab.R"))
```

```{r}
taxbills <- read_csv(path("data-raw", "rent-stab-units_joined_2007-2017.csv"))
```

For this demo, we only want to look at rent stabilized unit counts, which according to the Github documentation corresponds to column names that end in "uc". Let's also grab BBL (which is a unique identifier for NYC buildings) and Borough while we're at it:

```{r}
rentstab <- taxbills %>% select(borough, ucbbl, ends_with("uc") )
rentstab
```

<aside>
`starts_with(...)` and `ends_with(...)` are some of the the many "select helpers", which are a collection of functions that do just that: help you consisely select columns. In the case of these two functions, it matches a pattern of text at the beginning or end of the variable name. Some others include `everything()`, `contains()`, and `where()`. For more information see `?tidyselect`.
</aside>

Annoyingly, the data separates unit counts for different years into different columns, violating the principle of tidy data that every column is a variable. To make proper use of ggplot to visualizae our data, we'll need to first tidy up our dataset to get all of the year values in one column and the unit counts into another.

We can use `pivot_longer` to achieve this, performing this basic transformation:

```{r echo=FALSE, layout="l-body-outset"}
knitr::include_graphics(path("img", "tidy-pivoting-longer.png"))
# https://storybench.org/wp-content/uploads/2019/08/tidy-pivoting-longer.png
```


```{r}
rs_long <- rentstab %>%
  pivot_longer(
    ends_with("uc"),  # The multiple column names we want to mush into one column
    names_to = "year", # The title for the new column of names we're generating
    values_to = "units" # The title for the new column of values we're generating
  )
rs_long
```

Now that we have our data in the proper "long" (tidy) format, we can start working towards our desired plot. Let's try and make a yearly timeline of rent stab. unit counts for the boroughs of Manhattan and Brooklyn:


```{r}
rs_long_mn_bk_summary <- rs_long %>%
  filter(
    borough %in% c("MN","BK"), # Filter only Manhattan and Brooklyn values
    !is.na(units) # Filter out null unit count values
  ) %>%
  mutate(
    year = str_remove(year, "uc"), # Remove "uc" from year values
    year = as.integer(year) # change from character to integer
  ) %>%
  group_by(year, borough) %>%
  summarise(total_units = sum(units)) %>%
  ungroup()
rs_long_mn_bk_summary
```

Let's build our bar graph. We are going to specify a `dodge` property of the plot to show the Manhattan and Brooklyn bars side-by-side:

```{r layout="l-body-outset"}
rs_over_time_graph_col <- ggplot(rs_long_mn_bk_summary) +
  aes(x = year, y = total_units, fill = borough) +
  geom_col(stat = "identity", position = "dodge") +
  scale_x_continuous(breaks = 2007:2017) +
  scale_y_continuous(labels = scales::label_number_si()) +
  scale_fill_discrete(labels = c("BK" = "Brooklyn", "MN" = "Manhattan")) +
  labs(
    title = "Total Rent Stabilized Units over Time",
    subtitle = "Manhattan and Brooklyn, 2007 to 2017",
    fill = NULL,
    x = "Year",
    y = "Total Rent Stabilized Units",
    caption = "Source: taxbills.nyc"
  )
rs_over_time_graph_col
```

We can also change the `geom_*` function, and make a few other tweaks to change this to a line graph instead.

```{r layout="l-body-outset"}
rs_over_time_graph_line <- ggplot(rs_long_mn_bk_summary) +
  aes(x = year, y = total_units, color = borough) +
  geom_line() +
  scale_x_continuous(breaks = 2007:2017) +
  scale_y_continuous(labels = scales::label_number_si()) +
  scale_color_discrete(labels = c("BK" = "Brooklyn", "MN" = "Manhattan")) +
  labs(
    title = "Total Rent Stabilized Units over Time",
    subtitle = "Manhattan and Brooklyn, 2007 to 2017",
    color = NULL,
    x = "Year",
    y = "Total Rent Stabilized Units",
    caption = "Source: taxbills.nyc"
  )
rs_over_time_graph_line
```

If you ever need to make the opposite tranformation to go from "long" data to "wide", you can use `pivot_wider`. For example, we can reverse the change we made above using the following code.

```{r}
rs_wide <- rs_long %>%
  pivot_wider(
    names_from = year, # The current column containing our future column names
    values_from = units # The current column containing the values for our future columns
  )
rs_wide
```
