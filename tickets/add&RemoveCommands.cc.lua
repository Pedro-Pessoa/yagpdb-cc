{{/*
    Name: add&RemoveCommands.cc.lua
    This command manages the $add and $remove commands.

    Dont change anything!

    Trigger: Regex
    Regex: \A\$(add|remove)

    Usage:
    $add @user
    $remove @user
/*}}

{{/* ACTUAL CODE! DONT TOUCH */}}
{{$setup := sdict}} {{with (dbGet 0 "ticket_cfg").Value}} {{$setup = sdict .}} {{end}}
{{$category := toInt $setup.category}}
{{$admins := $setup.Admins}} {{$admins = cslice.AppendSlice $admins}}
{{$mods := $setup.Mods}} {{$mods = cslice.AppendSlice $mods}}
{{if eq .Channel.ParentID $category}}
	{{/* Vars */}}
	{{$tn := reFind `\d+` .Channel.Name | toInt}}
	{{if $tn}}
		{{$key := print $tn "adicionados"}}
		{{$user := .User}}
		{{$isMod := false}} {{$isModA := false}}
		{{$cmd := reFind `(?i)\$add|\$remove` .Cmd}}
		{{$master := sdict (dbGet (toInt $tn) "ticket").Value}}
		{{$creator := toInt $master.userID}}
		{{$atual := toInt $master.ticketCounter}}
		{{$tUser := .User}}

		{{/* Doing Stuff */}}
		{{range .Member.Roles}} {{if or (in $mods .) (in $admins .)}} {{$isModA = true}} {{end}} {{end}}
		{{if ne (toInt $master.pos) 3}}
			{{if or (eq .User.ID $creator) $isModA}}
				{{with .CmdArgs}}
					{{with index . 0 | userArg}}
						{{$user = .}}
						{{range (getMember $user.ID).Roles}} {{if in $mods .}} {{$isMod = true}} {{end}} {{end}}
						{{$isAlready := dbGet $user.ID $key}}
						{{if eq $cmd "$add"}}
							{{if lt $atual 15}}
								{{if not $isMod}}
									{{if and (not $isAlready) (ne $user.ID $creator)}}
										{{$s := exec "ticket adduser" $user.ID}}
										{{sendMessageNoEscape nil (cembed "description" (print "User " $user.Mention " was added to this ticket.") "color" 12370112)}}
										{{dbSet $user.ID $key 1}}
										{{$master.Set "ticketCounter" (str (add $atual 1))}}
										{{dbSet $tn "ticket" $master}}
									{{else}}
										Hey, {{$tUser.Mention}}!! The user **{{$user.Username}}** is already on this ticket!
									{{end}}
								{{else}}
									Hey, {{$tUser.Mention}}! Mods cant be added to a ticket!
								{{end}}
							{{else}}
							The maximum amount of participants in a ticket is 15 users, {{$tUser.Mention}}
							{{end}}
						{{else if eq $cmd "$remove"}}
							{{if not $isMod}}
								{{if $isAlready}}
									{{if ne $user.ID $creator}}
										{{$s := exec "ticket removeuser" $user.ID}}
										{{sendMessageNoEscape nil (cembed "description" (print "The user " $user.Mention " was removed from the ticket.") "color" 12370112)}}
										{{dbDel $user.ID $key}}
										{{$master.Set "ticketCounter" (str (sub $atual 1))}}
										{{dbSet $tn "ticket" $master}}
									{{else}}
										You cant remove the creator of the ticket, {{$tUser.Mention}}
									{{end}}
								{{else}}
									The user **{{$user.Username}}** is not a participant of the ticket, {{$tUser.Mention}}
								{{end}}
							{{else}}
								You cant remove mods from the ticket, {{$tUser.Mention}}
							{{end}}
						{{end}}
					{{else}}
						Invalid user, {{$tUser.Mention}}
					{{end}}
				{{else}}
					Correct usage of the command: $add or $remove @user
				{{end}}
			{{end}}
		{{end}}
	{{end}}
{{end}}
