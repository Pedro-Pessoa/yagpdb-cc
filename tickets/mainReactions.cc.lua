{{/*
    Name: mainReactions.cc.lua
    This command manages the tickets reactions.

    Dont change anything!

    Trigger: Reaction with "Added + Removed Reactions" option
/*}}

{{/* ACTUAL CODE! DONT TOUCH */}}
{{$setup := sdict}} {{with (dbGet 0 "ticket_cfg").Value}} {{$setup = sdict .}} {{end}}
{{$admins := $setup.Admins}} {{$admins = cslice.AppendSlice $admins}}
{{$mods := $setup.Mods}} {{$mods = cslice.AppendSlice $mods}}
{{$CCID := toInt $setup.CCID}}
{{$Trc := toInt $setup.Trc}} {{$category := toInt $setup.category}}
{{$msgID := toInt $setup.msgID}}
{{$SchedueledCCID := toInt $setup.SchedueledCCID}}
{{$oe := $setup.OpenEmoji}}{{$ce := $setup.CloseEmoji}}{{$se := $setup.SolveEmoji}}{{$aoe := $setup.AdminOnlyEmoji}}{{$cce := $setup.ConfirmCloseEmoji}}{{$dce := $setup.CancelCloseEmoji}}{{$ste := $setup.SaveTranscriptEmoji}}{{$roe := $setup.ReOpenEmoji}}{{$de := $setup.DeleteEmoji}}
{{$RID := .ReactionMessage.ID}}
{{$masterChannel := toInt $setup.masterTicketChannelID}}{{$displayMSGID := toInt $setup.displayMSGID}}
{{$strCID := str .Channel.ID}}
{{$isMod := false}}{{$isAdmin := false}}
{{$TO := $setup.ticketOpen}}{{$TS := $setup.ticketSolving}}{{$TC := $setup.ticketClose}}

{{/* OPENING TICKET */}}
{{if and .ReactionAdded (eq $RID $msgID) (eq .Reaction.Emoji.Name $oe)}} {{$s := exec "ticket open" "ticket"}} {{deleteMessageReaction nil $msgID .User.ID $oe}} {{end}}

{{if eq .Channel.ParentID $category}}
{{$tn := reFind `\d+` .Channel.Name}}
{{if $tn}}
    {{$master := sdict (dbGet (toInt $tn) "ticket").Value}}
    {{$creator := toInt $master.userID}}{{$ticketCounter := toInt $master.ticketCounter}}

    {{/* CHECKS */}}
    {{range .Member.Roles}} {{if in $mods .}} {{$isMod = true}} {{end}} {{if in $admins .}} {{$isAdmin = true}} {{end}} {{end}}

    {{/* CLOSING TICKET */}}
    {{if and .ReactionAdded (or (eq .User.ID $creator) $isMod $isAdmin) (eq $RID (toInt $master.mainMsgID)) (ne (toInt $master.pos) 3)}}
        {{if eq .Reaction.Emoji.Name $ce}}
            {{addMessageReactions nil $RID $dce $cce}}
            {{deleteMessageReaction nil $RID .User.ID $ce}}
        {{else if eq .Reaction.Emoji.Name $dce}}
            {{deleteMessageReaction nil $RID 204255221017214977 $dce $cce}}
            {{deleteMessageReaction nil $RID .User.ID $dce}}
            {{$master.Set "pos" 1}}
            {{dbSet (toInt $tn) "ticket" $master}}
        {{else if eq .Reaction.Emoji.Name $cce}}
            {{$s := sendTemplate nil "display" (sdict "ID" $strCID "Arg" $TC "Master" $masterChannel "MsgID" $displayMSGID)}}
            {{$ced := print "This ticket was closed by: " .User.Mention}}
            {{$ce := cembed "color" 16776960 "description" $ced "timestamp" currentTime}}
            {{sendMessageNoEscape nil $ce}}
            {{$ced2 := print $ste " Save transcript\n" $roe " Reopen Ticket\n" $de " Delete Ticket"}}
            {{$ce2 := cembed "color" 16711680 "description" $ced2}}
            {{$lm := sendMessageNoEscapeRetID nil $ce2}}
            {{addMessageReactions nil $lm $ste $roe $de}}
            {{$master.Set "lastMessageID" (str $lm)}}
            {{deleteMessageReaction nil $RID .User.ID $cce}}
            {{if getMember $creator}} {{$s := exec "ticket removeuser" $creator}} {{end}}
            {{if ge $ticketCounter 1}} {{execCC $CCID nil 5 (sdict "tn" $tn "um" 1)}}
            {{end}}
            {{$master.Set "pos" 3}}
            {{dbSet (toInt $tn) "ticket" $master}}
        {{end}}
    {{end}}

    {{/* SOLVING TICKET */}}
    {{if and (or $isMod $isAdmin) (eq $RID (toInt $master.mainMsgID)) (eq .Reaction.Emoji.Name $se)}}
        {{if .ReactionAdded}}
            {{if ne (toInt $master.pos) 2}}
                {{$s := sendTemplate nil "display" (sdict "ID" $strCID "Arg" $TS "Master" $masterChannel "MsgID" $displayMSGID)}}
                {{$desc := print "Now the mod " .User.Mention " is solving this ticket!"}}
                {{$emb := cembed "description" $desc "color" 1752220}}
                {{sendMessage nil $emb}}
                {{$master.Set "pos" 2}}
                {{$master.Set "resp" (str .User.ID)}}
                {{$master.Set "respArg" (userArg .User.ID)}}
                {{dbSet (toInt $tn) "ticket" $master}}
            {{end}}
        {{else}}
            {{if ne (toInt $master.pos) 1}}
                {{$s := sendTemplate nil "display" (sdict "ID" $strCID "Arg" $TO "Master" $masterChannel "MsgID" $displayMSGID)}}
                {{$desc := print "Looks like the mod " .User.Mention " could not solve your problem.\nDon't worry! Another staff member is coming to help you ASAP!"}}
                {{$emb := cembed "description" $desc "color" 1752220}}
                {{sendMessage nil $emb}}
                {{$master.Set "pos" 1}}
                {{$master.Set "resp" 0}}
                {{$master.Set "respArg" 0}}
                {{dbSet (toInt $tn) "ticket" $master}}
            {{end}}
        {{end}}
        {{if and .ReactionAdded (ne (toInt $master.pos) 2) (ne (toInt $master.pos) 1)}} {{deleteMessageReaction nil $RID .User.ID $se}} {{end}}
    {{end}}

    {{/* ADMIN ONLY TICKET */}}
    {{if and $isAdmin (eq $RID (toInt $master.mainMsgID)) (eq .Reaction.Emoji.Name $aoe)}}
        {{if .ReactionAdded}}
            {{$desc := print "This ticket is now in Admin Only mode"}}
            {{$emb := cembed "description" $desc "color" 1752220}}
            {{sendMessage nil $emb}}
            {{$s := exec "ticket ao"}}
        {{else}}
            {{$desc := print "This ticket is no longer in Admin Only mode"}}
            {{$emb := cembed "description" $desc "color" 1752220}}
            {{sendMessage nil $emb}}
            {{$s := exec "ticket ao"}}
        {{end}}
    {{end}}

    {{/* FINAL ACTIONS */}}
    {{$oldid := toInt $master.mainMsgID}}
    {{if and (or $isMod $isAdmin) (eq (toInt $master.lastMessageID) $RID) .ReactionAdded}}
        {{if eq .Reaction.Emoji.Name $de}}
            {{if ne (toInt $master.rodando) 1}}
                {{sendMessage nil (cembed "description" "This ticket will be deleted soon." "color" 15158332)}}
                {{deleteMessageReaction nil $RID .User.ID $de}}
                {{execCC $CCID nil 5 (sdict "tn" $tn "tres" 3)}}
                {{cancelScheduledUniqueCC $SchedueledCCID $tn}}
            {{else}}
                There are still users being removed. Wait until you can delete the ticket.
                {{deleteResponse 10}}
            {{end}}
        {{else if eq .Reaction.Emoji.Name $roe}}
            {{$s := sendTemplate nil "display" (sdict "ID" $strCID "Arg" $TO "Master" $masterChannel "MsgID" $displayMSGID)}}
            {{deleteMessage nil $RID 1}}
            {{sendMessage nil (cembed "description" (print "This ticket was reopened by: " .User.Mention) "color" 255)}}
            {{deleteMessageReaction nil $oldid 204255221017214977 $dce $cce}}
            {{$s := exec "ticket adduser" $creator}}
            {{execCC $CCID nil 5 (sdict "tn" $tn "dois" 2 "continueSch" true "AoD" $master.AoD "delay" $master.Delay)}}
            {{if ge (toInt $master.resp) 1}} {{$master.Set "pos" 2}}
            {{else}} {{$master.Set "pos" 1}}
            {{end}}
            {{dbSet (toInt $tn) "ticket" $master}}
            {{cancelScheduledUniqueCC $SchedueledCCID $tn}}
        {{else if eq .Reaction.Emoji.Name $ste}}
            {{sendMessage $Trc (cembed "title" (printf "Ticket %s transcript" $tn) "description" (execAdmin "logs 250"))}}
            {{sendMessage nil (cembed "description" "Transcript saved!" "color" 3066993)}}
            {{deleteMessageReaction nil $RID .User.ID $ste}}
        {{end}}
    {{end}}
{{end}}
{{end}}
{{define "display"}}
{{$arg := .TemplateArgs.Arg}}
{{$ID := str .TemplateArgs.ID}}
{{with (dbGet 0 "ticketDisplay").Value}} {{with sdict .}} {{if .Get $ID}} {{.Set $ID $arg}} {{dbSet 0 "ticketDisplay" .}} {{end}} {{end}} {{end}}
{{$arr := cslice}}
{{with (dbGet 0 "ticketDisplay").Value}}
    {{$map := sdict .}}
    {{range $k, $v := $map}} {{- $arr = $arr.Append (cslice $v $k) -}} {{end}}
    {{$len := len $arr}}
    {{range seq 0 $len}}
        {{- $min := . -}}
        {{- range seq (add . 1) $len -}} {{- if gt (index $arr $min 1) (index $arr . 1) }} {{ $min = . }} {{ end -}} {{- end -}}
        {{- if ne $min . -}} {{- $ := index $arr . -}} {{- $arr.Set . (index $arr $min) -}} {{- $arr.Set $min $ -}} {{- end -}}
    {{end}}
{{end}}
{{$desc := printf "%s - %-10s\n" "**TicketID**" "**Status**"}}
{{range $arr}} {{- $desc = print $desc (printf (print "<#%d> - `%-" (index . 0 | len) "s`\n") (index . 1 | toInt) (index . 0)) -}} {{end}}
{{editMessage .TemplateArgs.Master .TemplateArgs.MsgID (cembed "title" "Tickets Display" "color" (randInt 16777216) "description" $desc)}}
{{end}}
