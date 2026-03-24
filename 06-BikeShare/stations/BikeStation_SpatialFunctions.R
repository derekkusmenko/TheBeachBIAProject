# ==============================================================================
# TITLE: Toronto BIA Spatial Analysis Toolkit
# DESCRIPTION: Functions for fetching, categorizing, and selecting Bike Share
#              stations within BIA and Neighborhood boundaries.
# ==============================================================================

library(sf)
library(tidyverse)
library(jsonlite)
library(ggspatial)
library(mapview)
library(leaflet)
library(htmltools)
library(shiny)
library(miniUI)
library(DT)

# --- DATA FETCHING FUNCTIONS ---

# Load Toronto Open Data features and set projection
get_to_resource <- function(id) {
  opendatatoronto::get_resource(id) |>
    st_transform(4326)
}


# Fetch boundary data by type (neighborhood/bia) and name
get_geo_data <- function(type = c("neighborhood", "bia"), area_name) {
  id <- if (match.arg(type) == "neighborhood") {
    "0719053b-28b7-48ea-b863-068823a93aaa" 
  } else {
    "4d9216bd-71e7-4416-8d17-c2699c6354f0"
  }
  
  get_to_resource(id) |>
    filter(AREA_NAME == area_name)
}

# Download live station locations from Bike Share API
get_bike_stations <- function() {
  res <- fromJSON("https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_information")
  res$data$stations |>
    as_tibble() |>
    select(station_id, name, lat, lon) |>
    st_as_sf(coords = c("lon", "lat"), crs = 4326)
}

# --- SPATIAL PROCESSING ---

# Assign stations to zones based on spatial overlap
categorize_stations <- function(stations, bia_sf, nbhd_sf = NULL, buffer_dist = 500) {
  primary_area <- if (!is.null(nbhd_sf)) nbhd_sf else bia_sf
  outer_buffer <- st_buffer(primary_area, dist = buffer_dist)
  
  in_bia <- st_intersects(stations, bia_sf, sparse = FALSE)[, 1]
  in_nbhd <- if (!is.null(nbhd_sf)) {
    st_intersects(stations, nbhd_sf, sparse = FALSE)[, 1]
  } else {
    rep(FALSE, nrow(stations))
  }
  in_buffer <- st_intersects(stations, outer_buffer, sparse = FALSE)[, 1]
  
  stations |>
    mutate(
      location_type = case_when(
        in_bia    ~ "BIA Commercial Strip",
        in_nbhd   ~ "Neighborhood Stations",
        in_buffer ~ "Nearby Buffer Stations",
        TRUE      ~ "Outside"
      )
    ) |>
    filter(location_type != "Outside")
}


# --- STATIC MAPPING FUNCTION ---

plot_static_network <- function(categorized_data, bia_sf, nbhd_sf, curated_ids, area_label = "The Beach") {
  
  # Prepare the selection status
  map_data <- categorized_data %>%
    mutate(selection_status = if_else(station_id %in% curated_ids, "Selected", "Other Nearby"))
  
  # Build the plot
  ggplot() +
    # 1. Add the actual Toronto street map (CartoDB Light style)
    annotation_map_tile(type = "cartolight", zoomin = 0) +
    
    # 2. Add Neighbourhood Boundary
    geom_sf(data = nbhd_sf, fill = "#3498db", alpha = 0.05, color = "#2980b9", linetype = "dashed") +
    
    # 3. Add BIA Boundary
    geom_sf(data = bia_sf, fill = "#f39c12", alpha = 0.15, color = "#d35400", size = 0.7) +
    
    # 4. Add Stations
    geom_sf(data = map_data, aes(color = selection_status), size = 2.5, alpha = 0.8) +
    
    # 5. Styling & Colors
    scale_color_manual(values = c("Selected" = "#27ae60", "Other Nearby" = "#bdc3c7")) +
    theme_minimal() +
    
    # 6. Remove lat/lon axes and gridlines for a clean look
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 14)
    ) +
    
    labs(
      title = paste("Infrastructure Analysis:", area_label),
      subtitle = paste(length(curated_ids), "Curated Stations | BIA & 500m Buffer"),
      color = "Station Status",
      caption = "Map tiles by CartoDB | Data: Bike Share Toronto"
    )
}

# --- STATIC MAPPING FUNCTION ---

plot_static_network <- function(categorized_data, bia_sf, nbhd_sf, curated_ids, area_label = "The Beach") {
  
  # Prepare the selection status
  map_data <- categorized_data %>%
    mutate(selection_status = if_else(station_id %in% curated_ids, "Selected", "Other Nearby"))
  
  # Build the plot
  ggplot() +
    # 1. Add the actual Toronto street map (CartoDB Light style)
    annotation_map_tile(type = "cartolight", zoomin = 0) +
    
    # 2. Add Neighbourhood Boundary
    geom_sf(data = nbhd_sf, fill = "#3498db", alpha = 0.05, color = "#2980b9", linetype = "dashed") +
    
    # 3. Add BIA Boundary
    geom_sf(data = bia_sf, fill = "#f39c12", alpha = 0.15, color = "#d35400", size = 0.7) +
    
    # 4. Add Stations
    geom_sf(data = map_data, aes(color = selection_status), size = 3, alpha = 0.8) +
    
    # 5. Styling & Colors
    scale_color_manual(values = c("Selected" = "#27ae60", "Other Nearby" = "#bdc3c7")) +
    theme_minimal() +
    
    # 6. Remove lat/lon axes and gridlines for a clean look
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank(),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 12)
    ) +
    
    labs(
      title = paste("Infrastructure Analysis:", area_label),
      subtitle = paste(length(curated_ids), "Curated Stations | BIA & 500m Buffer"),
      color = "Station Status",
      caption = "Data: Bike Share Toronto"
    )
}

# --- VISUALIZATION & SELECTION ---

# Generate interactive map with a title
generate_labeled_bike_map <- function(bia_name, nbhd_name = NULL, buffer_dist = 500) {
  bia_geom <- get_geo_data(type = "bia", bia_name)
  nbhd_geom <- if(!is.null(nbhd_name)) get_geo_data(type = "neighborhood", nbhd_name) else NULL
  all_stations <- get_bike_stations()
  
  categorized_data <- categorize_stations(all_stations, bia_geom, nbhd_geom, buffer_dist)
  
  m <- mapview(bia_geom, col.regions = "#f39c12", alpha.regions = 0.4, 
               layer.name = "BIA", map.types = "CartoDB.Positron")
  
  if (!is.null(nbhd_geom)) {
    m <- m + mapview(nbhd_geom, col.regions = "#3498db", alpha.regions = 0.1, layer.name = "Neighborhood")
  }
  
  m <- m + mapview(categorized_data, zcol = "location_type", layer.name = "Station Category", cex = 7)
  
  map_title <- tags$div(
    style = "position: fixed; top: 10px; left: 50px; background: rgba(255,255,255,0.8); 
             padding: 10px; border-radius: 5px; border: 2px solid #ccc; z-index:9999; 
             font-size: 16px; font-weight: bold; font-family: sans-serif;",
    paste("Bike Share Network:", bia_name)
  )
  
  m@map <- m@map %>% addControl(html = map_title, position = "topleft")
  return(m)
}

# Visual Selector Gadget
collect_stations_visually <- function(stations_sf, nbhd_sf, bia_sf) {
  ui <- miniPage(
    gadgetTitleBar("Station Selector: Click to Toggle"),
    miniContentPanel(padding = 0,
                     fillRow(flex = c(2, 1),
                             leafletOutput("map", height = "100%"),
                             div(style = "padding: 10px; height: 100%; border-left: 1px solid #ddd;", DTOutput("table"))
                     )
    )
  )
  
  server <- function(input, output, session) {
    selected_ids <- reactiveVal(character())
    
    output$map <- renderLeaflet({
      leaflet() |>
        addProviderTiles("CartoDB.Positron") |>
        addPolygons(data = nbhd_sf, color = "blue", weight = 1, dashArray = "5, 5", fillColor = "blue", fillOpacity = 0.05) |>
        addPolygons(data = bia_sf, color = "darkorange", weight = 2, fillColor = "orange", fillOpacity = 0.2) |>
        addCircleMarkers(data = stations_sf, layerId = ~station_id, radius = 7, color = "white", fillColor = "#2c3e50", weight = 1, fillOpacity = 0.7, label = ~name)
    })
    
    observeEvent(input$map_marker_click, {
      id <- input$map_marker_click$id
      clean_id <- gsub("^sel_", "", id)
      new_list <- if (clean_id %in% selected_ids()) setdiff(selected_ids(), clean_id) else c(selected_ids(), clean_id)
      selected_ids(new_list)
      
      proxy <- leafletProxy("map") |> clearGroup("highlights")
      if(length(new_list) > 0) {
        sel_data <- stations_sf[stations_sf$station_id %in% new_list, ]
        proxy |> addCircleMarkers(data = sel_data, layerId = ~paste0("sel_", station_id), radius = 9, color = "black", fillColor = "#00ff00", weight = 2, fillOpacity = 1, group = "highlights", label = ~paste("Selected:", name))
      }
    })
    
    output$table <- renderDT({
      req(selected_ids())
      stations_sf |> st_drop_geometry() |> filter(station_id %in% selected_ids()) |> select(ID = station_id, Name = name) |> datatable(options = list(dom = 'tp', pageLength = 10, scrollY = "300px"), rownames = FALSE, selection = 'none')
    })
    
    observeEvent(input$done, { stopApp(selected_ids()) })
    observeEvent(input$cancel, { stopApp(NULL) })
  }
  
  runGadget(ui, server, viewer = paneViewer(minHeight = 550))
}


