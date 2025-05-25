#!/bin/bash

# Set locale to handle UTF-8 characters
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Check if file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <path_to_file>"
    exit 1
fi

FILE="$1"

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi

# Terminal control functions
hide_cursor() {
    printf '\033[?25l'
}

show_cursor() {
    printf '\033[?25h'
}

move_cursor() {
    printf '\033[%d;%dH' "$1" "$2"
}

clear_screen() {
    printf '\033[2J'
    printf '\033[H'
}

get_terminal_size() {
    local size=$(stty size 2>/dev/null)
    if [ -n "$size" ]; then
        TERM_ROWS=${size% *}
        TERM_COLS=${size#* }
    else
        TERM_ROWS=24
        TERM_COLS=80
    fi
}

cleanup() {
    show_cursor
    clear_screen
    echo "Goodbye!"
    exit 0
}

# Trap to ensure cursor is restored on exit
trap cleanup EXIT INT TERM

# Hide cursor at start
hide_cursor

# Get terminal size
get_terminal_size

# Parse the file and store tasks
declare -a categories=()
declare -A tasks=()
declare -A checked=()
declare -a display_items=()
declare -A item_line_counts=()  # Track how many lines each item takes
current_category=""
task_counter=0
current_task=""

while IFS= read -r line; do
    # Don't trim leading whitespace yet - we need to detect indentation
    trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ $line =~ ^@(.+)$ ]]; then
        # Save any pending task before starting new category
        if [[ -n "$current_task" && -n "$current_category" ]]; then
            task_key="task_${task_counter}"
            tasks["$task_key"]="$current_task"
            checked["$task_key"]=false
            display_items+=("TASK:$task_key")
            # Count lines in the task (plus 1 for empty line after)
            line_count=$(echo "$current_task" | wc -l)
            item_line_counts["TASK:$task_key"]=$((line_count + 1))
            ((task_counter++))
            current_task=""
        fi
        
        # This is a new category
        current_category="${BASH_REMATCH[1]}"
        categories+=("$current_category")
        display_items+=("CATEGORY:$current_category")
        # Categories take 2 lines (category + empty line)
        item_line_counts["CATEGORY:$current_category"]=2
        
    elif [[ -n "$trimmed_line" && -n "$current_category" ]]; then
        # Check if line starts with whitespace (continuation)
        if [[ $line =~ ^[[:space:]] && -n "$current_task" ]]; then
            # This is a continuation of the previous task
            current_task="$current_task"$'\n'"$trimmed_line"
        else
            # Save previous task if exists
            if [[ -n "$current_task" ]]; then
                task_key="task_${task_counter}"
                tasks["$task_key"]="$current_task"
                checked["$task_key"]=false
                display_items+=("TASK:$task_key")
                # Count lines in the task (plus 1 for empty line after)
                line_count=$(echo "$current_task" | wc -l)
                item_line_counts["TASK:$task_key"]=$((line_count + 1))
                ((task_counter++))
            fi
            # Start new task
            current_task="$trimmed_line"
        fi
    fi
done < "$FILE"

# Don't forget the last task
if [[ -n "$current_task" && -n "$current_category" ]]; then
    task_key="task_${task_counter}"
    tasks["$task_key"]="$current_task"
    checked["$task_key"]=false
    display_items+=("TASK:$task_key")
    # Count lines in the task (plus 1 for empty line after)
    line_count=$(echo "$current_task" | wc -l)
    item_line_counts["TASK:$task_key"]=$((line_count + 1))
    ((task_counter++))
fi

# Current selection and scrolling
current_selection=0
total_items=${#display_items[@]}
header_lines=4
scroll_offset=0
prev_scroll=0

# Calculate how many items can fit on screen based on their actual line counts
calculate_visible_items() {
    local available_lines=$((TERM_ROWS - header_lines - 1))
    local used_lines=0
    local count=0
    
    for (( i=scroll_offset; i<total_items; i++ )); do
        local item="${display_items[$i]}"
        local lines_needed=${item_line_counts["$item"]}
        
        if (( used_lines + lines_needed <= available_lines )); then
            used_lines=$((used_lines + lines_needed))
            count=$((count + 1))
        else
            break
        fi
    done
    
    max_visible_items=$count
    if [ $max_visible_items -lt 1 ]; then
        max_visible_items=1
    fi
}

# Calculate scroll position to keep current selection visible
update_scroll() {
    prev_scroll=$scroll_offset
    
    # If current selection is before scroll window, scroll up
    if [ $current_selection -lt $scroll_offset ]; then
        scroll_offset=$current_selection
        calculate_visible_items
        return
    fi
    
    # Calculate visible items from current scroll position
    calculate_visible_items
    
    # If current selection is after scroll window, scroll down
    visible_end=$((scroll_offset + max_visible_items))
    if [ $current_selection -ge $visible_end ]; then
        # Find the scroll position where current_selection is the last visible item
        target_end=$((current_selection + 1))
        available_lines=$((TERM_ROWS - header_lines - 1))
        used_lines=0
        
        # Work backwards from current_selection to find scroll_offset
        for (( i=current_selection; i>=0; i-- )); do
            item="${display_items[$i]}"
            lines_needed=${item_line_counts["$item"]}
            
            if (( used_lines + lines_needed <= available_lines )); then
                used_lines=$((used_lines + lines_needed))
                scroll_offset=$i
            else
                break
            fi
        done
        
        calculate_visible_items
    fi
}

# Function to display a task (handles multi-line)
display_task() {
    local task_key="$1"
    local is_selected="$2"
    local task_content="${tasks[$task_key]}"
    
    checkbox="[ ]"
    if [ "${checked[$task_key]}" = true ]; then
        checkbox="[✓]"
    fi
    
    # Split task into lines
    local first_line=true
    while IFS= read -r task_line; do
        if [ "$first_line" = true ]; then
            # First line includes checkbox
            local full_line="  $checkbox $task_line"
            first_line=false
        else
            # Continuation lines are indented
            local full_line="      $task_line"
        fi
        
        if [ "$is_selected" = true ]; then
            printf '\033[7m%s\033[0m\n' "$full_line"
        else
            printf '%s\n' "$full_line"
        fi
    done <<< "$task_content"
}

# Calculate the screen line position for an item
get_item_screen_position() {
    local item_index=$1
    local screen_line=$((header_lines + 1))
    
    for (( i=scroll_offset; i<item_index; i++ )); do
        local item="${display_items[$i]}"
        local lines_needed=${item_line_counts["$item"]}
        screen_line=$((screen_line + lines_needed))
    done
    
    echo $screen_line
}

# Display a single item at a specific index
display_item_at_index() {
    local item_index=$1
    local is_selected=$2
    local item="${display_items[$item_index]}"
    
    if [[ $item =~ ^CATEGORY:(.+)$ ]]; then
        local category="${BASH_REMATCH[1]}"
        if [ "$is_selected" = true ]; then
            printf '\033[7m@%s\033[0m\n' "$category"
        else
            printf '@%s\n' "$category"
        fi
        echo  # Empty line after category
    elif [[ $item =~ ^TASK:(.+)$ ]]; then
        local task_key="${BASH_REMATCH[1]}"
        display_task "$task_key" "$is_selected"
        echo  # Empty line after task
    fi
}

# Clear lines for an item
clear_item_lines() {
    local item_index=$1
    local item="${display_items[$item_index]}"
    local lines_needed=${item_line_counts["$item"]}
    
    for (( i=0; i<lines_needed; i++ )); do
        printf '\033[K\n'  # Clear line and move to next
    done
}

# Update selection display without full refresh
update_selection_display() {
    local old_selection=$1
    local new_selection=$2
    
    # If scroll position changed, do full refresh
    if [ $scroll_offset != $prev_scroll ]; then
        full_display
        return
    fi
    
    # Check if both items are visible on screen
    local visible_start=$scroll_offset
    local visible_end=$((scroll_offset + max_visible_items))
    
    if [ $old_selection -ge $visible_start ] && [ $old_selection -lt $visible_end ]; then
        # Redraw old position (unhighlighted)
        local old_screen_pos=$(get_item_screen_position $old_selection)
        move_cursor $old_screen_pos 1
        clear_item_lines $old_selection
        move_cursor $old_screen_pos 1
        display_item_at_index $old_selection false
    fi
    
    if [ $new_selection -ge $visible_start ] && [ $new_selection -lt $visible_end ]; then
        # Redraw new position (highlighted)
        local new_screen_pos=$(get_item_screen_position $new_selection)
        move_cursor $new_screen_pos 1
        clear_item_lines $new_selection
        move_cursor $new_screen_pos 1
        display_item_at_index $new_selection true
    fi
}

# Full display refresh
full_display() {
    clear_screen
    echo "Checklist - Use ↑/↓ to navigate, SPACE to toggle, q to quit"
    echo "File: $FILE"
    
    # Show scroll indicator
    if [ $total_items -gt $max_visible_items ]; then
        end_item=$((scroll_offset + max_visible_items - 1))
        if [ $end_item -ge $total_items ]; then
            end_item=$((total_items - 1))
        fi
        echo "Items $((scroll_offset + 1))-$((end_item + 1)) of $total_items"
    else
        echo "All items shown"
    fi
    
    echo "=================================================="
    
    # Display visible items
    visible_end=$((scroll_offset + max_visible_items))
    if [ $visible_end -gt $total_items ]; then
        visible_end=$total_items
    fi
    
    for (( i=scroll_offset; i<visible_end; i++ )); do
        display_item_at_index $i $([ $i -eq $current_selection ] && echo "true" || echo "false")
    done
}

# Get the task key at current selection
get_current_task_key() {
    item="${display_items[$current_selection]}"
    if [[ $item =~ ^TASK:(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Initial display
update_scroll
full_display

# Main loop
while true; do
    # Read single character
    IFS= read -rsn1 input
    
    # Handle different input cases
    if [[ $input == $'\x1b' ]]; then
        # ESC sequence - read next two characters
        IFS= read -rsn2 input
        case $input in
            '[A')  # Up arrow
                if [ $current_selection -gt 0 ]; then
                    old_selection=$current_selection
                    ((current_selection--))
                    update_scroll
                    update_selection_display $old_selection $current_selection
                fi
                ;;
            '[B')  # Down arrow
                if [ $current_selection -lt $((total_items - 1)) ]; then
                    old_selection=$current_selection
                    ((current_selection++))
                    update_scroll
                    update_selection_display $old_selection $current_selection
                fi
                ;;
            '[5~') # Page Up
                if [ $current_selection -gt 0 ]; then
                    current_selection=$((current_selection - max_visible_items))
                    if [ $current_selection -lt 0 ]; then
                        current_selection=0
                    fi
                    update_scroll
                    full_display
                fi
                ;;
            '[6~') # Page Down
                if [ $current_selection -lt $((total_items - 1)) ]; then
                    current_selection=$((current_selection + max_visible_items))
                    if [ $current_selection -ge $total_items ]; then
                        current_selection=$((total_items - 1))
                    fi
                    update_scroll
                    full_display
                fi
                ;;
        esac
    elif [[ $input == ' ' ]]; then
        # Space bar - toggle checkbox
        task_key=$(get_current_task_key)
        if [ -n "$task_key" ]; then
            if [ "${checked[$task_key]}" = true ]; then
                checked["$task_key"]=false
            else
                checked["$task_key"]=true
            fi
            # Redraw just the current item to update checkbox
            local screen_pos=$(get_item_screen_position $current_selection)
            move_cursor $screen_pos 1
            clear_item_lines $current_selection
            move_cursor $screen_pos 1
            display_item_at_index $current_selection true
        fi
    elif [[ $input == 'q' ]] || [[ $input == 'Q' ]]; then
        # Quit - cleanup will be called by trap
        exit 0
    elif [[ $input == 'r' ]] || [[ $input == 'R' ]]; then
        # Refresh display
        get_terminal_size
        update_scroll
        full_display
    fi
done

