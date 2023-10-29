################################################################################ 
## FSCI 2022 FIGURE REPLICATION SCRIPT #########################################
## Replicates all figures in:
##   "The state of food systems worldwide in the countdown to 2030"
## Created by: Kate Schneider
## Last revised: 29 October 2023
## Contact: Kate Schneider, kschne29@jhu.edu
## Input datasets: See Metadata and Codebook, and Stata Data Management replication code
##      Baseline dataset: https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/blob/552a860f9f3fda4e0116d42690f6b9c86773f458/Supplementary%20Data%20-%20Appendix%20F%20-%20Baseline%20dataset.xlsx
##          (and labeled in Stata format: https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/blob/552a860f9f3fda4e0116d42690f6b9c86773f458/Supplementary%20Data%20-%20Appendix%20F%20-%20Baseline%20dataset.dta)
##      Time series and indicator-specific datasets available here:
##          https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/tree/552a860f9f3fda4e0116d42690f6b9c86773f458/FSCI%20analysis%20datasets
## Metadata and codebook: Supplementary Material - Appendix E - Metadata and Codebook
##    Available here: 
##      https://github.com/KateSchneider-FoodPol/FSCI_2023Baseline_Replication/blob/552a860f9f3fda4e0116d42690f6b9c86773f458/FSCI%20Baseline_Supplementary%20Data%20-%20Appendix%20E%20-%20Metadata%20and%20Codebook.xlsx
################################################################################ 

################################################################################ 
# HOUSEKEEPING

# Install packages #############################################################

  # Data management packages 
   install.packages("tidyr")
   install.packages("dplyr")
   install.packages("haven")
   install.packages("janitor")
   install.packages("purrr")
   install.packages("maditr")
   install.packages("labelled")
   install.packages("pacman")
   

  # Visualization packages
   install.packages("ggplot2")
   install.packages("ggpubr")
   install.packages("paletteer")
   install.packages("tmap")
   install.packages("sf")
   install.packages("maptools")
   install.packages("ggthemes")
   install.packages("rnaturalearth")
   install.packages("cowplot")
   install.packages("ggh4x")
   install.packages("scales")
   install.packages("ggrepel")
   install.packages("fmsb")
   install.packages("grid")
   install.packages("Hmisc")
   install.packages("ggcorrplot")
   
# Load packages ################################################################
   library(dplyr)
   Packages <- c("tidyverse", "haven", "readxl", "janitor", "maditr", "labelled",
                 "ggplot2", "ggpubr", "ggh4x", "paletteer", "tmap", "sf", "maptools",
                 "ggthemes", "rnaturalearth", "scales", "ggrepel", "cowplot", "fmsb",
                 "expss", "viridis", "kableExtra", "RColorBrewer", "openxlsx", "grid", 
                 "Hmisc", "ggcorrplot")
   lapply(Packages, require, character.only = TRUE)
   

# Working directory is set to R Project root folder
  
  # Set relative directory paths for input data and figure output files
    data_in <- file.path(".", "FSCI analysis datasets")
    fig_out <- file.path(".", "Figures")
    
# Load dataset #################################################################
  
   # Baseline dataset:
  fsci_latest <- read_dta("Supplementary Data - Appendix F - Baseline dataset.dta")
  
  # Baseline dataset + weighting variables for weighted means
  fsci_data_weights <- read_dta(file.path(data_in, "FSCI_2022_latestyear_withweightvars.dta"))
  
  # Metadata file used for labels, weighting by classification, and desirable direction of change
  metadata <- read_excel(("FSCI Baseline_Supplementary Data - Appendix E - Metadata and Codebook.xlsx"),
                         sheet = "Coverage + Labels") %>%
    select(-c(15:16))
  
  # Time series datasets used for supplementary figures
  fsci_data <- read_dta(file.path(data_in, "FSCI_2022_timeseries.dta"))
  fsci_timeseries_weights <- read_dta(file.path(data_in, "FSCI_2022_timeseries_withweightvars.dta"))

      # Keep only years from 2000 forward for supplementary visualizations
        fsci_data <- subset(fsci_data, year >= 2000)
  
  # Factor and reorder the income groups
  fsci_data <- fsci_data %>% mutate(incgrp = as.factor(incgrp))
  levels(fsci_data$incgrp)
  fsci_data$incgrp <- factor(fsci_data$incgrp, levels = c("Low income", 
                                                          "Lower middle income", 
                                                          "Upper middle income",
                                                          "High income"))
  fsci_latest <- fsci_latest %>% mutate(incgrp = as.factor(incgrp))
  fsci_latest$incgrp <- factor(fsci_latest$incgrp, levels = c("Low income", 
                                                            "Lower middle income", 
                                                            "Upper middle income",
                                                            "High income"))
  
# Prepare color palettes  ######################################################
  color10 <-paletteer_d("colorBlindness::LightBlue2DarkBlue10Steps")
  color7 <-paletteer_d("colorBlindness::LightBlue2DarkBlue7Steps") 
  colordiv_redblue12 <- paletteer_d("colorBlindness::Blue2DarkRed12Steps")
  colordiv_bluered11 <- paletteer_d("colorBlindness::ModifiedSpectralScheme11Steps")
  color3 <- c("#7EC3E5FF", "#A3CC51FF", "#E57E7EFF")
  cbpalette_2 <-c("#990F0FFF", "#51A3CCFF")
  bluredcont <- paletteer_d("khroma::vik")
  colorqual <- paletteer_d("khroma::muted")
  cbpalette_urbrurl <- c("#CC8E51FF", "#99540FFF")
  continuous <- paletteer_d("RColorBrewer::PuBuGn")
  regions <- c("Central Asia" = "#CC6677FF",
                    "Eastern Asia" = "#332288FF",                  
                    "Latin America & Caribbean" = "#DDCC77FF",     
                    "Northern Africa & Western Asia" = "#117733FF", 
                    "Northern America and Europe" = "#88CCEEFF",    
                    "Oceania" = "#882255FF",
                    "South-eastern Asia" =  "#44AA99FF",            
                    "Southern Asia" = "#999933FF",                  
                    "Sub-Saharan Africa" = "#AA4499FF")
  brewer.pal(n = 8, name = "YlGnBu")
    incomescol <- c("#97a4b2", "#41B6C4", "#1D91C0", "#0C2C84")
  brewer.pal(n = 8, name = "PuBuGn")
    Blues <- c("gray75", "#A6BDDB", "#67A9CF",  "#02818A", "#016450")
  grayblue <- c("#97a4b2","#008989", "#096887", "#244369", "#12233c")

################################################################################ 

  
################################################################################ 
# MANUSCRIPT FIGURES
  data <- select(fsci_data, c(2,14,19:91))
  data <- data %>% select(-c("emint_eggs", "emint_chickenmeat", "emint_pork",
                             "yield_citrus", "yield_eggs", "yield_chickenmeat",
                             "yield_pork", "yield_pulses", "yield_roottuber", 
                             "yield_treenuts", "unemp_tot", "unemp_u",
                             "underemp_tot", "underemp_u"))
  
  
  ## Figure 2
  totalcoverage <- as.data.frame(data %>%
                                   group_by(country) %>%
                                   summarize_all( ~sum(!is.na(.))))
  totalcoverage <- select(totalcoverage, -c(fsci_regions)) 
  
  # Replace 0 value as "NA" to trick the package to plot zeros discretely and the rest on a continuous scale
  totalcoverage[totalcoverage == 0] <- NA
  
  # Heatmap
  toplot <- melt(totalcoverage, variable.name = "indicator",
                 value.name = "value", na.rm = TRUE) %>% 
    remove_labels(Value) 
  
  # Import theme
  metadata2 <- metadata %>%
    select(c(Indicator, Short_label, Theme, Domain)) %>%
    mutate(across(where(is.character), as.factor))
  names(metadata2) <- tolower(names(metadata2))
  df <- left_join(toplot, metadata2, by = "indicator")            
  df <- filter(df, !is.na(theme)) %>%
    mutate(across(where(is.character), as.factor))
  
  range(df$value)
  ggplot(df, aes(x = country,
                 y = short_label,
                 fill = value)) +
    geom_tile(colour="white", size=0.2) +
    facet_wrap(~theme, ncol = 1, scales = "free_y", strip.position = "right",
               labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
    scale_fill_gradientn(colors = grayblue, na.value="white",
                        breaks=c(1,5,10,15,20,23), labels=c(1,5,10,15,20,23),
                        limits=c(1,23)) + 
    labs(x = "", y = "") + 
    scale_y_discrete(limits=rev) +
    theme(axis.text.x  = element_text(angle=90, size=4, hjust=1,vjust=0.2), 
          axis.text.y  = element_text(size=6, vjust=0.2, hjust=0.95),
          strip.text = element_text(size = 7)) +
    guides(fill = guide_colourbar(title = "Number of years with data")) +
    theme(legend.position = "bottom",
          legend.margin=margin(t=-50),
          legend.justification=c(0,1))
  
  ggsave(file.path(fig_out, "Figure 2.png"), 
         width = 11, height = 8, dpi = 300, units = "in")

#########
## HISTOGRAMS FOR TABLE 1
df <- fsci_latest %>% select(c(1:5, 25:97)) %>%
    select(-c("unemp_tot", "unemp_u", "underemp_tot", "underemp_u"))
vars <- names(df[6:74])
for (var in vars) {
  pltName <- paste( '/hist', var, ".png", sep = '' )
  g <- ggplot(df, aes(x=get(var))) + 
    geom_histogram(aes(y = ..density..)) +
    theme(panel.background = element_rect(fill = 'white', color = 'white'),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x=element_blank(), 
          axis.ticks.x=element_blank(), 
          axis.text.y=element_blank(),  
          axis.ticks.y=element_blank(),
          strip.background =
    ) 
  ggsave(file.path(fig_out, pltName), 
         width = 2, height = 2, dpi = 300, units = "in")
  
}


#########
## Figure 3: Rank order 
  
  # Import metadata
  metadata2 <- metadata %>%
    select(c(Indicator, Theme, Domain, Desirable_direction)) %>%
    mutate(across(where(is.character), as.factor))
  names(metadata2) <- tolower(names(metadata2))
  

  # Define function to create rank order
  # Rank argument orders from lowest to highest (lowest = 1)
  addRankColumns_asc <- function(data, columns) {
    for (i in seq_along(columns)) {
      col <- columns[i]
      rank_col_name <- paste0("rank_", colnames(data)[col])
      data[[rank_col_name]] <- rank(data[[col]], na.last = "keep") 
    }
    return(data)
  }
  # Rank argument orders from highest to lowest (highest = 1)
  addRankColumns_desc <- function(data, columns) {
    for (i in seq_along(columns)) {
      col <- columns[i]
      rank_col_name <- paste0("rank_", colnames(data)[col])
      data[[rank_col_name]] <- rank(-data[[col]], na.last = "keep") 
    }
    return(data)
  }
  
  # Loop over indicators
  fsci_data_torank <- fsci_latest %>% select(c(1:5, 25:97)) %>%
    select(-c("unemp_tot", "unemp_u", "underemp_tot", "underemp_u"))
  sapply(fsci_data_torank, class)
  columns_to_rank <- c(6:74)
  df_ranked_asc <- addRankColumns_asc(fsci_data_torank, columns_to_rank)
  df_ranked_desc <- addRankColumns_desc(fsci_data_torank, columns_to_rank)
  df_ranked_asc <- df_ranked_asc %>% select(-c(6:74))
  df_ranked_desc <- df_ranked_desc %>% select(-c(6:74))
  
  # Reshape long and merge in metadata
  df_ranked_asc <- df_ranked_asc %>% pivot_longer(6:74, names_to = "indicator", values_to = "rank")
  df_ranked_asc$indicator <- sub("^rank_", "", df_ranked_asc$indicator)
  df_ranked_asc <- df_ranked_asc %>% left_join(x = df_ranked_asc, y = metadata2, by = "indicator")
  df_ranked_desc <- df_ranked_desc %>% pivot_longer(6:74, names_to = "indicator", values_to = "rank")
  df_ranked_desc$indicator <- sub("^rank_", "", df_ranked_desc$indicator)
  df_ranked_desc <- df_ranked_desc %>% left_join(x = df_ranked_desc, y = metadata2, by = "indicator")
  
  # Keep in the ascending data frame only indicators where lower is better
  df_ranked_asc <- df_ranked_asc %>% filter(desirable_direction == -1)
  
  # Keep in the descending data frame only indicators where higher is better
  df_ranked_desc <- df_ranked_desc %>% filter(desirable_direction == 1)
  
  # Merge the ranked dataframes
  df_ranked <- rbind(df_ranked_asc, df_ranked_desc)
    ## Now the data are ranked so that lower is better and higher is worse for all indicators
  
  # Create a table with the top and bottom 5 countries per indicator
  df <- df_ranked %>% 
    select(-c(theme,domain,desirable_direction)) %>%
    pivot_wider(names_from = "indicator", values_from = "rank") 
  
  # Drop categorical and binary indicators that do not make sense to rank
  df <- df %>% select(-c("accessinfo", "healthtax", "fspathway", "righttofood"))
      
  # Create an empty data frame to store the results
  result_df <- data.frame(
    Variable = character(),
    Country = character(),
    Rank = character(),
    stringsAsFactors = FALSE
  )
  
  # Loop over columns 6 to 70
  for (col_index in 6:70) {
    col_name <- colnames(df)[col_index]
    
    # Get the top 5 and bottom 5 observations for the current column
    top_5 <- head(df[order(df[, col_index]), ], 5)
    bottom_5 <- head(df[order(df[, col_index], decreasing = TRUE), ], 5)
    
    # Extract country values for the top 5 and bottom 5 observations
    top_5_countries <- top_5$country
    bottom_5_countries <- bottom_5$country

    # Create data frames for lowest rank (top 5) and highest rank (bottom 5) entries
    highest_rank_df <- data.frame(
      Variable = rep(col_name, length(top_5_countries)),
      Country = top_5_countries,
      Rank = rep("Highest Rank", length(top_5_countries)),
      stringsAsFactors = FALSE
    )
    
    lowest_rank_df  <- data.frame(
      Variable = rep(col_name, length(bottom_5_countries)),
      Country = bottom_5_countries,
      Rank = rep("Lowest Rank", length(bottom_5_countries)),
      stringsAsFactors = FALSE
    )
   
    # Append the combined data frames to the result data frame
    result_df <- rbind(result_df, lowest_rank_df, highest_rank_df)
  }
    # Reshape wide
    result_df_wide <- result_df %>% pivot_wider(names_from = Variable, values_from = Rank)
    result_df_wide2 <- result_df %>% pivot_wider(names_from = Variable, values_from = Country)
    
    # Format nicely
        # Unnest selected columns
        selected_columns <- 2:66
        
        for (col in selected_columns) {
          result_df_wide2[[col]] <- sapply(result_df_wide2[[col]], paste, collapse = ", ")
        }
        
        # Pivot the table
        df_pivoted <- result_df_wide2 %>%
          pivot_longer(cols = 2:last_col(), names_to = "Indicator", values_to = "Countries") %>%
          pivot_wider(names_from = "Rank", values_from = "Countries")
        
        # Merge in metadata
        names <- metadata %>% select(c("Indicator", "Short_label"))
        order <-  c("cohd", "avail_fruits", "avail_veg", "UPFretailval_percap", 
        "safeh20", "pou", "fies_modsev", "pctcantafford", "MDD_W", "MDD_iycf", 
        "All5", "zeroFV", "zeroFV_iycf", "NCD_P", "NCD_R", "SSSD", "fs_emissions", 
        "emint_cerealsnorice", "emint_beef", "emint_cowmilk", "emint_rice", "yield_cereals", 
        "yield_fruit", "yield_beef", "yield_cowmilk", "yield_vegetables", "croplandchange_pct", "agwaterdraw", 
        "functionalintegrity", "fishhealth", "pesticides", "sustNO2mgmt", "aginGDP", "unemp_r", "underemp_r", 
        "spcoverage", "spadequacy", "childlabor", "landholding_fem", "cspart", "mufppurbshare", 
         "govteffect", "foodsafety", "accountability", 
        "open_budget_index", "damages_gdp", "kcal_total", "mobile", "soccapindex", 
        "pctagland_minspecies", "genres_plant", "genres_animal", "rcsi_prevalence", "fpi_cv", "foodsupplyvar")
       
        top_bottom <- left_join(data.frame("Indicator"=order), df_pivoted, by = "Indicator")
        top_bottom <- left_join(df_pivoted, names, by = "Indicator") 
        top_bottom <- left_join(data.frame("Indicator"=order), top_bottom, by = "Indicator") %>%
          relocate("Short_label") %>% select(-c(Indicator)) %>%
          rename("Indicator" = "Short_label",
                 "Bottom Ranking" = "Lowest Rank",
                 "Top Ranking" = "Highest Rank")
        table <- kable(top_bottom, format = "html", align = "c") %>%
          kable_styling(bootstrap_options = "striped", full_width = FALSE)
        table
        
        ### RANKINGS for TABLE 1
        write.xlsx(top_bottom,
                   "C:\\Users\\Kate S\\OneDrive - Johns Hopkins\\FSCI\\FSCI Data team\\Baseline - Data Analysis Workstream\\Analysis results\\FSCI2022_Ranking results.xlsx", 
                   colNames = TRUE, sheetName="Rankings")

  # Calculate the average rank for each country by domain
  rank_meanbydomain <- df_ranked %>% 
    group_by(ISO, m49_code, country, incgrp, fsci_regions, theme, domain) %>%
    summarise(rank_mean = mean(rank, na.rm = TRUE))
  rank_meanbydomain <- rank_meanbydomain %>%
    mutate(rank_mean = round(rank_mean, digits = 0))
  range(rank_meanbydomain$rank_mean)
  rank_meanbydomain <- rank_meanbydomain %>%
    mutate(rank_mean = case_when(rank_mean == "NaN" ~ NA,
                                 TRUE ~ rank_mean))
  
  # Calculate the average rank for each country by theme
  rank_meanbytheme <- df_ranked %>% 
    select(-c(domain)) %>%
    group_by(ISO, m49_code, country, incgrp, fsci_regions, theme) %>%
    summarise(rank_mean = mean(rank, na.rm = TRUE))
  rank_meanbytheme <- rank_meanbytheme %>%
    mutate(rank_mean = round(rank_mean, digits = 0))
  range(rank_meanbytheme$rank_mean)
  rank_meanbytheme <- rank_meanbytheme %>%
    mutate(rank_mean = case_when(rank_mean == "NaN" ~ NA,
           TRUE ~ rank_mean))
  
  
  ### Stacked bar chart for each income group
  data <- rank_meanbytheme %>% ungroup() %>%
    #filter(incgrp == "Low income") %>%
    select(-c(2:3,5))
  tot <- data %>% group_by(ISO) %>% summarise(tot=sum(rank_mean))
  data <- left_join(x = data, y = tot, by = "ISO") %>%
    filter(incgrp != "") %>%
    mutate(country = as.factor(ISO)) %>%
    select(-c(ISO)) %>%
    relocate(country)
  
  # Reorder countries to sort figure
  data <- data %>% mutate(country = reorder(country, tot, FUN = function(x) sum(x)))
  is.na(data$tot)
  data <- data %>% filter(!is.na(tot))
  range(data$tot, na.rm = TRUE)
  median(data$tot, na.rm = TRUE)
  
  f_labels <- data.frame(incgrp = c("Low income", 
                                    "Lower middle income", 
                                    "Upper middle income",
                                    "High income"), 
                         label = c("", "", "Global median", ""),
                         theme = "Resilience")
  f_labels$incgrp <- factor(f_labels$incgrp, levels = c("Low income", 
                                                              "Lower middle income", 
                                                              "Upper middle income",
                                                              "High income"))

   plot<- ggplot(data, aes(x = as.factor(country), y = rank_mean, fill = theme)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = country), y = (data$tot+21), size = 2.25, color = "black", angle = 90) +
    facet_wrap(incgrp ~ ., scales = "free_x") +
    labs(title="", x="", y="") + 
    scale_fill_manual(values = Blues) +
    geom_hline(yintercept = 404) +
    theme(legend.position = 'bottom', 
      axis.text.x=element_blank(),
      axis.ticks.x=element_blank(),
      axis.text.y=element_blank(),
      axis.ticks.y=element_blank(),
      axis.title=element_text(size=10),
      legend.text=element_text(size=10),
      legend.title = element_blank(),
      strip.background = element_blank(),
      panel.background = element_blank()) +
    guides(fill = guide_legend(nrow = 2)) 
  
plottext <- plot + geom_text(x = 5, y = 415, aes(label = label), data = f_labels, size = 3)

    # Add label
    text1 <- ggplot() +
      annotate("text", x = 1,  y = 1,
               size = 4, color = "black",
               label = "Bottom ranking",
               angle=90, hjust = -.05) + theme_void()
    arrow1 <- ggplot() +
      annotate("segment", x = 0, xend = 0, y = 1, yend = 1.1,
               colour = "black", size = .5, arrow = arrow()) + theme_void()
    space <- ggplot() +
      annotate("text", x = 1,  y = 1,
               size = 5, color = "black",
               label = "         ",
               angle=90, hjust = -.05) + theme_void()
    text2 <- ggplot() +
      annotate("text", x = 1,  y = 1,
               size = 4, color = "black",
               label = "Top ranking",
               angle=90, hjust = 1.2) + theme_void()
    arrow2 <- ggplot() +
      annotate("segment", x = 0, xend = 0, y = 1.1, yend = 1,
               colour = "black", size = .5, arrow = arrow()) + theme_void() 
    p1 <- plot_grid(arrow1, text1, nrow = 2, ncol = 1, rel_heights = c(1,4))
    p2 <- plot_grid(text2, arrow2, nrow = 2, ncol = 1, rel_heights = c(4,1))
    p1s <- plot_grid(space, p1, nrow = 2, ncol = 1, rel_heights = c(1,4))
    p2s <- plot_grid(p2, space, nrow = 2, ncol = 1, rel_heights = c(3,1))
    left <- plot_grid(p1s, p2s, nrow = 2, ncol = 1)
    plot_grid(left, plottext, nrow = 1, ncol = 2, rel_widths = c(1,20))
    
ggsave(file.path(fig_out, "Figure 3.png"), width = 11, height = 8.5, dpi = 300, units = "in")
    
############
## Figure 4
  # Normalized distance to global mean, by income group
  df <- fsci_data_weights %>% select(-c("ISO", "fsci_regions", "wb_region", "UNmemberstate", 
                                        "UN_contregion_code", "UN_subregion_code", 
                                        "UN_intermedregion_code", "m49_code", "GDP_percap", 
                                        "UN_continental_region", "UN_subregion", 
                                        "UN_intermediary_region", "agland_area",
                                        "righttofood", "emint_eggs", "emint_chickenmeat", "emint_pork",
                                        "yield_citrus", "yield_eggs", "yield_chickenmeat",
                                        "yield_pork", "yield_pulses", "yield_roottuber", 
                                        "yield_treenuts", "prod_citrus", "prod_eggs",
                                        "prod_chickenmeat", "prod_pork",
                                        "prod_pulses", "prod_treenuts", "prod_roottuber",
                                        "areaharvested_citrus","producinganimals_eggs",
                                        "producinganimals_chickenmeat", "producinganimals_pork",
                                        "areaharvested_pulses", "areaharvested_roottuber", 
                                        "areaharvested_treenuts")) %>%
    filter(incgrp!="")
  # Melt data long, keeping weighting variables as columns
  df2 <- melt(df, cbind("country", "incgrp",  "GDP",
                        "totalpop", "landarea", "prod_cereals", "prod_fruit",
                        "prod_beef", "prod_cowmilk", "prod_vegetables", "prod_cerealsnorice",
                        "prod_rice", "areaharvested_cereals", 
                        "areaharvested_fruit", "producinganimals_beef",       
                        "producinganimals_cowmilk", "areaharvested_vegetables",
                        "cropland", "agland_area2015", "agland_area2010",
                        "pop_u"),
              variable.name = "indicator", 
              value.name = "value", na.rm = TRUE) %>% 
    remove_labels(Value) 
  levels(df2$indicator)
  
  # Import unit and theme
  metadata <- metadata %>%
    select(c(Indicator, Short_label, Theme, Domain, Unit, Unit_group, Desirable_direction, mean_weighting)) %>%
    mutate(direction = as.numeric(Desirable_direction)) %>% 
    mutate(across(where(is.character), as.factor)) %>%
    select(-c(Unit, Unit_group, Desirable_direction))
  names(metadata) <- tolower(names(metadata))
  df3 <- left_join(df2, metadata, by = "indicator")            
  df3 <- filter(df3, !is.na(theme)) %>%
    mutate(across(where(is.character), as.factor))
  levels(df3$mean_weighting)
  lapply(df3, class)
  levels(df3$incgrp)
  # recode income groups
  df3$incgrp <- factor(df3$incgrp, levels = c("Low income", "Lower middle income", 
                                              "Upper middle income", "High income"))
  levels(df3$incgrp)
  
  # Weighted means:
  df4 <- df3 %>% 
    group_by(indicator) %>%
    mutate(globalmean = case_when(
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, beef", indicator)) ~ weighted.mean(value, prod_beef, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, cereals (excl rice)", indicator)) ~ weighted.mean(value, prod_cerealsnorice, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, milk", indicator)) ~ weighted.mean(value, prod_cowmilk, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, rice", indicator)) ~ weighted.mean(value, prod_rice, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, cereals", indicator)) ~ weighted.mean(value, areaharvested_cereals, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, fruit", indicator)) ~ weighted.mean(value, areaharvested_fruit, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, vegetables", indicator)) ~ weighted.mean(value, areaharvested_vegetables, na.rm = TRUE)),
      ((grepl("producinganimals", mean_weighting) & grepl("Yield, beef", indicator)) ~ weighted.mean(value, producinganimals_beef, na.rm = TRUE)),
      ((grepl("producinganimals", mean_weighting) & grepl("Yield, milk", indicator)) ~ weighted.mean(value, producinganimals_cowmilk, na.rm = TRUE)),
      (grepl("pop_u", mean_weighting)  ~ weighted.mean(value, pop_u, na.rm = TRUE)), # Eastern asia not showing up
      (grepl("GDP", mean_weighting)  ~ weighted.mean(value, GDP, na.rm = TRUE)),
      (grepl("unweighted", mean_weighting) ~ mean(value, na.rm = TRUE)),
      (grepl("cropland", mean_weighting)  ~ weighted.mean(value, cropland, na.rm = TRUE)),
      (grepl("agland_area2015", mean_weighting)  ~ weighted.mean(value, agland_area2015, na.rm = TRUE)),
      (grepl("agland_area2010", mean_weighting)  ~ weighted.mean(value, agland_area2010, na.rm = TRUE)),
      (grepl("totalpop", mean_weighting) ~ weighted.mean(value, totalpop, na.rm = TRUE)),
      (grepl("landarea", mean_weighting) ~ weighted.mean(value, landarea, na.rm = TRUE)),
      TRUE ~ mean(value)))
  dffix <- df4 %>%
    subset(is.na(globalmean)) %>%
    drop_na(GDP) %>%
    group_by(indicator) %>%
    mutate(globalmean = case_when( 
      indicator == "aginGDP" & is.na(globalmean) ~ weighted.mean(value, GDP, na.rm = TRUE),
      TRUE ~ globalmean))
  dffix2 <- df4 %>%
    subset(is.na(globalmean)) %>%
    drop_na(cropland, agland_area2010, agland_area2015) %>%
    group_by(indicator) %>%
    mutate(globalmean = case_when( 
      indicator == "functionalintegrity" & is.na(globalmean) ~ weighted.mean(value, agland_area2015, na.rm = TRUE),
      indicator == "pesticides" & is.na(globalmean) ~ weighted.mean(value, cropland, na.rm = TRUE),
      indicator == "sustNO2mgmt" & is.na(globalmean) ~ weighted.mean(value, cropland, na.rm = TRUE),
      TRUE ~ globalmean)) 
  dffix <- rbind(dffix, dffix2)
  df4 <- rbind(df4,dffix) %>% drop_na(globalmean)
  df4 <- df4 %>% group_by(indicator) %>%
    mutate(globalmedian = median(value, na.rm = TRUE),
           globalmin = min(value, na.rm = TRUE),
           globalmax = max(value, na.rm = TRUE),
           globalp25 = quantile(value, c(.25)),
           globalp75 = quantile(value, c(.75))) %>%
    ungroup() %>% as.data.frame()
  df5 <- df4 %>% group_by(incgrp, indicator) %>%
    mutate(incmean = case_when(
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, beef", indicator)) ~ weighted.mean(value, prod_beef, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, cereals (excl rice)", indicator)) ~ weighted.mean(value, prod_cerealsnorice, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, milk", indicator)) ~ weighted.mean(value, prod_cowmilk, na.rm = TRUE)),
      ((grepl("production", mean_weighting) & grepl("Emissions intensity, rice", indicator)) ~ weighted.mean(value, prod_rice, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, cereals", indicator)) ~ weighted.mean(value, areaharvested_cereals, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, fruit", indicator)) ~ weighted.mean(value, areaharvested_fruit, na.rm = TRUE)),
      ((grepl("areaharvested", mean_weighting) & grepl("Yield, vegetables", indicator)) ~ weighted.mean(value, areaharvested_vegetables, na.rm = TRUE)),
      ((grepl("producinganimals", mean_weighting) & grepl("Yield, beef", indicator)) ~ weighted.mean(value, producinganimals_beef, na.rm = TRUE)),
      ((grepl("producinganimals", mean_weighting) & grepl("Yield, milk", indicator)) ~ weighted.mean(value, producinganimals_cowmilk, na.rm = TRUE)),
      ((grepl("unweighted", mean_weighting))  ~ mean(value, na.rm = TRUE)),
      (grepl("totalpop", mean_weighting) ~ weighted.mean(value, totalpop, na.rm = TRUE)),
      (grepl("landarea", mean_weighting) ~ weighted.mean(value, landarea, na.rm = TRUE)),
      (grepl("cropland", mean_weighting)  ~ weighted.mean(value, cropland, na.rm = TRUE)),
      (grepl("agland_area2015", mean_weighting)  ~ weighted.mean(value, agland_area2015, na.rm = TRUE)),
      (grepl("agland_area2010", mean_weighting)  ~ weighted.mean(value, agland_area2010, na.rm = TRUE)),
      (grepl("pop_u", mean_weighting)  ~ weighted.mean(value, pop_u, na.rm = TRUE)),
      (TRUE ~ mean(value, na.rm = TRUE)))) %>% ungroup() %>%
    group_by(incgrp, short_label, globalmean, globalmedian, globalmin, globalmax, globalp25, 
             globalp75, theme, direction) %>%
    summarise(incmean = first(incmean))
  df5 <- df5 %>% group_by(short_label) %>%
    mutate(incmin = min(incmean, na.rm = TRUE),
           incmax = max(incmean, na.rm = TRUE))
  
  # Normalize using min-max scaling
  df6 <- df5 %>% mutate(incmeannorm = ((incmean - globalmean) / (incmax - incmin))) %>%
    # Directionality
    mutate(incmeannorm = incmeannorm * direction)
  range(df6$incmeannorm, na.rm = TRUE)
  
  plota <- df6 %>% 
    filter(theme != "Environment, natural resources, and production" & theme != "Resilience") %>% 
    ggplot(aes(x = short_label, y = incmeannorm, color = incgrp)) +
    geom_hline(yintercept=0) + 
    geom_point(size = 3.5) + 
    scale_color_manual(values = incomescol) + 
    coord_flip() +
    labs(title="", x="") + 
    scale_y_continuous(limits = c(-1,1)) +
    scale_x_discrete(limits=rev) +
    facet_grid(theme ~ ., scales = "free_y", space = "free_y", switch = "y", 
               labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
    theme_classic() + theme(strip.text = element_text(size = 10),
                            strip.placement = "outside",
                            legend.position="none",
                            # remove background colour from facet labels
                            strip.background  = element_rect(fill="gray"),
                            # remove border from facet label
                            panel.border = element_blank(),
                            # make continent names horizontal
                            axis.text=element_text(size=10),
                            axis.title=element_text(size=10),
                            legend.text=element_text(size=12),
                            legend.title = element_text(size = 12)) + 
    ylab("") +
    grids(axis = c("y"), linetype = "solid", color = "gray")
  plota
  plotb <- df6 %>% 
    filter(theme == "Environment, natural resources, and production" | theme == "Resilience") %>% 
    ggplot(aes(x = short_label, y = incmeannorm, color = incgrp)) +
    geom_hline(yintercept=0) + 
    geom_point(size = 3.5) + 
    scale_color_manual(values = incomescol) + 
    coord_flip() +
    labs(title="", x="") + 
    scale_y_continuous(limits = c(-1,1)) +
    scale_x_discrete(limits=rev) +
    facet_grid(theme ~ ., scales = "free_y", space = "free_y", switch = "y") + 
    theme_classic() + theme(strip.text = element_text(size = 10),
                            strip.placement = "outside",
                            legend.position="none",
                            # remove background colour from facet labels
                            strip.background  = element_rect(fill="gray"),
                            # remove border from facet label
                            panel.border = element_blank(),
                            # make continent names horizontal
                            axis.text=element_text(size=10),
                            axis.title=element_text(size=10),
                            legend.text=element_text(size=12),
                            legend.title = element_text(size = 12)) + 
    ylab("") +
    grids(axis = c("y"), linetype = "solid", color = "gray")
  plotb
  legend <- df6 %>% 
    filter(theme == "Environment, natural resources, and production" | theme == "Resilience") %>% 
    ggplot(aes(x = short_label, y = incmeannorm, color = incgrp)) +
    geom_hline(yintercept=0) + geom_point(size = 5) + 
    scale_color_manual(values = incomescol,
                       name = "Income group",
                       labels = c("Low income", 
                                  "Lower middle income", 
                                  "Upper middle income",
                                  "High income")) + 
    coord_flip() +
    labs(title="", x="") + 
    scale_y_continuous(limits = c(-1,1)) +
    scale_x_discrete(limits=rev) +
    facet_grid(theme ~ ., scales = "free_y", space = "free_y", switch = "y") +
    theme_classic() + theme(strip.text = element_text(size = 10),
                            strip.placement = "bottom",
                            legend.position="bottom",
                            # remove background colour from facet labels
                            strip.background  = element_rect(fill="gray"),
                            # remove border from facet label
                            panel.border = element_blank(),
                            # make continent names horizontal
                            axis.text=element_text(size=10),
                            axis.title=element_text(size=10),
                            legend.text=element_text(size=10),
                            legend.title = element_text(size = 10, face = "bold")) + 
    ylab("Normalized distance to global mean, sign aligned to desirable direction") 
  plotlegend <- get_legend(legend)
  step1 <- plot_grid(plota, plotb) 
  step2 <- ggdraw(add_sub(step1,"Normalized distance to global mean (max-min scaling relative to global country-level values).\n Black vertical line indicates global mean, centered at 0. Sign aligned to desirable direction.",
                          size = 10))
  plotfig3 <- plot_grid(step2, NULL, plotlegend, nrow = 3, rel_heights = c(1,0,.1))
  plotfig3
  ggsave(file.path(fig_out, "Figure 4.png"), width = 11, height = 8.5, dpi = 300, units = "in")
  # Figure footnote:
  # Normalized distance to global mean (weighted means following weights defined in Table 1) is calculated relative to the global mean and scaled to the minimum and maximum of income group mean, per indicator (global mean centered at 0).  The sign of the normalized distance has been reversed for all indicators where a lower value is more desirable, such that -1 can be interpreted as "worse than" and 1 can be interpreted as “better than" the global mean. Number of people who cannot afford a healthy diet and Degree of legal recognition of the right to food not shown. Product mix in aggregate categories of emissions intensities (cereals) and yields (cereals, citrus, fruit, pulses, roots and tubers, and vegetables) differ across countries.
  
     
################################################################################ 
  
  
################################################################################ 
# SUPPLEMENTARY MATERIALS

#########################################################################################################################################
## APPENDIX A - SUPPLEMENTARY ANALYSIS
#########################################################################################################################################  
################################################################################ 

## Figure A.2
  ## Display countries in each region
  
  data <- select(fsci_data, c(ISO, country, fsci_regions))
  data <- data %>% filter(fsci_regions != "") %>%
    mutate(fsci_regions = as.factor(fsci_regions)) %>%
    rename(iso_a3 = ISO) # to match map country identifier
  
  #World map 
  World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  
  
  #merging data
  data_simple<-merge(World,data, by='iso_a3',  duplicateGeoms = TRUE)
  
  #Turn off s2 processing to avoid invalid polygons
  sf::sf_use_s2(FALSE)
  
  #Creating Map
  
  #Simple Map
  regionmap <- tm_shape(data_simple) + tm_polygons("fsci_regions",
                                                   style = "cat",
                                                   palette = regions,
                                                   title="") + 
    tm_layout(frame = FALSE, legend.outside=TRUE)
  
  regionmap
  
  tmap_save(regionmap, file.path(fig_out, "A.2_Country region mapping.png"), width = 10, height = 4, dpi=300, units = "in")
  
  
  
## Figures A.3 - A.11  
## Data Coverage Heatmaps by region
  data <- select(fsci_data, c(2,14,19:91))
  data <- data %>% select(-c("emint_eggs", "emint_chickenmeat", "emint_pork",
                             "yield_citrus", "yield_eggs", "yield_chickenmeat",
                             "yield_pork", "yield_pulses", "yield_roottuber", 
                             "yield_treenuts", "unemp_tot", "unemp_u",
                             "underemp_tot", "underemp_u"))
  
  byregcoverage <- as.data.frame(data %>%
                                   mutate(fsciregion = as.factor(fsci_regions)) %>%
                                   group_by(fsciregion, country) %>%
                                   summarize_all( ~sum(!is.na(.)))) %>%
    select(-c(fsci_regions))

  # Replace 0 value as "NA" to trick the package to plot zeros discretely and the rest on a continuous scale
  byregcoverage[byregcoverage == 0] <- NA
  
  # Heatmap
  toplot <- melt(byregcoverage, cbind("country", "fsciregion"),
                 variable.name = "indicator",
                 value.name = "value", na.rm = FALSE) %>% 
    remove_labels(Value) 
  
  # Import theme
  metadata2 <- metadata %>%
    select(c(Indicator, Short_label, Theme, Domain)) %>%
    mutate(across(where(is.character), as.factor))
  names(metadata2) <- tolower(names(metadata2))
  df <- left_join(toplot, metadata2, by = "indicator")            
  toplot <- filter(df, !is.na(theme)) %>%
    mutate(across(where(is.character), as.factor))
  
  ggplot(df, aes(x = country,
                 y = short_label,
                 fill = value)) +
    geom_tile(colour="white", size=0.2) +
    facet_wrap(~theme, ncol = 1, scales = "free_y", strip.position = "right",
               labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
    scale_fill_gradientn(colors = grayblue, na.value="white") + 
    labs(x = "", y = "") + 
    scale_y_discrete(limits=rev) +
    theme(axis.text.x  = element_text(angle=90, size=4, hjust=1,vjust=0.2), 
          axis.text.y  = element_text(size=6, vjust=0.2, hjust=0.95),
          strip.text = element_text(size = 7)) +
    guides(fill = guide_colourbar(title = "Number of years")) +
    theme(legend.position="bottom", 
          legend.margin=margin(t=-50))
  
  
          plot_list = list()
          for (i in 1:length(levels(toplot$fsciregion))) {
             p = ggplot(toplot[toplot$fsciregion == levels(toplot$fsciregion)[i],], aes(x = country,
                               y = short_label,
                               fill = value)) +
              geom_tile(colour="white", size=0.2) +
              facet_wrap(~theme, ncol = 1, scales = "free_y", strip.position = "right",
                          labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
              scale_fill_gradientn(colors = grayblue, na.value="white") + 
              labs(x = "", y = "") + 
              scale_y_discrete(limits=rev) +  ggtitle(levels(toplot$fsciregion)[i]) +
              theme(axis.text.x  = element_text(angle=90, size=4, hjust=1,vjust=0.2), 
                    axis.text.y  = element_text(size=4, vjust=0.2, hjust=0.95),
                    strip.text = element_text(size = 6),
                    plot.title = element_text(size = 10)) +
              guides(fill = guide_colourbar(title = "Number of years")) +
              theme(legend.position="right", 
                    legend.title = element_text(size=6),
                    legend.text = element_text(size=6)) 
             plot_list[[i]] = p
            ggsave(file.path(fig_out, paste("A.", i+2, "_Coverage Heatmap 2000-2022_reg", i, ".png", sep = "")), 
                   width = 10, height = 6, dpi = 300, units = "in")
          }

## Figures A.12-A.20
## Ranking by theme and region
          
    # Import metadata
    metadata2 <- metadata %>%
      select(c(Indicator, Theme, Domain, Desirable_direction)) %>%
      mutate(across(where(is.character), as.factor))
    names(metadata2) <- tolower(names(metadata2))
    
    
    # Define function to create rank order
    # Rank argument orders from lowest to highest (lowest = 1)
    addRankColumns_asc <- function(data, columns) {
      for (i in seq_along(columns)) {
        col <- columns[i]
        rank_col_name <- paste0("rank_", colnames(data)[col])
        data[[rank_col_name]] <- rank(data[[col]], na.last = "keep") 
      }
      return(data)
    }
    # Rank argument orders from highest to lowest (highest = 1)
    addRankColumns_desc <- function(data, columns) {
      for (i in seq_along(columns)) {
        col <- columns[i]
        rank_col_name <- paste0("rank_", colnames(data)[col])
        data[[rank_col_name]] <- rank(-data[[col]], na.last = "keep") 
      }
      return(data)
    }
    
    # Loop over indicators
    fsci_data_torank <- fsci_latest %>% select(c(1:5, 25:97)) %>%
      select(-c("unemp_tot", "unemp_u", "underemp_tot", "underemp_u"))
    sapply(fsci_data_torank, class)
    columns_to_rank <- c(6:74)
    df_ranked_asc <- addRankColumns_asc(fsci_data_torank, columns_to_rank)
    df_ranked_desc <- addRankColumns_desc(fsci_data_torank, columns_to_rank)
    df_ranked_asc <- df_ranked_asc %>% select(-c(6:74))
    df_ranked_desc <- df_ranked_desc %>% select(-c(6:74))
    
    # Reshape long and merge in metadata
    df_ranked_asc <- df_ranked_asc %>% pivot_longer(6:74, names_to = "indicator", values_to = "rank")
    df_ranked_asc$indicator <- sub("^rank_", "", df_ranked_asc$indicator)
    df_ranked_asc <- df_ranked_asc %>% left_join(x = df_ranked_asc, y = metadata2, by = "indicator")
    df_ranked_desc <- df_ranked_desc %>% pivot_longer(6:74, names_to = "indicator", values_to = "rank")
    df_ranked_desc$indicator <- sub("^rank_", "", df_ranked_desc$indicator)
    df_ranked_desc <- df_ranked_desc %>% left_join(x = df_ranked_desc, y = metadata2, by = "indicator")
    
    # Keep in the ascending data frame only indicators where lower is better
    df_ranked_asc <- df_ranked_asc %>% filter(desirable_direction == -1)
    
    # Keep in the descending data frame only indicators where higher is better
    df_ranked_desc <- df_ranked_desc %>% filter(desirable_direction == 1)
    
    # Merge the ranked dataframes
    df_ranked <- rbind(df_ranked_asc, df_ranked_desc)
    ## Now the data are ranked so that lower is better and higher is worse for all indicators
    
    # Create a table with the top and bottom 5 countries per indicator
    df <- df_ranked %>% 
      select(-c(theme,domain,desirable_direction)) %>%
      pivot_wider(names_from = "indicator", values_from = "rank") 
    
    # Drop categorical and binary indicators that do not make sense to rank
    df <- df %>% select(-c("accessinfo", "healthtax", "fspathway", "righttofood"))
    
    # Create an empty data frame to store the results
    result_df <- data.frame(
      Variable = character(),
      Country = character(),
      Rank = character(),
      stringsAsFactors = FALSE
    )
    
    # Loop over columns 6 to 70
    for (col_index in 6:70) {
      col_name <- colnames(df)[col_index]
      
      # Get the top 5 and bottom 5 observations for the current column
      top_5 <- head(df[order(df[, col_index]), ], 5)
      bottom_5 <- head(df[order(df[, col_index], decreasing = TRUE), ], 5)
      
      # Extract country values for the top 5 and bottom 5 observations
      top_5_countries <- top_5$country
      bottom_5_countries <- bottom_5$country
      
      # Create data frames for lowest rank (top 5) and highest rank (bottom 5) entries
      highest_rank_df <- data.frame(
        Variable = rep(col_name, length(top_5_countries)),
        Country = top_5_countries,
        Rank = rep("Highest Rank", length(top_5_countries)),
        stringsAsFactors = FALSE
      )
      
      lowest_rank_df  <- data.frame(
        Variable = rep(col_name, length(bottom_5_countries)),
        Country = bottom_5_countries,
        Rank = rep("Lowest Rank", length(bottom_5_countries)),
        stringsAsFactors = FALSE
      )
      
      # Append the combined data frames to the result data frame
      result_df <- rbind(result_df, lowest_rank_df, highest_rank_df)
    }
    # Reshape wide
    result_df_wide <- result_df %>% pivot_wider(names_from = Variable, values_from = Rank)
    result_df_wide2 <- result_df %>% pivot_wider(names_from = Variable, values_from = Country)
    
    # Format nicely
    # Unnest selected columns
    selected_columns <- 2:66
    
    for (col in selected_columns) {
      result_df_wide2[[col]] <- sapply(result_df_wide2[[col]], paste, collapse = ", ")
    }
    
    # Pivot the table
    df_pivoted <- result_df_wide2 %>%
      pivot_longer(cols = 2:last_col(), names_to = "Indicator", values_to = "Countries") %>%
      pivot_wider(names_from = "Rank", values_from = "Countries")
    
    # Merge in metadata
    names <- metadata %>% select(c("Indicator", "Short_label"))
    order <-  c("cohd", "avail_fruits", "avail_veg", "UPFretailval_percap", 
                "safeh20", "pou", "fies_modsev", "pctcantafford", "MDD_W", "MDD_iycf", 
                "All5", "zeroFV", "zeroFV_iycf", "NCD_P", "NCD_R", "SSSD", "fs_emissions", 
                "emint_cerealsnorice", "emint_beef", "emint_cowmilk", "emint_rice", "yield_cereals", 
                "yield_fruit", "yield_beef", "yield_cowmilk", "yield_vegetables", "croplandchange_pct", "agwaterdraw", 
                "functionalintegrity", "fishhealth", "pesticides", "sustNO2mgmt", "aginGDP", "unemp_r", "underemp_r", 
                "spcoverage", "spadequacy", "childlabor", "landholding_fem", "cspart", "mufppurbshare", 
                "govteffect", "foodsafety", "accountability", 
                "open_budget_index", "damages_gdp", "kcal_total", "mobile", "soccapindex", 
                "pctagland_minspecies", "genres_plant", "genres_animal", "rcsi_prevalence", "fpi_cv", "foodsupplyvar")
    
    top_bottom <- left_join(data.frame("Indicator"=order), df_pivoted, by = "Indicator")
    top_bottom <- left_join(df_pivoted, names, by = "Indicator") 
    top_bottom <- left_join(data.frame("Indicator"=order), top_bottom, by = "Indicator") %>%
      relocate("Short_label") %>% select(-c(Indicator)) %>%
      rename("Indicator" = "Short_label",
             "Worst Ranking" = "Lowest Rank",
             "Best Ranking" = "Highest Rank")
      
    # Calculate the average rank for each country by theme
    rank_meanbytheme <- df_ranked %>% 
      select(-c(domain)) %>%
      group_by(ISO, m49_code, country, fsci_regions, theme) %>%
      summarise(rank_mean = mean(rank, na.rm = TRUE))
    rank_meanbytheme <- rank_meanbytheme %>%
      mutate(rank_mean = round(rank_mean, digits = 0))
    range(rank_meanbytheme$rank_mean)
    rank_meanbytheme <- rank_meanbytheme %>%
      mutate(rank_mean = case_when(rank_mean == "NaN" ~ NA,
                                   TRUE ~ rank_mean)) 
          
      ### Generate total and reshape
      data <- rank_meanbytheme %>% ungroup() %>%
        select(c(1,3:6)) %>%
        mutate(across(where(is.character), as.factor))
      tot <- data %>% group_by(ISO) %>% summarise(tot=sum(rank_mean))
      data <- left_join(x = data, y = tot, by = "ISO") %>%
        filter(fsci_regions != "") %>%
        select(-c(ISO)) %>%
        relocate(country)
      
      # Reorder countries to sort figure
      data <- data %>% mutate(country = reorder(country, tot, FUN = function(x) sum(x)))
      is.na(data$tot)
      data <- data %>% filter(!is.na(tot))
      range(data$tot, na.rm = TRUE)
      median(data$tot, na.rm = TRUE)
      
      # For labels
      # Add label
      text1 <- ggplot() +
        annotate("text", x = 1,  y = 1,
                 size = 3, color = "black",
                 label = "Bottom ranking",
                 angle=90, hjust = -.05) + theme_void()
      arrow1 <- ggplot() +
        annotate("segment", x = 0, xend = 0, y = 1, yend = 1.1,
                 colour = "black", size = .5, arrow = arrow()) + theme_void()
      space <- ggplot() +
        annotate("text", x = 1,  y = 1,
                 size = 3, color = "black",
                 label = "         ",
                 angle=90, hjust = -.05) + theme_void()
      text2 <- ggplot() +
        annotate("text", x = 1,  y = 1,
                 size = 3, color = "black",
                 label = "Top ranking",
                 angle=90, hjust = 1.2) + theme_void()
      arrow2 <- ggplot() +
        annotate("segment", x = 0, xend = 0, y = 1.1, yend = 1,
                 colour = "black", size = .5, arrow = arrow()) + theme_void() 
      p1 <- plot_grid(arrow1, text1, nrow = 2, ncol = 1, rel_heights = c(1,5))
      p2 <- plot_grid(text2, arrow2, nrow = 2, ncol = 1, rel_heights = c(4,1))
      p1s <- plot_grid(space, p1, nrow = 2, ncol = 1, rel_heights = c(1,2))
      p2s <- plot_grid(p2, space, nrow = 2, ncol = 1, rel_heights = c(2,1))
      left <- plot_grid(p1s, p2s, nrow = 2, ncol = 1)
      
      # create variable for country labels so they only label once per bar
      data$country2 <- ifelse(data$theme == "Diets, Nutrition, and Health", as.character(data$country), "")

      
      # One plot per region
      plot_list = list()
      for (i in 1:length(levels(data$fsci_regions))) {
        p <- ggplot(data[data$fsci_regions == levels(data$fsci_regions)[i],],
                       aes(x = as.factor(country), y = rank_mean, fill = theme)) +
        geom_bar(stat = "identity") +
        geom_text(aes(label = country2), size = 2.25, 
                  vjust = 0, color = "black", position = 'stack', angle = 90) +
        labs(title="", x="", y="") + 
        scale_fill_manual(values = Blues) +
        geom_hline(yintercept = 404) +
        geom_text(x = 2, y = 415, aes(label = "Global median"), size = 3) +
        theme(legend.position = 'bottom', 
              axis.text.x=element_blank(),
              axis.ticks.x=element_blank(),
              axis.text.y=element_blank(),
              axis.ticks.y=element_blank(),
              axis.title=element_text(size=10),
              legend.text=element_text(size=10),
              legend.title = element_blank(),
              strip.background = element_blank(),
              panel.background = element_blank()) +
        guides(fill = guide_legend(nrow = 2)) + ggtitle(levels(data$fsci_regions)[i])
        p <- plot_grid(left, p, nrow = 1, ncol = 2, rel_widths = c(1,20))
        plot_list[[i]] = p
        ggsave(file.path(fig_out, paste("A.", i+11, "_Ranking_reg", i, ".png", sep = "")), 
               width = 10, height = 6, dpi = 300, units = "in")
      }
      
          
## Figures A.21-A.25
## Relationship to GDP per capita, by thematic area
      df <- fsci_latest %>% select(c(1,3:5,21,25:97)) 
      
      # Melt data long
      dflong <- melt(df, cbind("country", "fsci_regions", "ISO", "incgrp", "GDP_percap"), 
                     variable.name = "Indicator", 
                     value.name = "Value", na.rm = TRUE) %>% remove_labels(Value) 
      
      # Merge in unit and theme
      metadata2 <- metadata %>%
        select(c(Indicator, Short_label, Theme, Domain, Unit, Unit_group, Desirable_direction)) %>%
        mutate(direction = as.numeric(Desirable_direction)) %>% select(-c(Desirable_direction))
      dflong <- left_join(dflong, metadata, by = "Indicator")
      dflong <- dflong  %>% 
        mutate(theme = as.factor(Theme)) %>%
        mutate(indicator = as.factor(Short_label)) %>%
        mutate(fsciregion = as.factor(fsci_regions)) 
      
      # Winsorize GDP
      range(dflong$GDP_percap, na.rm = TRUE)

      # Normalize 
      dist <- dflong %>% group_by(indicator) %>%
        summarise(globalmin = min(Value, na.rm = TRUE),
                  globalmax = max(Value, na.rm = TRUE),
                  globalmedian = median(Value, na.rm = TRUE),
                  globalp25 = quantile(Value, c(.25), na.rm = TRUE),
                  globalp75 = quantile(Value, c(.75), na.rm = TRUE))
      dflong <- left_join(dflong, dist, by = "indicator")
      dflong <- dflong %>%
        mutate(valnormed = (Value - globalmin) / (globalmax - globalmin)) 

      ggplot(dflong, aes(x=GDP_percap)) + 
        geom_histogram(aes(y = ..density..)) +
        theme(panel.background = element_rect(fill = 'white', color = 'white'),
              axis.title.x = element_blank(),
              axis.title.y = element_blank(),
              axis.text.x=element_blank(), 
              axis.ticks.x=element_blank(), 
              axis.text.y=element_blank(),  
              axis.ticks.y=element_blank(),
              strip.background =
        ) 
       dflong <- dflong  %>% mutate(GDPpc_trimmed = case_when(GDP_percap > 25000 ~ (25000),
                                       TRUE ~ GDP_percap))     
      
       diets <- dflong %>%  
         filter(theme == "Diets, Nutrition, and Health") %>%
       ggplot(aes(x=GDP_percap, y=valnormed) ) +
        geom_hex(bins=30) +
        scale_fill_distiller(palette=4, direction=-1) + #this line determines a new four-color palette
        scale_x_continuous(labels = comma) +
        scale_y_continuous(expand = c(0, 0)) +
        facet_wrap(indicator~., labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        labs(x="GDP per capita", y = "Normalized value") +
        theme(
          legend.position='none'
        )
      ggsave(file.path(fig_out, "A.21_GDP-Diets.png"), width = 8.5, height = 10, dpi = 600, units = "in")
      
      enviro <- dflong %>%
        filter(theme == "Environment, natural resources, and production") %>%
        ggplot(aes(x=GDP_percap, y=valnormed) ) +
        geom_hex(bins=30) +
        scale_fill_distiller(palette=4, direction=-1) + #this line determines a new four-color palette
        scale_x_continuous(labels = comma) +
        scale_y_continuous(expand = c(0, 0)) +
        facet_wrap(indicator~., labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        labs(x="GDP per capita", y = "Normalized value") +
        theme(
          legend.position='none'
        )
      ggsave(file.path(fig_out, "A.22_GDP-Enviro.png"), width = 8.5, height = 10, dpi = 600, units = "in")
      
      
      lives <- dflong %>% 
        filter(theme == "Livelihoods, Poverty, and Equity") %>%
        ggplot(aes(x=GDP_percap, y=valnormed) ) +
        geom_hex(bins=30) +
        scale_fill_distiller(palette=4, direction=-1) + #this line determines a new four-color palette
        scale_x_continuous(labels = comma) +
        scale_y_continuous(expand = c(0, 0)) +
        facet_wrap(indicator~., labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        labs(x="GDP per capita", y = "Normalized value") +
        theme(
          legend.position='none'
        )
      ggsave(file.path(fig_out, "A.23_GDP-lives.png"), width = 8.5, height = 10, dpi = 600, units = "in")
      
      gov <- dflong %>% 
        filter(theme == "Governance" & indicator != "Food system pathway" &
                 indicator != "Right to food" & indicator != "Access to information" & 
                 indicator != "Food safety capacity" & indicator != "Health-related food tax") %>%
        ggplot(aes(x=GDP_percap, y=valnormed) ) +
        geom_hex(bins=30) +
        scale_fill_distiller(palette=4, direction=-1) + #this line determines a new four-color palette
        scale_x_continuous(labels = comma) +
        scale_y_continuous(expand = c(0, 0)) +
        facet_wrap(indicator~., labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        labs(x="GDP per capita", y = "Normalized value") +
        theme(
          legend.position='none'
        )
      ggsave(file.path(fig_out, "A.24_GDP-gov.png"), width = 8.5, height = 10, dpi = 600, units = "in")
      
      resil <- dflong %>% 
        filter(theme == "Resilience") %>%
        ggplot(aes(x=GDP_percap, y=valnormed) ) +
        geom_hex(bins=30) +
        scale_fill_distiller(palette=4, direction=-1) + #this line determines a new four-color palette
        scale_x_continuous(labels = comma) +
        scale_y_continuous(expand = c(0, 0)) +
        facet_wrap(indicator~., labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        labs(x="GDP per capita", y = "Normalized value") +
        theme(
          legend.position='none'
        )
      ggsave(file.path(fig_out, "A.25_GDP-resil.png"), width = 8.5, height = 10, dpi = 600, units = "in")
      
      # Figure footnote:
      # Normalized values are calculated using max-min normalization. Each dot represents a country data point.

# Figure A.26 Correlation matrix
      corrdat <- fsci_latest  %>%
        # Exclude classifiers that are not used in correlation
        select(-c(1:24)) %>% 
        # Exclude the urban and total employment indicators
        select(-c("unemp_u", "unemp_tot", "underemp_u", "underemp_tot")) %>%
        # Exclude categorical indicators
        select(-c("righttofood", "accessinfo", "healthtax")) %>%
        as.data.frame()
      dim(corrdat)
      
      # Inspect missing
      is.na(corrdat) %>% table()
      fscicorr_na <- !is.na(corrdat) 
      
      # compute correlation matrix using Spearman non-parametric correlations
      # Define Flatten function 
      # cormat : matrix of the correlation coefficients
      # pmat : matrix of the correlation p-values
      flattenCorrMatrix <- function(cormat, pmat) {
        ut <- upper.tri(cormat)
        data.frame(
          row = rownames(cormat)[row(cormat)[ut]],
          column = rownames(cormat)[col(cormat)[ut]],
          cor  =(cormat)[ut],
          p = pmat[ut]
        )
      }

      corr_mat <- Hmisc::rcorr(as.matrix(corrdat), type=c("spearman"))
      corr_mat
      
      # Extract the correlation coefficients
      corr_mat$r
      # Extract p-values
      corr_mat$P
      # Extract sample size
      corr_mat$n
      
      # Flatten / format the correlation matrix with function defined above
      corr <- flattenCorrMatrix(corr_mat$r, corr_mat$P) %>% as.data.frame()
      plot <- ggcorrplot(corr_mat$r,
                              p.mat =  corr_mat$P,
                              hc.order = FALSE,
                              type = "upper",
                              outline.color = "white",
                              tl.cex = 7, tl.col = "black", tl.srt = 90,
                              lab = FALSE, 
                              sig.level = 0.05,
                              insig = ("blank"),
                              ggtheme = theme_classic(),
                              legend.title = "Correlation coefficient\n(Spearman rank)",
                              colors = c("#B2182B", "white", "#2166AC")) 
      plot
      
      ggsave(file.path(fig_out, "A.26_corrmatrix.png"), 
             width = 8, height = 7, dpi = 600, units = "in")
      

################################################################################ 
  ## Indicator visualizations            
    
            
## Theme 1: Diets, Nutrition, & Health #########################################

############ Food Environments #################################################

## Cost of a healthy diet (FAO/Food Prices for Nutrition)

# Figure S1.1_cohd_region.png.png
     
      # Select variables
      data <- select(fsci_data, c("country", "cohd", "year", "fsci_regions")) %>%
            subset(year >= 2017 & year < 2021) %>% filter(!is.na(cohd)) %>% 
            filter(!is.na("fsci_regions"))
      
      # Reorder and factor 
      data$year <- factor(data$year, levels=c("2017", "2018", "2019", "2020"))
      data <- data %>% mutate(fsci_regions = as.factor(fsci_regions))
      
      cohd <- ggplot(data, aes(x=year, y=cohd, color = fsci_regions, fill = fsci_regions)) +
        geom_violin(trim = FALSE) +
        scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
        facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("Cost of a healthy diet (2015 $US PPP)") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))
      cohd
      #png
      ggsave(file.path(fig_out, "S1.1_cohd_region.png"), width = 10, height = 6, dpi=300, units = "in")

# Figure S1.2_cohd_income.png
      
      # Select variables
      data <- select(fsci_data, c("country", "cohd", "year", "incgrp"))

      # Drop years without this indicator and NA values
      data <- subset(data, year >= 2017 & year < 2021) %>% 
        filter(!is.na(cohd)) %>% filter(!is.na("incgrp"))

      # Reorder and factor 
      data$year <- factor(data$year, levels=c("2017", "2018", "2019", "2020"))

      cohd <- ggplot(data, aes(x=year, y=cohd, color = incgrp, fill = incgrp)) +
        geom_violin(trim = FALSE) +
        scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
        facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("Cost of a healthy diet (2015 $US PPP)") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))
      cohd
      
      ggsave(file.path(fig_out, "S1.2_cohd_income.png"), width = 10, height = 6, dpi=300, units = "in")

## Availability of fruits and vegetables (kg/capita) (FAO) 

# Figure S1.3_FVAvail_region.png
      fvdata <- select(fsci_data, c("country", "year", "fsci_regions", "incgrp", "avail_fruits", "avail_veg", "totalpop")) %>%
        drop_na(avail_fruits | avail_veg)
      
      # Weighted average by region
      fruit_mean <- fvdata %>% 
        group_by(year, fsci_regions) %>% 
        summarise(fruit_region_mean = weighted.mean(avail_fruits, totalpop, na.rm=TRUE))
      veg_mean <- fvdata %>% 
        group_by(year, fsci_regions) %>% 
        summarise(veg_region_mean = weighted.mean(avail_veg, totalpop, na.rm=TRUE))
      
      # Plot
      fruits <- ggplot(data = fruit_mean, aes(x = year, y = fruit_region_mean, color = fsci_regions), groups = fsci_regions) +
        geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
        labs(x = "", y = "g/person/day", color= "") + 
        scale_x_continuous(breaks=seq(2000, 2019, 1)) + ylim(0,750) +
        theme(axis.title.x = element_text(size = 14), 
              axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
              legend.text = element_text(size = 12), legend.title = element_text(size = 14),
              legend.position = "none") +
        scale_color_manual(values=regions) +
        ggtitle("Fruits")
      fruits
      veg <- ggplot(data = veg_mean, aes(x = year, y = veg_region_mean, color = fsci_regions), groups = fsci_regions) +
        geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
        labs(x = "", y = "", color= "Region") + 
        scale_x_continuous(breaks=seq(2000, 2019, 1)) +  ylim(0,750) +
        theme(axis.title.x = element_text(size = 14), 
              axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
              legend.text = element_text(size = 12), legend.title = element_text(size = 14), 
              legend.position = "none") +
        scale_color_manual(values=regions) +
        ggtitle("Vegetables")
      veg
      fruitsleg <- ggplot(data = fruit_mean, aes(x = year, y = fruit_region_mean, color = fsci_regions), groups = fsci_regions) +
        geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
        labs(x = "", y = "g/person/day", color= "") + 
        scale_x_continuous(breaks=seq(2000, 2019, 1)) +  ylim(0,750) +
        theme(axis.title.x = element_text(size = 14), 
              axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, 
                                                                                 vjust=1, hjust=1), 
              legend.text = element_text(size = 12), legend.title = element_text(size = 14),
              legend.position = "bottom") + guides(color=guide_legend(nrow=3, byrow=TRUE)) +
        scale_color_manual(values=regions) 
      legend <- get_legend(fruitsleg)
      fv_reg1 <- plot_grid(fruits, veg, align = "hv", axis = "right",
                           ncol = 2, label_size = 14, hjust = -0.2)
      fv_region <- plot_grid(fv_reg1, legend, nrow = 2, rel_heights = c(1,0.2))
      fv_region
      
      ggsave(file.path(fig_out, "S1.3_FVAvail_region.png"), width = 10, height = 6, dpi=300, units = "in")
      
# Figure S1.4_FVAvail_income.png
      
      fvdata <- select(fsci_data, c("country", "year", "fsci_regions", "incgrp", 
                                    "avail_fruits", "avail_veg", "totalpop")) %>%
        drop_na(avail_fruits | avail_veg | incgrp)
      
      # Weighted average by income
      fruit_mean1 <- fvdata %>% 
        group_by(year, incgrp) %>% 
        summarise(fruit_income_mean = weighted.mean(avail_fruits, totalpop, na.rm=TRUE))
      veg_mean1 <- fvdata %>% 
        group_by(year, incgrp) %>% 
        summarise(veg_income_mean = weighted.mean(avail_veg, totalpop, na.rm=TRUE))
      
      # Plot
      fruits <- ggplot(data = fruit_mean1, aes(x = year, y = fruit_income_mean, color = incgrp), groups = incgrp) +
      geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
      labs(x = "", y = "g/person/day", color= "") + 
      scale_x_continuous(breaks=seq(2000, 2019, 2)) + ylim(0,750) +
      theme(axis.title.x = element_text(size = 14), 
            axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
            legend.text = element_text(size = 12), legend.title = element_text(size = 14),
            legend.position = "none") +
      scale_color_manual(values=incomescol) +
      ggtitle("Fruits")
    fruits

    veg <- ggplot(data = veg_mean1, aes(x = year, y = veg_income_mean, color = incgrp), groups = incgrp) +
      geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
      labs(x = "", y = "", color= "Income Group") + 
      scale_x_continuous(breaks=seq(2000, 2019, 2)) +  ylim(0,750) +
      theme(axis.title.x = element_text(size = 14), 
            axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
            legend.text = element_text(size = 12), legend.title = element_text(size = 14), 
            legend.position = "none") +
      scale_color_manual(values=incomescol) +
      ggtitle("Vegetables")
    veg

    fruitsleg <- ggplot(data = fruit_mean1, aes(x = year, y = fruit_income_mean, color = incgrp), groups = incgrp) +
      geom_line(linewidth = 2, show.legend = NA) + theme_classic() +
      labs(x = "", y = "g/person/day", color= "") + 
      scale_x_continuous(breaks=seq(2000, 2019, 1)) +  ylim(0,750) +
      theme(axis.title.x = element_text(size = 14), 
            axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
            legend.text = element_text(size = 12), legend.title = element_text(size = 14),
            legend.position = "bottom") +
      scale_color_manual(values=incomescol) 
    legend <- get_legend(fruitsleg)

    fv_income1 <- plot_grid(fruits, veg, align = "hv", axis = "right",
                            ncol = 2, label_size = 14, hjust = -0.2)
    fv_income <- plot_grid(fv_income1, legend, nrow = 2, rel_heights = c(1,0.1))
    fv_income
     
    #png
    ggsave(file.path(fig_out, "S1.4_FVAvail_income.png"), width = 10, height = 6, dpi=300, units = "in")
      
## Retail Value of Ultra-Processed Foods by Country in 2019, Per Capita (US$)

# Figure S1.5_UPFretail_region.png

     #Set variables
     retaildata <- fsci_data %>% 
       select(c("country", "UPFretailval_percap", "year", "fsci_regions")) %>%
       filter(!is.na(fsci_regions)) %>%
       filter(!is.na(UPFretailval_percap))

     #reorder by year 
     retaildata <- retaildata %>% mutate(fsci_regions = as.factor(fsci_regions),
                                         year = as.factor(year))
       
     upf <- ggplot(retaildata, aes(x=year, y=UPFretailval_percap, 
                             color = fsci_regions, fill = fsci_regions)) +
       geom_violin(trim = FALSE) +
       scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
       facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
       ylab("Current US$ per capita") + xlab("") +
       theme_classic() + theme(strip.text = element_text(size = 10),
                               strip.placement = "bottom",
                               legend.position="none",
                               strip.background  = element_rect(fill="lightgray"),
                               panel.border = element_blank(),
                               axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                               axis.text.y=element_text(size=10),
                               axis.title=element_text(size=10))
     
     #png
     ggsave(file.path(fig_out, "S1.5_UPFretail_region.png"), width = 10, height = 6, dpi=300, units = "in")

# Figure S1.6_UPFretail_2019.png

     # Select Variables
      retaildata <- select(fsci_data, c("country", "UPFretailval_percap", "year", "ISO")) %>%
        rename(iso_a3 = ISO)

      #only use 2019 data
      retaildata <- filter(retaildata, year == "2019")

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      retaildata_simple<-merge(World, retaildata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Simple Map
      retail_map<-tm_shape(retaildata_simple) + tm_polygons("UPFretailval_percap",
                                                            style="cont",
                                                            breaks=c(0,200,400,600,800,900,1000,1200,1500),
                                                            palette= color10,
                                                            title="Current US$ per capita",
                                                            legend.is.portrait=FALSE,
                                                            labels = c("0","200","400","600","800","900","1000","1200","1500"),
                                                            colorNA = "grey85", 
                                                            textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      retail_map

      #png
      tmap_save(retail_map, file.path(fig_out, "S1.6_UPFretail_2019.png"), width = 10, height = 6, dpi=300, units = "in")

## % population using safely managed drinking water services (SDG 6.1.1) (WHO/UNICEF Joint Monitoring Programme) 

# Figure S1.7_safeh20_region.png
                               
      safewater <- select(fsci_data, c("country", "fsci_regions", "incgrp", "safeh20", "year", "totalpop")) %>% 
        drop_na() %>%  mutate(fsci_regions = fct_reorder2(fsci_regions, year, safeh20))
      
    # Weighted average by region
      safewater_means <- safewater %>% 
        group_by(year, fsci_regions) %>% 
        summarise(safeh20_region_mean = weighted.mean(safeh20, totalpop, na.rm=TRUE))

    # Set legend order
      region_order_2020 <- safewater_means %>% 
        filter(year=="2020") %>% arrange(safeh20_region_mean, by_group=FALSE) %>% 
        .$fsci_regions 
      
    # Plot
      ggplot(data = safewater_means, aes(x = year, y = safeh20_region_mean, color = fsci_regions), 
             groups = fsci_regions) +
        geom_line( size = 2, show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "% Population", color= "Region") + ylim(1,100) +
        scale_x_continuous(breaks=seq(2000, 2020, 5)) +
        theme(axis.title.x = element_text(size = 14), 
              axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
              legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions, 
                           breaks=rev(region_order_2020))
      
      ggsave(file.path(fig_out, "S1.7_safeh20_region.png"), width = 7, height = 5, dpi = 300, units = "in", device='png')

# Figure S1.8_safeh20_income.png
      
      safewater <- select(fsci_data, c("country", "wb_region", "incgrp", "safeh20", "year", "totalpop")) %>% 
        drop_na() %>%  mutate(wb_region = fct_reorder2(incgrp, year, safeh20))
      
    # Weighted average by income group
      safewater_means <- safewater %>% 
        group_by(year,incgrp) %>% 
        summarise(safeh20_income_mean = weighted.mean(safeh20, totalpop, na.rm=TRUE))
      
    # Set legend order
      income_order_2020 <- safewater_means %>% 
        filter(year=="2020") %>% 
        arrange(safeh20_income_mean,by_group=FALSE) %>% 
        .$incgrp #select just the regions

    # Plot
      ggplot(data = safewater_means,aes(x = year, y = safeh20_income_mean, color = incgrp), groups=incgrp) +
        geom_line(size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "% Population", color= "Income group") + ylim(1,100) +
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), axis.text.x = element_text(angle = 45, vjust=1, hjust=1), legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +
        scale_color_manual(values = incomescol,
                           breaks=rev(income_order_2020))
    
      ggsave(file.path(fig_out, "S1.8_safeh20_income.png"), width = 7, height = 5, dpi = 300, units = "in")

############ Food Security ### #################################################
## PoU: Prevalence of Undernourishment (FAO)
# Figure S1.9_PoU_region.png
      
      POU<- fsci_data %>% select(c("incgrp", "pou_yearrange", "pou", "country", 
                                   "fsci_regions", "year", "totalpop")) %>%
        drop_na(pou) %>% mutate(fsci_regions = factor(fsci_regions))
      
      POU <-POU %>%  mutate(fsci_regions = fct_reorder2(fsci_regions, year, pou))
      
      # Calculate means  
      POU_means <- POU %>% group_by(year, fsci_regions) %>% 
        summarise(pou_region_mean = weighted.mean(pou, totalpop, na.rm = TRUE))
      
      # Order for legend based on final year
      region_order_2020 <- POU_means %>% filter(year=="2020") %>% 
        arrange(pou_region_mean,by_group=FALSE) %>% 
        .$fsci_regions #select just the regions
      
      #generate the plot
      ggplot(data = POU_means,aes(x = year, y = pou_region_mean, color = fsci_regions,
                                  groups = fsci_regions)) +
        geom_line( size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "% Population", color= "Region") + ylim(1,30) +
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              axis.text.x = element_text(angle = 45, vjust=1, hjust=1), 
              legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions,
                           breaks=rev(region_order_2020))
      
      ggsave(file.path(fig_out, "S1.9_PoU_region.png"), width = 10, height = 6, dpi =300, units = "in")
      
      # Figure S1.10_PoU_income.png
      POU<- fsci_data %>% select(c("incgrp", "pou_yearrange", "pou", "country", "fsci_regions", "year", "totalpop")) %>%
        drop_na(pou) %>% mutate(fsci_regions = factor(fsci_regions)) %>%
        drop_na(incgrp)
      
      POU <- POU %>%  mutate(incgrp = fct_reorder2(incgrp, year, pou))
      
      # Calculate means  
      POU_means <- POU %>% group_by(year,incgrp) %>% 
        summarise(pou_incgrp_mean = weighted.mean(pou, totalpop, na.rm=TRUE))
      
      # Order legend by order in final year
      incgrp_order_2020 <-POU_means %>% filter(year=="2020") %>% 
        arrange(pou_incgrp_mean, by_group = FALSE) %>% .$incgrp
      
      #generate the plot
      ggplot(data=POU_means, aes(x = year, y = pou_incgrp_mean, color = incgrp), groups=incgrp) +
        geom_line( size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "% Population", color= "Income Group") + 
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              axis.text.x = element_text(size = 12, angle = 45, vjust=1, hjust=1), axis.text.y = element_text(size = 11),
              legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
        scale_color_manual(values = incomescol,
                           breaks=rev(incgrp_order_2020))
      
      ggsave(file.path(fig_out, "S1.10_PoU_income.png"), width = 10, height = 6, dpi =300, units = "in")

## % population experiencing moderate or severe food insecurity (FAO)                       
# Figure "S1.11_FIES_region.png

      data <- fsci_data %>%
        select(c("incgrp", "fies_yearrange", "fies_modsev", "country", "fsci_regions")) %>%
        drop_na()
      
      #convert year ranges and proportion of populations experiencing food insecurity to factor variables
      data$fies_yearrange <- as.factor(data$fies_yearrange)
      data <- data %>% mutate(fsci_regions = as.factor(fsci_regions))
      
      fies <- ggplot(data, aes(x=fies_yearrange, y=fies_modsev, 
                                    color = fsci_regions, fill = fsci_regions)) +
        geom_boxplot(width=0.5)+ ylim(0, 100) +
        scale_x_discrete(labels=c("2014-2016" = "2014-16", "2015-2017" = "2015-17", 
                                  "2016-2018" = "2016-18", "2017-2019" = "2017-19", 
                                  "2018-2020" = "2018-20")) +
        scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
        facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("% population") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))

      #save figures
      ggsave(file.path(fig_out, "S1.11_FIES_region.png"), width = 10, height = 6, dpi=300, units = "in")

# Figure S1.12_FIES_income.png
    
      #select the relevant variables from the master dataset
      data <- fsci_data %>%
        select(c("incgrp", "fies_yearrange", "fies_modsev", "country", "fsci_regions")) %>%
        drop_na()
      
      fies <- ggplot(data, aes(x=fies_yearrange, y=fies_modsev, 
                               color = incgrp, fill = incgrp)) +
        geom_boxplot(width=0.5)+ ylim(0, 100) +
        scale_x_discrete(labels=c("2014-2016" = "2014-16", "2015-2017" = "2015-17", 
                                  "2016-2018" = "2016-18", "2017-2019" = "2017-19", 
                                  "2018-2020" = "2018-20")) +
        scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
        facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("% population") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))

      #save figures
      ggsave(file.path(fig_out, "S1.12_FIES_income.png"), width = 10, height = 6, dpi=300, units = "in")

## % population who cannot afford a healthy diet (FAO/ Food Prices for Nutrition)
# Figure S1.13_Afford_region.png

  #select the relevant variables from the master dataset
  costofdiet<- select(fsci_data, c("country", "fsci_regions", "incgrp", "pctcantafford", "year")) %>%
    filter(!is.na(pctcantafford))

    #reorder by year 
    costofdiet <- costofdiet %>% mutate(fsci_regions = as.factor(fsci_regions),
                                        year = as.factor(year))
    
    costofdiet <- ggplot(costofdiet, aes(x=year, y=pctcantafford, 
                                  color = fsci_regions, fill = fsci_regions)) +
      geom_violin(trim = FALSE) + ylim(0,100) +
      scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
      facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
      ylab("% population") + xlab("") +
      theme_classic() + theme(strip.text = element_text(size = 10),
                              strip.placement = "bottom",
                              legend.position="none",
                              strip.background  = element_rect(fill="lightgray"),
                              panel.border = element_blank(),
                              axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                              axis.text.y=element_text(size=10),
                              axis.title=element_text(size=10))
    
      #save file
      ggsave(file.path(fig_out, "S1.13_Afford_region.png"), width = 10, height = 6, dpi = 300, units = "in")

# Figure S1.14_Afford_income.png

    costofdiet<- select(fsci_data, c("country", "fsci_regions", "incgrp", "pctcantafford", "year")) %>%
      filter(!is.na(pctcantafford)) %>%
      mutate(year = as.factor(year))
   
     costofdiet <- ggplot(costofdiet, aes(x=year, y=pctcantafford, 
                                         color = incgrp, fill = incgrp)) +
      geom_violin(trim = FALSE) + ylim(0,100) +
      scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
      facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
      ylab("% population") + xlab("") +
      theme_classic() + theme(strip.text = element_text(size = 10),
                              strip.placement = "bottom",
                              legend.position="none",
                              strip.background  = element_rect(fill="lightgray"),
                              panel.border = element_blank(),
                              axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                              axis.text.y=element_text(size=10),
                              axis.title=element_text(size=10))
    
    ggsave(file.path(fig_out, "S1.14_Afford_income.png"), width = 8, height = 8, dpi = 300, units = "in", device='png')



## Diet Quality ##

## MDD-W: % adult women meeting minimum dietary diversity (Gallup World Poll)
# S1.15_MDDW.png
    # Use indicator-specific dataset
    MDD_W_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
      select(c("country", "MDD_W", "MDD_W_LCI", "MDD_W_UCI", "year", "incgrp", "fsci_regions"))
    
    #reordering from greatest to lowest MDD and categorizing based on regions.
    MDD_W_2021 <- MDD_W_2021 %>%
      arrange(-MDD_W) %>%
      mutate(country = factor(country, levels = country)) %>%
      mutate(country = fct_reorder(country, fsci_regions))
    
    #generating the plot
    theme_set(
      theme_classic() +
        theme(legend.position = "top")) + 
          theme(axis.text.x = element_text(angle = 90))
    
    ggplot(data = MDD_W_2021, aes(x = MDD_W, y= country, MDD_W, col = fsci_regions)) +
      geom_point() + 
      geom_errorbar(data = MDD_W_2021, aes(xmin = MDD_W_LCI, xmax = MDD_W_UCI), width = 0) + 
      labs(x = "% Women", y = "") + theme(legend.title=element_blank()) +
      scale_color_manual(values = regions) 
    
    ggsave(file.path(fig_out, "S1.15_MDDW.png"), width = 10, height = 5, dpi =300, units = "in")

# Figure S1.16_MDDIYCF_sex.png
    # Use indicator-specific datasets for disaggregation variables
    MDD_youngchild <- read_dta(file.path(data_in, "MDD_youngchild.dta")) %>%
      select(c("year", "country", "fsci_regions", "incgrp", "MDD_iycf",
               "MDD_iycf_m", "MDD_iycf_f", "MDD_iycf_u", "MDD_iycf_r"))

    # Create a new column sex and aggregate the MDD_iycf_f and MDD_iycf_m
    # under the same column
    MDD_youngchild <-
      gather(MDD_youngchild, key = "sex",
             value = "MDD",
             c(MDD_iycf_f, MDD_iycf_m)) %>% 
      # Rename MDD_iycf_f and MDD_iycf_m to m and f respectively
      mutate(sex = case_when(sex == "MDD_iycf_f" ~ "Female",
                             sex == "MDD_iycf_m" ~ "Male")) %>%
      group_by(country) 
    
    #drop any NA value
    MDD_youngchild <- drop_na(MDD_youngchild)
    
    #Plot the figure
    ggplot(data = MDD_youngchild, aes(
      x = MDD,
      y = reorder(fsci_regions,
                  MDD, 
                  decreasing = FALSE),
      fill = sex)) +
      geom_bar(stat = "summary",
               fun = "mean",
               position = "dodge") +
      ylab("Region") + xlab("% Children 6-23 months") +
      scale_fill_manual(values = cbpalette_2[c(1, 10)]) +
      theme_classic() + theme(legend.title=element_blank())
    
    ggsave(file.path(fig_out, "S1.16_MDDIYCF_sex.png"), width = 7, height = 5, dpi=300, units = "in")

# Figure S1.17_MDDIYCF_geo.png
    
    # Use indicator-specific datasets for disaggregation variables
      MDD_youngchild <- read_dta(file.path(data_in, "MDD_youngchild.dta")) %>%
        select(c("year", "country", "fsci_regions", "incgrp", "MDD_iycf",
                 "MDD_iycf_m", "MDD_iycf_f", "MDD_iycf_u", "MDD_iycf_r"))

  # Create a new column geo and aggregate the MDD_iycf_r and MDD_iycf_u data under the same column
      MDD_youngchild <-
          gather(MDD_youngchild, key = "geo",
           value = "MDD_iycf",
           c(MDD_iycf_u, MDD_iycf_r)) %>%
      # Rename MDD_iycf_u and MDD_iycf_r to u and r respectively
      mutate(geo = case_when(geo == "MDD_iycf_u" ~ "Urban",
                             geo == "MDD_iycf_r" ~ "Rural")) %>%
      group_by(country) 
    
      MDD_youngchild <- drop_na(MDD_youngchild)

    #Plot 
      ggplot(data = MDD_youngchild, aes(y = MDD_iycf, x = reorder(fsci_regions, MDD_iycf, decreasing = FALSE), fill = geo)) +
        geom_bar(stat = "summary", fun = "mean", position="dodge") +
        coord_flip() + 
        ylab("Region") + xlab("% Children 6-23 months") +
        scale_fill_manual(values = cbpalette_urbrurl) + 
        theme_classic() + theme(legend.title=element_blank())
      
      #Save the figure as png
      ggsave(file.path(fig_out, "S1.17_MDDIYCF_geo.png"), width = 7, height = 5, dpi=300, units = "in")

## MDD (IYCF): All-5: % adult population consuming all 5 food groups (Gallup World Poll)
# Figure S1.18_All5_adult.png
    # Use indicator-specific dataset
      All5_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
        select(c("country", "All5", "All5_LCI", "All5_UCI", 
                 "year", "incgrp", "fsci_regions"))
      
    # Order descending
      All5_2021 <- All5_2021 %>%
      arrange(-All5) %>%
      mutate(country = factor(country, levels = country)) %>%
      mutate(country = fct_reorder(country, fsci_regions))
    
    # Plot
      theme_set(
        theme_classic() +
          theme(legend.position = "top")) + theme(axis.text.x = element_text(angle = 90))
      
      ggplot(data = All5_2021, aes(x = All5, y = country, All5, col = fsci_regions)) +
        geom_point() +
        geom_errorbar(data = All5_2021, aes(xmin = All5_LCI, xmax = All5_UCI), width = 0) + 
        labs(x = "% Adult population", y = "") + theme(legend.title = element_blank()) +
        scale_color_manual(values=regions) 
      
    # The width is adjusted to fit the legend
    ggsave(file.path(fig_out, "S1.18_All5_adult.png"), width = 10, height = 8, dpi=300, units = "in")
                
## Zero fruits and vegetables consumption, adults (Gallup World Poll)
# Figure S1.19_ZeroFV_adult.png
    # Use indicator-specific dataset
    ZeroFV_adult_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
        select(c("country", "zeroFV", "zeroFV_LCI",
                 "zeroFV_UCI", "year", "incgrp", "fsci_regions"))
    # Reorder descending
      ZeroFV_adult_2021 <- ZeroFV_adult_2021 %>%
        arrange (-zeroFV) %>%
        mutate(country = factor(country, levels = country)) %>%
        mutate(country = fct_reorder(country, fsci_regions))
    
    # Plot
      theme_set(
        theme_classic() +
          theme(legend.position = "top")) + 
           theme(axis.text.x = element_text(angle = 90))
      
      ggplot(data = ZeroFV_adult_2021, aes(x = zeroFV, y = country, zeroFV, col = fsci_regions)) +
        geom_point() +
        geom_errorbar(data = ZeroFV_adult_2021, aes(xmin = zeroFV_LCI,xmax = zeroFV_UCI), width = 0) +
        labs(x = "% Adult population", y = "") + theme(legend.title = element_blank()) +
        scale_color_manual(values = regions)
    # The width is adjusted to fit the legend
      ggsave(file.path(fig_out, "S1.19_ZeroFV_adult.png"), width = 10, height = 8, dpi=300, units = "in")

## Zero fruits and vegetables consumption,  children 6-23 months (UNICEF), by region, female versus male
# Figure S1.20_ZeroFV_IYCF_sex.png
      # Use indicator-specific dataset
        ZeroFV_youngchild <- read_dta(file.path(data_in, "ZeroFV_youngchild.dta")) %>%       
          drop_na()

      # Create a new column sex and aggregate the MDD_iycf_f and MDD_iycf_m
      # under the same column
        zeroFV_reshape <- ZeroFV_youngchild %>%  
          gather(key = "sex",
                 value = "zeroFV",
                 c(zeroFV_iycf_f, zeroFV_iycf_m)) %>% 
        # Rename zero_iycf_f and zero_iycf_m to m and f respectively
        mutate(sex = case_when(sex == "zeroFV_iycf_f" ~ "Female",
                               sex == "zeroFV_iycf_m" ~ "Male")) %>%
        group_by(country)
    
    # Plot
    ggplot(data = zeroFV_reshape, aes(
      x = zeroFV,
      y = reorder(fsci_regions, 
                  zeroFV_iycf,
                  decreasing = FALSE),
      fill = sex)) + 
      geom_bar(stat = "summary",
               fun = "mean",
               position = "dodge") +
      ylab("Region") + xlab("% Children 6-23 months") +
      scale_fill_manual(values = cbpalette_2[c(1, 10)]) +
      theme_classic() + theme(legend.title = element_blank())
    
    ggsave(file.path(fig_out, "S1.20_ZeroFV_IYCF_sex.png"), width = 8, height = 8, dpi = 300, units = "in")
    
# Figure S1.21_ZeroFV_IYCF_geo.png
    # Use indicator-specific dataset
    ZeroFV_youngchild <- read_dta(file.path(data_in, "ZeroFV_youngchild.dta")) %>%       
      drop_na()

    # Create a new column sex and aggregate the MDD_iycf_f and MDD_iycf_m
    # under the same column
    zeroFV_reshape <- ZeroFV_youngchild %>%  
      gather(key = "geo", value = "zeroFV_icyf",
             c(zeroFV_icyf_u, zeroFV_icyf_r)) %>% 
      
      mutate(geo = case_when(geo == "zeroFV_icyf_u" ~ "Urban",
                             geo == "zeroFV_icyf_r" ~ "Rural")) %>%
      group_by(country)
      
    ggplot(data = zeroFV_reshape, aes(x = reorder(fsci_regions, +zeroFV_icyf), y = zeroFV_icyf, fill = geo)) +
      geom_bar(stat = "summary", fun = "mean", position="dodge") +
      coord_flip() + 
      xlab("Region") + ylab("% Children 6-23 months") +
      scale_fill_manual(values = cbpalette_urbrurl) + 
      theme_classic() + theme(legend.title=element_blank())
    
    ggsave(file.path(fig_out, "S1.21_ZeroFV_IYCF_geo.png"), width = 8, height = 8, dpi=300, units = "in")

## NCD-protect, adults (Gallup World Poll)
# Figure S1.22_NCDProtect_adult.png
    # Use indicator-specific dataset
    NCD_protect_adult_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
      select(c("country", "fsci_regions", "incgrp", "NCD_P", "NCD_P_LCI", "NCD_P_UCI"))
      
      #reorder from greatest to lowest MDD and categorizing based on regions.
      NCD_protect_adult_2021 <- NCD_protect_adult_2021 %>%
        arrange (-NCD_P) %>%
        mutate(country = factor(country, levels = country)) %>%
        mutate(country = fct_reorder(country, fsci_regions))
      
      #generating the plot
      theme_set(
        theme_classic() +
          theme(legend.position = "top")) + 
            theme(axis.text.x = element_text(angle = 90))
      
      ggplot(data = NCD_protect_adult_2021, aes(x = NCD_P, y = country, NCD_P, col = fsci_regions)) +
        geom_point() +
        geom_errorbar(data = NCD_protect_adult_2021, aes(xmin = NCD_P_LCI,xmax = NCD_P_UCI, width = 0)) +
        labs(x = "Score", y = "") + theme(legend.title = element_blank()) +
        scale_color_manual(values = regions) 
      
      #The width is adjusted to fit the legend
      ggsave(file.path(fig_out, "S1.22_NCDProtect_adult.png"), width = 10, height = 8, dpi=300, units = "in")
      
## NCD-risk, adults (Gallup World Poll)
# Figure S1.23_NCDRisk_adult.png
      
      # Use indicator-specific dataset
      NCD_risk_adult_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
        select(c("country", "fsci_regions", "incgrp", "NCD_R", "NCD_R_LCI", "NCD_R_UCI"))
      
      #reordering from greatest to lowest MDD and categorizing based on regions.
      NCD_risk_adult_2021 <- NCD_risk_adult_2021 %>%
        arrange (-NCD_R) %>%
        mutate(country = factor(country, levels = country)) %>%
        mutate(country = fct_reorder(country, fsci_regions))
      
      # Plot
      theme_set(
        theme_classic() +
          theme(legend.position = "top")) + 
            theme(axis.text.x = element_text(angle = 90))
      
      ggplot(data = NCD_risk_adult_2021, aes(x = NCD_R, y = country, NCD_R, col = fsci_regions)) +
        geom_point() +
        geom_errorbar(data = NCD_risk_adult_2021, aes(xmin = NCD_R_LCI,xmax = NCD_R_UCI, width = 0)) +
        labs(x = "Score", y = "") + theme(legend.title = element_blank()) +
        scale_color_manual(values=regions) 
      
      #The width is adjusted to fit the legend
      ggsave(file.path(fig_out, "S1.23_NCDRisk_adult.png"), width = 10, height = 8, dpi=300, units = "in")

## Sugar sweetened soft drink consumption, adults (Gallup World Poll)
# S1.24_SSSD_adult.png
    # Use indicator-specific dataset
      SSSD_adult_2021 <- read_dta(file.path(data_in, "DQQ_2021.dta")) %>%
        select(c("country", "fsci_regions", "incgrp", "SSSD", "SSSD_LCI", "SSSD_UCI"))
      
    #reordering from greatest to lowest MDD and categorizing based on regions.
    SSSD_adult_2021 <- SSSD_adult_2021 %>%
      arrange (-SSSD) %>%
      mutate(country = factor(country, levels = country)) %>%
      mutate(country = fct_reorder(country, fsci_regions))
    
    # Plot
    theme_set(
      theme_classic() +
        theme(legend.position = "top")) + 
      theme(axis.text.x = element_text(angle = 90))
    
    ggplot(data = SSSD_adult_2021, aes(x = SSSD, y = country, SSSD, col = fsci_regions)) +
      geom_point() +
      geom_errorbar(data = SSSD_adult_2021, aes(xmin = SSSD_LCI,xmax = SSSD_UCI), width = 0) + 
      labs(x = "% Adult population", y = "") + theme(legend.title = element_blank()) +
      scale_color_manual(values=regions)
    
    #The width is adjusted to fit the legend
    ggsave(file.path(fig_out, "S1.24_SSSD_adult.png"), width = 10, height = 8, dpi=300, units = "in")


## Theme 2: Environment, natural resources, and production #####################

## Agri-food systems greenhouse gas emissions (kT CO2eq) (AR5) 
# Figure S2.1_fsemissions.png
    fsemiss <- select(fsci_data, c("country", "year", "fsci_regions", "incgrp", "fs_emissions")) %>%
      drop_na(fs_emissions)
    
    # Unweighted average by region
    fsemiss_mean <- fsemiss %>% 
      group_by(year, fsci_regions) %>% 
      summarise(fsemiss_mean_region = mean(fs_emissions, na.rm=TRUE))

    # Set order for legend
    region_order_2020 <- fsemiss_mean %>% 
      filter(year=="2020") %>% 
      arrange(fsemiss_mean_region, by_group=FALSE) %>% .$fsci_regions 

    # Plot
    fsemiss_plot <- ggplot(data = fsemiss_mean, aes(x = year, y = fsemiss_mean_region, 
                                                    color = fsci_regions), groups = fsci_regions) +
      geom_line(linewidth = 2, show.legend = TRUE) + theme_classic() +
      labs(x = "", y = "kT CO2eq (AR5) ", color= "") + 
      scale_x_continuous(breaks=seq(2000, 2020, 2)) + 
      theme(axis.title.x = element_text(size = 14), 
            axis.title.y = element_text(size = 14), axis.text.x = element_text(angle =45, vjust=1, hjust=1), 
            legend.text = element_text(size = 12), legend.title = element_text(size = 14),
            legend.position = "right") + labs(color = "Region") +
      scale_color_manual(values=regions,
                          breaks=rev(region_order_2020)) + 
      scale_y_continuous(labels = label_comma())
    fsemiss_plot
    ggsave(file.path(fig_out, "S2.1_fsemissions.png"), width = 10, height = 6, dpi=300, units = "in")
    
# Figure S2.2_fsemissions_2020.png 
    fsemiss <- select(fsci_data, c("country", "year", "ISO", "fs_emissions")) %>%
      drop_na(fs_emissions) %>% rename(iso_a3 = ISO) %>% filter(year == 2020) %>%
      select(-c(year))
    
    #World map options
    data(World)
    
    #merging data
    fsemiss_simple <-merge(World, fsemiss, by='iso_a3',  duplicateGeoms = TRUE)
    
    #Turn off s2 processing to avoid invalid polygons
    sf::sf_use_s2(FALSE)
    
    #Map
    fsemiss_map <-tm_shape(fsemiss_simple) + 
      tm_polygons("fs_emissions", style="cont", 
                  palette=gradientred, title="Kg CO2eq (AR5)", 
                  legend.is.portrait=FALSE, colorNA="grey85", textNA="Data Unavailable", midpoint = NA) +
      
      tm_layout(frame = FALSE, legend.outside = TRUE,
                legend.outside.position = "bottom", outer.margins=0,
                legend.outside.size = .2) + 
      tm_legend(legend.title.fontface = 2,  # legend bold
                legend.title.size = 3, 
                legend.text.size = 3, 
                legend.bg.alpha = 0, 
                legend.width = 5) 
    fsemiss_map
    tmap_save(fsemiss_map, file.path(fig_out, "S2.2_fsemissions_2020.png"), width = 10, height = 6, dpi=300, units = "in")
    
## Greenhouse gas emissions intensity

    # Code to set up data for all emissions intensity figures
      #set variables
      emint_reg <- select(fsci_data, contains(c("country", "fsci_regions", "year", "emint", "prod"))) %>%
        select(-c(ends_with("range")))

      #remove countries not assigned to any region
      emint_reg <- emint_reg[!emint_reg$fsci_regions=="",]
      
      # Create data frame of production-weighted global mean values
      envirodatalong <- as.data.frame(melt(emint_reg, cbind("country", "year", "fsci_regions"), 
                                           variable.name = "variable", 
                                           value.name = "value", na.rm = TRUE)) %>%
        separate(variable, into = c("indicator", "item"), sep = "_") 
      envirodatawide <- envirodatalong %>%
        group_by(country, year, item) %>%
        pivot_wider(names_from = indicator, values_from = value) %>%
        mutate(prod = ifelse(is.na(prod), 1, prod))
      
      emint_mean <- envirodatawide %>%
        group_by(year, fsci_regions, item) %>%
        summarise(emint_mean = weighted.mean(emint, prod, na.rm = TRUE)) %>%
        mutate(emint_mean = str_replace(emint_mean, "NaN", "")) %>%
        mutate(emint_mean = as.numeric(emint_mean)) %>%
          # remove NAs - products with no emissions intensity data
          drop_na() %>% as.data.frame()
      emint_mean$item <- factor(emint_mean$item)


## Emissions intensity, staple foods, by region
# Figure S2.3_emint_staples_region.png

      #set variables
      cereals <- emint_mean %>% filter(item == "cerealsnorice" | item == "rice") 
      cereals$item <- as.character(cereals$item)
      cereals$item <- ifelse(cereals$item == "cerealsnorice",
                             "Cereals, excluding rice", "Rice")
      
      #create faceted graph
      graphtotal <- ggplot(cereals, aes(year, emint_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + 
        xlab("Year") + ylab("Kg CO2eq/kq product")
      graphtotal
      ggsave(file.path(fig_out, "S2.3_emint_staples_region.png"), width = 10, height = 10, dpi=300, units = "in")

## Emissions intensity, meats, by region
# Figure S2.4_emint_meats_region.png
                         
      #set variables
      meat <- emint_mean %>% filter(item == "beef" | item == "chickenmeat" | item == "pork") 
      meat$item <- as.character(meat$item)
      meat$item <- ifelse(meat$item == "beef", "Beef", meat$item)
      meat$item <- ifelse(meat$item == "chickenmeat", "Chicken", meat$item)
      meat$item <- ifelse(meat$item == "pork", "Pork", meat$item)
      
      #create faceted graph
      graphtotal <- ggplot(meat, aes(year, emint_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + 
        scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + 
        xlab("Year") + ylab("Kg CO2eq/kq product")
      graphtotal
      ggsave(file.path(fig_out, "S2.4_emint_meats_region.png"), width = 10, height = 10, dpi=300, units = "in")


## Emissions intensity, other animal-source foods, by region
# Figure S2.5_emint_otherasf_region.png
                         
      #set variables
      asf <- emint_mean %>% filter(item == "cowmilk" | item == "eggs") 
      asf$item <- as.character(asf$item)
      asf$item <- ifelse(asf$item == "cowmilk", "Milk (raw, from cattle)", "Eggs (hen)")

      #create faceted graph
      graphtotal <- ggplot(asf, aes(year, emint_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("Kg CO2eq/kq product")
      graphtotal
      ggsave(file.path(fig_out, "S2.5_emint_otherasf_region.png"), width = 10, height = 10, dpi=300, units = "in")


## Food product yield per food group 
  # Code to set up data for all yield figures
      
      #set variables
      yield_reg <- select(fsci_data, contains(c("country", "fsci_regions", "year", 
                                                        "yield", "areaharvested", "producinganimals"))) %>%
        select(-c(contains(c("yearrange")))) %>%
        subset(year >= 2000) %>%
        subset(fsci_regions!="")
      
      # Create data frame of production-weighted global mean values
      datalong <- as.data.frame(melt(yield_reg, cbind("country", "year", "fsci_regions"), variable.name = "variable", 
                                           value.name = "value", na.rm = TRUE)) %>%
        separate(variable, into = c("indicator", "item"), sep = "_") 
      datawide <- datalong %>%
        group_by(country, year, item) %>%
        pivot_wider(names_from = indicator, values_from = value) %>%
        mutate(weight = ifelse(is.na(producinganimals), areaharvested, producinganimals)) 
      
      yield_mean <- datawide %>%
        group_by(year, fsci_regions, item) %>%
        summarise(yield_mean = weighted.mean(yield, weight, na.rm = TRUE)) %>%
        mutate(yield_mean = str_replace(yield_mean, "NaN", "")) %>%
        mutate(yield_mean = as.numeric(yield_mean)) %>%
        # remove NAs - products with no emissions intensity data
        drop_na() %>% as.data.frame()
      yield_mean$item <- factor(yield_mean$item)
      
## Yield, staple foods
# Figure S2.6_yield_staples_region.png

      #set variables
      staples <- yield_mean %>% filter(item == "cereals" | item == "roottuber") 
      staples$item <- as.character(staples$item)
      staples$item <- ifelse(staples$item == "cereals",
                             "Cereals", "Roots & Tubers")
      
      #create faceted graph
      graphtotal <- ggplot(staples, aes(year, yield_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("tonnes/ha")
      graphtotal

      ggsave(file.path(fig_out, "S2.6_yield_staples_region.png"), width = 10, height = 10, dpi=300, units = "in")

## Yield, meats, by region
# Figure S2.7_yield_meats_region.png
      #set variables
      meat <- yield_mean %>% filter(item == "beef" | item == "chickenmeat" | item == "pork") 
      meat$item <- as.character(meat$item)
      meat$item <- ifelse(meat$item == "beef", "Beef", meat$item)
      meat$item <- ifelse(meat$item == "chickenmeat", "Chicken", meat$item)
      meat$item <- ifelse(meat$item == "pork", "Pork", meat$item)
      
      #create faceted graph
      graphtotal <- ggplot(meat, aes(year, yield_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("kg/animal")
      graphtotal
      
      ggsave(file.path(fig_out, "S2.7_yield_meats_region.png"), width = 10, height = 10, dpi=300, units = "in")


## Yield, other animal-source foods, by region
# Figure S2.8_yield_otherasf_region.png

      #set variables
      asf <- yield_mean %>% filter(item == "cowmilk" | item == "eggs") 
      asf$item <- as.character(asf$item)
      asf$item <- ifelse(asf$item == "cowmilk", "Milk (raw, from cattle)", "Eggs (hen)")
      
      #create faceted graph
      graphtotal <- ggplot(asf, aes(year, yield_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("kg/animal")
      graphtotal
      
      #create png
      ggsave(file.path(fig_out, "S2.8_yield_otherasf_region.png"), width = 10, height = 10, dpi=300, units = "in")


## Yield, pulses & nuts, by region
# Figure S2.9_yield_pulsenut_region.png
      
      #set variables
      plsnut <- yield_mean %>% filter(item == "pulses" | item == "treenuts") 
      plsnut$item <- as.character(plsnut$item)
      plsnut$item <- ifelse(plsnut$item == "pulses", "Pulses", "Treenuts")
      
      #create faceted graph
      graphtotal <- ggplot(plsnut, aes(year, yield_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("tonnes/ha")
      graphtotal

      ggsave(file.path(fig_out, "S2.9_yield_pulsenut_region.png"), width = 10, height = 10, dpi=300, units = "in")


## Yield, fruits & vegetables, by region
# Figure S2.10_yield_fruitveg_region.png

      fv <- yield_mean %>% filter(item == "citrus" | item == "fruit" | item == "vegetables") 
      fv$item <- as.character(fv$item)
      fv$item <- ifelse(fv$item == "citrus", "Citrus fruits", fv$item )
      fv$item <- ifelse(fv$item == "fruit", "Fruits (excluding citrus)", fv$item )
      fv$item <- ifelse(fv$item == "vegetables", "Vegetables", fv$item )
      
      #create faceted graph
      graphtotal <- ggplot(fv, aes(year, yield_mean, fill = fsci_regions, colour = fsci_regions)) + 
        geom_line(linewidth = 2) + theme_classic() +
        ggtitle("") + scale_color_manual(values=regions) + 
        facet_wrap(~item, ncol = 1, scales = "free") + labs(colour = "Region") + xlab("Year") + ylab("tonnes/ha")
      graphtotal
      
      ggsave(file.path(fig_out, "S2.10_yield_fruitveg_region.png"), width = 10, height = 10, dpi=300, units = "in")

## Map of the latest 5 year average change (2016-2020), Average change (%)
      # Figure S2.11_landexpansion.png
      croplandchange  <- fsci_latest %>%
        select(c("country", "ISO", "croplandchange_pct"))	%>%
        drop_na(croplandchange_pct) 
      croplandchange <- rename(croplandchange, iso_a3 = ISO)

      #World map options
      data(World)

      #merging data
      croplandchange_simple <-merge(World, croplandchange, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      View(croplandchange_simple) #view to decide on the breaks
      range(croplandchange_simple$croplandchange_pct)

      #Map
      croplandchange_simple_map <- tm_shape(croplandchange_simple) + 
        tm_polygons("croplandchange_pct", style="cont", breaks=c(-15, -10, -5,0,5,10,15), 
                    labels = c("-15", "-10","-5","0","5","10","15"), 
                    palette=colordiv_redblue12, title="% change over previous 5 years", 
                    legend.is.portrait=FALSE, colorNA="grey85", textNA="Data Unavailable", midpoint = NA) +

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      
    tmap_save(croplandchange_simple_map, file.path(fig_out, "S2.11_landexpansion.png"), width = 10, height = 6, dpi=300, units = "in")
  
## Agriculture Water Withdrawal as % of Total Renewable Water Resources (AQUASTAT)           
# Figure S2.12_agwaterdraw_2018.png ## Agricultural Water Withdrawal as a Percentage of Renewable Water Resources, Unadjusted 2018

      #Set variables
      agwdata <- select(fsci_data, c("year", "ISO", "agwaterdraw")) %>%
        rename(iso_a3 = ISO) %>% 
        filter(year == "2018")

      #World map 
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      agwdata_simple<-merge(World,agwdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      ag_map<-tm_shape(agwdata_simple) + tm_polygons("agwaterdraw",
                                                     style="cont",
                                                     breaks=c(0,10,20,30,40,50,60,70,80,90,100, 4000),
                                                     palette = color10,
                                                     title="% of total renewable water resources",
                                                     legend.is.portrait=FALSE,
                                                     labels = c("0","10","20","30","40","50","60","70","80","90","100", "100+"),
                                                     colorNA = "grey85", textNA = "Data Unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      ag_map

      #create png for ag_map
      tmap_save(ag_map, file.path(fig_out, "S2.12_agwaterdraw_2018.png"), width = 10, height = 6, dpi=300, units = "in")
                        
# Figure S2.13_agwaterdraw_region.png
    agwaterd <- select(fsci_data, c("year", "country", "agwaterdraw", "incgrp", "fsci_regions")) %>% 
      drop_na(agwaterdraw)
    
    #convert agricultural water withdrawal variable to numeric
    agwaterd$agwaterdraw <- as.numeric(agwaterd$agwaterdraw)
    
    agwaterd <- agwaterd %>% mutate(fsci_regions = as.factor(fsci_regions),
                                        year = as.factor(year))
    
    ggplot(agwaterd, aes(x=year, y=agwaterdraw, 
                                         color = fsci_regions, fill = fsci_regions)) +
      geom_boxplot(trim = FALSE) + ylim(0,100) +
      scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
      facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
      ylab("% of Total Renewable Resources") + xlab("") +
      theme_classic() + theme(strip.text = element_text(size = 10),
                              strip.placement = "bottom",
                              legend.position="none",
                              strip.background  = element_rect(fill="lightgray"),
                              panel.border = element_blank(),
                              axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                              axis.text.y=element_text(size=10),
                              axis.title=element_text(size=10))
    
    #save the figure as png + width and helight is different than the standard set for the data team, in order to fit the legend
    ggsave(file.path(fig_out, "S2.13_agwaterdraw_region.png"), width = 10, height = 8, dpi = 300, units = "in")  

# Figure S2.14_agwaterdraw_income.png
     awwdata <- select(fsci_data, c("incgrp", "agwaterdraw", "year")) %>%
       drop_na(agwaterdraw, incgrp) %>%
       mutate(year = as.factor(year)) %>%
       filter(incgrp!="")

     ggplot(awwdata, aes(x=year, y=agwaterdraw, 
                          color = incgrp, fill = incgrp)) +
       geom_boxplot(trim = FALSE) + ylim(0,100) +
       scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
       facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
       ylab("% of Total Renewable Resources") + xlab("") +
       theme_classic() + theme(strip.text = element_text(size = 10),
                               strip.placement = "bottom",
                               legend.position="none",
                               strip.background  = element_rect(fill="lightgray"),
                               panel.border = element_blank(),
                               axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                               axis.text.y=element_text(size=10),
                               axis.title=element_text(size=10))
     
      ggsave(file.path(fig_out, "S2.14_agwaterdraw_income.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Functional integrity: % Agricultural Land with Minimum Level of Natural Habitat, 2015                         
# Figure S2.15_funcinteg_2015.png

      #Set variables
      functiondata <- select(fsci_data, c("ISO", "functionalintegrity", "year")) %>%
        rename(iso_a3 = ISO) %>%
        filter(year == 2015) %>%
        select(-c(year))

      #make sure functional integrity is numeric
      functiondata$functionalintegrity <- as.numeric(functiondata$functionalintegrity)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      functiondata_simple<-merge(World,functiondata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      function_map <-tm_shape(functiondata_simple) + tm_polygons("functionalintegrity",
                                                            style="cont",
                                                            breaks=c(75,80,85,90,95,100),
                                                            palette= color10,
                                                            title="% agricultural land with minimum level of natural habitat",
                                                            legend.is.portrait=FALSE,
                                                            labels = c("<75%","80%","85%","90%","95%","100%"),
                                                            colorNA = "grey85", 
                                                            textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      function_map
      tmap_save(function_map, file.path(fig_out, "S2.15_funcinteg_2015.png"), width = 10, height = 6, dpi=300, units = "in")

## Fishery health index progress score
# Figure S2.16_fishhealth_2021.png 

      #Select variables
      fish_index <- select(fishhealth, c("fishhealth", "ISO", "year")) %>%
        rename(iso_a3 = ISO) %>% filter(year == 2021) %>% drop_na

      #World map 
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  
      fish <- merge(World, fish_index, by=("iso_a3"), duplicateGeoms = TRUE)

      # Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      fish_map <- tm_shape(fish) + tm_polygons("fishhealth",
                                               style="cont",
                                               breaks=c(0,10,20,30,40,50,60,70,80),
                                               palette = color7,
                                               title="Fishery health index Score",
                                               legend.is.portrait=FALSE,
                                               labels = c("0","10","20","30","40","50","60","70","80"),
                                               colorNA = "grey85", textNA = "Data Unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) +
        tm_compass(color.dark = "gray45", # color the compass
                   text.color = "gray45") # color the text of the compass

      fish_map

      # Saving Plot
      tmap_save(fish_map, file.path(fig_out, "S2.16_fishhealth_2021.png"), units="in", width=8, height=4, dpi=300)
                         
##Total pesticides per unit of land (kg/ha) (FAO)
# Figure S2.17_pesticides_region.png
     
      # Select variables
        pesticides_data <- select(fsci_data, c("country", "pesticides", "year", "fsci_regions", "croplandcov")) %>%
          drop_na()
        
      # Order and create regional mean
        pesticides_data <- pesticides_data %>% 
          mutate(fsci_regions = fct_reorder2(fsci_regions, year, pesticides)) %>% 
          group_by(year,fsci_regions) %>% 
          summarise(pesticide_region_mean = weighted.mean(pesticides, croplandcov, na.rm=TRUE))

      # Set order for legend
        region_order_2019 <- pesticides_data %>% 
          filter(year=="2019") %>% 
          arrange(pesticide_region_mean,by_group=FALSE) %>% .$fsci_regions 

        ggplot(data=pesticides_data, aes(x = year, y = pesticide_region_mean, color = fsci_regions), groups=fsci_regions) +
          geom_line(size = 2, show.legend = NA) + theme_classic() +
          labs(x = "Year", y = "Total pesticides per hectare (kg/ha)", color= "Region") + 
          scale_x_continuous(breaks=seq(2000, 2019, 5)) +
          theme(axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14), 
                axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 12),
                legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +
          scale_color_manual(values=regions,
                             breaks=rev(region_order_2019))
        
        ggsave(file.path(fig_out, "S2.17_pesticides_region.png"), width = 10, height = 6, dpi=300, units = "in")
 
# Figure S2.18_pesticides_2019.png ## Total pesticides per unit of land (kg/ha) - Cloropleth map of 2019 data
       # Select variables
       pesticides <- select(fsci_data, c("pesticides", "ISO", "year")) %>%
         rename(iso_a3 = ISO) %>% filter(year == 2019) %>% drop_na

       #World map 
       World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  
       pesticides <- merge(World, pesticides, by=("iso_a3"), duplicateGeoms = TRUE)

       # Turn off s2 processing to avoid invalid polygons
       sf::sf_use_s2(FALSE)

       # Map
       pesticides_map <- tm_shape(pesticides) + tm_polygons("pesticides",
                                                             style="cont",
                                                             breaks=c(0,5,10,15,20,25),
                                                             palette = gradientred,
                                                             title="Total pesticides per unit of land (kg/ha)",
                                                             legend.is.portrait=FALSE,
                                                             labels = c("0","5","10","15","20","25"),
                                                             colorNA = "grey85", textNA = "Data Unavailable") + 
         tm_layout(frame = FALSE, legend.outside = TRUE,
                    legend.outside.position = "bottom", outer.margins = 0,
                    legend.outside.size = .2) + 
         tm_legend(legend.title.fontface = 2,  # legend bold
                    legend.title.size = 3, 
                    legend.text.size = 3, 
                    legend.bg.alpha = 0, 
                    legend.width = 5) 

        pesticides_map
        
        # Saving Plot
        tmap_save(pesticides_map, file.path(fig_out, "S2.18_pesticides_2019.png"), units="in", width=8, height=4, dpi=300)

## Sustainable Nitrogen Management Index 
                         
##Sustainable nitrogen management index 
# Figure S2.19_sustNO2_region.png
      
    # Select variables
      no2_data <- select (fsci_data, c("country", "sustNO2mgmt", "year", "fsci_regions", "croplandcov")) %>%
        drop_na() 
    
    # Regional mean
      no2_data <-no2_data %>%  
        mutate(fsci_regions = fct_reorder2(fsci_regions, year, sustNO2mgmt)) %>%
        group_by(year, fsci_regions) %>% 
        summarise(no2_region_mean = weighted.mean(sustNO2mgmt, croplandcov, na.rm=TRUE))

    # Set order for legend 
      region_order_2018 <- no2_data %>% filter(year=="2018") %>% 
        arrange(no2_region_mean, by_group=FALSE) %>% 
        .$fsci_regions 
      # Manual fix for mysterious bug in region order causing legend not to show
      region_order_2018 <- c("Northern Africa & Western Asia",
                             "Oceania", "Sub-Saharan Africa", "Southern Asia",
                             "Latin America & Caribbean", "Eastern Asia", 
                             "Northern America and Europe",
                             "South-eastern Asia", "Central Asia")
      region_order_2018 <- as.factor(region_order_2018)
        
      ggplot(data = no2_data, aes(x = year, y = no2_region_mean, color = fsci_regions)) +
      geom_line(size = 2, show.legend = TRUE) + theme_classic() +
      labs(x = "Year", y = "Sustainable nitrogen management index", color= "Region") + 
      scale_x_continuous(breaks=seq(2000, 2018, 2)) +
      theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
            legend.text = element_text(size = 12), axis.text.x = element_text(size = 12), 
            axis.text.y = element_text(size = 12),legend.title = element_text(size = 14)) + 
        scale_color_manual(values=regions, breaks=(region_order_2018))    
      
     ggsave(file.path(fig_out, "S2.19_sustNO2_region.png"), width = 10, height = 6, dpi=300, units = "in")
                         
# Figure S2.20_sustNO2_2018.png

    #Select variables
    no2_data <- select(fsci_data, c("ISO", "sustNO2mgmt", "year")) %>%
      rename(iso_a3 = ISO) %>% filter(year == "2018") %>% 
      drop_na(sustNO2mgmt)

    #set up variable for year 2018
    y2018 <- filter(no2_data, year == "2018")

    #convert sustNO2mgmt variable to number variable
    y2018$sustNO2mgmt <- as.numeric(no2_data$sustNO2mgmt)

    #World map options
    World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

    #merging data
    data_simple <- merge(World, no2_data, by='iso_a3',  duplicateGeoms = TRUE)

    #Turn off s2 processing to avoid invalid polygons
    sf::sf_use_s2(FALSE)

    #Creating Map

    #Simple Map
    data_map<-tm_shape(data_simple) + tm_polygons("sustNO2mgmt",
                                                  style="cont",
                                                  palette= color10,
                                                  title="Sustainable Nitrogen Management Index",
                                                  legend.is.portrait=FALSE,
                                                  colorNA = "grey85", 
                                                  textNA = "Data Unavailable") + 

      tm_layout(frame = FALSE, legend.outside = TRUE,
                legend.outside.position = "bottom", outer.margins=0,
                legend.outside.size = .2) + 
      tm_legend(legend.title.fontface = 2,  # legend bold
                legend.title.size = 3, 
                legend.text.size = 3, 
                legend.bg.alpha = 0, 
                legend.width = 5) 
      data_map

      tmap_save(data_map, file.path(fig_out, "S2.20_sustNO2_2018.png"), width = 10, height = 6, dpi=300, units = "in")

### S2.21 
      envirodata <- fsci_data_timeseries %>% select(contains(c("country", "year", "emint_", "prod", "areaharvested", "yield"))) %>%
        select(-c(ends_with("range")))
      
      envirodata <- melt(envirodata, cbind("country", "year"), variable.name = "variable", 
                         value.name = "value", na.rm = TRUE)
      
      # Create dataframe with base year value as a column
      rel_to <- envirodata %>% 
        filter(year == 2000) %>%
        rename(value_2000 = value) %>%
        select(-year)
      
      # Merge base year value back into dataset
      envirodata <- envirodata %>%
        left_join(rel_to, by = cbind("country", "variable"))
      
      # Calculate annual change relative to year 2000 baseline value
      envirodata <- envirodata %>%
        mutate(relativechange = ((value - value_2000) / value_2000)) 
      envirodata <- apply_labels(envirodata, country = "Country", year = "Year", 
                                 variable = "Indicator", value = "Value", 
                                 value_2000 = "Baseline value (2000)",
                                 relativechange = "% Change relative to 2000")
      envirodata <- envirodata %>% select(-c(value, value_2000)) 
      freqtable <- envirodata %>% group_by(year, variable) %>% summarise(freq=n()) 
      # Aggregate emissions intensity for cerealsnorice and rice to match product groups in yield and production
      # Methodology note: Production weighted average used to aggregate emissions intensity variables for cereals with out rice and rice
      envirodata <- pivot_wider(envirodata, names_from = variable, 
                                values_from = relativechange)
      envirodata <- envirodata %>%
        mutate(emint_cereals = ((emint_cerealsnorice * prod_cerealsnorice) + 
                                  (emint_rice * prod_rice)) / (prod_cerealsnorice + prod_rice)) %>%
        # Note this mutate creates NaN for all division / 0, which occurs in year 2000
        # Replace year 2000 as zero and convert to numeric
        mutate(emint_cereals = str_replace(emint_cereals, "NaN", "0")) %>%
        mutate(emint_cereals = as.numeric(emint_cereals)) %>%
        mutate(emint_cereals = case_when(year == 2000 & is.na(emint_cereals) & !is.na(prod_cereals) ~ 0,
                                         TRUE ~ emint_cereals)) %>%
        # Remove columns no longer needed
        select(-c(emint_cerealsnorice, prod_cerealsnorice, emint_rice, prod_rice)) 
      
      # Create data frame of production-weighted global mean values for emissions intensity and yield
      envirodatalong <- as.data.frame(melt(envirodata, cbind("country", "year"), variable.name = "variable", 
                                           value.name = "value", na.rm = TRUE)) %>%
        separate(variable, into = c("indicator", "item"), sep = "_") 
      envirodatawide <- envirodatalong %>%
        group_by(country, year, item) %>%
        pivot_wider(names_from = indicator, values_from = value) %>%
        mutate(prod = ifelse(is.na(prod), 1, prod)) 
      class(envirodatawide$producinganimals)
      class(envirodatawide$areaharvested)
      class(envirodatawide$yield)
      
      emint_mean <- envirodatawide %>%
        filter(item != "all" & item != "vegetables") %>%
        group_by(year, item) %>%
        summarise(emint_mean = weighted.mean(emint, prod, na.rm = TRUE)) %>%
        # Note this mutate creates NaN for all division / 0, which occurs in year 2000
        # Replace year 2000 as zero and convert to numeric
        mutate(emint_mean = str_replace(emint_mean, "NaN", "")) %>%
        mutate(emint_mean = as.numeric(emint_mean)) %>%
        mutate(emint_mean = case_when(year == 2000 & is.na(emint_mean) ~ 0,
                                      TRUE ~ emint_mean)) %>%
        as.data.frame()
      
      yield_mean <- envirodatawide %>%
        filter(item != "all") %>%
        mutate(weight = case_when(
          !is.na(areaharvested) ~ areaharvested,
          TRUE ~ producinganimals)) %>% 
        select(-c(producinganimals, areaharvested)) %>%
        group_by(year, item) %>%
        summarise(yield_mean = weighted.mean(yield, weight, na.rm = TRUE)) %>%
        # Note this mutate creates NaN for all division / 0, which occurs in year 2000
        # Replace year 2000 as zero and convert to numeric
        mutate(yield_mean = str_replace(yield_mean, "NaN", "")) %>%
        mutate(yield_mean = as.numeric(yield_mean)) %>%
        mutate(yield_mean = case_when(year == 2000 & is.na(yield_mean) ~ 0,
                                      TRUE ~ yield_mean)) %>%
        as.data.frame()
      
      prod_mean <- envirodatawide %>%
        filter(item != "all") %>%
        group_by(year, item) %>%
        summarise(prod_mean = mean(prod, na.rm = TRUE)) %>%
        as.data.frame()
      enviro_fig <- prod_mean %>% left_join(yield_mean, by = cbind("year", "item")) %>% 
        left_join(emint_mean, by = cbind("year", "item"))  %>%
        as.data.frame()
      # Plot milk
      milk <- enviro_fig %>% filter(item == "cowmilk") %>%
        select(-c("item")) %>% as.data.frame()
      milk <- melt(milk, id = 'year', variable.name = "indicator", 
                   value.name = "relativechange", na.rm = TRUE)
      milk <- apply_labels(milk, year = "Year", 
                           indicator = "Indicator",
                           relativechange = "% Change relative to 2000")
      milk <- ggplot(milk, aes(x = year, y = relativechange, color = indicator), 
                     groups = indicator) +
        geom_line(linewidth = 1) + 
        ggtitle("Milk") +
        ylab("Relative change from 2000 (%)") + ylim(-1,1) +
        xlab("") +
        scale_color_manual(values=colorqual, 
                           labels = c("Production", 
                                      "Yield", "Emissions Intensity")) +
        guides(color = guide_legend(title="")) +
        theme_classic()
      milk
      
      ggsave(file.path(fig_out, "S2.21_MilkEfficiency.png"), width = 10, height = 6, dpi = 300, units = "in")
      
    
## Theme 3: Livelihoods, Poverty, and Equity ###################################
    
############ Income & Poverty ##################################################
    
############ Employment #################################################

##Share of agriculture in GDP (%GDP)
# Figure S3.1_aginGDP_2019.png
                             
      # Select variables
      agdata <- select(fsci_data, c("country", "year", "ISO", "aginGDP")) %>%
        filter(year == "2019") %>% rename(iso_a3 = ISO) %>%
        drop_na(aginGDP)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      agdata_simple<-merge(World,agdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      ag_map<-tm_shape(agdata_simple) + tm_polygons("aginGDP",
                                                    style="cont",
                                                    breaks=c(0,5,10,20,30,40,50,60,70),
                                                    palette= color7,
                                                    title="% Share of Agriculture in GDP",
                                                    legend.is.portrait=FALSE,
                                                    labels=c("0","5","10","20","30","40","50","60","70"),
                                                    colorNA = "grey85", 
                                                    textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
        ag_map

        tmap_save(ag_map, file.path(fig_out, "S3.1_aginGDP_2019.png"), width = 10, height = 6, dpi=300, units = "in")
                         
# Figure S3.2_aginGDP_region.png

      # Select variables
        agshareGDP <- select(fsci_data, c("country","aginGDP", "year", "fsci_regions", "GDP")) %>%
          drop_na() %>% mutate(as.factor(fsci_regions)) %>%
        mutate(fsci_regions = fct_reorder2(fsci_regions, year, aginGDP))
      
      # Regional mean
        agshareGDP <- agshareGDP %>% 
          group_by(year,fsci_regions) %>% 
          summarise(aginGDP_region_mean = weighted.mean(aginGDP, GDP, na.rm=TRUE))

      # Order for legend
        region_order_2019 <- agshareGDP %>% filter(year=="2020") %>% 
          arrange(aginGDP_region_mean,by_group=FALSE) %>% .$fsci_regions 

      ggplot(data=agshareGDP, aes(x = year, y = aginGDP_region_mean, color = fsci_regions), 
             groups = fsci_regions) +
        geom_line(size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "Share of agriculture in GDP (%)", color= "Region") + 
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              legend.text = element_text(size = 12), axis.text.x = element_text(size = 12), 
              axis.text.y = element_text(size = 12), legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions,
                             breaks=rev(region_order_2019))
      
      #Saving the plot displayed. 
      ggsave(file.path(fig_out, "S3.2_aginGDP_region.png"), width = 10, height = 6, dpi=300, units = "in")
                        
## Unemployment and Underemployment Rates, urban and rural
# Figure S3.3_employintersects_2020.png --- MICHAEL filling in

      # Select variables
      udata <- read_dta(file.path(data_in, "employment_disaggregated.dta")) %>%
        select(c("country", "year", "sex", "unemp", "agegroup", "geog", "underemp")) %>%
        mutate(sex = as.factor(sex),
               unemp = as.numeric(unemp),
               underemp = as.numeric(underemp),
               agegroup = as.numeric(agegroup),
               sex = as.numeric(sex),
               geog = as.numeric(geog)) 
       udata$agegroup <- recode_factor(udata$agegroup,
                      '0' = "Total population age 15+",
                      '1' = "Youth, age 15-24",
                      '2' = "Adults, age 25+")
       udata$sex <- recode_factor(udata$sex,
                                       '3' = "Total",
                                       '1' = "Female",
                                       '2' = "Male")
       udata$geog <- recode_factor(udata$geog,
                                  '0' = "Total",
                                  '1' = "Rural",
                                  '2' = "Urban",
                                  '3' = "Undefined")  
      udata <- udata %>% filter(geog != "Undefined")
      #set up variable for year 2020
      data <- filter(udata, year == "2020")
      data <- filter(udata, unemp!= "")
      

      #set up variables for sex
      totalpop <- filter(udata, agegroup == "Total population age 15+")
      totalpop <- filter(totalpop, geog == "Total")
      isMale <- filter(totalpop, sex == "Male")
      isFemale <- filter(totalpop, sex == "Female")

      #set up variables for age
      totalpop2 <- filter(udata, sex == "Total")
      totalpop2 <- filter(totalpop2, geog == "Total")
      isYouth <- filter(totalpop2, agegroup == "Youth, age 15-24")
      isAdult <- filter(totalpop2, agegroup == "Adults, age 25+")

      #set up variables for urban/rural
      totalpop3 <- filter(udata, sex == "Total")
      totalpop3 <- filter(totalpop3, agegroup == "Total population age 15+")
      isUrban <- filter(totalpop3, geog == "Urban")
      isRural <- filter(totalpop3, geog == "Rural")

      #now, melt data so we can have both unemp and underemp on the same boxplot
      dat.sex <- melt(udata,id.vars='sex', measure.vars=c('unemp','underemp'))
      dat.geog <- melt(udata,id.vars='geog', measure.vars=c('unemp','underemp'))
      dat.age <- melt(udata,id.vars='agegroup', measure.vars=c('unemp','underemp'))

      #reorder variables under dat.age
      dat.age$agegroup <- factor(dat.age$agegroup, levels = c('Youth, age 15-24', 'Adults, age 25+'))

      #paleteer colors for visuals
      paletteer_d("colorBlindness::SteppedSequential5Steps")  

      plotSex <- ggplot(dat.sex, aes(x=sex, y=value, fill=variable)) +
        geom_boxplot(trim=FALSE)+
        scale_fill_manual(labels = c("Unemployed", "Underemployed"), values = c("#990F0FFF", "#E57E7EFF")) +
        labs(title="Sex",x = "", y = "% Percentage")+
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle=45, vjust=1, hjust=1), legend.position="right", legend.title=element_blank()) +
        theme(legend.key=element_blank())

      plotGeog <- ggplot(dat.geog, aes(x=geog, y=value, fill=variable)) +
        geom_boxplot(trim=FALSE)+
        scale_fill_manual(labels = c("Unemployed", "Underemployed"), values = c("#990F0FFF", "#E57E7EFF")) +
        labs(title="Geography",x = "", y = "% Percentage")+
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle=45, vjust=1, hjust=1), legend.position="right", legend.title=element_blank()) +
        theme(legend.key=element_blank())

      plotAge <- ggplot(dat.age, aes(x=agegroup, y=value, fill=variable)) +
        geom_boxplot(trim=FALSE)+
        scale_fill_manual(labels = c("Unemployed", "Underemployed"), values = c("#990F0FFF", "#E57E7EFF")) +
        labs(title="Age Group",x = "", y = "% Percentage")+
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), axis.text.x = element_text(angle=45, vjust=1, hjust=1), legend.position="right", legend.title=element_blank()) +
        theme(legend.key=element_blank())

      plot <- ggarrange(plotSex, plotGeog, plotAge, common.legend = TRUE, legend="bottom")

      plot <- plot + theme(plot.title = element_text(size = 18, hjust = 0.5))

      ggsave(file.path(fig_out, "S3.3_employintersects_2020.png"), width = 10, height = 8, dpi=300, units = "in")

### Unemployment rate for each region 2010-2020 (facet by region)
##Figure S3.4_unemp_region_2010-20

        #Select the variables
        empdata <- fsci_data %>%
          select(c("country", "year", "unemp_tot", "fsci_regions")) %>%
          filter(year >= "2010") %>% drop_na(unemp_tot) %>%
          rename(unemp = unemp_tot)
        
        empdata$year <- as.factor(empdata$year)
        empdata <- empdata %>% mutate(fsci_regions = as.factor(fsci_regions))
        
        ggplot(empdata, aes(x=year, y=unemp, color = fsci_regions, fill = fsci_regions)) +
          geom_violin(trim = FALSE) +
          ylim(0,50) +
          scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
          facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
          ylab("% working age population") + xlab("") +
          theme_classic() + theme(strip.text = element_text(size = 10),
                                  strip.placement = "bottom",
                                  legend.position="none",
                                  strip.background  = element_rect(fill="lightgray"),
                                  panel.border = element_blank(),
                                  axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                  axis.text.y=element_text(size=10),
                                  axis.title=element_text(size=10))
       
        ggsave(file.path(fig_out, "S3.4_unemp_region_2010-20.png"), width = 10, height = 10, dpi= 300, units = "in")

##Figure S3.5_underemp_region_2010-20

        # Select the variables
        empdata <- fsci_data %>%
          select(c("country", "year", "underemp_tot", "fsci_regions")) %>%
          filter(year >= "2010") %>% drop_na(underemp_tot) %>% 
          rename(underemp = underemp_tot) %>%
          mutate(fsci_regions = as.factor(fsci_regions),
                 year = as.factor(year))

        ggplot(empdata, aes(x=year, y=underemp, color = fsci_regions, fill = fsci_regions)) +
          geom_violin(trim = FALSE) +
          ylim(0,50) +
          scale_color_manual(values = regions) + scale_fill_manual(values = regions) +
          facet_wrap(~ fsci_regions, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
          ylab("% working age population") + xlab("") +
          theme_classic() + theme(strip.text = element_text(size = 10),
                                  strip.placement = "bottom",
                                  legend.position="none",
                                  strip.background  = element_rect(fill="lightgray"),
                                  panel.border = element_blank(),
                                  axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                  axis.text.y=element_text(size=10),
                                  axis.title=element_text(size=10))
        
        ggsave(file.path(fig_out, "S3.5_underemp_region_2010-20.png"), width = 10, height = 10, dpi= 300, units = "in")

##Figure S3.6_unemp_income_2010-20.png ## Unemployment rate for each income group 2010-2020 (facet by income group)
        
        empdata <- fsci_data %>%
          select(c("country", "year", "unemp_tot", "incgrp")) %>%
          filter(year >= "2010") %>% drop_na(unemp_tot, incgrp) %>%
          rename(unemp = unemp_tot) %>%
          mutate(year = as.factor(year))

        ggplot(empdata, aes(x=year, y=unemp, color = incgrp, fill = incgrp)) +
          geom_violin(trim = FALSE) +
          ylim(0,50) +
          scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
          facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
          ylab("% working age population") + xlab("") +
          theme_classic() + theme(strip.text = element_text(size = 10),
                                  strip.placement = "bottom",
                                  legend.position="none",
                                  strip.background  = element_rect(fill="lightgray"),
                                  panel.border = element_blank(),
                                  axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                  axis.text.y=element_text(size=10),
                                  axis.title=element_text(size=10))
          
          ggsave(file.path(fig_out, "S3.6_unemp_income_2010-20.png"), width = 10, height = 10, dpi = 300, unit = "in")
                         
##Figure S3.7_underemp_income_2010-20.png ## Underemployment rate for each income group 2010-2020 (facet by income group)
      empdata <- fsci_data %>%
        select(c("country", "year", "underemp_tot", "incgrp")) %>%
        filter(year >= "2010") %>% 
        drop_na(underemp_tot, incgrp) %>% rename(underemp = underemp_tot) %>%
        mutate(year = as.factor(year))
      
      ggplot(empdata, aes(x=year, y=underemp, color = incgrp, fill = incgrp)) +
        geom_violin(trim = FALSE) +
        ylim(0,50) +
        scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
        facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("% working age population") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))
      
      ggsave(file.path(fig_out, "S3.7_underemp_income_2010-20.png"), width = 10, height = 10, dpi = 300, unit = "in")
                                                       
# Figure S3.8_employcombo_region.png
 
      # Select variables and order by region and year
      data <- select(fsci_data, c("country", "unemp_tot", "year", "fsci_regions", "totalpop")) %>% drop_na(totalpop) %>%  
      filter(!is.na(fsci_regions)) %>%
      arrange(fsci_regions, year) %>%
      filter(!is.na(unemp_tot))
      attributes(data$fsci_regions)
      range(data$year)

    # Create data frame of population-weighted mean by region and year
    unemp_region <- as.data.frame(data %>%
                                    group_by(fsci_regions, year) %>%
                                    summarise(unemp_mean = weighted.mean(unemp_tot, totalpop, 
                                                                         na.rm = TRUE), .groups = 'keep')) %>%
      filter(!is.na(unemp_mean))
    range(unemp_region$unemp_mean)

    # Select variables and order by region and year
    data <- select(fsci_data, c("country", "underemp_tot", "year", "fsci_regions", "totalpop")) %>%  drop_na(totalpop) %>%  
      filter(!is.na(fsci_regions)) %>%
      arrange(fsci_regions, year) %>%
      filter(!is.na(underemp_tot))
    attributes(data$fsci_regions)
    range(data$year)

    # Create data frame of population-weighted mean by region and year
    underemp_region <- as.data.frame(data %>%
                                       group_by(fsci_regions, year) %>%
                                       summarise(underemp_mean = weighted.mean(underemp_tot, 
                                                                               totalpop, na.rm = TRUE), 
                                                 .groups = 'keep')) %>%
      filter(!is.na(underemp_mean))
    range(underemp_region$underemp_mean)

    # Plot - Unemployment
    unemp <- ggplot(unemp_region, aes(x = year, y = unemp_mean, group = fsci_regions, 
                                      label = fsci_regions, color = fsci_regions)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + 
      expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "% Working age population") + 
      scale_y_continuous(name = "% Working age population", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "none", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = regions) + 
      ggtitle("Unemployment")

    # Plot - Underemployment
    underemp <- ggplot(underemp_region, aes(x = year, y = underemp_mean, group = fsci_regions, 
                                            label = fsci_regions, color = fsci_regions)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "") + 
      scale_y_continuous(name = "", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "none", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = regions) + 
      ggtitle("Underemployment")

    legend <- ggplot(underemp_region, aes(x = year, y = underemp_mean, group = fsci_regions, 
                                          label = fsci_regions, color = fsci_regions)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "") +
      scale_y_continuous(name = "", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "bottom", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = regions)  

    legend1 <- get_legend(legend)

    emp1 <- plot_grid(unemp, underemp, align = "hv", axis = "right",
                      ncol = 2, label_size = 14, hjust = -0.2)
    emp <- plot_grid(emp1, legend1, nrow = 2, rel_heights = c(1,0.1))
    emp
    
    ggsave(file.path(fig_out, "S3.8_employcombo_region.png"), width = 10, height = 6, dpi = 300, units = "in")

##Figure S3.9_employcombo_income.png            
    # Select variables and order by income and year
    data <- select(fsci_data, c("country", "unemp_tot", "year", "incgrp", "totalpop")) %>% 
      drop_na(totalpop, incgrp) %>%
      arrange(incgrp, year) %>%
      filter(!is.na(unemp_tot))
    attributes(data$incgrp)
    range(data$year)

    # Create data frame of population-weighted mean by region and year
    unemp_inc <- as.data.frame(data %>%
                                 group_by(incgrp, year) %>%
                                 summarise(unemp_mean = weighted.mean(unemp_tot, totalpop, 
                                                                      na.rm = TRUE), .groups = 'keep')) %>% 
    filter(!is.na(unemp_mean))
    range(unemp_inc$unemp_mean)

    # Select variables and order by income group and year
    data <- select(fsci_data, c("country", "underemp_tot", "year", "incgrp", "totalpop")) %>% drop_na(totalpop) %>%
      filter(!is.na(incgrp)) %>%
      arrange(incgrp, year) %>%
      filter(!is.na(underemp_tot))
    attributes(data$wb_region)
    range(data$year)

    # Create data frame of population-weighted mean by region and year
    underemp_inc <- as.data.frame(data %>%
                                    group_by(incgrp, year) %>%
                                    summarise(underemp_mean = weighted.mean(underemp_tot, totalpop, 
                                                                            na.rm = TRUE), .groups = 'keep')) %>% 
      filter(!is.na(underemp_mean))
      range(underemp_inc$underemp_mean)

    # Plot - Unemployment
    unemp <- ggplot(unemp_inc, aes(x = year, y = unemp_mean, group = incgrp, 
                                   label = incgrp, color = incgrp)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + 
      expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "% Working age population") + 
      scale_y_continuous(name = "% Working age population", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "none", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = incomescol) + 
      ggtitle("Unemployment")

    # Plot - Underemployment
    underemp <- ggplot(underemp_inc, aes(x = year, y = underemp_mean, group = incgrp, label = incgrp, color = incgrp)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "") + 
      scale_y_continuous(name = "", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "none", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = incomescol) + 
      ggtitle("Underemployment")

    legend <- ggplot(underemp_inc, aes(x = year, y = underemp_mean, group = incgrp, label = incgrp, color = incgrp)) +
      geom_line(size = 2, show.legend = NA) + theme_classic() + expand_limits(x = c(2000,2021)) +
      labs(x = "", y = "") + 
      scale_y_continuous(name = "", limits = c(0,15)) + 
      theme(plot.title = element_text(size = 14)) +
      theme(legend.position = "bottom", legend.title=element_blank(), legend.key=element_blank()) +
      scale_color_manual(values = incomescol)

    legend1 <- get_legend(legend)

    emp1 <- plot_grid(unemp, underemp, align = "hv", axis = "right",
                      ncol = 2, label_size = 14, hjust = -0.2)
    emp <- plot_grid(emp1, legend1, nrow = 2, rel_heights = c(1,0.1))
    emp
    
    ggsave(file.path(fig_out, "S3.9_employcombo_income.png"), width = 10, height = 6, dpi = 300, units = "in")
      
## Social protection coverage
## Social protection adequacy
# Figure S3.10_socprotec.png 

      #Set variables
      socialdata <- select(fsci_data, c("spcoverage", "spadequacy", "fsci_regions", "country", "year")) %>%
        filter(!is.na(spcoverage | spadequacy))

      #ensure data is not blank
      socialdata <- filter(socialdata, spcoverage!= "")

      #convert spcoverage and spadequacy to numeric data and country to factor data
      socialdata$spcoverage <- as.numeric(as.character(socialdata$spcoverage))
      socialdata$spadequacy <- as.numeric(as.character(socialdata$spadequacy))
      socialdata$country <- as.factor(socialdata$country)

      #set up variables for each world region 
      NAEU <- filter(socialdata, fsci_regions == "Northern America and Europe") 
      LAC <- filter(socialdata, fsci_regions=="Latin America & Caribbean")
      EA <- filter(socialdata, fsci_regions=="Eastern Asia") 
      SSA <- filter(socialdata, fsci_regions=="Sub-Saharan Africa")
      CA <- filter(socialdata, fsci_regions=="Central Asia")
      SEA <- filter(socialdata, fsci_regions=="South-eastern Asia")
      SA <- filter(socialdata, fsci_regions=="Southern Asia")
      MENA <- filter(socialdata, fsci_regions=="Northern Africa & Western Asia")
      OA <- filter(socialdata, fsci_regions=="Oceania")

      #now, melt data for each region so we can have both spcoverage and spadequacy on the same graph
      dat.total <- melt(socialdata, id.vars= c('country', 'fsci_regions'), measure.vars=c('spcoverage','spadequacy'))
      dat.total$value <- as.numeric(dat.total$value)
      dat.total$value <- ifelse(dat.total$variable == "spcoverage", dat.total$value*-1, dat.total$value)

      #make graph 1
      dat.eurasia <- dat.total %>%
        filter(fsci_regions!="" & (fsci_regions=="Eastern Asia" | fsci_regions=="Northern America and Europe" | 
                                     fsci_regions=="Latin America & Caribbean" |
                                     fsci_regions=="Northern Africa & Western Asia")) %>% 
        #creating variable for landholding by male only
        mutate(dat.coverage=ifelse(variable=="spcoverage", value, NA)) %>%
        #making country a factor with order by landholding_male
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.coverage, na.rm=TRUE))
      dat.eurasia$country1 <- fct_reorder(dat.eurasia$country1, dat.eurasia$dat.coverage, na.rm=TRUE)

      graph1 <- ggplot(dat.eurasia, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.eurasia, variable == "spadequacy"), stat = "identity") + 
        geom_bar(data = subset(dat.eurasia, variable == "spcoverage"), stat = "identity") + 
        #scale_y_continuous(labels = abs) +
        labs(x = "", y = "", fill = "") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        theme(strip.clip = "off") +
        labs(title="Coverage | Adequacy", x="") +
        facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 10, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-101,101), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.5)) + ylab("%")

      #make graph 2
      dat.restofworld <-  dat.total %>%
        filter(fsci_regions!="" & (fsci_regions=="Southern Asia" |
                                     fsci_regions=="Sub-Saharan Africa" |
                                     fsci_regions=="South-eastern Asia" | fsci_regions=="Oceania")) %>% 
        mutate(dat.restofworld.coverage=ifelse(variable=="spcoverage", value, NA)) %>%
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.restofworld.coverage, na.rm=TRUE))
      dat.restofworld$country1 <- fct_reorder(dat.restofworld$country1, 
                                              dat.restofworld$dat.restofworld.coverage, na.rm=TRUE)

      graph2 <-  ggplot(dat.restofworld, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.restofworld, variable == "spadequacy"), stat = "identity") + 
        geom_bar(data = subset(dat.restofworld, variable == "spcoverage"), stat = "identity") + 
        #scale_y_continuous(labels = abs) +
        labs(x = "", y = "", fill = "") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        theme(strip.clip = "off") +
        labs(title="Coverage | Adequacy", x="") +
        facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 10, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-101,101), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.5)) + ylab("%")

      plot<- plot_grid(graph1, graph2, ncol=2, rel_widths=c(1,1,.4)) 
         
      ggsave(file.path(fig_out, "S3.10_socprotec.png"), width = 10, height = 8, dpi=300, units = "in", device='png')

# Figure S3.11_childlabor_region.png 
      
      # Select variables
      childlabor_data <- fsci_data %>% select(c("country", "incgrp", "fsci_regions", "year",
                                                "childlabor", "childlabor_m", "childlabor_f", 
                                                "totalpop")) %>%
        filter(!is.na(childlabor_m | childlabor_f)) %>%
        mutate(fsci_regions = as.factor(fsci_regions))
      range(childlabor_data$year) ## Note data come from different years
      childlabor_data <- childlabor_data %>% select(-c("year"))
      
      #ensure data is not blank
      childlabordata <- filter(childlabor_data, childlabor_f!= "")

      #convert childlabor_f and childlabor_m to numeric data and country to factor data
      childlabordata$childlabor_f <- as.numeric(as.character(childlabordata$childlabor_f))
      childlabordata$childlabor_m <- as.numeric(as.character(childlabordata$childlabor_m))
      childlabordata$country <- as.factor(childlabordata$country)

      #set up variables for each world region 
      NAEU <- filter(socialdata, fsci_regions == "Northern America and Europe") 
      LAC <- filter(socialdata, fsci_regions=="Latin America & Caribbean")
      EA <- filter(socialdata, fsci_regions=="Eastern Asia")
      SSA <- filter(socialdata, fsci_regions=="Sub-Saharan Africa")
      CA <- filter(socialdata, fsci_regions=="Central Asia")
      SEA <- filter(socialdata, fsci_regions=="South-eastern Asia")
      SA <- filter(socialdata, fsci_regions=="Southern Asia")
      MENA <- filter(socialdata, fsci_regions=="Northern Africa & Western Asia")
      OA <- filter(socialdata, fsci_regions=="Oceania")

      #now, melt data for each region so we can have both childlabor_f and childlabor_m on the same graph
      dat.total <- melt(childlabordata, id.vars= c('country', 'fsci_regions'), measure.vars=c('childlabor_f','childlabor_m'))
      dat.total$value <- as.numeric(dat.total$value)
      dat.total$value <- ifelse(dat.total$variable == "childlabor_f", dat.total$value*-1, dat.total$value)

      #make graph 1
      dat.eurasia <- dat.total %>%
        filter(fsci_regions!="" & (fsci_regions=="Sub-Saharan Africa" |
                                     fsci_regions=="Latin America & Caribbean")) %>% 
        #creating variable for female child labor only
        mutate(dat.coverage=ifelse(variable=="childlabor_f", value, NA)) %>%
        #making country a factor with order by female child labor
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.coverage, na.rm=TRUE))
      dat.eurasia$country1 <- fct_reorder(dat.eurasia$country1, dat.eurasia$dat.coverage, na.rm=TRUE)

      graph1 <- ggplot(dat.eurasia, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.eurasia, variable == "childlabor_m"), stat = "identity") + 
        geom_bar(data = subset(dat.eurasia, variable == "childlabor_f"), stat = "identity") + 
        labs(x = "East Asia & Pacific", y = "", fill = "Variable") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        labs(title="Female | Male", x="") +
        facet_grid(fsci_regions~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-41,41), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              #axis.text.x = element_text(angle=45, vjust=1, hjust=1),
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.4)) + ylab("%")
      graph1
      #make graph 2
      dat.restofworld <-  dat.total %>%
        filter(fsci_regions!="" & (fsci_regions=="Eastern Asia" | fsci_regions=="Southern Asia" |
                                     fsci_regions=="South-eastern Asia" | fsci_regions=="Oceania" |
                                     fsci_regions=="Northern Africa & Western Asia" | 
                                     fsci_regions=="Northern America and Europe")) %>% 
        mutate(dat.restofworld.coverage=ifelse(variable=="childlabor_f", value, NA)) %>%
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.restofworld.coverage, na.rm=TRUE))
      dat.restofworld$country1 <- fct_reorder(dat.restofworld$country1, dat.restofworld$dat.restofworld.coverage, na.rm=TRUE)

      graph2 <-  ggplot(dat.restofworld, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.restofworld, variable == "childlabor_m"), stat = "identity") + 
        geom_bar(data = subset(dat.restofworld, variable == "childlabor_f"), stat = "identity") + 
        scale_y_continuous(labels = abs) +
        labs(x = "East Asia & Pacific", y = "", fill = "Variable") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        labs(title="Female | Male", x="") +
        facet_grid(fsci_regions~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width =12, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-41,41), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.375)) + ylab("%")
      graph2
     plot_grid(graph1, graph2, ncol=2, rel_widths=c(1,1,.4)) 

      ggsave(file.path(fig_out, "S3.11_childlabor_region.png"), width = 10, height = 8, dpi=300, units = "in")
                         
##Child labor: % of children 5-17 engaged in child labor
# Figure S3.12_childlabor_income.png 
          
      # Select variables
          childlabor_data <- fsci_data %>% select(c("country", "incgrp", 
                                                    "year", "childlabor", "childlabor_m",
                                                    "childlabor_f", "totalpop")) %>%
            filter(!is.na(childlabor_m | childlabor_f)) 
          range(childlabor_data$year) ## Note data come from different years
          childlabor_data <- childlabor_data %>% select(-c("year"))
    
      #convert childlabor_f and childlabor_m to numeric data and country to factor data
      childlabordata$childlabor_f <- as.numeric(as.character(childlabordata$childlabor_f))
      childlabordata$childlabor_m <- as.numeric(as.character(childlabordata$childlabor_m))
      childlabordata$country <- as.factor(childlabordata$country)

      #set up variables for each income group 
      LI <- filter(childlabordata, incgrp == "Low income") 
      LMI <- filter(childlabordata, incgrp=="Lower middle income")
      UMI <- filter(childlabordata, incgrp=="Upper middle income")
      HI <- filter(childlabordata, incgrp=="High income")

      #now, melt data for each region so we can have both childlabor_f and childlabor_m on the same graph
      dat.total <- melt(childlabordata, id.vars= c('country', 'incgrp'), measure.vars=c('childlabor_f','childlabor_m'))
      dat.total$value <- as.numeric(dat.total$value)
      dat.total$value <- ifelse(dat.total$variable == "childlabor_f", dat.total$value*-1, dat.total$value)

      #make graph 1
      dat.lower <- dat.total %>%
        filter(incgrp!="" & (incgrp=="Low income" | incgrp=="Lower middle income")) %>% 
        #creating variable for female child labor only
        mutate(dat.coverage=ifelse(variable=="childlabor_f", value, NA)) %>%
        #making country a factor with order by female child labor
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.coverage, na.rm=TRUE))
      dat.lower$country1 <- fct_reorder(dat.lower$country1, dat.lower$dat.coverage, na.rm=TRUE)

      graph1 <- ggplot(dat.lower, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.lower, variable == "childlabor_m"), stat = "identity") + 
        geom_bar(data = subset(dat.lower, variable == "childlabor_f"), stat = "identity") + 
        labs(x = "", y = "", fill = "Variable") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        labs(title="Female | Male", x="") +
        facet_grid(incgrp~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-101,102), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.41)) + ylab("")
      graph1
      #make graph 2
      dat.upper <-  dat.total %>%
        filter(incgrp!="" & (incgrp=="Upper middle income" | incgrp=="High income")) %>% 
        mutate(dat.upper.coverage=ifelse(variable=="childlabor_f", value, NA)) %>%
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, dat.upper.coverage, na.rm=TRUE))
      dat.upper$country1 <- fct_reorder(dat.upper$country1, dat.upper$dat.upper.coverage, na.rm=TRUE)

      graph2 <-  ggplot(dat.upper, aes(x = country1, y = value, fill = variable)) +
        geom_bar(data = subset(dat.upper, variable == "childlabor_m"), stat = "identity") + 
        geom_bar(data = subset(dat.upper, variable == "childlabor_f"), stat = "identity") + 
        scale_y_continuous(labels = abs) +
        labs(x = "East Asia & Pacific", y = "", fill = "Variable") +
        coord_flip() + scale_fill_manual(values=cbpalette_2) +
        labs(title="Female | Male", x="") +
        facet_grid(incgrp~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + scale_y_continuous(limits = c(-101,102), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              strip.text.y = element_text(size = 7),
              legend.position="none", plot.title = element_text(hjust = 0.44)) + ylab("")

      plot_grid(graph1, graph2, ncol=2, rel_widths=c(1,1,.4)) +
            plot_annotation(title = "")

      ggsave(file.path(fig_out, "S3.12_childlabor_income.png"), width = 10, height = 6, dpi=300, units = "in")

## Distribution of landholdings by sex
# Figure S3.13_landholdings_sex.png 

      # Use indicator-specific dataset with disaggregated landholdings
      landdata <- read_dta(file.path(data_in, "landholdings_bysex.dta"))
      landdata$landholding <- as.numeric(landdata$landholding)
      landdata <- filter(landdata, UNmemberstate == 1) %>%
        select(c("country", "landholding", "sex", "fsci_regions"))
      landdata <- filter(landdata, landholding!= "")
      
      #remove Uruguay from landdataset because landdata is incomplete
      landdata <- landdata[landdata$country != "Uruguay", ]
      
      # Label sex
      landdata$sex <- factor(landdata$sex, levels = c(1,2),
                             labels = c("Female", "Male")) %>%
        as.character(landdata$sex)
      # remove Uruguay from landdataset because landdata is incomplete
      landdata <- landdata[landdata$country != "Uruguay", ]
      
      #rename long country names
      landdata$country <- case_when(
        landdata$country == "United Kingdom of Great Britain and Northern Ireland" ~ "United Kingdom",
        landdata$country == "Bolivia (Plurinational State of)" ~ "Bolivia",
        landdata$country == "Lao People's Democratic Republic" ~ "Lao PDR",
        landdata$country == "Venezuela, Bolivarian Republic of" ~ "Venezuela",
        landdata$country == "United States of America" ~ "USA",
        landdata$country == "Democratic Republic of the Congo" ~ "Dem. Rep. of Congo",
        landdata$country == "Gambia (Republic of The)" ~ "The Gambia",
        landdata$country == "United Republic of Tanzania" ~ "Tanzania",
        TRUE ~ landdata$country)
      
      #set up variables for each world region 
      NAEU <- filter(landdata, fsci_regions == "Northern America and Europe") 
      LAC <- filter(landdata, fsci_regions=="Latin America & Caribbean")
      EA <- filter(landdata, fsci_regions=="Eastern Asia")
      SSA <- filter(landdata, fsci_regions=="Sub-Saharan Africa")
      CA <- filter(landdata, fsci_regions=="Central Asia")
      SEA <- filter(landdata, fsci_regions=="South-eastern Asia")
      SA <- filter(landdata, fsci_regions=="Southern Asia")
      MENA <- filter(landdata, fsci_regions=="Northern Africa & Western Asia")
      OA <- filter(landdata, fsci_regions=="Oceania")
      
      #set up color palettes
          regions_a <-c("#DDCC77FF", "#88CCEEFF", "#999933FF")
          regions_b <-c("#CC6677FF", "#332288FF", "#117733FF", "#882255FF", "#44AA99FF", "#AA4499FF")
    graph1 <-landdata %>%
      filter(fsci_regions!="" & (fsci_regions=="Northern America and Europe" | fsci_regions=="Latin America & Caribbean" | fsci_regions=="Southern Asia")) %>% 
      #creating variable for landholding by male only
      mutate(landholding_male=ifelse(sex=="Male", landholding, NA)) %>%
      #making country a factor with order by landholding_male
      mutate(country1 = as.factor(country),
             country1=fct_reorder(country1, landholding_male, na.rm=TRUE))  %>% 
      ggplot(aes(x=country1, y=landholding)) +
      geom_bar(stat = "identity", aes(fill=fsci_regions, alpha=sex), position = "stack") +
      scale_alpha_manual(name="Sex", values = c(0.6, 1)) +
      coord_flip() + scale_fill_manual(values=regions) +
      labs(title="", x="") +
      facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", 
                 labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
      theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
      theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
            strip.placement = "outside",
            # remove background colour from facet labels
            strip.background  = element_blank(),
            # remove border from facet label
            panel.border = element_blank(),
            # make continent names horizontal
            strip.text.y = element_blank(),
            legend.position="none",
            text = element_text(size = 20)) + ylab("Landholdings (%)")
    graph1
    
    graph2<-landdata %>%
      filter(fsci_regions!="" & (fsci_regions=="Central Asia" | fsci_regions=="Eastern Asia" |
                                   fsci_regions=="South-eastern Asia" | fsci_regions=="Oceania" |
                                   fsci_regions=="Northern Africa & Western Asia" | fsci_regions=="Sub-Saharan Africa")) %>% 
      #creating variable for landholding by male only
      mutate(landholding_male=ifelse(sex=="Male", landholding, NA)) %>%
      #making country a factor with order by landholding_male
      mutate(country1 = as.factor(country),
             country1=fct_reorder(country1, landholding_male, na.rm=TRUE)) %>% 
      ggplot(aes(x=country1, y=landholding)) +
      geom_bar(stat = "identity", aes(fill=fsci_regions, alpha=sex), position = "stack") +
      scale_alpha_manual(name="Sex", values = c(0.6, 1)) +
      coord_flip() + scale_fill_manual(values=regions_b) +
      labs(title="", x="") +
      facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                 labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
      theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
      theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
            strip.placement = "outside",
            # remove background colour from facet labels
            strip.background  = element_blank(),
            # remove border from facet label
            panel.border = element_blank(),
            # make continent names horizontal
            strip.text.y = element_blank(),
            legend.position="none",
            text = element_text(size = 20)) + ylab("Landholdings (%)")

  legend1<-landdata %>%
      #creating variable for landholding by male only
      mutate(landholding_male=ifelse(sex=="Male", landholding, NA)) %>%
      #making country a factor with order by landholding_male
      mutate(country1 = as.factor(country),
             country1=fct_reorder(country1, landholding_male, na.rm=TRUE)) %>% 
      ggplot(aes(x=country1, y=landholding)) +
      geom_bar(stat = "identity", aes(fill=fsci_regions, alpha=sex), position = "stack") +
      scale_alpha_manual(name="Sex", values = c(0.6, 1)) +
      coord_flip() + scale_fill_manual(values=regions) +
      labs(title="", x="") +
      facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                 labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
      theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
      theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
            strip.placement = "outside",
            # remove background colour from facet labels
            strip.background  = element_blank(),
            # remove border from facet label
            panel.border = element_blank(),
            # make continent names horizontal
            strip.text.y = element_blank(),
            legend.position="bottom", legend.box = "vertical",
            text = element_text(size = 32)) + 
      ylab("Landholdings (%)") +
      guides(fill = guide_legend(nrow = 3, title = "Regions"), alpha = guide_legend(title = "Sex"))
    legend <- get_legend(legend1)
    
    landholdings1 <- plot_grid(graph1, graph2, ncol=2, rel_widths=c(1,1))
    landholdings <- plot_grid(landholdings1, legend, nrow = 2, rel_heights = c(1,.1))
    landholdings
          
    ggsave(file.path(fig_out, "S3.13_landholdings_sex.png"), width = 20, height = 24, dpi=300, units = "in", device='png')                      
                         
## Theme 4: Governance #########################################################

## Civil Society Index (Varieties of democracy)
                         
# Figure S4.1_cspi_2021.png ## Civil Society Index by Country, 2021

      #Set variables
      demdata <- select(fsci_data, c("ISO", "cspart")) %>% rename(iso_a3 = ISO)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      demdata_simple<-merge(World,demdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      dem_map<-tm_shape(demdata_simple) + tm_polygons("cspart",
                                                      style="cont",
                                                      breaks=c(0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1),
                                                      palette= color10,
                                                      title="Civil Society Index by country",
                                                      legend.is.portrait=FALSE,
                                                      labels = c("0",".1",".2",".3",".4",".5",".6",".7",".8",".9","1"),
                                                      colorNA = "grey85", 
                                                      textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      dem_map

      #png
      tmap_save(dem_map, file.path(fig_out, "S4.1_cspi_2021.png"), width = 10, height = 6, dpi=300, units = "in")
                         
# Figure S4.2_cspi_region.png

        # Select variables
          cspi_data <- select(fsci_data, c("country", "cspart", "year", "fsci_regions", "incgrp", "totalpop")) %>%
            drop_na() %>% mutate(fsci_regions = fct_reorder2(fsci_regions, year, cspart))


          # Regional mean weighted by population 
          cspi_data <- cspi_data %>% group_by(year,fsci_regions) %>% 
            summarise(cspi_region_mean = weighted.mean(cspart, totalpop, na.rm=TRUE))

        # Order legend
          region_order_2021 <- cspi_data %>% filter(year=="2021") %>% 
            arrange(cspi_region_mean, by_group=FALSE) %>% .$fsci_regions 
          
        # Plot
          ggplot(data=cspi_data, aes(x = year, y = cspi_region_mean, color = fsci_regions), groups=fsci_regions) +
            geom_line(size = 2,show.legend = NA) + theme_classic() +
            labs(x = "Year", y = "Civil Society Participation Index", color= "Region") + 
            scale_x_continuous(breaks=seq(2000, 2021, 5))+
            theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
                  axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 11),
                  legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
            scale_color_manual(values=regions, breaks=rev(region_order_2021))
          
          ggsave(file.path(fig_out, "S4.2_cspi_region.png"), width = 10, height = 6, dpi=300, units = "in")

#Figure S4.3_cspi_income.png ## Line graphs over time  
          
          cspi_data <- select(fsci_data, c("country", "cspart", "year", "fsci_regions", "incgrp", "totalpop")) %>%
            drop_na() %>% mutate(incgrp = fct_reorder2(incgrp, year, cspart))
          
          
          # Regional mean weighted by population 
          cspi_data <- cspi_data %>% group_by(year, incgrp) %>% 
            summarise(cspi_income_mean = weighted.mean(cspart, totalpop, na.rm=TRUE))
          
          # Order legend
          incgrp_order_2021 <- cspi_data %>% filter(year=="2021") %>% 
            arrange(cspi_income_mean, by_group=FALSE) %>% .$incgrp 
          
          ggplot(data=cspi_data, aes(x = year, y = cspi_income_mean, color = incgrp), groups=incgrp) +
            geom_line(size = 2,show.legend = NA) + theme_classic() +
            labs(x = "Year", y = "Civil Society Participation Index", color= "Income Group") + 
            scale_x_continuous(breaks=seq(2000, 2021, 5))+
            theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
                  axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 11),
                  legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
            scale_color_manual(values = incomescol,
                               breaks=rev(incgrp_order_2021))
          
          ggsave(file.path(fig_out, "S4.3_cspi_income.png"), width = 10, height = 6, dpi=300, units = "in")

## % Urban Population Living in Cities Signed Onto the Milan Urban Food Policy Pact, 2020 (Map)
# Figure S4.4_mufppurb_2020.png

      #Set variables
      Milandata <- select(fsci_data, c("ISO", "mufppurbshare", "year")) %>%
        rename(iso_a3 = ISO) %>%
        filter(year == 2020) %>% select(-c(year))

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      Milandata_simple<-merge(World,Milandata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      Milan_map <-tm_shape(Milandata_simple) + tm_polygons("mufppurbshare",
                                                           style="cont",
                                                           palette= color10,
                                                           breaks = c(0,10,20,30,40,50,60,70, 80),
                                                           labels = c("0", "10", "20", "30", "40", "50", "60","70", ">70"),
                                                           title="% Urban population in cities signed on the MUFPP",
                                                           legend.is.portrait=FALSE,
                                                           colorNA = "grey85", 
                                                           textNA = "No Cities Participate") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      Milan_map

      tmap_save(Milan_map, file.path(fig_out, "S4.4_mufppurb_2020.png"), width = 10, height = 6, dpi=300, units = "in")

## % Urban Population Living in Cities Signed Onto the Milan Urban Food Policy Pact, 2020 (Bar Graphs)
# Figure S4.5_mufppurb_cntry.png

      #Set variables
      milandata <- select(fsci_data, c("ISO", "mufppurbshare", "country", "fsci_regions")) %>%
        rename(iso_a3 = ISO) 
      #ensure milandata is not blank
      milandata <- filter(milandata, mufppurbshare!= "0")
      
      #convert to numeric
      milandata$mufppurbshare <- as.numeric(milandata$mufppurbshare)
      
      #rename long country names
      milandata$country <- case_when(
        milandata$country == "United Kingdom of Great Britain and Northern Ireland" ~ "United Kingdom",
        milandata$country == "Bolivia (Plurinational State of)" ~ "Bolivia",
        milandata$country == "Lao People's Democratic Republic" ~ "Lao PDR",
        milandata$country == "Venezuela, Bolivarian Republic of" ~ "Venezuela",
        milandata$country == "United States of America" ~ "USA",
        milandata$country == "Democratic Republic of the Congo" ~ "Dem. Rep. of Congo",
        milandata$country == "Gambia (Republic of The)" ~ "The Gambia",
        milandata$country == "United Republic of Tanzania" ~ "Tanzania",
        TRUE ~ milandata$country)
      
      #set up variables for each world region 
      NAEU <- filter(milandata, fsci_regions == "Northern America and Europe") 
      LAC <- filter(milandata, fsci_regions=="Latin America & Caribbean")
      EA <- filter(milandata, fsci_regions=="Eastern Asia")
      SSA <- filter(milandata, fsci_regions=="Sub-Saharan Africa")
      CA <- filter(milandata, fsci_regions=="Central Asia")
      SEA <- filter(milandata, fsci_regions=="South-eastern Asia")
      SA <- filter(milandata, fsci_regions=="Southern Asia")
      MENA <- filter(milandata, fsci_regions=="Northern Africa & Western Asia")
      OA <- filter(milandata, fsci_regions=="Oceania")
      
      #set up color palettes
      regions_a <-c("#332288FF", "#88CCEEFF", "#882255FF", "#44AA99FF")
      regions_b <-c("#CC6677FF", "#DDCC77FF", "#117733FF", "#999933FF", "#AA4499FF")
      
      graph1 <-milandata %>%
        filter(fsci_regions!="" & (fsci_regions=="Northern America and Europe" | fsci_regions=="Oceania" | 
                                     fsci_regions=="Eastern Asia" | fsci_regions=="South-eastern Asia" )) %>% 
        #making country a factor with order by urban share
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, mufppurbshare, na.rm=TRUE)) %>% 
        ggplot(aes(x=country1, y=mufppurbshare)) +
        geom_bar(stat = "identity", aes(fill=fsci_regions), position = "stack") +
        scale_alpha_manual(name="", values = c(0.6, 1)) +
        coord_flip() + scale_fill_manual(values=regions_a) +
        labs(title="", x="") +
        facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              strip.placement = "outside",
              # remove background colour from facet labels
              strip.background  = element_blank(),
              # remove border from facet label
              panel.border = element_blank(),
              # make continent names horizontal
              strip.text.y = element_blank(),
              legend.position="none",
              text = element_text(size = 20)) + ylab("% Urban Population")
      graph1
      
      graph2<-milandata %>%
        filter(fsci_regions!="" & (fsci_regions=="Southern Asia" | fsci_regions=="Sub-saharan Africa" |
                                     fsci_regions=="Latin America & Caribbean" | fsci_regions=="Central Asia" |
                                     fsci_regions=="Northern Africa & Western Asia" )) %>%
        #making country a factor with order by urban share
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, mufppurbshare, na.rm=TRUE)) %>% 
        ggplot(aes(x=country1, y=mufppurbshare)) +
        geom_bar(stat = "identity", aes(fill=fsci_regions), position = "stack") +
        scale_alpha_manual(name="", values = c(0.6, 1)) +
        coord_flip() + scale_fill_manual(values=regions_b) +
        labs(title="", x="") +
        facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              #axis.text.x = element_text(angle=45, vjust=1, hjust=1),
              strip.placement = "outside",
              # remove background colour from facet labels
              strip.background  = element_blank(),
              # remove border from facet label
              panel.border = element_blank(),
              strip.text.y = element_blank(),
              legend.position="none",
              text = element_text(size = 20)) + ylab("% Urban Population")
      graph2
      legend1<-milandata %>%
        #making country a factor with order by urban share
        mutate(country1 = as.factor(country),
               country1=fct_reorder(country1, mufppurbshare, na.rm=TRUE)) %>% 
        ggplot(aes(x=country1, y=mufppurbshare)) +
        geom_bar(stat = "identity", aes(fill=fsci_regions), position = "stack") +
        scale_alpha_manual(name="", values = c(0.6, 1)) +
        coord_flip() + scale_fill_manual(values=regions) +
        labs(title="", x="") +
        facet_grid(fsci_regions ~., scales = "free_y", space = "free_y", switch = "x", 
                   labeller = label_wrap_gen(width = 20, multi_line = TRUE)) +
        theme_classic() + #scale_y_continuous(limits = c(-1,101), expand = c(0, 0)) + 
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), 
              #axis.text.x = element_text(angle=45, vjust=1, hjust=1),
              strip.placement = "outside",
              # remove background colour from facet labels
              strip.background  = element_blank(),
              # remove border from facet label
              panel.border = element_blank(),
              # make continent names horizontal
              strip.text.y = element_blank(),
              legend.position="bottom",
              text = element_text(size = 28)) + ylab("% Urban Population") +
        guides(fill = guide_legend(title = "Regions", nrow = 3))
      legend <- get_legend(legend1)

      urban1 <-plot_grid(graph1, graph2, ncol=2, rel_widths=c(1,1))
      urban <-plot_grid(urban1, legend, nrow = 2, rel_heights = c(1,0.2))
      urban
      ggsave(file.path(fig_out, "S4.5_mufppurb_cntry.png"), width = 14, height = 17, dpi=300, units = "in", device='png')

## Degree of legal recognition of the Right to Food                         
# Figure S4.6_rtf.png
                         
    #Set variables
      rtfdata <- select(fsci_data, c("ISO", "righttofood")) %>%
        rename(iso_a3 = ISO) %>% drop_na(righttofood)

    #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

    #merging data
      rtfdata_simple<-merge(World,rtfdata, by='iso_a3',  duplicateGeoms = TRUE)

    #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

    # Map
      rtf_map <-tm_shape(rtfdata_simple) + tm_polygons("righttofood",
                                                                 style="fixed",
                                                                 breaks=c(1, 2, 3, 4),
                                                                 palette= color3,
                                                                 title="Degree of Legal Recognition of the Right to Food",
                                                                 legend.is.portrait=TRUE,
                                                                 labels = c("Explicit protection or directive principle of state policy", "Other implicit or national codification of international obligations or relevant provisions", "None"),
                                                                 colorNA = "grey85", 
                                                                 textNA = "Data Unavailable")   + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 5, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      rtf_map

      tmap_save(rtf_map, file.path(fig_out, "S4.6_rtf.png"), width = 10, height = 6, dpi=300, units = "in")
  
## Presence of a National Food System Transformation Pathway, 2022                         
# Figure S4.7_fspathway.png

     #Set variables
      pathwaydata <- select(fsci_data, c("ISO", "fspathway")) %>%
        rename(iso_a3 = ISO) %>% drop_na(fspathway)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      pathwaydata_simple<-merge(World,pathwaydata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      pathway_map<-tm_shape(pathwaydata_simple) + tm_polygons("fspathway",
                                                              style="fixed",
                                                              breaks=c(0, 1, 2),
                                                              palette= cbpalette_2,
                                                              title="Presence of a national food system transformation pathway",
                                                              legend.is.portrait=TRUE,
                                                              labels = c("Not Present", "Present"),
                                                              colorNA = "grey85", 
                                                              textNA = "Data Unavailable")  + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      pathway_map

      tmap_save(pathway_map, file.path(fig_out, "S4.7_fspathway.png"), width = 10, height = 6, dpi=300, units = "in")
             
## Government Effectiveness Index 
# Figure S4.8_govteff_region.png
      
      # Select variables
      goveffect_data <- select(fsci_data, c("country", "govteffect", "year", "fsci_regions", "incgrp", "totalpop")) %>%
        drop_na(govteffect) %>%  mutate(fsci_regions = fct_reorder2(fsci_regions, year, govteffect)) %>%
        drop_na(fsci_regions) %>% drop_na(totalpop)
      
    # Population-weighted regional average
      goveffect_data <- goveffect_data %>% group_by(fsci_regions, year) %>% 
        summarise(goveffect_region_mean = weighted.mean(govteffect, totalpop))

    # Order legend
      region_order_2020 <- goveffect_data %>% filter(year=="2020") %>% 
        arrange(goveffect_region_mean,by_group=FALSE) %>% .$fsci_regions 

    #Plot
        ggplot(data=goveffect_data, aes(x = year, y = goveffect_region_mean, color = fsci_regions), groups=fsci_regions) +
        geom_line(size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "Government Effectiveness Index", color= "Region") + 
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14), 
              axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 11),
              legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions)
      
      ggsave(file.path(fig_out, "S4.8_govteff_region.png"), width = 10, height = 6, dpi=300, units = "in")
      
# Figure S4.9_govteff_income.png
      
     # Select variables
      goveffect_data <- select(fsci_data, c("country", "govteffect", "year", "wb_region", "incgrp", "totalpop")) %>%
        drop_na(govteffect) %>%  mutate(incgrp = fct_reorder2(incgrp, year, govteffect)) %>%
        drop_na(incgrp) %>% drop_na(totalpop)

      # Population-weighted regional average
      goveffect_data <- goveffect_data %>% group_by(incgrp, year) %>% 
        summarise(goveffect_income_mean = weighted.mean(govteffect, totalpop))

      # Order legend
      income_order_2020 <- goveffect_data %>% filter(year=="2020") %>% 
        arrange(goveffect_income_mean, by_group=FALSE) %>% .$incgrp 

      ggplot(data=goveffect_data, aes(x = year, y = goveffect_income_mean, color = incgrp), groups=incgrp) +
        geom_line( size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "Government Effectiveness Index", color= "Income Group") + 
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 11),
              legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
        scale_color_manual( values = incomescol,
                            breaks=rev(income_order_2020))
      
      #Saving the plot displayed. 
      ggsave(file.path(fig_out, "S4.9_govteff_income.png"), width = 10, height = 6, dpi=300, units = "in")
 
## International Health Regulations State Party Assessment Report, % Food Safety Attributes Attained by Country, Latest Year                         
# Figure S4.10_foodsafety.png
                         
  #Set variables
      fooddata <- select(fsci_data, c("ISO", "foodsafety", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(foodsafety) %>% filter(year == "2020")

  #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

  #merging data
      fooddata_simple<-merge(World, fooddata, by='iso_a3',  duplicateGeoms = TRUE)

  #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

  # Map
     food_map <-tm_shape(fooddata_simple) + tm_polygons("foodsafety",
                                                       style="cont",
                                                       breaks=c(0,20,40,60,80,100),
                                                       palette= color10,
                                                       title="% Food safety attributes attained by country",
                                                       legend.is.portrait=FALSE,
                                                       labels = c("0","20","40","60","80","100"),
                                                       colorNA = "grey85", 
                                                       textNA = "Data Unavailable") + 

      tm_layout(frame = FALSE, legend.outside = TRUE,
                legend.outside.position = "bottom", outer.margins=0,
                legend.outside.size = .2) + 
      tm_legend(legend.title.fontface = 2,  # legend bold
                legend.title.size = 3, 
                legend.text.size = 3, 
                legend.bg.alpha = 0, 
                legend.width = 5) 
      food_map

      tmap_save(food_map, file.path(fig_out, "S4.10_foodsafety.png"), width = 10, height = 6, dpi=300, units = "in")
         
## Presence of Health-Related Food Taxes by Country, 2021                        
# Figure S4.11_healthtax.png

      #Set variables
      healthdata <- select(fsci_data, c("ISO", "healthtax", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(healthtax)

      #World map 
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      healthdata_simple <- merge(World, healthdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      health_map <-tm_shape(healthdata_simple) + tm_polygons("healthtax",
                                                             style="fixed",
                                                             breaks=c(0,1, 10),
                                                             palette= cbpalette_2,
                                                             title="Presence of health-related food taxes by country",
                                                             legend.is.portrait=TRUE,
                                                             labels = c("Not Present", "Present"),
                                                             colorNA = "grey85", 
                                                             textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      health_map

      tmap_save(health_map, file.path(fig_out, "S4.11_healthtax.png"), width = 10, height = 6, dpi=300, units = "in")
     
## V-Dem Accountability Index by Country, 2021      
# Figure S4.12_accountability_2021.png

      #Set variables
      demdata <- select(fsci_data, c("ISO", "accountability", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(accountability)

      #only use 2021 data
      demdata <- filter(demdata, year == "2021")

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      demdata_simple<-merge(World,demdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      dem_map<-tm_shape(demdata_simple) + tm_polygons("accountability",
                                                      style="cont",
                                                      breaks = c(-1.2,-.8,-.4,0,.4,.8,1.2,1.6,2),
                                                      palette = colordiv_bluered11,
                                                      title="V-Dem Accountability Index by country",
                                                      legend.is.portrait=FALSE,
                                                      labels = c("-1.2","-.8","-.4","0",".4",".8","1.2","1.6","2"),
                                                      colorNA = "grey85", 
                                                      textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2,
                  aes.palette = list(seq = "-colordiv_redblue12")) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      dem_map

      tmap_save(dem_map, file.path(fig_out, "S4.12_accountability_2021.png"), width = 10, height = 6, dpi=300, units = "in")

## V-Dem Accountability Index by Income Level 
# Figure S4.13_accountability_region.png
      
      # Select variables
      acc_data <- select(fsci_data, c("country", "accountability", "year", "fsci_regions", "incgrp", "totalpop")) %>%
        drop_na(accountability) %>% drop_na(totalpop) %>% mutate(fsci_regions = fct_reorder2(fsci_regions, year, accountability))

    # Population-weighted mean by region
      acc_data <- acc_data %>% group_by(fsci_regions, year) %>% 
        summarise(acc_region_mean = weighted.mean(accountability, totalpop, na.rm=TRUE))
                         
    # Order legend
      region_order_2021 <- acc_data %>% filter(year=="2021") %>% 
        arrange(acc_region_mean,by_group=FALSE) %>% .$fsci_regions 

      ggplot(data=acc_data, aes(x = year, y = acc_region_mean, color = fsci_regions), groups=fsci_regions) +
        geom_line( size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "V-Dem accountability index", color= "Region") + 
        scale_x_continuous(breaks=seq(2000, 2021, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              legend.text = element_text(size = 12), axis.text.x = element_text(size = 12), 
              axis.text.y = element_text(size = 12),legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions,breaks=rev(region_order_2021))
      
      ggsave(file.path(fig_out, "S4.13_accountability_region.png"), width = 10, height = 6, dpi=300, units = "in")
  
# Figure S4.14_accountability_income.png
                         
      # Select variables
      acc_data <- select(fsci_data, c("country", "accountability", "year", "wb_region", "incgrp", "totalpop")) %>%
        drop_na(accountability) %>% drop_na(totalpop) %>% mutate(incgrp = fct_reorder2(incgrp, year, accountability))
      
      # Population-weighted mean by region
      acc_data <- acc_data %>% group_by(incgrp, year) %>% 
        summarise(acc_income_mean = weighted.mean(accountability, totalpop, na.rm=TRUE))
      
      # Order legend
      income_order_2021 <- acc_data %>% filter(year=="2021") %>% 
        arrange(acc_income_mean, by_group=FALSE) %>% .$incgrp 
      
      ggplot(data=acc_data, aes(x = year, y = acc_income_mean, color = incgrp), groups=incgrp) +
        geom_line( size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "V-Dem accountability index", color= "Income group") + 
        scale_x_continuous(breaks=seq(2000, 2021, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              legend.text = element_text(size = 12), axis.text.x = element_text(size = 12), 
              axis.text.y = element_text(size = 12),legend.title = element_text(size = 14)) +
        scale_color_manual(values = incomescol,
                           breaks=rev(income_order_2021))
      
      ggsave(file.path(fig_out, "S4.14_accountability_income.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Open Budget Index by Region                         
# Figure S4.15_obi_income.png

      #Set variables
      obidata <- select(fsci_data, c("incgrp", "year", "open_budget_index")) %>%
        drop_na(open_budget_index) %>% filter(incgrp != "") %>%
        mutate(year = as.factor(year))
      
      ggplot(obidata, aes(x=year, y=open_budget_index,
                             color = incgrp, fill = incgrp)) +
        geom_violin(trim = FALSE) + ylim(0,100) +
        scale_color_manual(values = incomescol) + scale_fill_manual(values = incomescol) +
        facet_wrap(~ incgrp, labeller = label_wrap_gen(width = 25, multi_line = TRUE)) +
        ylab("Open budget index") + xlab("") +
        theme_classic() + theme(strip.text = element_text(size = 10),
                                strip.placement = "bottom",
                                legend.position="none",
                                strip.background  = element_rect(fill="lightgray"),
                                panel.border = element_blank(),
                                axis.text.x=element_text(angle = 45, size=10, vjust = -.01),
                                axis.text.y=element_text(size=10),
                                axis.title=element_text(size=10))
      

      ggsave(file.path(fig_out, "S4.15_obi_income.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Guarantees for Public Access to Information, Adopted by Year                          
# Figure S4.16_accessinfo.png

     # Use indicator specific dataset to get information access year of adoption
      accessdata <- read_dta(file.path(data_in, "AccessInfo.dta")) %>%
        rename(iso_a3 = ISO) %>% drop_na(accessinfo)
      
    # Categorize years - workaround for map program error
      accessdata <- accessdata %>% mutate(yearofadoption = case_when(yearofadoption == 1776 ~ "1776",
                                                           yearofadoption >= 1950  & yearofadoption <= 1959 ~ '1950s',
                                                           yearofadoption >= 1960  & yearofadoption <= 1969 ~ '1960s',
                                                           yearofadoption >= 1970  & yearofadoption <= 1979 ~ '1970s',
                                                           yearofadoption >= 1980  & yearofadoption <= 1989 ~ '1980s',
                                                           yearofadoption >= 1990  & yearofadoption <= 1999 ~ '1990s',
                                                           yearofadoption >= 2000  & yearofadoption <= 2009 ~ '2000s',
                                                           yearofadoption >= 2010  & yearofadoption <= 2019 ~ '2010s',
                                                           yearofadoption >= 2020  & yearofadoption <= 2029 ~ '2020s'))

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      accessdata_simple<-merge(World, accessdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      access_map<-tm_shape(accessdata_simple) + tm_polygons("yearofadoption",
                                                            style="cat",
                                                            palette = gradientred,
                                                            title="Year guarantees for public access to information adopted",
                                                            legend.is.portrait=TRUE,
                                                            labels = c("1776", "1950s","1960s","1970s","1980s","1990s","2000s","2010s","2020s"),
                                                            colorNA = "grey85",
                                                            textNA = "Unadopted/Data Unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.title.fontface = 2) 
      access_map

      tmap_save(access_map, file.path(fig_out, "S4.16_accessinfo.png"), width = 10, height = 6, dpi=300, units = "in")

### S4.17 
      # Select variables and order by region and year
      data <- select(fsci_data_timeseries, c("ISO", "country", "incgrp", "year", "foodsafety", "govteffect")) %>%
        filter(!is.na("incgrp")) %>%
        arrange("country", year) %>%
        filter(!is.na(foodsafety)) %>%
        subset(year >= 2018 & year <=2020)
      data2 <- select(data, c("country", "incgrp", "ISO", "year")) %>%
        filter(year == 2020)
      data2 <- select(data2, -c("year"))
      
      # Create data frame of 3-year average
      gov_fig <- as.data.frame(aggregate(cbind(govteffect, foodsafety) ~ country, data = data, FUN = mean, na.rm = TRUE))
      
      # Merge income group back in
      gov_fig <- gov_fig %>% left_join(data2, by = "country")
      
      # Remove Venezuela not classified in income category (but not NA)
      gov_fig <- subset(gov_fig, country != "Venezuela, Bolivarian Republic of")
      
      # Classify food safety scores
      gov_fig$foodsafetycat <- cut(gov_fig$foodsafety,
                                   breaks = c(0, 20, 40, 60, 80))
      
      # Reorder income group levels
      gov_fig$incgrp <- as.factor(gov_fig$incgrp)
      levels(gov_fig$incgrp)
      gov_fig$incgrp <- factor(gov_fig$incgrp, levels = c("Low income", "Lower middle income", 
                                                          "Upper middle income", "High income"))
      gov_fig$ISO <- as.factor(gov_fig$ISO)
      
      # Plot
      ggplot(subset(gov_fig, !is.na(gov_fig$incgrp) & !is.na(gov_fig$foodsafetycat)), 
             aes(x = foodsafetycat, y = govteffect, fill = incgrp)) +
        geom_half_violin(inherit.aes = FALSE, aes (x = foodsafetycat, y = govteffect)) + 
        geom_dotplot(binaxis = "y", stackdir = "up", binwidth = 0.2, 
                     binpositions="all", dotsize = .5, color = NA) +
        geom_text_repel(aes(label = country), size = 5, 
                        box.padding = 0.1, point.padding = 0.2,
                        position = "dodge", width = 0.1,
                        max.overlaps = 3, min.segment.length = Inf,) +
        theme_classic () +
        theme(axis.text.x = element_text(hjust=.3)) +
        theme(strip.text.x = element_text(size = 12)) +
        ylab("Government Effectiveness Index") +
        xlab("Food safety capacity score") +
        scale_fill_manual(values = c(colorqual)) +
        guides(fill = guide_legend(title = "Income group"))
      ggsave(file.path(fig_out, "S4.17_Gov effect and food safety.png"), width = 10, height = 8, dpi = 300, units = "in")
      
      
## Theme 5: Resilience##
                         
## Ratio of total damages of all disasters to GDP
# Figure S5.1_damages.png

      # select data
      damages <- fsci_data %>% select(c("ISO", "damages_gdp", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(damages_gdp) %>%
        filter(year >= 2012 & year < 2022) 

      # take average over 10 years
      damages <- damages %>% group_by(iso_a3) %>% 
        summarise(damages_mean = mean(damages_gdp))

      #convert damages_gdp variable to number variable
      damages$damages_mean <- as.numeric(damages$damages_mean)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      damages_simple <- merge(World, damages, by='iso_a3',  duplicateGeoms = TRUE)

      view(damages_simple) #to decide on the breaks

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      range(damages$damages_mean)
      damages_map <- tm_shape(damages_simple) + tm_polygons("damages_mean", style="cont",
                                                            breaks=c(0,0.00002,0.0004,0.008,0.01,0.1,1.3,2), labels = c("0","0.00002","0.0004","0.008","0.01","0.1","1.3","2"),
                                                            palette = color10,
                                                            title="Country-level mean",
                                                            legend.is.portrait=FALSE,
                                                            colorNA = "grey85",
                                                            textNA = "Data unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      damages_map

      tmap_save(damages_map, file.path(fig_out, "S5.1_damages.png"), width = 10, height = 6, dpi=300, units = "in")
                    
## Dietary sourcing flexibility index (FAO), by income group, and total variables by the food category
# Figure S5.2_dsfi.png
    # Use indicator-specific dataset for variabels beyond calories
      dsfi_data <- read_dta(file.path(data_in, "dsfi.dta")) %>% drop_na(incgrp) 
        
      #exclude the unneccessary columns from the dataset
      dsfi1 = dsfi_data[-c(2:4, 6:8, 10:12, 14:16, 18, 21:28)]
      dsfi1$incgrp <- factor(dsfi1$incgrp, levels = c("Low income", "Lower middle income", 
                                                    "Upper middle income", "High income"))
      dsfi1 <- dsfi1 %>% select(-c("wb_region", "year"))
      
      #rename the columns
      colnames(dsfi1)[which(names(dsfi1) == "kcal_total")] <- "Calories" 
      colnames(dsfi1)[which(names(dsfi1) == "fv_total")] <- "Fruits and vegetables" 
      colnames(dsfi1)[which(names(dsfi1) == "protein_total")] <- "Protein" 
      colnames(dsfi1)[which(names(dsfi1) == "fat_total")] <- "Fat"

      #convert the multiple columns/variables into one column 
      dsfi1_long <- melt(dsfi1)

      # Plot the figure
      ggplot(dsfi1_long, aes(x=variable, y=value, fill=incgrp)) + ylab('Dietary sourcing flexibility index') +
        xlab('Food categories') + geom_boxplot() + ylim(0,1) +
        theme(panel.background = element_rect(fill = "white", colour = "grey50"), legend.position="bottom") +
        scale_fill_manual(values = incomescol, name = "")

      # Print the png
      ggsave(file.path(fig_out, "S5.2_dsfi.png"), width = 7, height = 5, dpi=300, units = "in")          
          
## Dietary Sourcing Flexibility Index for Kilocalories, 2018                         
# Figure S5.3_dsfi_2018.png

      #Set variables
      dsfidata <- select(dsfi, c("ISO", "kcal_total", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(kcal_total)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      dsfidata_simple<-merge(World,dsfidata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      dsfi_map<- tm_shape(dsfidata_simple) + tm_polygons("kcal_total",
                                                         style="cont",
                                                         breaks=c(0,.2,.4,.5,.6,.7,.8,.9,1),
                                                         palette= color10,
                                                         title="Dietary Sourcing Flexibility Index for kilocalories",
                                                         legend.is.portrait=FALSE,
                                                         labels = c("0",".2",".4",".5",".6",".7",".8",".9","1"),
                                                         colorNA = "grey85", 
                                                         textNA = "Data Unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      dsfi_map

      #png
      tmap_save(dsfi_map, file.path(fig_out, "S5.3_dsfi_2018.png"), width = 10, height = 6, dpi=300, units = "in")

## Number of mobile cellular subscriptions (per 100 people)
# Figure S5.4_mobile.png

      #Select variables
      mobile_data <- select(fsci_data, c("country", "mobile", "year", "fsci_regions", "incgrp")) %>%
        drop_na(mobile) %>% drop_na(fsci_regions) %>%  mutate(fsci_regions = fct_reorder2(fsci_regions, year, mobile))

      # regional mean (unweighted)
      mobile_data <-mobile_data %>% group_by(fsci_regions,year) %>% 
        summarise(mobile_region_mean = mean(mobile, na.rm=TRUE))

    # Legend order
      region_order_2020 <- mobile_data %>% filter(year=="2020") %>% 
        arrange(mobile_region_mean,by_group=FALSE) %>% .$fsci_regions

      ggplot(data=mobile_data,aes(x = year, y = mobile_region_mean, color = fsci_regions), groups=fsci_regions) +
        geom_line(size = 2,show.legend = NA) + theme_classic() +
        labs(x = "Year", y = "Number of mobile cellular subscriptions (per 100 people)", color= "Region") + 
        scale_x_continuous(breaks=seq(2000, 2020, 5))+
        theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
              axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 11),
              legend.text = element_text(size = 11), legend.title = element_text(size = 14)) +
        scale_color_manual(values=regions, breaks=rev(region_order_2020)) 

      ggsave(file.path(fig_out, "S5.4_mobile.png"), width = 10, height = 6, dpi=300, units = "in")
              
## Map of 10 year average of mobile subscriptions (mobile) (per 100 people) (International Telecommunications Union / World Bank)                        
# Figure S5.5_mobile_map.png    

      #open the dataset and select the relevant variables
      mobile <- select(fsci_data, c("ISO", "mobile", "year", "country")) %>%
        rename(iso_a3 = ISO) %>% filter(between(year, 2011, 2020))

      # 10 year average 
      mobile <- mobile %>% group_by(iso_a3, country) %>% 
        summarise(mobile_mean = mean(mobile, na.rm = TRUE)) %>%
        mutate(iso_a3, iso_a3 = as.factor(iso_a3))

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      mobile_simple <-merge(World, mobile, by = 'iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      mobile_map <-tm_shape(mobile_simple) + tm_polygons("mobile_mean", 
                                                         style="cont", 
                                                         breaks = c(10,30,50,70,90,100,120,150,180), 
                                                         labels = c("10","30","50","70","90","100","120","150","180"), 
                                                         palette = color10, title = "10-year average mobile subscriptions per 100 people by country", 
                                                         legend.is.portrait = FALSE, colorNA = "grey85", textNA = "Data Unavailable")+

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins = 0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      mobile_map

      tmap_save(mobile_map, file.path(fig_out, "S5.5_mobile_map.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Social capital index (with the value 0 to 1)
# Figure S5.6_soccap_region.png

    # Select variables
    sc_data <- select(fsci_data, c("country", "soccapindex", "year", "fsci_regions", "incgrp", "totalpop")) %>% 
      drop_na(totalpop) %>% 
      drop_na(soccapindex | fsci_regions) %>%  
      mutate(fsci_regions = fct_reorder2(fsci_regions, year, soccapindex))

    # Population-weighted average 
    sc_data <- sc_data %>% group_by(fsci_regions, year) %>% 
      summarise(sc_region_mean = weighted.mean(soccapindex, totalpop, na.rm=TRUE))

  # Legend order
    region_order_2021 <- sc_data %>% filter(year=="2021") %>% 
      arrange(sc_region_mean,by_group=FALSE) %>% .$fsci_regions 
    
    ggplot(data=sc_data,aes(x = year, y = sc_region_mean, color = fsci_regions),groups=fsci_regions) +
      geom_line( size = 2,show.legend = NA) + theme_classic() +
      labs(x = "Year", y = "Social capital index", color= "Region") + 
      scale_x_continuous(breaks=seq(2007, 2021, 2))+
      theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), 
            legend.text = element_text(size = 12), axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 12),legend.title = element_text(size = 14)) +
      scale_color_manual(values=regions,
                         breaks=rev(region_order_2021))
    
    ggsave(file.path(fig_out, "S5.6_soccap_region.png"), width = 10, height = 6, dpi=300, units = "in")
    
# Figure S5.7_soccap_income.png
                         
    # Select variables
    sc_data <- select(fsci_data, c("country", "soccapindex", "year", "fsci_regions", "incgrp", "totalpop")) %>% drop_na(totalpop) %>% 
      drop_na(soccapindex | incgrp) %>%  mutate(incgrp = fct_reorder2(incgrp, year, soccapindex))
    
    # Population-weighted average 
    sc_data <- sc_data %>% group_by(incgrp, year) %>% 
      summarise(sc_incgrp_mean = weighted.mean(soccapindex, totalpop, na.rm=TRUE))
    
    # Legend order
    incgrp_order_2021 <- sc_data %>% filter(year=="2021") %>% 
      arrange(sc_incgrp_mean, by_group=FALSE) %>% .$incgrp 
   
    # Plot
    ggplot(data=sc_data,aes(x = year, y = sc_incgrp_mean, color = incgrp),groups=incgrp) +
      geom_line( size = 2,show.legend = NA) + theme_classic() +
      labs(x = "Year", y = "Social capital index", color= "Income group") + 
      scale_x_continuous(breaks=seq(2007, 2021, 2))+
      theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), legend.text = element_text(size = 12), axis.text.x = element_text(size = 12), axis.text.y = element_text(size = 12),legend.title = element_text(size = 14)) +
      scale_color_manual(values = incomescol,
                         breaks=rev(incgrp_order_2021))
    
    ggsave(file.path(fig_out, "S5.7_soccap_income.png"), width = 10, height = 6, dpi=300, units = "in")
      
##  Map of 5 year average for 2017-2021 of the social capital index (soccap)                         
# Figure S5.8_soccap_2021.png
    
      #Set variables
      socialcapital <- select(fsci_data, c("ISO", "soccapindex", "year", "country")) %>%
        rename(iso_a3=ISO) %>% filter(between(year, 2017, 2021))

      # 5 year average
      socialcapital <- socialcapital %>% group_by(iso_a3, country) %>% 
        summarise(socialcapital_mean = mean(soccapindex, na.rm = TRUE)) %>%
        mutate(iso_a3, iso_a3 = as.factor(iso_a3))

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      socialcapital_simple <-merge(World, socialcapital, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      socialcapital_map <-tm_shape(socialcapital_simple) + tm_polygons("socialcapital_mean", style="cont", breaks=c(.1,.2,.3,.4,.5,.6,.7,.8,.9), labels = c("0.1","0.2","0.3","0.4","0.5","0.6","0.7","0,8","0.9"), palette=color10, title="Social capital index, average of last 5 years", legend.is.portrait=FALSE, colorNA="grey85", textNA="Data Unavailable")+

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      socialcapital_map

    tmap_save(socialcapital_map, file.path(fig_out, "S5.8_soccap_2021.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Percentage of Agricultural Land with Minimum Level of Species Diversity (Crop and Pasture), 2010                         
# Figure S5.9_minspecies_2010.png
     
      #Set variables
      mindata <- select(minspeciesrichness, c("ISO", "pctagland_minspecies", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(pctagland_minspecies)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      mindata_simple<-merge(World,mindata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      min_map<-tm_shape(mindata_simple) + tm_polygons("pctagland_minspecies",
                                                      style="cont",
                                                      breaks=c(0,10,20,30,40,50,60,70,80,90,100),
                                                      palette= color10,
                                                      title="% of agricultural land with minimum level of species diversity",
                                                      legend.is.portrait=FALSE,
                                                      labels = c("0%","10%","20%","30%","40%","50%","60%","70%","80%","90%","100%"),
                                                      colorNA = "grey85", 
                                                      textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 2.5, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      min_map

      tmap_save(min_map, file.path(fig_out, "S5.9_minspecies_2010.png"), width = 10, height = 6, dpi=300, units = "in")                            
             
## Number of Wild Useful Plants for Food and Agriculture Secured in Conservation Facilities (Thousands), 2020                         
# Figure S5.10_genres_plants_2020.png
   
      #Set variables
      geneticdata <- select(fsci_data, c("wb_region", "year", "genres_plant", "ISO")) %>% 
        filter(year == "2020") %>% rename(iso_a3 = ISO)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      geneticdata_simple<-merge(World,geneticdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      genetic_map<-tm_shape(geneticdata_simple) + tm_polygons("genres_plant",
                                                              style="cont",
                                                              breaks=c(0,20,40,60,80,100,250,500,900),
                                                              palette= color10,
                                                              title="Number of wild useful plants secured in conservation facilities (thousands)",
                                                              legend.is.portrait=FALSE,
                                                              labels = c("0","20","40","60","80","100","250","500","900"),
                                                              colorNA = "grey85", 
                                                              textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      genetic_map

      tmap_save(genetic_map, file.path(fig_out, "S5.10_genres_plants_2020.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Number of Animal Genetic Resources Secured in Conservation Facilities, 2021                         
# Figure S5.11_genres_animals_2021.png   
                            
      #Set Variables
      geneticdata <- select(fsci_data, c("wb_region", "year", "genres_animal", "ISO")) %>% 
        filter(year == "2021") %>% rename(iso_a3 = ISO) %>% drop_na(genres_animal)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      geneticdata_simple<-merge(World,geneticdata, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      #Creating Map

      #Simple Map
      genetic_map<-tm_shape(geneticdata_simple) + tm_polygons("genres_animal",
                                                              style="cont",
                                                              breaks=c(0,2,4,6,8,10,20,30,37),
                                                              palette= color10,
                                                              title="Number of animal genetic resources secured in conservation facilities",
                                                              legend.is.portrait=FALSE,
                                                              labels = c("0","2","4","6","8","10","20","30","37"),
                                                              colorNA = "grey85", 
                                                              textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      genetic_map

      tmap_save(genetic_map, file.path(fig_out, "S5.11_genres_animals_2021.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## Coping Strategies Index by Country, 2021                         
# Figure S5.12_rCSI.png

     #Set variables
      coping <- select(rCSI_2021, c("ISO", "rcsi_prevalence", "year")) %>%
        rename(iso_a3 = ISO) %>% drop_na(rcsi_prevalence)

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      coping_simple<-merge(World, coping, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      coping_map<-tm_shape(coping_simple) + tm_polygons("rcsi_prevalence",
                                                        style="cont",
                                                        breaks=c(0,10,20,25,30,35,40,50,60),
                                                        palette= color10,
                                                        title="Proportion of population using extreme coping strategies",
                                                        legend.is.portrait=FALSE,
                                                        labels = c("0","10","20","25","30","35","40","50","60"),
                                                        colorNA = "grey85", 
                                                        textNA = "Data Unavailable") + 

        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      coping_map

      tmap_save(coping_map, file.path(fig_out, "S5.12_rCSI.png"), width = 10, height = 6, dpi=300, units = "in") 
                         
## Global map of average of last 3 years of food price volatility (2019-2021) (variable: fpi_cv)                         
# Figure S5.13_fpvol.png
    # Select variables
    foodpricevolatility <- select(fsci_data, c("ISO", "fpi_cv", "year", "country")) %>%
      rename(iso_a3 = ISO) %>% drop_na(fpi_cv) %>% filter(between(year, 2019, 2021))

    # 3-year mean
    foodpricevolatility <-
      foodpricevolatility %>% group_by(iso_a3, country) %>% 
      summarise(foodpricevolatility_mean = mean(fpi_cv, na.rm = TRUE)) %>%
      mutate(iso_a3, iso_a3 = as.factor(iso_a3))
    
    #World map options
    World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  
    
    #merging data
    foodpricevolatility_simple <-merge(World, foodpricevolatility, by='iso_a3',  duplicateGeoms = TRUE)
    
    #Turn off s2 processing to avoid invalid polygons
    sf::sf_use_s2(FALSE)
    
    # Map
      foodpricevolatility_map <-tm_shape(foodpricevolatility_simple) + tm_polygons("foodpricevolatility_mean", 
                                                                             style="cont",
                                                                             breaks=(0,.2,.4,.6,.8,1),
                                                                             palette = colordiv_redblue12, 
                                                                             title="Country level 3-year average food price volatility", 
                                                                             legend.is.portrait = FALSE, 
                                                                             labels = c("0",".2", ".4", ".6",".8","1"), 
                                                                             colorNA="grey85", 
                                                                             textNA="Data Unavailable") +
  
      tm_layout(frame = FALSE, legend.outside = TRUE,
                legend.outside.position = "bottom", outer.margins = 0,
                legend.outside.size = .2) + 
      tm_legend(legend.title.fontface = 2,  # legend bold
                legend.title.size = 3, 
                legend.text.size = 3, 
                legend.bg.alpha = 0, 
                legend.width = 5) 
    foodpricevolatility_map

    tmap_save(foodpricevolatility_map, file.path(fig_out,"S5.13_fpvol.png"), width = 10, height = 6, dpi=300, units = "in")

## Food supply variability (kcal/capita/day)
# Figure S5.14_foodsupplyvar_region.png
    
    #Select variables
    foodsupplyvariability <- select(fsci_data, c("country", "foodsupplyvar", "year", "fsci_regions", "incgrp", "totalpop")) %>%
    drop_na(foodsupplyvar) %>%  mutate(fsci_regions = fct_reorder2(fsci_regions, year, foodsupplyvar))

    # Unweighted mean
    foodsupplyvariability <- foodsupplyvariability %>% group_by(fsci_regions, year) %>% 
    summarise(foodsupplyvariability_region_mean = mean(foodsupplyvar, na.rm=TRUE))

    # Order legend
    region_order_2020 <-foodsupplyvariability %>% filter(year=="2020") %>% 
    arrange(foodsupplyvariability_region_mean, by_group=FALSE) %>% .$fsci_regions 
    range(foodsupplyvariability$foodsupplyvariability_region_mean)

    ggplot(data=foodsupplyvariability, aes(x = year, y = foodsupplyvariability_region_mean, color = fsci_regions),
         groups=fsci_regions) +
    geom_line(size = 2,show.legend = NA) + theme_classic() +
    labs(x = "Year", y = "Food supply variability (kcal/capita/day)", color= "Region") + 
    scale_x_continuous(breaks=seq(2000, 2020, 5)) +
    theme(axis.title.x = element_text(size = 14), axis.title.y = element_text(size = 14), 
          legend.text = element_text(size = 12), legend.title = element_text(size = 14)) +
    scale_color_manual(values=regions,
                       breaks=rev(region_order_2020))+
    scale_y_continuous(name="Food supply variability (kcal/capita/day)", limits = c(0,80)) 
    
    # Saving the plot displayed
    ggsave(file.path(fig_out, "S5.14_foodsupplyvar_region.png"), width = 10, height = 6, dpi=300, units = "in")

# Figure S5.15_foodsupplyvar_income.png
                         
    #Select variables
    foodsupplyvariability <- select(fsci_data, c("country", "foodsupplyvar", "year", "wb_region", "incgrp", "totalpop")) %>%
      drop_na(foodsupplyvar) %>%  drop_na(incgrp) %>% mutate(incgrp = fct_reorder2(incgrp, year, foodsupplyvar)) 
    foodsupplyvariability$incgrp <- factor(foodsupplyvariability$incgrp, levels = c("Low income", "Lower middle income", 
                                                      "Upper middle income", "High income"))
    
    # Unweighted mean
    foodsupplyvariability <- foodsupplyvariability %>% group_by(incgrp, year) %>% 
      summarise(foodsupplyvariability_incgrp_mean = mean(foodsupplyvar, na.rm=TRUE)) %>%
      drop_na(incgrp)
   
    #Plot 
    ggplot(data=foodsupplyvariability, aes(x = year, y = foodsupplyvariability_incgrp_mean, color = incgrp), groups=incgrp) +
      geom_line(size = 2,show.legend = NA) + theme_classic() +
      labs(x = "Year", y = "Food supply variability (kcal/capita/day)", color= "Income group") + 
      scale_x_continuous(breaks=seq(2000, 2020, 5))+
      theme(axis.title.x = element_text(size = 14),axis.title.y = element_text(size = 14), legend.text = element_text(size = 12), 
            legend.title = element_text(size = 14)) +
      scale_color_manual(values = incomescol) +
      scale_y_continuous(name="Food supply variability (kcal/capita/day)") 
    
    ggsave(file.path(fig_out, "S5.15_foodsupplyvar_income.png"), width = 10, height = 6, dpi=300, units = "in")
                         
## 10 Year Average of Food Supply Variability by Country, 2011-2020
# Figure S5.16_foodsupplyvar_map.png
                         
     #Set variables
      fsvdata <- select(fsci_data, c("ISO", "foodsupplyvar", "year"))  %>% 
        rename(iso_a3 = ISO) %>% drop_na(foodsupplyvar)

      # Mean by country for 2011-2020
      fsv_avg <- fsvdata %>%
        filter(iso_a3 != "") %>% 
        filter(year >= "2011") %>% 
        group_by(iso_a3, year) %>% 
        summarise(mean_reg1 = mean(foodsupplyvar, na.rm=TRUE)) %>%
        aggregate(cbind(mean_reg2 = mean_reg1) ~ iso_a3, data = ., mean) %>%
        ungroup 

      #World map options
      World <- ne_countries(scale = 50,  returnclass = c("sp", "sf"))  

      #merging data
      fsvdata_simple<-merge(World,fsv_avg, by='iso_a3',  duplicateGeoms = TRUE)

      #Turn off s2 processing to avoid invalid polygons
      sf::sf_use_s2(FALSE)

      # Map
      fsv_map<- tm_shape(fsvdata_simple) + tm_polygons("mean_reg2",
                                                       style="cont",
                                                       breaks=c(10,20,30,40,50,60,70,80,115),
                                                       palette= color10,
                                                       title="10 Year Average of Food Supply Variability by Country",
                                                       legend.is.portrait=FALSE,
                                                       labels = c("10","20","30","40","50","60","70","80","115"),
                                                       colorNA = "grey85", 
                                                       textNA = "Data Unavailable") + 
        tm_layout(frame = FALSE, legend.outside = TRUE,
                  legend.outside.position = "bottom", outer.margins=0,
                  legend.outside.size = .2) + 
        tm_legend(legend.title.fontface = 2,  # legend bold
                  legend.title.size = 3, 
                  legend.text.size = 3, 
                  legend.bg.alpha = 0, 
                  legend.width = 5) 
      fsv_map

      tmap_save(fsv_map, file.path(fig_out, "S5.16_foodsupplyvar_map.png"), width = 10, height = 6, dpi=300, units = "in")

# Figure S5.17 Created in Excel
      
