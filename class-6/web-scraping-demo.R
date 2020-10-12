install.packages("rvest")
library(rvest)
library(tidyverse)

# Data Scraping with rvest

# https://www.nycgovparks.org/events/f2020-10-12
# ^^ this website contains a paginated list of parks events in NYC.  Because the list is well-structured,
# we can pull out the values we are interested in as text using the library rvest


# first let's make an empty dataframe to store our new dataset (no values, just column names and types)
# these are the four values we'd like to scrape from each event
# everything will be character() for now
events_table <- data.frame(
  title=character(),
  description=character(),
  start_date=character(),
  street_address=character()
)

# load the entire website using rvest's html() function
# raw_html is a list of "nodes" parsed from the page, we can use rvests's functions on these nodes
# to isolate the parts of the page we want to pull text from
raw_html <- html('https://www.nycgovparks.org/events/f2020-10-12')

# all of the information for an event is located within an element with class 'event'
# we can select all .event elements using html_nodes().
# parks_events is a list of nodes representing each of the 10 events on the page
parks_events <-
  html_nodes(raw_html, ".event") # get all elements with class "event"

# loop over each event node
# for each event, we want to run some code to pull out the individual values we are interested in
for (e in parks_events) {

  # find the element with class 'event-title', then find its descendant 'a' element, then get its text
  title <- html_node(e, ".event-title") %>% html_node('a') %>% html_text()

  # find the element with class 'description', get its text
  description <- html_node(e, ".description") %>% html_text()

  # start_date and street_address are tricky, because they aren't stored as text
  # rather, they are attributes of meta elements, hidden from view on the page but available
  # in the page source.  Furthermore, street address info doesn't exist for every event
  # to pull them out we need some more logic

  # first get all of the meta elements
  meta_elements <- html_nodes(e, "meta")

  # create the new values as empty strings
  # we will update them if they exist in this event
  start_date <- ''
  street_address <- ''

  for (m in meta_elements) {
    # each meta element has an 'itemprop' attribute describing its type (startDate, streetAddress, etc)
    # each meta element has a 'content' attribute with the value corresponding to the itemprop
    itemprop <- html_attr(m, 'itemprop')
    content <- html_attr(m, 'content')

    # if itemprop is 'startDate', update start_date to be the value of 'content'
    if (itemprop == 'startDate') {
      start_date <- content
    }

    # if itemprop is 'streetAddress', update street_address to be  the value of 'content'
    if (itemprop == 'streetAddress') {
      street_address <- content
    }
  }

  # now we append a row to the events_table dataframe using add_row() (part of tidyverse)
  events_table <- add_row(
    events_table,
    title=title,
    description=description,
    start_date=start_date,
    street_address=street_address
  )
}

# This example only gets us the first page of results.  When you click "Next>" you will see that the url
# changes to add /p2 for page 2, /p3 for page 3 and so on.
# Scraping multiple pages could be accomplished by turning the above code into a function,
# creating our new dataframe for each page or events, then binding them all together into one dataframe.
