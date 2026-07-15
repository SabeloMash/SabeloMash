#!/bin/bash


osascript <<EOF
set timeoutSeconds to 15
 
try
    -- Show dialog with only "Reboot Now" button and timeout
    display dialog "The process is complete. Your Mac needs to reboot." buttons {"Reboot Now"} default button "Reboot Now" giving up after timeoutSeconds
    if gave up of the result then
        -- User did not respond in time, reboot automatically
        do shell script "sudo shutdown -r now" with administrator privileges
    else
        -- User clicked "Reboot Now"
        do shell script "sudo shutdown -r now" with administrator privileges
    end if
on error errMsg number errNum
    -- Handle if user closes the dialog forcibly or error occurs
    -- Just proceed to reboot anyway
    do shell script "sudo shutdown -r now" with administrator privileges
end try
EOF
