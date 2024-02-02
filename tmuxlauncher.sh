#!/bin/bash

# while getopts s: option; do
#     case $option in
#         s) # Enter a store_id
#         app=$OPTARG ;;
#         \?) # Invalid option
#             echo "Error: Invalid option"
#             exit
#         ;;
#     esac
# done

session="proxysession"

sudo systemctl stop waydroid-container.service
sudo systemctl start waydroid-container.service

if [[ -n $(pgrep tmux) ]]; then
	tmuxrunning=true
else
	tmuxrunning=false
fi

if [ "$tmuxrunning" = true ]; then
	echo "tmux already up = $tmuxrunning"
	# Check if the session exists, discarding output
	# We can check $? for the exit status (zero for success, non-zero for failure)
	# kill session, temp
	if tmux has-session -t $session 2>/dev/null; then
		echo "Found running tmux $session"
		dolaunchsess=false
	else
		dolaunchsess=true
		echo "tmux up but can't find $session"
	fi
else
	echo "tmux not open, launch new"
	dolaunchsess=true
fi

if [ "$dolaunchsess" = true ]; then
	echo "Launching new session"
	# Set up your session
	tmux new-session -d -s $session
	# Initial: Top Left
	tmux send-keys -t $session "waydroid session start" Enter
	# Top Right
	tmux split-window -h -t $session
	tmux send-keys -t $session "source ~/mobile-network-traffic/mitm-env/bin/activate" Enter
	tmux send-keys -t $session "./proxysetup.sh -w" Enter
	#tmux split-window -v -p 50 -t $session
	# Bottom Right
	#tmux send-keys -t $session "hiii" Enter
	# Bottom Left
	tmux select-pane -t $session:0.0
	tmux split-window -v -p 50 -t $session
	tmux send-keys -t $session "waydroid show-full-ui" Enter
	#tmux select-pane -t $session:0.0
else
	echo "Attach existing new session"
fi

tmux att -t $session

# Attach to created session
#tmux attach-session -t $session
