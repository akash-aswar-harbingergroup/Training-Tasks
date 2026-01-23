

# HEART DISEASE PREDICTION DASHBOARD (FULL ML + VISUALIZATION)
# WITHOUT caret VARIABLE IMPORTANCE


library(shiny)
library(shinydashboard)
library(ggplot2)
library(caret)
library(caTools)
library(pROC)


# UI


ui <- dashboardPage(
  dashboardHeader(title = "Heart Disease Prediction Dashboard"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Upload Data", tabName = "upload", icon = icon("file-upload")),
      menuItem("Model Training", tabName = "model", icon = icon("brain")),
      menuItem("ROC Curve", tabName = "roc", icon = icon("chart-line")),
      menuItem("Feature Importance", tabName = "importance", icon = icon("star"))
    )
  ),

  dashboardBody(
    tabItems(

      
      # TAB 1: Upload Data
      
      tabItem(tabName = "upload",
        fluidRow(
          box(title = "Upload heart.csv File", width = 6,
              fileInput("file", "Choose CSV File", accept = ".csv"),
              verbatimTextOutput("preview")
          ),
          box(title = "Dataset Summary", width = 6,
              verbatimTextOutput("summary")
          )
        )
      ),

      
      # TAB 2: Model Training Results
      
      tabItem(tabName = "model",
        fluidRow(
          box(title = "Model Accuracy", width = 6,
              verbatimTextOutput("accuracy")
          ),
          box(title = "Confusion Matrix", width = 6,
              verbatimTextOutput("confMatrix")
          )
        )
      ),

      
      # TAB 3: ROC Curve Visualization
     
      tabItem(tabName = "roc",
        fluidRow(
          box(title = "ROC Curve + AUC", width = 12,
              plotOutput("rocPlot", height = "450px")
          )
        )
      ),

      
      # TAB 4: FEATURE IMPORTANCE
      
      tabItem(tabName = "importance",
        fluidRow(
          box(title = "Coefficient Importance", width = 6,
              plotOutput("coefPlot", height = "400px")
          ),
          box(title = "Odds Ratio Plot", width = 6,
              plotOutput("oddsPlot", height = "400px")
          )
        )
      )
    )
  )
)


# SERVER


server <- function(input, output) {

  #  Load dataset 
  dataInput <- reactive({
    req(input$file)
    df <- read.csv(input$file$datapath)
    df
  })

  #  Preview 
  output$preview <- renderPrint({
    head(dataInput())
  })

  output$summary <- renderPrint({
    summary(dataInput())
  })

  #  Model Training 
  modelResults <- reactive({

    df <- dataInput()
    df$target <- factor(df$target, levels = c(0,1))

    set.seed(123)
    split <- sample.split(df$target, SplitRatio = 0.7)
    train <- subset(df, split == TRUE)
    test  <- subset(df, split == FALSE)

    # Train logistic regression
    model <- glm(target ~ ., data = train, family = binomial)

    # Predictions
    pred_prob <- predict(model, newdata = test, type = "response")
    pred_class <- ifelse(pred_prob > 0.5, 1, 0)
    pred_class <- factor(pred_class, levels = c(0,1))

    # Evaluation
    conf_mat <- confusionMatrix(pred_class, test$target, positive = "1")
    roc_curve <- roc(test$target, pred_prob)

    list(
      model = model,
      confusion = conf_mat,
      accuracy = round(conf_mat$overall["Accuracy"], 4),
      roc = roc_curve,
      train = train,
      test = test
    )
  })

  #  Accuracy 
  output$accuracy <- renderPrint({
    paste("Accuracy:", modelResults()$accuracy)
  })

  # Confusion Matrix 
  output$confMatrix <- renderPrint({
    modelResults()$confusion$table
  })

  #  ROC Curve Plot 
  output$rocPlot <- renderPlot({
    roc_curve <- modelResults()$roc

    plot(
      roc_curve,
      col = "blue",
      lwd = 3,
      main = paste("ROC Curve (AUC =", round(auc(roc_curve), 3), ")")
    )

    abline(a = 0, b = 1, col = "red", lty = 2)
  })

  #  Coefficient Importance Plot 
  output$coefPlot <- renderPlot({
    model <- modelResults()$model

    coef_df <- data.frame(
      Feature = names(coef(model))[-1],
      Coefficient = coef(model)[-1]
    )

    ggplot(coef_df, aes(x = reorder(Feature, Coefficient), y = Coefficient)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      coord_flip() +
      ggtitle("Feature Importance (Logistic Regression Coefficients)") +
      xlab("Features") +
      ylab("Coefficient Value")
  })

  # Odds Ratio Plot 
  output$oddsPlot <- renderPlot({
    model <- modelResults()$model
    odds <- exp(coef(model))

    odds_df <- data.frame(
      Feature = names(odds)[-1],
      OddsRatio = odds[-1]
    )

    ggplot(odds_df, aes(x = reorder(Feature, OddsRatio), y = OddsRatio)) +
      geom_bar(stat = "identity", fill = "darkgreen") +
      coord_flip() +
      ggtitle("Odds Ratio of Features (Risk Indicator)") +
      xlab("Features") +
      ylab("Odds Ratio")
  })
}


# RUN APP

shinyApp(ui, server)
