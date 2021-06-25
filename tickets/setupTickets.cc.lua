{{/*
    Name: setupTickets.cc.lua
    This command is your setup command, you should add this command last.
    Run it only once, and you should be good to go.

    Only change the USER VARIABLES PART

    Trigger Type: Command
    Trigger: setuptickets

    Just say -setuptickets on any channel after that you can delete this command.
*/}}

{{/* USER VARIABLES */}}

    {{/* Satff Roles */}}
        {{$Admins := cslice 673258482211749917}} {{/* IDs of your ADMINs Roles. Leave the "cslice" here even if you have only 1 role */}}
        {{$Mods := cslice 674429313097007106}} {{/* IDs of your MODs Roles. Leave the "cslice" here even if you have only 1 role */}}
        {{$MentionRoleID := 647298324734541827}} {{/* Role to be mentioned when a new ticket is opened */}}

    {{/* Open Message Info */}}
        {{$msgOpenChannelID := 578976698931085333}} {{/* Channel ID where the msg to open tickets is at. THIS CHANNEL CANT BE IN THE SAME CATEGORY AS THE TICKETS!!!!! */}}
        {{$msgID := 656755443506610176}} {{/* Message ID of the message the user has to react to open ticket */}}

    {{/* EMOJIS - Emoji MUST be unicode characters, like the examples here. */}}
        {{$OpenEmoji := "📩"}}
        {{$CloseEmoji := "🔒"}}
        {{$SolveEmoji := "📌"}}
        {{$AdminOnlyEmoji := "🛡️"}}
        {{$ConfirmCloseEmoji := "✅"}} {{/* Closing the ticket with this system is a 2 step proccess. So, after you click the CloseEmoji, you can either confirm the closing or cancel it. */}}
        {{$CancelCloseEmoji := "❎"}}
        {{$SaveTranscriptEmoji := "📑"}}
        {{$ReOpenEmoji := "🔓"}}
        {{$DeleteEmoji := "⛔"}}

    {{/* Ticket Status */}}
        {{$ticketOpen := "Open"}} {{/* Status of an open ticket - CAN NOT HAVE ANY SPECIAL CHARACTERS OR SPACE */}}
        {{$ticketClose := "Closed"}} {{/* Status of a closed ticket - CAN NOT HAVE ANY SPECIAL CHARACTERS OR SPACE */}}
        {{$ticketSolving := "Solving"}} {{/* Status of an solving ticket - CAN NOT HAVE ANY SPECIAL CHARACTERS OR SPACE */}}

    {{/* Misc */}}
        {{$CCID := 132}} {{/* ID of your "Range CC" */}}
        {{$SchedueledCCID := 133}} {{/* ID of your "Schedueled CC" */}}
        {{$masterTicketChannelID := 721766366776131663}} {{/* A channel ID where the status of ur tickets will be displayed (Further explained in the README) */}}
        {{$Trc := 682036950999629879}} {{/* Channe ID to save transcripts */}}
        {{$category := 682207474178195489}} {{/* Tickets category ID */}}
        {{$Delay := 24}} {{/* Delay (in hours) for a ticket to automatically be deleted if no messages are sent */}}

{{/* END OF USER VARIABLES */}}



{{/* ACTUAL CODE! DONT TOUCH */}}
{{if not .ExecData}}
    {{$error := ""}}
    {{$guildRoles := cslice}} {{range .Guild.Roles}} {{$guildRoles = $guildRoles.Append .ID}} {{end}} {{$invalid := false}}

    {{if not $Admins}}
        {{$error = print $error "\n" "You need to set at least one admin role in the **$Admins** variable"}}
    {{else}}
        {{range $Admins}}
            {{- if not (in $guildRoles .)}} {{$invalid = true}} {{end -}}
        {{end}}
        {{if $invalid}}
            {{$error = print $error "\n" "One or more of the admins roles provided in **$Admins** are not valid roles."}}
        {{end}}
    {{end}} {{$invalid = false}}


    {{if not $Mods}}
        {{$error = print $error "\n" "You need to set at least one mod role in the **$Mods** variable"}}
    {{else}}
        {{range $Mods}}
            {{- if not (in $guildRoles .)}} {{$invalid = true}} {{end -}}
        {{end}}
        {{if $invalid}}
            {{$error = print $error "\n" "One or more of the mod roles provided in **$Mods** are not valid roles."}}
        {{end}}
    {{end}}


    {{if not (in $guildRoles $MentionRoleID)}}
        {{$error = print $error "\n" "The provided **$MentionRoleID** is not a valid role."}}
    {{end}}


    {{if not (getChannel $msgOpenChannelID)}}
        {{$error = print $error "\n" "The **$msgOpenChannelID** provided is not a valid channel."}}
    {{end}}


    {{if not (getMessage $msgOpenChannelID $msgID)}}
        {{$error = print $error "\n" print "The **$msgID** provided is not a valid msg, or is not in the <#" $msgOpenChannelID "> channel."}}
    {{end}}


    {{if or (reFind `[^a-zA-Z\d-]` $ticketOpen) (reFind `[^a-zA-Z\d-]` $ticketClose) (reFind `[^a-zA-Z\d-]` $ticketSolving)}}
        {{$error = "Incorrect setup.\n**$ticketOpen $ticketClose $ticketSolving** can **NOT** have special characters like `á` or even white spaces ` `.\nThey also have to be a single word."}}
    {{end}}


    {{if not (toInt $CCID)}}
        {{$error = print $error "\n" "**$CCID** provided must be an int."}}
    {{end}}
    {{$s := exec "cc" $CCID}}
    {{if not (reFind `This is the "Range CC" command.` $s)}}
        {{$error = print $error "\n" "**$CCID** provided is not a valid CC"}}
    {{end}}


    {{if not (toInt $SchedueledCCID)}}
        {{$error = print $error "\n" "**$SchedueledCCID** provided must be an int."}}
    {{end}}
    {{$s := exec "cc" $SchedueledCCID}}
    {{if not (reFind `This is the "Schedueled CC" command.` $s)}}
        {{$error = print $error "\n" "**$SchedueledCCID** provided is not a valid CC"}}
    {{end}}


    {{if not (getChannel $masterTicketChannelID)}}
        {{$error = print $error "\n" "The **$masterTicketChannelID** provided is not a valid channel."}}
    {{end}}


    {{if not (getChannel $Trc)}}
        {{$error = print $error "\n" "The **$Trc** provided is invalid. You have to set a proper channel to save transcripts."}}
    {{end}}


    {{if not (getChannel $category)}}
        {{$error = print $error "\n" "The **$category** provided is not a valid category."}}
    {{end}}


    {{if $Delay}}
        {{if ne (printf "%T" $Delay) "int"}}
            {{$error = print $error "\n" "The variable **$Delay** has to be an integer. i.e 1, 2, 3, etc...\nIt cannot be 2.75 for example"}}
        {{else if lt $Delay 1}}
            {{$error = print $error "\n" "The variable **$Delay** can not be less than 1."}}
        {{end}}
    {{end}}


    {{if not $error}}
        {{addReactions $OpenEmoji $CloseEmoji $SolveEmoji $AdminOnlyEmoji $ConfirmCloseEmoji $CancelCloseEmoji $SaveTranscriptEmoji $ReOpenEmoji $DeleteEmoji}}
    {{end}}
    {{with $error}}
        {{.}}
    {{else}}
        {{$checkMsg := sendMessageRetID nil "Doing the last checks. Wait.\n**If this msgs doesnt get deleted in 6 seconds, it means that $CCID and/or $SchedueledCCID were not set properly.**"}}
        {{execCC $CCID nil 0 (sdict "test" "test" "id" $checkMsg "sch" $SchedueledCCID "thisCC" .CCID)}}
    {{end}}
{{else}}
{{dbDel 0 "ticketDisplay"}}
{{deleteMessage nil .ExecData.id 0}}
{{$id := sendMessageRetID $masterTicketChannelID (cembed "title" "Tickets Display" "color" (randInt 16777216))}}
{{dbSet 0 "ticket_cfg" (sdict "Admins" $Admins "Mods" $Mods "MentionRoleID" (str $MentionRoleID) "OpenEmoji" $OpenEmoji "CloseEmoji" $CloseEmoji "SolveEmoji" $SolveEmoji "AdminOnlyEmoji" $AdminOnlyEmoji "ConfirmCloseEmoji" $ConfirmCloseEmoji "CancelCloseEmoji" $CancelCloseEmoji "SaveTranscriptEmoji" $SaveTranscriptEmoji "ReOpenEmoji" $ReOpenEmoji "DeleteEmoji" $DeleteEmoji "ticketOpen" (lower $ticketOpen) "ticketClose" (lower $ticketClose) "ticketSolving" (lower $ticketSolving) "SchedueledCCID" (str $SchedueledCCID) "CCID" (str $CCID) "msgID" (str $msgID) "Trc" (str $Trc) "category" (str $category) "Delay" (str $Delay) "masterTicketChannelID" $masterTicketChannelID "displayMSGID" $id)}}
All good! If you did everything right, you should now be good to use your Reaction Ticket System! :)
{{$setup := sdict}} {{with (dbGet 0 "ticket_cfg").Value}} {{$setup = sdict .}} {{end}}
{{addMessageReactions $msgOpenChannelID $msgID $OpenEmoji}}
**Admins:** {{range $setup.Admins}} <@&{{.}}> {{end}}
**Mods:** {{range $setup.Mods}} <@&{{.}}> {{end}}
**RoleToBeMentionedWhenTicketIsOpened:** <@&{{toInt $setup.MentionRoleID}}>
**RangeCCID:** {{toInt $setup.CCID}}
**SchedueledCCID:** {{toInt $setup.SchedueledCCID}}
**TransCriptChannel:** <#{{toInt $setup.Trc}}>
**TicketsDisplayChannel:** <#{{toInt $setup.masterTicketChannelID}}>
**Category:** <#{{toInt $setup.category}}>
**MessageToOpenTicketID:** {{toInt $setup.msgID}}
**OpenEmoji:** {{$setup.OpenEmoji}}
**CloseEmoji:** {{$setup.CloseEmoji}}
**SolveEmoji:** {{$setup.SolveEmoji}}
**AdminOnlyEmoji:** {{$setup.AdminOnlyEmoji}}
**ConfirmCloseEmoji:** {{$setup.ConfirmCloseEmoji}}
**CancelCloseEmoji:** {{$setup.CancelCloseEmoji}}
**SaveTranscriptEmoji:** {{$setup.SaveTranscriptEmoji}}
**ReOpenEmoji:** {{$setup.ReOpenEmoji}}
**DeleteEmoji:** {{$setup.DeleteEmoji}}
**TicketOpenChannelStatus:** {{$setup.ticketOpen}}
**TicketSolvingChannelStatus:** {{$setup.ticketSolving}}
**TicketCloseChannelStatus:** {{$setup.ticketClose}}
**Delay (in hours):** {{toInt $setup.Delay}}
{{deleteResponse 120}}
{{end}}
{{deleteTrigger 7}}
