# ============================================================================
# AI CLASSROOM MONITORING SYSTEM - COMPLETE DASHBOARD
# Doctor Portal & Student Portal
# ============================================================================

library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)
library(shinyWidgets)
library(lubridate)

# ============================================================================
# DATA LOADING FROM INTEGRATED PROJECT CSV FILES
# ============================================================================

set.seed(123)

# Students Data (from integrated repository file)
students_raw <- read.csv("students.csv", stringsAsFactors = FALSE, check.names = FALSE)
names(students_raw) <- trimws(names(students_raw))
names_clean <- tolower(gsub("[^a-z0-9]+", "", iconv(names(students_raw), to = "ASCII//TRANSLIT")))
id_col <- names(students_raw)[match("studentid", names_clean)]
name_col <- names(students_raw)[match("studentname", names_clean)]
if (is.na(id_col) || is.na(name_col)) {
  id_col <- names(students_raw)[1]
  name_col <- names(students_raw)[2]
}

students_data <- students_raw %>%
  transmute(
    Student_ID = trimws(as.character(.data[[id_col]])),
    Student_Name = trimws(as.character(.data[[name_col]]))
  ) %>%
  filter(Student_ID != "", Student_Name != "") %>%
  distinct(Student_ID, .keep_all = TRUE) %>%
  mutate(
    Email = paste0("student", Student_ID, "@university.edu"),
    Password = "student123",
    Department = rep(c("Computer Science", "Engineering", "Medicine"), length.out = n()),
    Year = rep(c("Year 1", "Year 2", "Year 3", "Year 4"), length.out = n())
  )

# Doctors Data
doctors_data <- data.frame(
  Doctor_ID = c(2001, 2002),
  Doctor_Name = c("Dr. Mohamed Fathy", "Dr. Samira Khalil"),
  Email = c("mohamed.fathy@university.edu", "samira.khalil@university.edu"),
  Password = c("doctor123", "doctor123"),
  Department = c("Computer Science", "Computer Science"),
  Specialization = c("Advanced Statistics", "Data Science"),
  stringsAsFactors = FALSE
)

# Ensure removed doctor names are not present
doctors_data <- doctors_data %>%
  filter(!grepl("Ahmed Alyasergy", Doctor_Name, ignore.case = TRUE))

# Subjects Data
subjects_data <- data.frame(
  Subject_ID = c("CS101", "CS102", "CS201", "CS202", "CS301"),
  Subject_Name = c("Introduction to Programming", "Advanced Statistics", "Artificial Intelligence",
                   "Machine Learning", "Computer Vision"),
  Doctor_ID = c(2001, 2001, 2001, 2002, 2002),
  Credits = c(3, 4, 3, 4, 3),
  Semester = c("Fall 2026", "Fall 2026", "Spring 2026", "Spring 2026", "Fall 2026"),
  stringsAsFactors = FALSE
)

# Student Enrollments
enrollments <- expand.grid(
  Student_ID = students_data$Student_ID,
  Subject_ID = subjects_data$Subject_ID
) %>%
  sample_n(nrow(students_data) * nrow(subjects_data))

# Generate Attendance Data (30 days of classes)
attendance_data <- data.frame()
for(i in 1:nrow(enrollments)) {
  for(day in 1:30) {
    attendance_data <- rbind(attendance_data, data.frame(
      Student_ID = enrollments$Student_ID[i],
      Subject_ID = enrollments$Subject_ID[i],
      Date = Sys.Date() - days(30 - day),
      Status = sample(c("Present", "Absent", "Late"), 1, prob = c(0.75, 0.15, 0.10)),
      Time = paste0(sample(8:16, 1), ":", sample(c("00", "30"), 1)),
      stringsAsFactors = FALSE
    ))
  }
}

normalize_name <- function(x) {
  x[is.na(x)] <- ""
  x <- trimws(x)
  x <- gsub("\\s+", " ", x)
  tolower(x)
}

featured_students <- unique(c(
  "نور احمد محمد", "احمد فوزى الياسرجى", "ريم حسين حسن", "ادهم هانى اسماعيل",
  "nour ahmed moahmed", "nour ahmed mohamed", "ahmed fawzy alyasergy", "reem hussein", "adham hany"
))
featured_ids <- students_data %>%
  mutate(Student_Name_Normalized = normalize_name(Student_Name)) %>%
  filter(Student_Name_Normalized %in% normalize_name(featured_students)) %>%
  pull(Student_ID)

if(length(featured_ids) > 0) {
  attendance_data <- attendance_data %>%
    mutate(
      Status = ifelse(
        Student_ID %in% featured_ids,
        sample(c("Present", "Late", "Absent"), n(), replace = TRUE, prob = c(0.86, 0.10, 0.04)),
        Status
      )
    )
}

# Emotion Log Data (from integrated repository file)
emotion_data <- read.csv("emotion_log.csv", stringsAsFactors = FALSE) %>%
  mutate(
    Student_ID = trimws(as.character(Student_ID)),
    Time = trimws(as.character(Time)),
    Emotion = tools::toTitleCase(tolower(trimws(as.character(Emotion)))),
    Confidence = suppressWarnings(as.numeric(Confidence)),
    Confidence = ifelse(is.na(Confidence), 0.75, pmin(pmax(Confidence, 0), 1)),
    Lecture_ID = trimws(as.character(Lecture_ID))
  ) %>%
  filter(Student_ID != "", Emotion != "", Lecture_ID != "") %>%
  filter(Student_ID %in% students_data$Student_ID) %>%
  mutate(
    Lecture_ID = ifelse(Lecture_ID %in% subjects_data$Subject_ID,
                        Lecture_ID,
                        sample(subjects_data$Subject_ID, n(), replace = TRUE)),
    Date = Sys.Date() - days((row_number() - 1) %% 30)
  )

if(length(featured_ids) > 0) {
  emotion_data <- emotion_data %>%
    mutate(
      Student_ID = ifelse(runif(n()) < 0.35, sample(featured_ids, n(), replace = TRUE), Student_ID),
      Emotion = ifelse(
        Student_ID %in% featured_ids,
        sample(c("Focused", "Happy", "Neutral", "Surprised", "Sad", "Angry"), n(), replace = TRUE,
               prob = c(0.42, 0.30, 0.18, 0.05, 0.03, 0.02)),
        Emotion
      ),
      Confidence = ifelse(Student_ID %in% featured_ids, round(runif(n(), 0.82, 0.99), 2), Confidence)
    )
}

# ============================================================================
# UI DEFINITION
# ============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = span(
      icon("graduation-cap"),
      "AI Classroom System"
    ),
    titleWidth = 280
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "sidebar",
      
      # Login Section
      conditionalPanel(
        condition = "output.logged_in == false",
        div(
          style = "padding: 20px;",
          h4("Login Portal", style = "color: white; text-align: center;"),
          selectInput("user_type", "Login as:", 
                     choices = c("Doctor", "Student"),
                     selected = "Doctor"),
          textInput("email", "Email:", placeholder = "Enter email"),
          passwordInput("password", "Password:", placeholder = "Enter password"),
          actionButton("login_btn", "Login", 
                      class = "btn-primary btn-block",
                      icon = icon("sign-in-alt")),
          div(style = "margin-top: 15px; padding: 10px; background: rgba(255,255,255,0.1); border-radius: 5px;",
              h5("Demo Credentials:", style = "color: #fff; margin-bottom: 10px;"),
              p(style = "color: #ddd; font-size: 11px; margin: 3px 0;", 
                strong("Doctor:"), br(),
                "Email: mohamed.fathy@university.edu", br(),
                "Password: doctor123"),
              p(style = "color: #ddd; font-size: 11px; margin: 3px 0;", 
                strong("Student:"), br(),
                "Email: student231014666@university.edu", br(),
                "Password: student123")
          )
        )
      ),
      
      # Doctor Menu
      conditionalPanel(
        condition = "output.logged_in == true && output.is_doctor == true",
        menuItem("Dashboard", tabName = "doctor_dashboard", icon = icon("tachometer-alt")),
        menuItem("My Subjects", tabName = "doctor_subjects", icon = icon("book")),
        menuItem("Students Analytics", tabName = "doctor_analytics", icon = icon("chart-line")),
        menuItem("Attendance Tracking", tabName = "doctor_attendance", icon = icon("clipboard-check")),
        menuItem("Emotion Analysis", tabName = "doctor_emotions", icon = icon("smile")),
        menuItem("Student Details", tabName = "doctor_students", icon = icon("users")),
        hr(),
        actionButton("logout_btn", "Logout", icon = icon("sign-out-alt"), 
                    class = "btn-danger", style = "margin: 10px 20px;")
      ),
      
      # Student Menu
      conditionalPanel(
        condition = "output.logged_in == true && output.is_doctor == false",
        menuItem("My Dashboard", tabName = "student_dashboard", icon = icon("home")),
        menuItem("My Subjects", tabName = "student_subjects", icon = icon("book-open")),
        menuItem("My Attendance", tabName = "student_attendance", icon = icon("calendar-check")),
        menuItem("Performance", tabName = "student_performance", icon = icon("chart-bar")),
        hr(),
        actionButton("logout_btn_student", "Logout", icon = icon("sign-out-alt"), 
                    class = "btn-danger", style = "margin: 10px 20px;")
      )
    )
  ),
  
  # Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #ecf0f5; }
        .box { border-top: 3px solid #3c8dbc; }
        .info-box { min-height: 90px; }
        .info-box-icon { border-radius: 5px 0 0 5px; }
        .small-box { border-radius: 5px; }
        .small-box .icon { font-size: 70px; }
        .nav-tabs-custom { box-shadow: 0 1px 3px rgba(0,0,0,0.12); }
        .login-box { margin-top: 50px; }
        .table-hover tbody tr:hover { background-color: #f5f5f5; }
        .stat-card { transition: all 0.3s; }
        .stat-card:hover { transform: translateY(-5px); box-shadow: 0 5px 15px rgba(0,0,0,0.3); }
      "))
    ),
    
    tabItems(
      # ========== DOCTOR DASHBOARD ==========
      tabItem(
        tabName = "doctor_dashboard",
        fluidRow(
          box(
            width = 12,
            title = textOutput("doctor_welcome"),
            status = "primary",
            solidHeader = TRUE
          )
        ),
        
        fluidRow(
          valueBoxOutput("total_students_box", width = 3),
          valueBoxOutput("total_subjects_box", width = 3),
          valueBoxOutput("avg_attendance_box", width = 3),
          valueBoxOutput("active_classes_box", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Attendance Overview (Last 30 Days)",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("doctor_attendance_chart", height = 300)
          ),
          box(
            title = "Subject Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("doctor_subject_dist", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "Emotion Trends",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("doctor_emotion_chart", height = 300)
          ),
          box(
            title = "Top Performers",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            DTOutput("top_performers_table")
          )
        )
      ),
      
      # ========== DOCTOR SUBJECTS ==========
      tabItem(
        tabName = "doctor_subjects",
        fluidRow(
          box(
            title = "My Subjects",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("doctor_subjects_table")
          )
        ),
        fluidRow(
          box(
            title = "Subject Statistics",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("subject_stats_chart", height = 400)
          )
        )
      ),
      
      # ========== DOCTOR ANALYTICS ==========
      tabItem(
        tabName = "doctor_analytics",
        fluidRow(
          box(
            title = "Filter Options",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(4, selectInput("analytics_subject", "Select Subject:", 
                                   choices = NULL)),
              column(4, dateRangeInput("analytics_date_range", "Date Range:",
                                       start = Sys.Date() - 30,
                                       end = Sys.Date())),
              column(4, br(), actionButton("apply_filter", "Apply Filter", 
                                          class = "btn-success",
                                          icon = icon("filter")))
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Student Performance Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("performance_distribution", height = 350)
          ),
          box(
            title = "Attendance vs Engagement",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("attendance_engagement", height = 350)
          )
        ),
        
        fluidRow(
          box(
            title = "Detailed Analytics Table",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("analytics_detailed_table")
          )
        )
      ),
      
      # ========== DOCTOR ATTENDANCE ==========
      tabItem(
        tabName = "doctor_attendance",
        fluidRow(
          box(
            title = "Attendance Tracking",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(6, selectInput("attendance_subject", "Select Subject:", 
                                   choices = NULL)),
              column(6, dateInput("attendance_date", "Select Date:", 
                                 value = Sys.Date()))
            )
          )
        ),
        
        fluidRow(
          infoBoxOutput("present_count", width = 3),
          infoBoxOutput("absent_count", width = 3),
          infoBoxOutput("late_count", width = 3),
          infoBoxOutput("attendance_rate", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Attendance Details",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("attendance_details_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Attendance Trend (Last 30 Days)",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("attendance_trend_chart", height = 350)
          )
        )
      ),
      
      # ========== DOCTOR EMOTIONS ==========
      tabItem(
        tabName = "doctor_emotions",
        fluidRow(
          box(
            title = "Emotion Analysis Dashboard",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            selectInput("emotion_subject", "Select Subject:", choices = NULL)
          )
        ),
        
        fluidRow(
          valueBoxOutput("happy_percentage", width = 3),
          valueBoxOutput("focused_percentage", width = 3),
          valueBoxOutput("neutral_percentage", width = 3),
          valueBoxOutput("negative_percentage", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Emotion Distribution",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("emotion_pie_chart", height = 350)
          ),
          box(
            title = "Emotion Timeline",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("emotion_timeline", height = 350)
          )
        ),
        
        fluidRow(
          box(
            title = "Student Emotion Details",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("emotion_details_table")
          )
        )
      ),
      
      # ========== DOCTOR STUDENTS ==========
      tabItem(
        tabName = "doctor_students",
        fluidRow(
          box(
            title = "Student Directory",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("students_directory_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Student Details",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            uiOutput("student_detail_panel")
          )
        )
      ),
      
      # ========== STUDENT DASHBOARD ==========
      tabItem(
        tabName = "student_dashboard",
        fluidRow(
          box(
            width = 12,
            title = textOutput("student_welcome"),
            status = "primary",
            solidHeader = TRUE
          )
        ),
        
        fluidRow(
          valueBoxOutput("student_total_subjects", width = 3),
          valueBoxOutput("student_attendance_rate", width = 3),
          valueBoxOutput("student_classes_attended", width = 3),
          valueBoxOutput("student_classes_missed", width = 3)
        ),
        
        fluidRow(
          box(
            title = "My Attendance Overview",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("student_attendance_overview", height = 300)
          ),
          box(
            title = "Attendance by Subject",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            plotlyOutput("student_subject_attendance", height = 300)
          )
        ),
        
        fluidRow(
          box(
            title = "Recent Activity",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            DTOutput("student_recent_activity")
          )
        )
      ),
      
      # ========== STUDENT SUBJECTS ==========
      tabItem(
        tabName = "student_subjects",
        fluidRow(
          box(
            title = "My Enrolled Subjects",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("student_subjects_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Subject Credits Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("student_credits_chart", height = 300)
          ),
          box(
            title = "Semester Overview",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("student_semester_chart", height = 300)
          )
        )
      ),
      
      # ========== STUDENT ATTENDANCE ==========
      tabItem(
        tabName = "student_attendance",
        fluidRow(
          box(
            title = "My Attendance Records",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(6, selectInput("student_attendance_subject", "Select Subject:", 
                                   choices = NULL)),
              column(6, dateRangeInput("student_attendance_range", "Date Range:",
                                       start = Sys.Date() - 30,
                                       end = Sys.Date()))
            )
          )
        ),
        
        fluidRow(
          infoBoxOutput("student_present_days", width = 4),
          infoBoxOutput("student_absent_days", width = 4),
          infoBoxOutput("student_late_days", width = 4)
        ),
        
        fluidRow(
          box(
            title = "Attendance Details",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("student_attendance_table")
          )
        ),
        
        fluidRow(
          box(
            title = "Attendance Calendar",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("student_attendance_calendar", height = 400)
          )
        )
      ),
      
      # ========== STUDENT PERFORMANCE ==========
      tabItem(
        tabName = "student_performance",
        fluidRow(
          box(
            title = "My Performance Summary",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h4("Overall Statistics")
          )
        ),
        
        fluidRow(
          box(
            title = "Attendance Rate by Subject",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("student_performance_by_subject", height = 350)
          ),
          box(
            title = "Attendance Trend",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("student_performance_trend", height = 350)
          )
        ),
        
        fluidRow(
          box(
            title = "Performance Insights",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            uiOutput("performance_insights")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER LOGIC
# ============================================================================

server <- function(input, output, session) {
  
  # ========== AUTHENTICATION ==========
  user_data <- reactiveValues(
    logged_in = FALSE,
    is_doctor = FALSE,
    user_id = NULL,
    user_name = NULL,
    user_email = NULL
  )
  
  output$logged_in <- reactive({ user_data$logged_in })
  output$is_doctor <- reactive({ user_data$is_doctor })
  outputOptions(output, "logged_in", suspendWhenHidden = FALSE)
  outputOptions(output, "is_doctor", suspendWhenHidden = FALSE)
  
  # Login Handler
  observeEvent(input$login_btn, {
    if(input$user_type == "Doctor") {
      doctor <- doctors_data %>% 
        filter(Email == input$email, Password == input$password)
      
      if(nrow(doctor) > 0) {
        user_data$logged_in <- TRUE
        user_data$is_doctor <- TRUE
        user_data$user_id <- doctor$Doctor_ID[1]
        user_data$user_name <- doctor$Doctor_Name[1]
        user_data$user_email <- doctor$Email[1]
        
        showNotification("Login successful! Welcome Doctor.", type = "message")
        updateTabItems(session, "sidebar", "doctor_dashboard")
      } else {
        showNotification("Invalid credentials. Please try again.", type = "error")
      }
    } else {
      student <- students_data %>% 
        filter(Email == input$email, Password == input$password)
      
      if(nrow(student) > 0) {
        user_data$logged_in <- TRUE
        user_data$is_doctor <- FALSE
        user_data$user_id <- student$Student_ID[1]
        user_data$user_name <- student$Student_Name[1]
        user_data$user_email <- student$Email[1]
        
        showNotification("Login successful! Welcome Student.", type = "message")
        updateTabItems(session, "sidebar", "student_dashboard")
      } else {
        showNotification("Invalid credentials. Please try again.", type = "error")
      }
    }
  })
  
  # Logout Handlers
  observeEvent(input$logout_btn, {
    user_data$logged_in <- FALSE
    user_data$is_doctor <- FALSE
    user_data$user_id <- NULL
    user_data$user_name <- NULL
    user_data$user_email <- NULL
    showNotification("Logged out successfully.", type = "message")
  })
  
  observeEvent(input$logout_btn_student, {
    user_data$logged_in <- FALSE
    user_data$is_doctor <- FALSE
    user_data$user_id <- NULL
    user_data$user_name <- NULL
    user_data$user_email <- NULL
    showNotification("Logged out successfully.", type = "message")
  })
  
  # ========== DOCTOR DASHBOARD ==========
  
  output$doctor_welcome <- renderText({
    req(user_data$logged_in, user_data$is_doctor)
    paste("Welcome,", user_data$user_name, "| Dashboard Overview")
  })
  
  # Get doctor's subjects
  doctor_subjects <- reactive({
    req(user_data$logged_in, user_data$is_doctor)
    subjects_data %>% filter(Doctor_ID == user_data$user_id)
  })
  
  # Get students enrolled in doctor's subjects
  doctor_students <- reactive({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- enrollments %>% 
      filter(Subject_ID %in% subject_ids) %>% 
      pull(Student_ID) %>% 
      unique()
    students_data %>% filter(Student_ID %in% student_ids)
  })
  
  output$total_students_box <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    valueBox(
      nrow(doctor_students()),
      "Total Students",
      icon = icon("users"),
      color = "aqua"
    )
  })
  
  output$total_subjects_box <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    valueBox(
      nrow(doctor_subjects()),
      "Subjects Teaching",
      icon = icon("book"),
      color = "green"
    )
  })
  
  output$avg_attendance_box <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    att_data <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids)
    
    if(nrow(att_data) > 0) {
      avg_att <- round(sum(att_data$Status == "Present") / nrow(att_data) * 100, 1)
    } else {
      avg_att <- 0
    }
    
    valueBox(
      paste0(avg_att, "%"),
      "Average Attendance",
      icon = icon("check-circle"),
      color = if(avg_att >= 75) "green" else if(avg_att >= 60) "yellow" else "red"
    )
  })
  
  output$active_classes_box <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    valueBox(
      30,
      "Classes Conducted",
      icon = icon("chalkboard-teacher"),
      color = "purple"
    )
  })
  
  output$doctor_attendance_chart <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    att_summary <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Date, Status) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(att_summary, x = ~Date, y = ~Count, color = ~Status,
            type = "scatter", mode = "lines+markers",
            colors = c("Present" = "#00a65a", "Absent" = "#dd4b39", "Late" = "#f39c12")) %>%
      layout(title = "",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Number of Students"),
             hovermode = "x unified")
  })
  
  output$doctor_subject_dist <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    enrollment_count <- enrollments %>%
      filter(Subject_ID %in% subject_ids) %>%
      group_by(Subject_ID) %>%
      summarise(Students = n(), .groups = "drop") %>%
      left_join(subjects_data, by = "Subject_ID")
    
    plot_ly(enrollment_count, labels = ~Subject_Name, values = ~Students,
            type = "pie", hole = 0.4,
            marker = list(colors = c('#3c8dbc', '#00a65a', '#f39c12', '#dd4b39', '#605ca8'))) %>%
      layout(title = "")
  })
  
  output$doctor_emotion_chart <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    emotion_summary <- emotion_data %>%
      filter(Lecture_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Emotion) %>%
      summarise(Count = n(), .groups = "drop") %>%
      arrange(desc(Count))
    
    plot_ly(emotion_summary, x = ~Emotion, y = ~Count, type = "bar",
            marker = list(color = c('#00a65a', '#3c8dbc', '#f39c12', '#dd4b39', '#605ca8', '#00c0ef'))) %>%
      layout(title = "",
             xaxis = list(title = "Emotion"),
             yaxis = list(title = "Frequency"))
  })
  
  output$top_performers_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    top_students <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Student_ID) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        Attendance = round(Present/Total * 100, 1),
        .groups = "drop"
      ) %>%
      arrange(desc(Attendance)) %>%
      head(10) %>%
      left_join(students_data, by = "Student_ID") %>%
      select(Student_Name, Department, Attendance)
    
    datatable(top_students,
              options = list(pageLength = 10, dom = 't'),
              rownames = FALSE,
              colnames = c("Student", "Department", "Attendance %"))
  })
  
  # ========== DOCTOR SUBJECTS ==========
  
  # Update subject selectors
  observe({
    req(user_data$logged_in, user_data$is_doctor)
    subjects <- doctor_subjects()
    choices <- setNames(subjects$Subject_ID, subjects$Subject_Name)
    
    updateSelectInput(session, "analytics_subject", choices = c("All Subjects" = "all", choices))
    updateSelectInput(session, "attendance_subject", choices = choices)
    updateSelectInput(session, "emotion_subject", choices = c("All Subjects" = "all", choices))
  })
  
  output$doctor_subjects_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor)
    
    subjects <- doctor_subjects() %>%
      mutate(
        Enrolled_Students = sapply(Subject_ID, function(sid) {
          nrow(enrollments %>% filter(Subject_ID == sid))
        })
      ) %>%
      select(Subject_ID, Subject_Name, Credits, Semester, Enrolled_Students)
    
    datatable(subjects,
              options = list(pageLength = 10, dom = 'tp'),
              rownames = FALSE,
              colnames = c("Code", "Subject Name", "Credits", "Semester", "Students"))
  })
  
  output$subject_stats_chart <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    stats <- attendance_data %>%
      filter(Subject_ID %in% subject_ids) %>%
      group_by(Subject_ID) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        Absent = sum(Status == "Absent"),
        Late = sum(Status == "Late"),
        Attendance_Rate = round(Present/Total * 100, 1),
        .groups = "drop"
      ) %>%
      left_join(subjects_data, by = "Subject_ID")
    
    plot_ly(stats) %>%
      add_trace(x = ~Subject_Name, y = ~Present, name = "Present", type = "bar",
                marker = list(color = '#00a65a')) %>%
      add_trace(x = ~Subject_Name, y = ~Late, name = "Late", type = "bar",
                marker = list(color = '#f39c12')) %>%
      add_trace(x = ~Subject_Name, y = ~Absent, name = "Absent", type = "bar",
                marker = list(color = '#dd4b39')) %>%
      layout(barmode = "stack",
             xaxis = list(title = "Subject"),
             yaxis = list(title = "Number of Records"))
  })
  
  # ========== DOCTOR ANALYTICS ==========
  
  output$performance_distribution <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    perf_data <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Student_ID) %>%
      summarise(
        Attendance_Rate = round(sum(Status == "Present")/n() * 100, 1),
        .groups = "drop"
      )
    
    plot_ly(perf_data, x = ~Attendance_Rate, type = "histogram",
            marker = list(color = '#3c8dbc', line = list(color = '#fff', width = 1))) %>%
      layout(title = "",
             xaxis = list(title = "Attendance Rate (%)"),
             yaxis = list(title = "Number of Students"))
  })
  
  output$attendance_engagement <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    combined_data <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Student_ID) %>%
      summarise(Attendance = round(sum(Status == "Present")/n() * 100, 1), .groups = "drop") %>%
      left_join(
        emotion_data %>%
          filter(Lecture_ID %in% subject_ids, Student_ID %in% student_ids) %>%
          filter(Emotion %in% c("Happy", "Focused")) %>%
          group_by(Student_ID) %>%
          summarise(Engagement = n(), .groups = "drop"),
        by = "Student_ID"
      ) %>%
      mutate(Engagement = replace_na(Engagement, 0)) %>%
      left_join(students_data, by = "Student_ID")
    
    plot_ly(combined_data, x = ~Attendance, y = ~Engagement, text = ~Student_Name,
            type = "scatter", mode = "markers",
            marker = list(size = 10, color = '#00a65a', opacity = 0.7)) %>%
      layout(title = "",
             xaxis = list(title = "Attendance Rate (%)"),
             yaxis = list(title = "Engagement Score"))
  })
  
  output$analytics_detailed_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    detailed <- attendance_data %>%
      filter(Subject_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Student_ID) %>%
      summarise(
        Total_Classes = n(),
        Present = sum(Status == "Present"),
        Absent = sum(Status == "Absent"),
        Late = sum(Status == "Late"),
        Attendance_Rate = round(Present/Total_Classes * 100, 1),
        .groups = "drop"
      ) %>%
      left_join(students_data, by = "Student_ID") %>%
      select(Student_Name, Department, Total_Classes, Present, Absent, Late, Attendance_Rate) %>%
      arrange(desc(Attendance_Rate))
    
    datatable(detailed,
              options = list(pageLength = 15, dom = 'ftip'),
              rownames = FALSE,
              colnames = c("Student", "Department", "Total", "Present", "Absent", "Late", "Rate (%)")) %>%
      formatStyle('Attendance_Rate',
                  backgroundColor = styleInterval(c(60, 75), c('#dd4b39', '#f39c12', '#00a65a')),
                  color = 'white')
  })
  
  # ========== DOCTOR ATTENDANCE ==========
  
  output$present_count <- renderInfoBox({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    count <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date == input$attendance_date,
             Status == "Present") %>%
      nrow()
    
    infoBox("Present", count, icon = icon("check"), color = "green")
  })
  
  output$absent_count <- renderInfoBox({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    count <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date == input$attendance_date,
             Status == "Absent") %>%
      nrow()
    
    infoBox("Absent", count, icon = icon("times"), color = "red")
  })
  
  output$late_count <- renderInfoBox({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    count <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date == input$attendance_date,
             Status == "Late") %>%
      nrow()
    
    infoBox("Late", count, icon = icon("clock"), color = "yellow")
  })
  
  output$attendance_rate <- renderInfoBox({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    att <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date == input$attendance_date)
    
    if(nrow(att) > 0) {
      rate <- round(sum(att$Status == "Present") / nrow(att) * 100, 1)
    } else {
      rate <- 0
    }
    
    infoBox("Attendance Rate", paste0(rate, "%"), icon = icon("percentage"),
            color = if(rate >= 75) "green" else if(rate >= 60) "yellow" else "red")
  })
  
  output$attendance_details_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    details <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date == input$attendance_date) %>%
      left_join(students_data, by = "Student_ID") %>%
      select(Student_Name, Status, Time) %>%
      arrange(Student_Name)
    
    datatable(details,
              options = list(pageLength = 20, dom = 'ftip'),
              rownames = FALSE,
              colnames = c("Student Name", "Status", "Time")) %>%
      formatStyle('Status',
                  backgroundColor = styleEqual(c('Present', 'Absent', 'Late'),
                                              c('#00a65a', '#dd4b39', '#f39c12')),
                  color = 'white')
  })
  
  output$attendance_trend_chart <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor, input$attendance_subject)
    
    trend <- attendance_data %>%
      filter(Subject_ID == input$attendance_subject,
             Date >= (Sys.Date() - 30)) %>%
      group_by(Date) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        Rate = round(Present/Total * 100, 1),
        .groups = "drop"
      )
    
    plot_ly(trend, x = ~Date, y = ~Rate, type = "scatter", mode = "lines+markers",
            line = list(color = '#3c8dbc', width = 3),
            marker = list(size = 8, color = '#00a65a')) %>%
      layout(title = "",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Attendance Rate (%)"))
  })
  
  # ========== DOCTOR EMOTIONS ==========
  
  output$happy_percentage <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    total <- emotion_data %>% filter(Lecture_ID %in% subject_ids) %>% nrow()
    happy <- emotion_data %>% filter(Lecture_ID %in% subject_ids, Emotion == "Happy") %>% nrow()
    pct <- if(total > 0) round(happy/total * 100, 1) else 0
    
    valueBox(paste0(pct, "%"), "Happy", icon = icon("smile"), color = "green")
  })
  
  output$focused_percentage <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    total <- emotion_data %>% filter(Lecture_ID %in% subject_ids) %>% nrow()
    focused <- emotion_data %>% filter(Lecture_ID %in% subject_ids, Emotion == "Focused") %>% nrow()
    pct <- if(total > 0) round(focused/total * 100, 1) else 0
    
    valueBox(paste0(pct, "%"), "Focused", icon = icon("brain"), color = "blue")
  })
  
  output$neutral_percentage <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    total <- emotion_data %>% filter(Lecture_ID %in% subject_ids) %>% nrow()
    neutral <- emotion_data %>% filter(Lecture_ID %in% subject_ids, Emotion == "Neutral") %>% nrow()
    pct <- if(total > 0) round(neutral/total * 100, 1) else 0
    
    valueBox(paste0(pct, "%"), "Neutral", icon = icon("meh"), color = "yellow")
  })
  
  output$negative_percentage <- renderValueBox({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    total <- emotion_data %>% filter(Lecture_ID %in% subject_ids) %>% nrow()
    negative <- emotion_data %>% 
      filter(Lecture_ID %in% subject_ids, Emotion %in% c("Sad", "Angry")) %>% nrow()
    pct <- if(total > 0) round(negative/total * 100, 1) else 0
    
    valueBox(paste0(pct, "%"), "Negative", icon = icon("frown"), color = "red")
  })
  
  output$emotion_pie_chart <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    emotion_summary <- emotion_data %>%
      filter(Lecture_ID %in% subject_ids) %>%
      group_by(Emotion) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(emotion_summary, labels = ~Emotion, values = ~Count, type = "pie",
            marker = list(colors = c('#00a65a', '#dd4b39', '#605ca8', '#3c8dbc', '#f39c12', '#00c0ef'))) %>%
      layout(title = "")
  })
  
  output$emotion_timeline <- renderPlotly({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    
    timeline <- emotion_data %>%
      filter(Lecture_ID %in% subject_ids) %>%
      group_by(Date, Emotion) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(timeline, x = ~Date, y = ~Count, color = ~Emotion, type = "scatter", mode = "lines",
            colors = c('#00a65a', '#dd4b39', '#605ca8', '#3c8dbc', '#f39c12', '#00c0ef')) %>%
      layout(title = "",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Frequency"))
  })
  
  output$emotion_details_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor)
    subject_ids <- doctor_subjects()$Subject_ID
    student_ids <- doctor_students()$Student_ID
    
    details <- emotion_data %>%
      filter(Lecture_ID %in% subject_ids, Student_ID %in% student_ids) %>%
      group_by(Student_ID) %>%
      summarise(
        Total_Records = n(),
        Happy = sum(Emotion == "Happy"),
        Focused = sum(Emotion == "Focused"),
        Neutral = sum(Emotion == "Neutral"),
        Negative = sum(Emotion %in% c("Sad", "Angry")),
        Avg_Confidence = round(mean(Confidence), 2),
        .groups = "drop"
      ) %>%
      left_join(students_data, by = "Student_ID") %>%
      select(Student_Name, Total_Records, Happy, Focused, Neutral, Negative, Avg_Confidence) %>%
      arrange(desc(Focused))
    
    datatable(details,
              options = list(pageLength = 15, dom = 'ftip'),
              rownames = FALSE)
  })
  
  # ========== DOCTOR STUDENTS ==========
  
  output$students_directory_table <- renderDT({
    req(user_data$logged_in, user_data$is_doctor)
    
    student_list <- doctor_students() %>%
      select(Student_ID, Student_Name, Email, Department, Year)
    
    datatable(student_list,
              options = list(pageLength = 20, dom = 'ftip'),
              rownames = FALSE,
              selection = 'single')
  })
  
  output$student_detail_panel <- renderUI({
    req(user_data$logged_in, user_data$is_doctor)
    selected <- input$students_directory_table_rows_selected
    
    if(length(selected) > 0) {
      student <- doctor_students()[selected, ]
      subject_ids <- doctor_subjects()$Subject_ID
      
      att <- attendance_data %>%
        filter(Student_ID == student$Student_ID, Subject_ID %in% subject_ids) %>%
        summarise(
          Total = n(),
          Present = sum(Status == "Present"),
          Rate = round(Present/Total * 100, 1)
        )
      
      tagList(
        fluidRow(
          column(4,
                 h4(icon("user"), student$Student_Name),
                 p(strong("ID:"), student$Student_ID),
                 p(strong("Email:"), student$Email),
                 p(strong("Department:"), student$Department),
                 p(strong("Year:"), student$Year)
          ),
          column(8,
                 h4("Attendance Statistics"),
                 fluidRow(
                   column(4,
                          div(class = "info-box bg-aqua",
                              div(class = "info-box-content",
                                  span(class = "info-box-text", "Total Classes"),
                                  span(class = "info-box-number", att$Total)
                              )
                          )
                   ),
                   column(4,
                          div(class = "info-box bg-green",
                              div(class = "info-box-content",
                                  span(class = "info-box-text", "Present"),
                                  span(class = "info-box-number", att$Present)
                              )
                          )
                   ),
                   column(4,
                          div(class = "info-box bg-yellow",
                              div(class = "info-box-content",
                                  span(class = "info-box-text", "Attendance Rate"),
                                  span(class = "info-box-number", paste0(att$Rate, "%"))
                              )
                          )
                   )
                 )
          )
        )
      )
    } else {
      h4("Select a student from the table above to view details")
    }
  })
  
  # ========== STUDENT DASHBOARD ==========
  
  output$student_welcome <- renderText({
    req(user_data$logged_in, !user_data$is_doctor)
    paste("Welcome,", user_data$user_name, "| My Dashboard")
  })
  
  student_subjects <- reactive({
    req(user_data$logged_in, !user_data$is_doctor)
    subject_ids <- enrollments %>%
      filter(Student_ID == user_data$user_id) %>%
      pull(Subject_ID)
    subjects_data %>% filter(Subject_ID %in% subject_ids)
  })
  
  output$student_total_subjects <- renderValueBox({
    req(user_data$logged_in, !user_data$is_doctor)
    valueBox(
      nrow(student_subjects()),
      "Enrolled Subjects",
      icon = icon("book"),
      color = "blue"
    )
  })
  
  output$student_attendance_rate <- renderValueBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    att <- attendance_data %>%
      filter(Student_ID == user_data$user_id)
    
    if(nrow(att) > 0) {
      rate <- round(sum(att$Status == "Present") / nrow(att) * 100, 1)
    } else {
      rate <- 0
    }
    
    valueBox(
      paste0(rate, "%"),
      "Overall Attendance",
      icon = icon("percentage"),
      color = if(rate >= 75) "green" else if(rate >= 60) "yellow" else "red"
    )
  })
  
  output$student_classes_attended <- renderValueBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    count <- attendance_data %>%
      filter(Student_ID == user_data$user_id, Status == "Present") %>%
      nrow()
    
    valueBox(count, "Classes Attended", icon = icon("check"), color = "green")
  })
  
  output$student_classes_missed <- renderValueBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    count <- attendance_data %>%
      filter(Student_ID == user_data$user_id, Status == "Absent") %>%
      nrow()
    
    valueBox(count, "Classes Missed", icon = icon("times"), color = "red")
  })
  
  output$student_attendance_overview <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    overview <- attendance_data %>%
      filter(Student_ID == user_data$user_id) %>%
      group_by(Date, Status) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(overview, x = ~Date, y = ~Count, color = ~Status, type = "scatter", mode = "lines+markers",
            colors = c("Present" = "#00a65a", "Absent" = "#dd4b39", "Late" = "#f39c12")) %>%
      layout(title = "",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Count"))
  })
  
  output$student_subject_attendance <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    by_subject <- attendance_data %>%
      filter(Student_ID == user_data$user_id) %>%
      group_by(Subject_ID) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        Rate = round(Present/Total * 100, 1),
        .groups = "drop"
      ) %>%
      left_join(subjects_data, by = "Subject_ID")
    
    plot_ly(by_subject, labels = ~Subject_Name, values = ~Rate, type = "pie",
            marker = list(colors = c('#3c8dbc', '#00a65a', '#f39c12', '#dd4b39', '#605ca8'))) %>%
      layout(title = "")
  })
  
  output$student_recent_activity <- renderDT({
    req(user_data$logged_in, !user_data$is_doctor)
    
    recent <- attendance_data %>%
      filter(Student_ID == user_data$user_id) %>%
      arrange(desc(Date)) %>%
      head(20) %>%
      left_join(subjects_data, by = "Subject_ID") %>%
      select(Date, Subject_Name, Status, Time) %>%
      arrange(desc(Date))
    
    datatable(recent,
              options = list(pageLength = 10, dom = 'tp'),
              rownames = FALSE,
              colnames = c("Date", "Subject", "Status", "Time")) %>%
      formatStyle('Status',
                  backgroundColor = styleEqual(c('Present', 'Absent', 'Late'),
                                              c('#00a65a', '#dd4b39', '#f39c12')),
                  color = 'white')
  })
  
  # ========== STUDENT SUBJECTS ==========
  
  observe({
    req(user_data$logged_in, !user_data$is_doctor)
    subjects <- student_subjects()
    choices <- setNames(subjects$Subject_ID, subjects$Subject_Name)
    
    updateSelectInput(session, "student_attendance_subject", 
                     choices = c("All Subjects" = "all", choices))
  })
  
  output$student_subjects_table <- renderDT({
    req(user_data$logged_in, !user_data$is_doctor)
    
    subjects <- student_subjects() %>%
      left_join(doctors_data, by = "Doctor_ID") %>%
      select(Subject_ID, Subject_Name, Doctor_Name, Credits, Semester)
    
    datatable(subjects,
              options = list(pageLength = 10, dom = 'tp'),
              rownames = FALSE,
              colnames = c("Code", "Subject", "Instructor", "Credits", "Semester"))
  })
  
  output$student_credits_chart <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    subjects <- student_subjects()
    
    plot_ly(subjects, labels = ~Subject_Name, values = ~Credits, type = "pie",
            marker = list(colors = c('#3c8dbc', '#00a65a', '#f39c12', '#dd4b39', '#605ca8'))) %>%
      layout(title = "")
  })
  
  output$student_semester_chart <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    by_semester <- student_subjects() %>%
      group_by(Semester) %>%
      summarise(Subjects = n(), Total_Credits = sum(Credits), .groups = "drop")
    
    plot_ly(by_semester, x = ~Semester, y = ~Subjects, type = "bar", name = "Subjects",
            marker = list(color = '#3c8dbc')) %>%
      add_trace(y = ~Total_Credits, name = "Credits", marker = list(color = '#00a65a')) %>%
      layout(barmode = "group",
             xaxis = list(title = ""),
             yaxis = list(title = "Count"))
  })
  
  # ========== STUDENT ATTENDANCE ==========
  
  output$student_present_days <- renderInfoBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    count <- attendance_data %>%
      filter(Student_ID == user_data$user_id,
             Date >= input$student_attendance_range[1],
             Date <= input$student_attendance_range[2],
             Status == "Present") %>%
      nrow()
    
    infoBox("Present Days", count, icon = icon("check-circle"), color = "green", fill = TRUE)
  })
  
  output$student_absent_days <- renderInfoBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    count <- attendance_data %>%
      filter(Student_ID == user_data$user_id,
             Date >= input$student_attendance_range[1],
             Date <= input$student_attendance_range[2],
             Status == "Absent") %>%
      nrow()
    
    infoBox("Absent Days", count, icon = icon("times-circle"), color = "red", fill = TRUE)
  })
  
  output$student_late_days <- renderInfoBox({
    req(user_data$logged_in, !user_data$is_doctor)
    
    count <- attendance_data %>%
      filter(Student_ID == user_data$user_id,
             Date >= input$student_attendance_range[1],
             Date <= input$student_attendance_range[2],
             Status == "Late") %>%
      nrow()
    
    infoBox("Late Days", count, icon = icon("clock"), color = "yellow", fill = TRUE)
  })
  
  output$student_attendance_table <- renderDT({
    req(user_data$logged_in, !user_data$is_doctor)
    
    filter_subject <- input$student_attendance_subject
    
    att_data <- attendance_data %>%
      filter(Student_ID == user_data$user_id,
             Date >= input$student_attendance_range[1],
             Date <= input$student_attendance_range[2])
    
    if(filter_subject != "all") {
      att_data <- att_data %>% filter(Subject_ID == filter_subject)
    }
    
    att_data <- att_data %>%
      left_join(subjects_data, by = "Subject_ID") %>%
      select(Date, Subject_Name, Status, Time) %>%
      arrange(desc(Date))
    
    datatable(att_data,
              options = list(pageLength = 15, dom = 'ftip'),
              rownames = FALSE,
              colnames = c("Date", "Subject", "Status", "Time")) %>%
      formatStyle('Status',
                  backgroundColor = styleEqual(c('Present', 'Absent', 'Late'),
                                              c('#00a65a', '#dd4b39', '#f39c12')),
                  color = 'white')
  })
  
  output$student_attendance_calendar <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    calendar_data <- attendance_data %>%
      filter(Student_ID == user_data$user_id,
             Date >= input$student_attendance_range[1],
             Date <= input$student_attendance_range[2]) %>%
      group_by(Date, Status) %>%
      summarise(Count = n(), .groups = "drop")
    
    plot_ly(calendar_data, x = ~Date, y = ~Count, color = ~Status, type = "bar",
            colors = c("Present" = "#00a65a", "Absent" = "#dd4b39", "Late" = "#f39c12")) %>%
      layout(barmode = "stack",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Classes"))
  })
  
  # ========== STUDENT PERFORMANCE ==========
  
  output$student_performance_by_subject <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    perf <- attendance_data %>%
      filter(Student_ID == user_data$user_id) %>%
      group_by(Subject_ID) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        Rate = round(Present/Total * 100, 1),
        .groups = "drop"
      ) %>%
      left_join(subjects_data, by = "Subject_ID")
    
    plot_ly(perf, x = ~Subject_Name, y = ~Rate, type = "bar",
            marker = list(color = ~Rate, colorscale = list(c(0, "red"), c(0.5, "yellow"), c(1, "green")),
                         line = list(color = '#fff', width = 1))) %>%
      layout(title = "",
             xaxis = list(title = "Subject"),
             yaxis = list(title = "Attendance Rate (%)"))
  })
  
  output$student_performance_trend <- renderPlotly({
    req(user_data$logged_in, !user_data$is_doctor)
    
    # Calculate rolling 7-day attendance rate
    trend <- attendance_data %>%
      filter(Student_ID == user_data$user_id) %>%
      arrange(Date) %>%
      group_by(Date) %>%
      summarise(
        Total = n(),
        Present = sum(Status == "Present"),
        .groups = "drop"
      ) %>%
      mutate(
        Rate = round(Present/Total * 100, 1)
      )
    
    plot_ly(trend, x = ~Date, y = ~Rate, type = "scatter", mode = "lines+markers",
            line = list(color = '#3c8dbc', width = 3),
            marker = list(size = 8, color = '#00a65a')) %>%
      layout(title = "",
             xaxis = list(title = "Date"),
             yaxis = list(title = "Daily Attendance Rate (%)"))
  })
  
  output$performance_insights <- renderUI({
    req(user_data$logged_in, !user_data$is_doctor)
    
    att <- attendance_data %>%
      filter(Student_ID == user_data$user_id)
    
    total <- nrow(att)
    present <- sum(att$Status == "Present")
    rate <- round(present/total * 100, 1)
    
    worst_subject <- att %>%
      group_by(Subject_ID) %>%
      summarise(Rate = round(sum(Status == "Present")/n() * 100, 1), .groups = "drop") %>%
      arrange(Rate) %>%
      head(1) %>%
      left_join(subjects_data, by = "Subject_ID")
    
    best_subject <- att %>%
      group_by(Subject_ID) %>%
      summarise(Rate = round(sum(Status == "Present")/n() * 100, 1), .groups = "drop") %>%
      arrange(desc(Rate)) %>%
      head(1) %>%
      left_join(subjects_data, by = "Subject_ID")
    
    tagList(
      fluidRow(
        column(6,
               div(class = "alert alert-success",
                   h4(icon("trophy"), " Best Subject"),
                   p(strong(best_subject$Subject_Name)),
                   p(paste0("Attendance: ", best_subject$Rate, "%"))
               )
        ),
        column(6,
               div(class = "alert alert-warning",
                   h4(icon("exclamation-triangle"), " Needs Attention"),
                   p(strong(worst_subject$Subject_Name)),
                   p(paste0("Attendance: ", worst_subject$Rate, "%"))
               )
        )
      ),
      fluidRow(
        column(12,
               div(class = if(rate >= 75) "alert alert-info" else "alert alert-danger",
                   h4(icon("info-circle"), " Overall Status"),
                   p(if(rate >= 75) {
                     "Great job! Your attendance is excellent. Keep up the good work!"
                   } else if(rate >= 60) {
                     "Your attendance is acceptable but could be improved. Try to attend more classes regularly."
                   } else {
                     "Warning: Your attendance is below the minimum requirement. Please improve your attendance to avoid academic penalties."
                   })
               )
        )
      )
    )
  })
}

# ============================================================================
# RUN APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server)
