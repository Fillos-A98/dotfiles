#!/bin/bash
# HyprWave Toggle Script

ACTION="$1"
ARG="$2"

CONFIG_FILE="$HOME/.config/hyprwave/config.conf"
LOG_FILE="/tmp/hyprwave-toggle.log"

if [ -z "$ACTION" ]; then
    echo "Usage: hyprwave-toggle {visibility|expand|play|next|prev|set-position|set-theme}"
    exit 1
fi

# Function to update config file
update_config() {
    local key="$1"
    local value="$2"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found at $CONFIG_FILE"
        exit 1
    fi
    
    # Update the config file
    sed -i "s/^$key = .*/$key = $value/" "$CONFIG_FILE"
}

# Function to get hyprwave PID (not this script)
get_hyprwave_pid() {
    pgrep -x hyprwave 2>/dev/null
}

# Handle set-theme (change colors with slide animation)
if [ "$ACTION" = "set-theme" ]; then
    if [ -z "$ARG" ]; then
        echo "Usage: hyprwave-toggle set-theme <theme-name>"
        echo "Available themes:"
        # List from both locations
        if [ -d "$HOME/.local/share/hyprwave/themes" ]; then
            ls -1 "$HOME/.local/share/hyprwave/themes/" 2>/dev/null | sed 's/.css$//' | sed 's/^/   /'
        fi
        if [ -d "/usr/share/hyprwave/themes" ]; then
            ls -1 "/usr/share/hyprwave/themes/" 2>/dev/null | sed 's/.css$//' | sed 's/^/   /'
        fi
        exit 1
    fi
    
    STYLE_FILE="$HOME/.local/share/hyprwave/style.css"
    LAYOUT_FILE_USER="$HOME/.local/share/hyprwave/style-layout.css"
    LAYOUT_FILE_SYSTEM="/usr/share/hyprwave/style-layout.css"
    
    # Check user themes first, then system themes
    THEME_FILE=""
    if [ -f "$HOME/.local/share/hyprwave/themes/$ARG.css" ]; then
        THEME_FILE="$HOME/.local/share/hyprwave/themes/$ARG.css"
    elif [ -f "/usr/share/hyprwave/themes/$ARG.css" ]; then
        THEME_FILE="/usr/share/hyprwave/themes/$ARG.css"
    fi
    
    # Check if theme exists
    if [ -z "$THEME_FILE" ]; then
        echo "❌ Theme not found: $ARG"
        echo ""
        echo "Available themes:"
        echo "  User themes (~/.local/share/hyprwave/themes/):"
        if [ -d "$HOME/.local/share/hyprwave/themes" ]; then
            ls -1 "$HOME/.local/share/hyprwave/themes/" 2>/dev/null | sed 's/.css$//' | sed 's/^/    /'
        else
            echo "    (none - create custom themes here!)"
        fi
        echo ""
        echo "  System themes (/usr/share/hyprwave/themes/):"
        if [ -d "/usr/share/hyprwave/themes" ]; then
            ls -1 "/usr/share/hyprwave/themes/" 2>/dev/null | sed 's/.css$//' | sed 's/^/    /'
        else
            echo "    (none)"
        fi
        exit 1
    fi
    
    # Find layout file (prefer user, fallback to system)
    LAYOUT_FILE=""
    if [ -f "$LAYOUT_FILE_USER" ]; then
        LAYOUT_FILE="$LAYOUT_FILE_USER"
    elif [ -f "$LAYOUT_FILE_SYSTEM" ]; then
        LAYOUT_FILE="$LAYOUT_FILE_SYSTEM"
    else
        echo "❌ Error: style-layout.css not found"
        exit 1
    fi
    
    # Ensure style.css location exists (for AUR users)
    mkdir -p "$HOME/.local/share/hyprwave"
    
    # Check if hyprwave is running
    HYPRWAVE_PID=$(get_hyprwave_pid)
    
    if [ -n "$HYPRWAVE_PID" ]; then
        echo "Changing theme to: $ARG"
        
        # 1. Hide current instance
        kill -SIGUSR1 "$HYPRWAVE_PID" 2>/dev/null
        
        # 2. Wait for slide-out animation
        sleep 0.4
        
        # 3. Concatenate theme + layout into user's style.css
        cat "$THEME_FILE" "$LAYOUT_FILE" > "$STYLE_FILE"
        
        # 4. Kill current instance
        kill -TERM "$HYPRWAVE_PID" 2>/dev/null
        
        # 5. Wait for process to fully exit
        sleep 0.3
        
        # 6. Find hyprwave binary
        HYPRWAVE_BIN=$(which hyprwave 2>/dev/null)
        
        if [ -z "$HYPRWAVE_BIN" ]; then
            # Try common locations
            if [ -x "$HOME/.local/bin/hyprwave" ]; then
                HYPRWAVE_BIN="$HOME/.local/bin/hyprwave"
            elif [ -x "/usr/bin/hyprwave" ]; then
                HYPRWAVE_BIN="/usr/bin/hyprwave"
            else
                echo "❌ Error: Could not find hyprwave binary"
                exit 1
            fi
        fi
        
        # 7. Restart hyprwave with --start-hidden (will slide in with new theme)
        "$HYPRWAVE_BIN" --start-hidden >> "$LOG_FILE" 2>&1 &
        
        # Give it a moment to start
        sleep 0.3
        
        # Verify it started
        if pgrep -x hyprwave > /dev/null; then
            echo "✅ Theme changed to: $ARG"
        else
            echo "⚠️  Theme updated but hyprwave failed to restart"
            echo "   Check log: $LOG_FILE"
        fi
    else
        # Just update theme if not running
        cat "$THEME_FILE" "$LAYOUT_FILE" > "$STYLE_FILE"
        echo "✅ Theme updated. Start hyprwave to see changes."
    fi
    
    exit 0
fi

# Handle set-position (doesn't require hyprwave to be running)
if [ "$ACTION" = "set-position" ]; then
    if [ -z "$ARG" ]; then
        echo "Usage: hyprwave-toggle set-position {left|right|top|bottom}"
        exit 1
    fi
    
    # Validate position
    case "$ARG" in
        left|right|top|bottom)
            ;;
        *)
            echo "Invalid position: $ARG"
            echo "Valid positions: left, right, top, bottom"
            exit 1
            ;;
    esac
    
    # Check if hyprwave is running
    HYPRWAVE_PID=$(get_hyprwave_pid)
    
    if [ -n "$HYPRWAVE_PID" ]; then
        echo "Changing position to: $ARG"
        
        # 1. Hide current instance
        kill -SIGUSR1 "$HYPRWAVE_PID" 2>/dev/null
        
        # 2. Wait for slide-out animation
        sleep 0.4
        
        # 3. Update config
        update_config "edge" "$ARG"
        
        # 4. Kill current instance
        kill -TERM "$HYPRWAVE_PID" 2>/dev/null
        
        # 5. Wait for process to fully exit
        sleep 0.3
        
        # 6. Find hyprwave binary
        HYPRWAVE_BIN=$(which hyprwave 2>/dev/null)
        
        if [ -z "$HYPRWAVE_BIN" ]; then
            # Try common locations
            if [ -x "$HOME/.local/bin/hyprwave" ]; then
                HYPRWAVE_BIN="$HOME/.local/bin/hyprwave"
            elif [ -x "/usr/bin/hyprwave" ]; then
                HYPRWAVE_BIN="/usr/bin/hyprwave"
            else
                echo "❌ Error: Could not find hyprwave binary"
                echo "   Check that hyprwave is installed"
                exit 1
            fi
        fi
        
        echo "Using binary: $HYPRWAVE_BIN" > "$LOG_FILE"
        
        # 7. Restart hyprwave with --start-hidden
        # Try different methods
        
        # Method 1: Simple background with full path
        "$HYPRWAVE_BIN" --start-hidden >> "$LOG_FILE" 2>&1 &
        RESTART_PID=$!
        
        # Give it a moment to start
        sleep 0.3
        
        # Verify it started
        if pgrep -x hyprwave > /dev/null; then
            echo "✅ Position changed to: $ARG"
        else
            echo "⚠️  Config updated but hyprwave failed to restart"
            echo "   Check log: $LOG_FILE"
            if [ -f "$LOG_FILE" ]; then
                echo "   Last error:"
                tail -n 5 "$LOG_FILE" | sed 's/^/   /'
            fi
        fi
    else
        # Just update config if not running
        update_config "edge" "$ARG"
        echo "✅ Config updated. Start hyprwave to see changes."
    fi
    
    exit 0
fi

# For all other actions, require hyprwave to be running
HYPRWAVE_PID=$(get_hyprwave_pid)

if [ -z "$HYPRWAVE_PID" ]; then
    echo "HyprWave is not running"
    exit 1
fi

# Handle other actions (send signal to specific PID)
case "$ACTION" in
    visibility)
        kill -SIGUSR1 "$HYPRWAVE_PID"
        ;;
    expand)
        kill -SIGUSR2 "$HYPRWAVE_PID"
        ;;
    play)
        kill -SIGRTMIN "$HYPRWAVE_PID"
        ;;
    next)
        kill -SIGRTMIN+1 "$HYPRWAVE_PID"
        ;;
    prev)
        kill -SIGRTMIN+2 "$HYPRWAVE_PID"
        ;;
    *)
        echo "Invalid action: $ACTION"
        echo "Usage: hyprwave-toggle {visibility|expand|play|next|prev|set-position|set-theme}"
        exit 1
        ;;
esac
