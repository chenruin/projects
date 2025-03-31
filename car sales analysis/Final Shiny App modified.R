library(shiny)
library(tidyverse)
library(shinydashboard)
library(readr)
library("reshape2")
library(usmap)


cars<- read_csv("cars_raw.csv")

# remove Not Priced in Price and change price to numeric
cars <-cars %>%
  filter(!Price=="Not Priced")
# convert price to numeric
cars$Price <-as.numeric(str_remove(str_remove(cars$Price,"\\$"),","))

# Data cleaning - remove not appliable state names
cars <-cars %>%
  filter(!State =="Bldg",!State=="Glens",!State=="RT",!State=="SE",!State=="Suite",
         !State=="US-12",!State=="US-169",!State == "Michigan",!State== "AZ-101")

# grouping and filtering the Fuel type
cars$FuelType[cars$FuelType == "–"] <- "Electric"
cars$FuelType[cars$FuelType == "Diesel Fuel"] <- "Diesel"
cars$FuelType[cars$FuelType == "Flex Fuel Capability"] <- "E85 Flex Fuel"
cars$FuelType[cars$FuelType == "Flexible Fuel"] <- "E85 Flex Fuel"
cars$FuelType[cars$FuelType == "Electric Fuel System"] <- "Electric"
cars$FuelType[cars$FuelType == "Gasoline Fuel"] <- "Gasoline"
cars$FuelType[cars$FuelType == "Gasoline/Mild Electric Hybrid"] <- "Hybrid"
cars$FuelType[cars$FuelType == "Plug-In Electric/Gas"] <- "Hybrid"

# Select models >= 50
cars_Q3<-cars %>% 
  group_by(Model) %>% 
  mutate(n = n()) %>%
  filter(n>=50)

#Shiny App
ui <- shinydashboard::dashboardPage(
  dashboardHeader(title = "US Used-car Data"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Most popular car", tabName = "PopularCar"),
      menuItem("PriceVSMileage", tabName = "PvsM"),
      menuItem("PriceVSYear", tabName = "PvsY"),
      menuItem("Color distribution vs state", tabName = "cdvs"),
      menuItem("MPG vs state", tabName = "MVS"),
      menuItem("Make ratings vs year", tabName = "mrvy"),
      menuItem("Deal type vs state", tabName = "dtvs")
      )
    ),
  body = shinydashboard::dashboardBody(
    shinydashboard::tabItems(
      shinydashboard::tabItem(tabName = "PopularCar",
                              p("Top sales cars in the United States, and each state"),
                              sidebarPanel(
                                selectInput("region", "U.S. or States", 
                                            choices = c("U.S.", "States")),
                                conditionalPanel(condition = "input.region == 'States'",
                                                 selectInput("States",
                                                             "States", 
                                                             choices = unique(cars$State)
                                                             ),
                                ),
                                
                                selectInput("top",
                                            "top",
                                            choices = c(1,3,5,10))

                                ),
                              
                              # Show a plot of the generated distribution
                              mainPanel(
                                plotOutput("Popular"))),
      
      shinydashboard::tabItem(tabName = "PvsM",
                              p("This plot is used to determine how the car's mileage may impact the pricing of the same model car. Any model quantity greater than 50 was selected in this tab to be plotted."),
                              
                              sidebarPanel(
                                selectInput(inputId = "Make",
                                            label = "Select a make",
                                            choices = unique(cars_Q3$Make),
                                            selected = c('Honda')),
                                selectInput(inputId = "Model",
                                            label = "Select a model",
                                            choices = unique(cars_Q3$Model),
                                            multiple = TRUE
                                ),
                              ),
                              plotOutput(outputId = "PvsMPlot")),
      shinydashboard::tabItem(tabName = "PvsY",
                              p("This plot is used to determine how the car's year may impact the pricing of the same model car. Any model quantity greater than 50 was selected in this tab to be plotted."),
                              sidebarPanel(
                                selectInput(inputId = "Make2",
                                            label = "Select a make",
                                            choices = unique(cars_Q3$Make),
                                            selected = c('Honda')),
                                selectInput(inputId = "Model2",
                                            label = "Select a model",
                                            choices = unique(cars_Q3$Model),
                                            multiple = TRUE
                                ),
                              ),
                              plotOutput(outputId = "PvsYPlot")),
      shinydashboard::tabItem(tabName = "cdvs",
                              p("This graph reflects the count for each exterior color for a given state. Dark color includes Black, Grey, Granite, Blue, Gun, Red, Ebony, Magnetic, Ruby, Graphite, and Caviar. Light includes Silver, Steel, White, Pearl, and Platinum. The remaining colors are grouped as others."),
                              sidebarPanel(
                                selectInput("v_select", 
                                            label = "State", 
                                            choices = unique(cars$State), 
                                            selected = "AZ",
                                ),
                              ),
                              plotOutput(outputId ="p1")),
      shinydashboard::tabItem(tabName = "MVS",
                              p("This graph observes the different trends of states’ MPG selections. In our data, we had min MPG(city MPG) and Max MPG(Highway MPG). We picked the mean value of each model and matched them in the US Map."),
                               sidebarPanel(
                                 radioButtons("v_select1", 
                                              label = "Min or MAX", 
                                              choices = c("MinMPGAvg","MaxMPGAvg"), 
                                              selected = "MinMPGAvg"),
                                 selectInput("v_select2", 
                                             label = "Fuel type", 
                                             choices = unique(cars$FuelType), 
                                             selected = "Gasoline",
                                 ),
                               ),
                               plotOutput(outputId ="p2")),
      shinydashboard::tabItem(tabName = "mrvy",
                              p("This boxplot could help users see ratings from the general public (ComfortRating, InteriorDesignRating, PerformanceRating, ValueForMoneyRating, ExteriorStylingRating, ReliabilityRating) of the Make by year."),
                               sidebarPanel(
                                 selectInput("v_select3", 
                                             label = "Brand", 
                                             choices = unique(cars$Make), 
                                             selected = "Toyota"),
                                 sliderInput("slider1", 
                                             label = "Year", 
                                             min = min(cars$Year), 
                                             max = max(cars$Year), 
                                             value = 2019, step = 1,
                                 ),
                              ),
                              plotOutput(outputId = "p3")),
      shinydashboard::tabItem(tabName = "dtvs",
                              p("This graph could discover the customer’s assessment of the dealers’ service level in three ranks, Fair, Good, and Great."),
                              sidebarPanel(
                                selectInput("v_select4", 
                                            label = "State", 
                                            choices = unique(cars$State), 
                                            selected = "AZ",
                                ),
                              ),
                              plotOutput(outputId = "p4"))
    
    )
  )
)




server <- function(input, output){
  #Popular
  output$Popular <- renderPlot({
    
    if(input$region == "States")
      x<- cars %>% 
        filter(State == input$States) %>% 
        group_by(Make) %>% 
        count()
    
    if(input$region == "U.S.")
      x<- cars %>% 
        group_by(Make) %>% 
        count() 
    
    x[order(-x$n),][1:input$top,] %>% 
      ggplot(aes(x = reorder(Make, -n), y = n, fill = Make)) + 
      geom_col() + 
      ylab("the amount has sold") + 
      xlab("top makes") +
      theme(axis.title.y=element_text(angle=0)) +
      scale_fill_brewer(palette = "Paired") +
      theme_bw()
    
  })
  # code for price vs. mileage
  observeEvent(
    input$Make,
    updateSelectInput(session=getDefaultReactiveDomain(),'Model','Select a model',
                      choices = cars_Q3$Model[cars_Q3$Make==input$Make]))
  output$PvsMPlot <- renderPlot({
    cars_Q3 %>%
      filter(Make == input$Make) %>%
      filter(Model == input$Model) %>%
      ggplot(aes(x=Mileage,y=Price,color=Model)) +geom_point()+theme_bw()+ # Improvement
      geom_smooth()+
      xlim(10000, 100000)+
      ylim(5000, 50000)})
  
  # code for price vs. year
  observeEvent(
    input$Make2,
    updateSelectInput(session=getDefaultReactiveDomain(),'Model2','Select a model',
                      choices = cars_Q3$Model[cars_Q3$Make==input$Make2]))
  output$PvsYPlot <- renderPlot({
    cars_Q3 %>%
      filter(Make == input$Make2) %>%
      filter(Model == input$Model2) %>%
      ggplot(aes(x=Year,y=Price, color=Model)) +geom_jitter()+theme_bw()+
      scale_x_continuous(breaks = seq(2010, 2022, by = 2))+
      ylim(5000, 50000)})
  
  #Vikas-p1
  output$p1 <- renderPlot({
    cars %>% mutate(Extc=ifelse((grepl(("Black|Grey|Granite|Blue|Gun|Red|Ebony|Magnetic|Ruby|Graphite|Caviar"),ExteriorColor)),"Dark",
                               ifelse(grepl(("Silver|Steel|White|Pearl|Platinum"),ExteriorColor),"Light", "Other"))) %>%
      filter(State == input$v_select) %>% 
      group_by(State,Extc)%>%count()%>%
      ggplot(aes(x = Extc,y=n, fill = Extc)) + 
      geom_bar(stat='identity') +
      labs(x="Exterior color",y="count")+
      geom_text(aes(label = n),nudge_y = 4)+
      theme_bw()+
      scale_fill_brewer(palette = "Paired")+
      ggtitle(paste("color distribution for state",input$v_select))
  })
  
  # Vikas-P2
  output$p2 <- renderPlot({
    X<-cars %>% 
      filter(FuelType == input$v_select2) %>% group_by(State)%>%mutate(MinMPGAvg=mean(MinMPG),MaxMPGAvg=mean(MaxMPG))%>%
      select(State,MinMPGAvg,MaxMPGAvg)%>%unique() 
    new_data<-merge(X, statepop, by.x = "State", by.y = "abbr")
    plot_usmap(data = new_data, values = input$v_select1, color = "black") + 
      scale_fill_continuous(name = input$v_select1, label = scales::comma) + 
      scale_fill_distiller(palette = "YlOrRd")+
      theme(legend.position = "right") +
      theme_bw() +
      ggtitle(paste(input$v_select1,"using fuel type as: ",input$v_select2))
  })
  
  # Vikas-P3
  output$p3 <- renderPlot({
    cars %>% 
      filter(Make == input$v_select3, Year == input$slider1) %>%
      select(ComfortRating,InteriorDesignRating,PerformanceRating,ValueForMoneyRating,ExteriorStylingRating,ReliabilityRating,Make)%>%
      melt()%>%ggplot(aes(x=variable,y=value,fill=variable))+geom_boxplot(alpha=0.3) + theme(legend.position="none")+
      coord_cartesian(ylim=c(1,5))+labs(x="Ratings",y="")+
      ggtitle(paste("Ratings for",input$v_select3,"make year is ",input$slider1))+
      theme_bw()
  })
  
  # Vikas-P4
  output$p4 <- renderPlot({
    cars %>% 
      filter(State == input$v_select4, !DealType=="NA") %>%
      group_by(DealType)%>%count()%>%
      ggplot(aes(x = DealType,y=n, fill=DealType))+
      geom_bar(stat='identity')+ theme(legend.position="none")+
      geom_text(aes(label = n),nudge_y = 4)+
      labs(x="DealType",y="count")+
      scale_fill_brewer(palette = "Paired")+
      ggtitle(paste("Deal type distribution for state",input$v_select4)) +
      theme_bw()
  })
  
}

shinyApp(ui, server)
