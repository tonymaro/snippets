#!/bin/bash
# Play doorbell human detected video
# 
# NOTE:  This is running on Linux with Xfce.  I've disabled the window stack management in Xfce with the settings option
#        so that I could manually manage the window display in code
#
##########################################

export DISPLAY=:0

killall mpv
killall ffplay

# Pick a random video
if (( RANDOM %2 )); then
	DOORBELL="/home/tony/Videos/Door/someoneatdoor.mp4"
else
	DOORBELL="/home/tony/Videos/Door/someoneatdoor2.mp4"
fi
# Temporarily only use this one:
DOORBELL="/home/tony/Videos/Door/someoneatdoor3.mp4"

# Start the camera stream forked - takes about 3 seconds to launch
ffplay -fs -an rtsp://stream:stream123@192.168.5.5:80/rtsp/streaming?channel=02 & STREAM_PID=$!
# Start the avatar video
ffplay -fs -autoexit -ss 0 "$DOORBELL" & FIRST_PID=$!

# Find the avatar video and pop it to the top
MAX_WAIT=5
START_TIME=$(date +%s)
while true; do
        # Get the window ID
        WINDOW_ID=$(xdotool search --pid $FIRST_PID | tail -1)

        # Check if the window ID is found
        if [ -n "$WINDOW_ID" ]; then
                xdotool windowactivate "$WINDOW_ID"
                EXIT_STATUS=$?

                if [ "$EXIT_STATUS" -eq 0 ]; then
                        break;
                else
                        echo "Window not activated"
                fi
        fi
        # Check if 5 seconds have passed
	CURRENT_TIME=$(date +%s)
	ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
	if [ "$ELAPSED_TIME" -ge "$MAX_WAIT" ]; then
	    break
	fi
    # Sleep for a short duration before checking again
    sleep 0.1
done

# Hide firefox to eliminate flicker when switching to video stream
sleep 0.5
wmctrl -r Firefox -b add,hidden

# Wait for the avatar to finish
wait $FIRST_PID

# Make sure the camera stream pops to top
xdotool windowactivate `xdotool search --pid $STREAM_PID | tail -1`
sleep 3
# Show firefox again
wmctrl -r Firefox -b remove,hidden
# Let camera show for 20 seconds
sleep 20
killall ffplay
# Note that we've done something to stave off the slideshow kicking in
touch /home/tony/scripts/lasttouch.txt
