#!/usr/bin/env bash

# Load helper functions and set initial variables
vendir sync
. ./vendir/demo-magic/demo-magic.sh
export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TEMP_DIR="upgrade-example"
PROMPT_TIMEOUT=8

# Function to pause and clear the screen
function talkingPoint() {
  wait
  clear
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  sdk update
  sdk install java 8.0.392-librca
  sdk install java 21.0.1-librca
}

# Prepare the working directory
function init {
  rm -rf "$TEMP_DIR"
  mkdir "$TEMP_DIR"
  cd "$TEMP_DIR" || exit
  clear
}

# Switch to Java 8 and display version
function useJava8 {
  displayMessage "Use Java 8, this is for educational purposes only, don't do this at home! (I have jokes.)"
  pei "sdk use java 8.0.392-librca"
  pei "java -version" 
}

# Switch to Java 21 and display version
function useJava21 {
  displayMessage "Switch to Java 21 for Spring Boot 3"
  pei "sdk use java 21.0.1-librca"
  pei "java -version"
}

# Clone a simple Spring Boot application
function cloneApp {
  displayMessage "Clone a Spring Boot 1.5.0 application. Again, it's a demo, DO NOT USE 1.5.x!"
  pei "git clone https://github.com/dashaun/hello-spring-boot-1-5.git ./"
}

# Start the Spring Boot application
function springBootStart {
  displayMessage "Start the Spring Boot application"
  pei "./mvnw -q clean package spring-boot:start -Dfork=true -DskipTests 2>&1 | tee '$1' &"
}

# Stop the Spring Boot application
function springBootStop {
  displayMessage "Stop the Spring Boot application"
  pei "./mvnw spring-boot:stop -Dfork=true"
}

# Check the health of the application
function validateAppOldPattern {
  displayMessage "Check application health"
  pei "http :8080/health"
}

# Check the health of the application
function validateApp {
  displayMessage "Check application health"
  pei "http :8080/actuator/health"
}

# Display memory usage of the application
function showMemoryUsage {
  local pid=$1
  local log_file=$2
  local rss=$(ps -o rss= "$pid" | tail -n1)
  local mem_usage=$(bc <<< "scale=1; ${rss}/1024")
  echo "The process was using ${mem_usage} megabytes"
  echo "${mem_usage}" >> "$log_file"
}

# Upgrade the application to Spring Boot 3.2
function rewriteApplication {
  displayMessage "Upgrade to Spring Boot 3.2"
  pei "./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST -DactiveRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2"
}

# Display a message with a header
function displayMessage() {
  echo "#### $1"
  echo ""
}

function startupTime() {
  echo "$(sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < $1)"
}

function statsSoFarTable {
  displayMessage "Comparison of memory usage and startup times"
  echo ""

  # Headers
  printf "%-35s %-25s %-15s %s\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
  echo "--------------------------------------------------------------------------------------------"

  # Spring Boot 1.5 with Java 8
  #STARTUP1=$(sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < java8with1.5.log)
  #STARTUP1=$(grep -o 'Started HelloSpringApplication in .*' < java8with1.5.log)
  MEM1=$(cat java8with1.5.log2)
  printf "%-35s %-25s %-15s %s\n" "Spring Boot 1.5 with Java 8" "$(startupTime 'java8with1.5.log')" "$MEM1" "-"

  # Spring Boot 3.2 with Java 21
  #STARTUP2=$(grep -o 'Started HelloSpringApplication in .*' < java21with3.2.log)
  MEM2=$(cat java21with3.2.log2)
  PERC2=$(bc <<< "scale=2; 100 - ${MEM2}/${MEM1}*100")
  printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.2 with Java 21" "$(startupTime 'java21with3.2.log')" "$MEM2" "$PERC2%"
  
  echo "--------------------------------------------------------------------------------------------"
  echo "That's just infrastructure savings, we haven't even started talking about the security yet."
  echo "The latest version is getting OSS security updates."
  echo ""
  echo "Spring Boot 2.5 (or older) is no longer getting support."
  echo "Spring Boot 2.7 OSS support ended 2023-11-24"
  echo "Spring Boot 2.6 commercial support ends 2024-02-24"
  echo "Spring Boot 2.7 commercial support ends 2025-08-24"
  echo ""
  echo "Spring Boot 3.2 was released 2023-11-23, you should be using that now!"
}

# Display Docker image statistics
function imageStats {
  pei "docker images | grep demo"
}

# Main execution flow
initSDKman
init
useJava8
talkingPoint
cloneApp
talkingPoint
springBootStart java8with1.5.log
talkingPoint
validateAppOldPattern
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" java8with1.5.log2
talkingPoint
springBootStop
talkingPoint
rewriteApplication
talkingPoint
useJava21
talkingPoint
springBootStart java21with3.2.log
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" java21with3.2.log2
talkingPoint
springBootStop
talkingPoint
statsSoFarTable
