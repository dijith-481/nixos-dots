#!/usr/bin/env bash
if hyprctl activeworkspace | grep -q "workspace ID 14" ; then
	    brave --app=https://web.whatsapp.com
else
	if  hyprctl clients | grep -q "web.whatsapp.com" ; then
		hyprctl dispatch workspace 14
	else
	    brave --app=https://web.whatsapp.com
	fi
fi
