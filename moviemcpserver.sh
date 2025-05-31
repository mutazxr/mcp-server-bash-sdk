#!/bin/bash
# Movie business logic implementation

# Override configuration paths BEFORE sourcing the core
MCP_CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/assets/movieserver_config.json"
MCP_TOOLS_LIST_FILE="$(dirname "${BASH_SOURCE[0]}")/assets/movieserver_tools.json"
MCP_LOG_FILE="$(dirname "${BASH_SOURCE[0]}")/logs/movieserver.log"

# MCP Server Tool Function Guidelines:
# 1. Name all tool functions with prefix "tool_" followed by the same name defined in tools_list.json
# 2. Function should accept a single parameter "$1" containing JSON arguments
# 3. For successful operations: Echo the expected result and return 0
# 4. For errors: Echo an error message and return 1
# 5. All tool functions are automatically exposed to the MCP server based on tools_list.json

# Source the core MCP server implementation
source "$(dirname "${BASH_SOURCE[0]}")/mcpserver_core.sh"

# Tool: Get movies currently playing
# No parameters required
# Success: Echo JSON result and return 0
tool_get_movies() {
    local movies=$(cat << 'EOF' | jq -c '.'
[
    {"id": 1, "title": "Avengers: Endgame", "showTimes": ["10:00", "13:30", "17:00", "20:30"], "price": 12.99, "rating": "PG-13"},
    {"id": 2, "title": "The Matrix Resurrections", "showTimes": ["11:00", "14:00", "18:30", "21:00"], "price": 11.99, "rating": "A"},
    {"id": 3, "title": "Dune", "showTimes": ["10:30", "13:00", "16:30", "20:00"], "price": 12.99, "rating": "PG-13"},
    {"id": 4, "title": "No Time to Die", "showTimes": ["11:30", "15:00", "18:00", "21:30"], "price": 13.99, "rating": "U"}
]
EOF
    )
    
    echo "$movies"
    return 0
}

# Tool: Book movie tickets
# Parameters: Takes a JSON object with movieId, showTime, and numTickets
# Success: Echo JSON result and return 0
# Error: Echo error message and return 1
tool_book_ticket() {
    local args="$1"
    
    local movie_id=$(echo "$args" | jq -r '.movieId')
    local show_time=$(echo "$args" | jq -r '.showTime')
    local num_tickets=$(echo "$args" | jq -r '.numTickets')
    
    # Simple validation with direct error messages
    if [[ -z "$movie_id" ]]; then
        echo "Missing required parameter: movieId"
        return 1
    fi
    
    if ! [[ "$movie_id" =~ ^[0-9]+$ ]]; then
        echo "Invalid movieId: must be a number"
        return 1
    fi
    
    if [[ -z "$show_time" ]]; then
        echo "Missing required parameter: showTime"
        return 1
    fi
    
    if [[ -z "$num_tickets" ]]; then
        echo "Missing required parameter: numTickets"
        return 1
    fi
    
    if ! [[ "$num_tickets" =~ ^[0-9]+$ ]]; then
        echo "Invalid numTickets: must be a positive number"
        return 1
    fi
    
    # Generate booking confirmation
    local total_price=$(echo "$num_tickets * 12.99" | bc)
    local booking_info="{\"bookingId\": \"BK$(date +%s)\", \"movieId\": $movie_id, \"showTime\": \"$show_time\", \"numTickets\": $num_tickets, \"totalPrice\": $total_price}"
    echo "$booking_info"
    return 0
}

# Tool: Validate user age for movie rating
# Parameters: Takes a JSON object with age and movieRating
# Success: Echo validation result and return 0
# Error: Echo error message and return 1
tool_validate_age() {
    local args="$1"
    
    local age=$(echo "$args" | jq -r '.age')
    local movie_rating=$(echo "$args" | jq -r '.movieRating')
    
    # Parameter validation (treated as errors)
    if [[ -z "$age" ]]; then
        echo "Missing required parameter: age"
        return 1
    fi
    
    if ! [[ "$age" =~ ^[0-9]+$ ]]; then
        echo "Invalid age: must be a positive number"
        return 1
    fi
    
    if [[ -z "$movie_rating" ]]; then
        echo "Missing required parameter: movieRating"
        return 1
    fi
    
    if [[ ! "$movie_rating" =~ ^(A|PG-13|U)$ ]]; then
        echo "Invalid movie rating: $movie_rating"
        return 1
    fi
    
    # Age validation responses (normal responses, not errors)
    if [[ "$movie_rating" == "A" && "$age" -lt 18 ]]; then
        echo "Must be at least 18 years old for A-rated movies"
        return 0
    elif [[ "$movie_rating" == "PG-13" && "$age" -lt 13 ]]; then
        echo "Must be at least 13 years old for PG-13 movies"
        return 0
    fi
    
    # If we get here, validation passed
    echo "Age validation successful for $movie_rating movie"
    return 0
}

# Start the MCP server
run_mcp_server "$@"