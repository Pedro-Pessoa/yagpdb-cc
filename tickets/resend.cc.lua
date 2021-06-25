{{/*
    Name: resend.cc.lua
    This command manages the -resend command

    It deletes the original first message of the ticket and resends it so that you dont have to scroll up to make actions!

    Dont change anything!

    Trigger type: Command
    Trigger: resend

    Usage:
    -resend
/*}}

{{/* ACTUAL CODE! DONT TOUCH */}}
{{/* VARIABLES */}}
{{$setup := sdict}} {{with (dbGet 0 "ticket_cfg").Value}} {{$setup = sdict .}} {{end}}
{{$category := toInt $setup.category}}
{{$admins := $setup.Admins}} {{$admins = cslice.AppendSlice $admins}}
{{$mods := $setup.Mods}} {{$mods = cslice.AppendSlice $mods}}
{{$CloseEmoji := $setup.CloseEmoji}}
{{$SolveEmoji := $setup.SolveEmoji}}
{{$AdminOnlyEmoji := $setup.AdminOnlyEmoji}}
{{$ConfirmCloseEmoji := $setup.ConfirmCloseEmoji}}
{{$CancelCloseEmoji := $setup.CancelCloseEmoji}}
{{$ModeratorRoleID := toInt $setup.MentionRoleID}}
{{$time :=  currentTime}}
{{$tn := reFind `\d+` .Channel.Name}}
{{if $tn}}
    {{$master := sdict (dbGet (toInt $tn) "ticket").Value}}
    {{$isMod := false}}
    {{/* END OF VARIABLES */}}

    {{/* CHECKS */}}
    {{range .Member.Roles}} {{if (or (in $mods .) (in $admins .))}} {{$isMod = true}} {{end}} {{end}}

    {{if and $isMod (eq .Channel.ParentID $category) (ne $master.pos 3)}}
        {{deleteMessage nil (toInt $master.mainMsgID) 2}}
        {{$autor := $master.creator}}
        {{$content := print "Welcome, **" $autor.Username "**"}}
        {{$descr := print "An <@&" $ModeratorRoleID "> will talk to you soon!\n\nFor now, please describe in **detail** your concern/issue so that we can respond faster!\n\nAn available mod will use the " $SolveEmoji " icon to assign the ticket to themself.\n\nTo close the ticket, click on the " $CloseEmoji ". Click the " $ConfirmCloseEmoji " icon to confirm or the " $CancelCloseEmoji " icon to cancel."}}
        {{$embed := cembed "color" 8190976 "description" $descr "timestamp" $time}}
        {{$id := sendMessageNoEscapeRetID nil (complexMessage "content" $content "embed" $embed)}}
        {{addMessageReactions nil $id $CloseEmoji $SolveEmoji $AdminOnlyEmoji}}
        {{$master.Set "mainMsgID" (str $id)}}
        {{dbSet (toInt $tn) "ticket" $master}}
        {{deleteTrigger 2}}
    {{end}}
{{end}}
