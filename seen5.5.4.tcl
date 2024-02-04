#
# 'seen' command for eggdrop 1.x.x
#
# Ernst's eggdrop page:  http://www.baschny.de/eggdrop/
#
# Added public command (can be disabled, see 'seen_chanreq'):
#   !seen Nick
# Added private command:
#   seen Nick
# Added DCC command:
#   .seen Nick
# Added party-line command:
#   seen Nick
#
# Development has passed through: Robey, eden, cmwagner@gate.net,
# floydman@netaxs.com, pulse@indy.mvbms.com, beldin@light.iinet.net.au,
# alambers@onyx.idbsu.edu, tartarus@grayphics.com, kinslayer@nxp.co.za,
# p.fournier@ieee.ca, Fantomas and myself (Ernst).  The "Updates list" was
# getting too big and useless, so I just deleted it.
#
# Version 5.5.4 by Ernst <ernst@baschny.de> 27-Sep-2000
# - Now should also work without errors on eggdrop 1.5.x
#   ("Tcl error [part:seen]: called "part:seen" with too many arguments.")
#
# Version 5.5.2 by Ernst <ernst@baschny.de> 12-Jun-1999
# - Fixed bugs when loading seen with TCL 8.0 and eggdrop 1.3.x
#
# Version 5.5.1 by Ernst <ernst@studbox.uni-stuttgart.de>
# - Fixed some bugs (one year later hehe)
# - Set your bot version right at the top of the config part of the script
#   if you are getting strange errors
#
# Version 5.5 by Ernst <ernst@studbox.uni-stuttgart.de>
# - Some variables names were wrong for the 1.1 and 1.2 compatibility
# - With TCL >8.0, a 1.1 or 1.2 bot was always detected, even if it was a
#   1.3 bot, thus making this all not work correctly, now it does (should)
#
# Version 5.4 by Ernst <ernst@studbox.uni-stuttgart.de>
# - adapted to also work on 1.1 and 1.2 eggdrops (not tested, if it works
#   for you, send me a note)
# - added 'seen_flood' setting to avoid the bot flooding off for answering
#   public flood requests
# - now cuts down nick to 9 chars, when answering that 'user is not known'
#
# -----------------------------------------------------------------------------
# This script can make use of 'altnick.tcl', which enables you to have altnicks
# stored with each user, so asking !seen one_altnick gives you the proper
# response.  This is OPTIONAL and will only work if you have and load
# 'altnick.tcl' *before* this seen5.tcl in your config.  It is avaliable at
# ftp://ftp.sodre.net/pub/eggdrop/scripts1.0/altnick.tcl.gz (eggs 1.0-1.2) or 
# ftp://ftp.sodre.net/pub/eggdrop/scripts1.3/altnick3.tcl.gz (eggs 1.3), and
# it will probably not hurt you installing it.
# -----------------------------------------------------------------------------

# Set the version of your bot here if things don't seem to work well.
# The script tries to detect this, but sometimes it fails (TCL 8.0?)

# Eggdrop 1.0, 1.1, 1.2:
#set seen_newbot 0
# Eggdrop 1.3:
#set seen_newbot 1

# Only reply this ammount of !seen's in this ammount of seconds. This
# is valid for the sum of ALL requests, and not for each nick users
# Set to '0' to disable this checking
set seen_flood 5:30

# Also include the partyline, when checking for laston times? (1.3.x only)
set seen_partyline 0

# Save and display "Quit message" on !seen requests? (0 = no, 1 = yes)
set seen_quitmsg 1

# On public channel requests
#  0 - never respond
#  1 - respond privately
#  2 - respond to channel
#  3 - respond privately if none of the 'seen_otherbots' are there
#  4 - respond to channel if none of the 'seen_otherbots' are there
set seen_chanreq 4

# Space separated list of bots. If all of these bots are not on the channel,
# I will reply public requests in channel  (user entry with +b for these is
# required, and also a working hostmaks)
set seen_otherbots "Zeep"

# Should bot recommend use of private requests when asked in public chan?
set seen_recommend_private 0

# !seen which the bot fail to answer corretly can be logged. So you can then
# later see who people are trying to find, maybe you can then consider adding
# them to the bot (or maybe an altnick to someone already known). Set to ""
# to disable this logging
set seen_unknown_log ""

# Reply botnet party-line requests via private note (1) or via broadcast (0)
set seen_botnet_note 1

# Send IRC responses via PRIVMSGs (1) or NOTICEs (0)
set seen_privmsg 0

# -----------------------------------------------------------------------------

# Returns nick in correct case, as in userfile
proc nickcase { nick } {
	if {![validuser $nick]} { return "" }
	set nicklwr [string tolower $nick]
	foreach user [userlist] {
		if {[string tolower $user] == $nicklwr} {
			return "$user"
		}
	}
	return ""
}

# If altnick.tcl is loaded, use it
if {[info commands findnick] == ""} {
	proc findnick {nick} {
		if {[validuser $nick]} { return $nick } { return "" }
	}
}

# - eggdrop compatibility -----------------------------------------------------

if {![info exist seen_newbot]} {
  global numversion
  catch { set numversion }
  if {[info exist numversion]} {
  	if {$numversion >= 1030000} {
    	# 1.3, 1.4 and 1.5 bots
  		set seen_newbot 1
  	} {
  		# Some other strange bot
  		set seen_newbot 0
  	}
  } {
  	# 1.1 and 1.2 bots
  	set seen_newbot 0
  }
}

# Procs for compability: 1.1&1.2 vs. 1.3 bots

if {$seen_newbot} {
	# 1.3, 1.4 and 1.5 bots
	proc seen_getxtra { handle key } {
		return [getuser $handle XTRA $key]
	}
  proc seen_setxtra { handle key value } {
		setuser $handle XTRA $key $value
	}
	# returns list "unixtime channel"
	proc seen_laston { nick } {
		global seen_partyline
		if {![validuser $nick]} { return 0 }
		set lastchan ""
		set lasttime 0
		set tmp [getuser $nick LASTON]
    if {$tmp == ""} { set tmp 0 }
		if {!$seen_partyline &&
		    ![regexp "\\[string index [lindex $tmp 1] 0]" "#&+!"]
		} {
			# Just party-line info avaliable, so go through each channel
			foreach thischan [channels] {
				set tmp [getuser $nick LASTON $thischan]
				if {$tmp > $lasttime} {
					set lasttime $tmp
					set lastchan $thischan
				}
			}
		} {
			set lasttime [lindex $tmp 0]
			set lastchan [lindex $tmp 1]
		}
		return [list $lasttime $lastchan]
	}
	proc seen_setlaston { handle chan } {
		setuser $handle LASTON [unixtime] $chan
	}
} {
	# 1.1 and 1.2 bots
    proc seen_getxtra { handle key } {
		set xtra [getxtra $handle]
		for {set i 0} {$i < [llength $xtra]} {incr i} {
			set this [lindex $xtra $i]
			if {[string compare [lindex $this 0] $key] == 0} {
				return [lindex $this 1]
			}
		}
		return ""
	}
    proc seen_setxtra { handle key value } {
		set xtra [getxtra $handle]
		for {set i 0} {$i < [llength $xtra]} {incr i} {
			set this [lindex $xtra $i]
			if {[string compare [lindex $this 0] $key] == 0} {
				set this [list $key $value]
				if {$value == ""} {
					setxtra $handle [lreplace $xtra $i $i]
				} {
					setxtra $handle [lreplace $xtra $i $i $this]
				}
				return
			}
		}
		if {$value != ""} {
			lappend xtra [list $key $value]
			setxtra $handle $xtra
		}
	}
	# returns list "unixtime channel"
	proc seen_laston { nick } {
		set lasttime [getlaston $nick]
		set lastchan [getchanlaston $nick]
	}
	proc seen_setlaston { handle chan } {
		setlaston $handle $chan
	}
}

# -----------------------------------------------------------------------------

# Bindings
bind pub - !seen pub_seen
bind msg - seen msg_seen
bind msg - !seen msg_seen
bind dcc - seen cmd_seen
bind chat - "!seen *" chat_seen

# Save "Quit msg" on quit, split, part or kick
bind sign - * sign:seen
proc sign:seen {nick uhost handle channel reason} {
	global seen_quitmsg
	if {$handle != "*"} {
		# Set laston on Quit (not being done by eggdrop as of 1.1.5)
		if {$reason != "lost in the netsplit"} {
			seen_setlaston $handle $channel
			if {$seen_quitmsg} { seen_setxtra $handle "lastleft" "quit: $reason" }
		}
	}
}
bind splt - * splt:seen
proc splt:seen {nick uhost handle channel} {
	global seen_quitmsg
	if {$handle != "*"} {
		seen_setlaston $handle $channel
		if {$seen_quitmsg} { seen_setxtra $handle "lastleft" "splt" }
	}
}
bind part - * part:seen
proc part:seen {nick uhost handle channel {reason ""}} {
	global seen_quitmsg
	if {$handle != "*"} {
		if {$seen_quitmsg} { seen_setxtra $handle "lastleft" "part" }
	}
}
bind kick - * kick:seen
proc kick:seen {nick uhost handle channel kicked reason} {
	global seen_quitmsg
	set kicked_hand [nick2hand $kicked $channel]
	if {$kicked_hand != "*"} {
		if {$seen_quitmsg} { seen_setxtra $kicked_hand "lastleft" "kick: $nick $reason" }
	}
}
bind nick - * nick:seen
proc nick:seen {nick uhost handle channel newnick} {
	global seen_quitmsg
	if {$handle != "*"} {
		if {[finduser $newnick!$uhost] != $handle} {
			seen_setlaston $handle $channel
			if {$seen_quitmsg} { seen_setxtra $handle "lastleft" "nick: $newnick" }
		}
	}
}

# The main seen routine
proc do_seen { user uhost seennick seenchan } {
	global botnick seen_quitmsg	seen_unknown_log

# Initialize things
	if { $seenchan == "" } { set inchan [lindex [channels] 0] } { set inchan $seenchan }
	set randnick [lindex [chanlist $inchan] [rand [llength [chanlist $inchan]]]]

	# Find anyone with that nick (either normal or altnick)
	set validnick [nickcase [findnick $seennick]]
	if {[string tolower $validnick] != [string tolower $seennick]} {
		set realuser "$seennick (aka $validnick)"
	} {
		set realuser "$validnick"
	}

# Some stupid situations
	if {[string compare [string tolower $botnick] [string tolower $seennick]] == 0 || \
	    [string compare [string tolower $botnick] [string tolower $validnick]] == 0} {
		return "yeah, whenever I look in a mirror."
	}
	set seen_self {
		"try looking in a mirror."
		"yes, I see you."
		"if I were a normal bot, I would say 'Trying to find yourself, eh?'"
		"hmm, I think you are %nick, or am I wrong?"
		"strange, you look just like %nick!"
		"I think %randnick knows something about you..."
	}
	set self 0
	if {[string tolower $seennick] == [string tolower $user]} { set self 1 }
#	if {$uhost != "dcc" && [string tolower $seennick] == [string tolower [finduser $user!$uhost]]} {
#		set self 1
#	}
	if {$self} {
		set chosen [lindex $seen_self [rand [llength $seen_self]]]
		regsub -all "%randnick" $chosen "$randnick" chosen
		regsub -all "%nick" $chosen "$seennick" chosen
		return "$chosen"
	}
	set output ""

# Nick was here, but got net-split
	set splitchan ""
	foreach chan [channels] {
		if {[onchansplit $seennick $chan]} {
			lappend splitchan $chan
		}
	}
	if {$splitchan != ""} {
		regsub -all " " $splitchan ", " splitchan
		return "$seennick was on $splitchan a moment ago, but got netsplitted. :("
	}

# Nick is online somewhere
	set onchan ""
	foreach chan [channels] {
		if {[onchan $seennick $chan]} { lappend onchan $chan }
	}
	if {$onchan != ""} {
		regsub -all " " $onchan ", " onchan
		return "$seennick is in $onchan right now!"
	}

# Still not found, search channels lists, maybe he is using a different nick
	set splitchan ""
	set onchan ""
	foreach chan [channels] {
		foreach i [chanlist $chan] {
			set hand [finduser $i![getchanhost $i $chan]]
			if {($hand != "*") && ([string compare [string tolower $hand] [string tolower $validnick]] == 0)} {
				set realnick $i
				if {[onchansplit $i $chan]} {
					lappend splitchan $chan
				} elseif {[onchan $i $chan]} {
					lappend onchan $chan
				}
				break
			}
		}
	}
	# List searched, was he found?
	if {[llength $splitchan] > 0} {
		regsub -all " " $splitchan ", " splitchan
		return "$realuser was on $splitchan a moment ago, but got netsplitted. :("
	}
	if {[llength $onchan] > 0} {
		if {[string compare [string tolower $realnick] [string tolower $user]] == 0} {
			set seen_self {
				"correct me if I am wrong, but I think you are %nick!"
				"you are %nick!"
				"I think you are %nick, or am I wrong?"
				"yes, I see you, %nick!"
				"%nick and %curnick are the same... And that is *you*!"
			}
			set chosen [lindex $seen_self [rand [llength $seen_self]]]
			regsub -all "%randnick" $chosen "$randnick" chosen
			regsub -all "%curnick" $chosen "$realnick" chosen
			regsub -all "%nick" $chosen "$seennick" chosen
			return "$chosen"
		} {
			if {[string compare [string tolower $realnick] [string tolower $seennick]] == 0} {
				set output "$realuser"
			} {
				set output "$realuser is $realnick, and $realnick"
			}
			regsub -all " " $onchan ", " onchan
			return "$output is in $onchan right now!"
		}
	}

# Well, he is definitively NOT online. So go to userlist now.
	if {![validuser $validnick]} {
		# not even in the userlist, thats bad... :(
		set seen_unknown {
			"I think I don't know %nick yet."
			"hmmm... %nick, this name is not strange to me, but I don't know, sorry."
			"you must introduce me to %nick one day, must be a great person!"
			"I don't know anything about %nick, don't you mean %randnick?"
			"I don't know %nick, ask %randnick, maybe he knows something."
		}
		if {$seen_unknown_log != ""} {
			if {![catch {set out [open $seen_unknown_log a+]}]} {
				puts $out "\[[clock format [clock seconds] -format "%d/%m/%y %H:%M"]\] $seennick \($user!$uhost\)"
				close $out
			}
		}
		if {[string length $seennick] > 9} {
			set seennick "[string range $seennick 0 8]..."
		}
		set chosen [lindex $seen_unknown [rand [llength $seen_unknown]]]
		regsub -all "%randnick" $chosen "$randnick" chosen
		regsub -all "%nick" $chosen "$seennick" chosen
		return "$chosen"
	}

	# Yes, we got him!
	set laston [seen_laston $validnick]
	set lasttime [lindex $laston 0]
	set lastchan [lindex $laston 1]
	if {$lasttime == 0} {
		return "I know who $realuser is, but never saw him around."
	}
	# How did he left
	set reason ""
	if {$seen_quitmsg} {
		set reason [seen_getxtra $validnick "lastleft"]
		if {$reason != ""} {
			if {[string range $reason 0 3] == "quit"} {
				set reason " \(quit saying \"[string range $reason 6 end]\"\)"
			} elseif {[string range $reason 0 3] == "splt"} {
				set reason " \(netsplitted\)"
			} elseif {[string range $reason 0 3] == "kick"} {
				set reason " \(kicked by [lindex $reason 1]: \"[lrange $reason 2 end]\"\)"
			} elseif {[string range $reason 0 3] == "nick"} {
				set reason " \(changed his nick to [lindex $reason 1]\)"
			} {
				set reason ""
			}
		}
	}
	# Where was he seen
	if {$lastchan == "partyline"} {
		set lastchan "my partyline"
		set reason ""
	} elseif {[string index $lastchan 0] == "@"} {
		set lastchan "[string range $lastchan 1 end]'s partyline"
		set reason ""
	} elseif {$lastchan == "???"} {
		set lastchan ""
	} elseif {$lastchan == $seenchan} {
		set lastchan "this channel"
	} {
		set lastchan "$lastchan"
	}

	set totalyear [expr [unixtime] - $lasttime]
	if {$totalyear < 60} {
		if {$lastchan != ""} {
			return "$realuser has left $lastchan$reason less than a minute ago!"
		} {
			return "$realuser has left$reason less than a minute ago!"
		}
	}
	if {$totalyear >= 31536000} {
		set yearsfull [expr $totalyear/31536000]
		set years [expr int($yearsfull)]
		set yearssub [expr 31536000*$years]
		set totalday [expr $totalyear - $yearssub]
	}
	if {$totalyear < 31536000} {
		set totalday $totalyear
		set years 0
	}
	if {$totalday >= 86400} {
		set daysfull [expr $totalday/86400]
		set days [expr int($daysfull)]
		set dayssub [expr 86400*$days]
		set totalhour [expr $totalday - $dayssub]
	}
	if {$totalday < 86400} {
		set totalhour $totalday
		set days 0
	}
	if {$totalhour >= 3600} {
		set hoursfull [expr $totalhour/3600]
		set hours [expr int($hoursfull)]
		set hourssub [expr 3600*$hours]
		set totalmin [expr $totalhour - $hourssub]
	}
	if {$totalhour < 3600} {
		set totalmin $totalhour
		set hours 0
	}
	if {$totalmin >= 60} {
		set minsfull [expr $totalmin/60]
		set mins [expr int($minsfull)]
	}
	if {$totalmin < 60} {
		set mins 0
	}
	if {$years < 1} {set yearstext ""} elseif {$years == 1} {set yearstext "$years year, "} {set yearstext "$years years, "}
	if {$days < 1} {set daystext ""} elseif {$days == 1} {set daystext "$days day, "} {set daystext "$days days, "}
	if {$hours < 1} {set hourstext ""} elseif {$hours == 1} {set hourstext "$hours hour, "} {set hourstext "$hours hours, "}
	if {$mins < 1} {set minstext ""} elseif {$mins == 1} {set minstext "$mins minute"} {set minstext "$mins minutes"}
	set output $yearstext$daystext$hourstext$minstext
	set output [string trimright $output ", "]
	if {$lastchan != ""} {
		return "I last saw $realuser in $lastchan$reason $output ago"
	} {
		return "I last saw $realuser$reason $output ago"
	}
}

# -----------------------------------------------------------------------------

# Avoids pub/msg flooding
proc seen_detectflood { } {
	global seen_flood
	global seen_floodtrigger
	set thr [lindex [split $seen_flood ":"] 0]
	set lapse [lindex [split $seen_flood ":"] 1]
	if {$thr == "" || $thr == 0} { return 0 }
	if {![info exist seen_floodtrigger]} {
		# First time called
		set seen_floodtrigger [list [unixtime] 1]
		return 0
	}
	if {[expr [lindex $seen_floodtrigger 0] + $lapse] <= [unixtime]} {
		# Trigger time has passed, reset counter
		set seen_floodtrigger [list [unixtime] 1]
		return 0
	}
	set lasttime [lindex $seen_floodtrigger 0]
	set times [lindex $seen_floodtrigger 1]
	if {$times >= $thr} {
		# Flood!
		return 1
	}
	set seen_floodtrigger [list $lasttime [expr $times + 1]]
	return 0
}

# -----------------------------------------------------------------------------

proc pub_seen {nick uhost hand chan arg} {
	global seen_privmsg seen_chanreq seen_recommend_private seen_otherbots
	set arg [string trim $arg "\?! "]
	if {[seen_detectflood]} {
		putcmdlog "<$nick@$chan> !$hand! seen $arg (seen flood... not answering!)"
		return ""
	}
	set responded 0
	if {$seen_chanreq == 1} {
		# Always respond privately
		set responded 1
		if {$seen_privmsg} {
			puthelp "PRIVMSG $nick :[do_seen $nick $uhost $arg $chan]"
		} {
			puthelp "NOTICE $nick :[do_seen $nick $uhost $arg $chan]"
		}
		putcmdlog "<$nick@$chan> !$hand! seen $arg"
	} elseif {$seen_chanreq == 2} {
		# Always respond to channel
		set responded 1
		if {$seen_privmsg} {
			puthelp "PRIVMSG $chan :$nick, [do_seen $nick $uhost $arg $chan]"
		} {
			puthelp "NOTICE $chan :$nick, [do_seen $nick $uhost $arg $chan]"
		}
		putcmdlog "<$nick@$chan> !$hand! seen $arg"
	} elseif {$seen_chanreq == 3 || $seen_chanreq == 4} {
		# First check if there is another bot who can reply
		set ishere 0
		set botishere ""
		foreach thisbot $seen_otherbots	{
			if {[handonchan $thisbot $chan]} {
				set ishere 1
				set botishere $thisbot
				break
			}
		}
		if {$ishere} {
			putcmdlog "<$nick@$chan> !$hand! seen $arg ($botishere is here to answer)"
		} {
			set responded 1
			if {$seen_chanreq == 3} {
				# Respond privately if "otherbots" are not here
				if {$seen_privmsg} {
					puthelp "PRIVMSG $nick :$nick, [do_seen $nick $uhost $arg $chan]"
				} {
					puthelp "NOTICE $nick :$nick, [do_seen $nick $uhost $arg $chan]"
				}
			} {
				# Respond on channel if "otherbots" are not here
				if {$seen_privmsg} {
					puthelp "PRIVMSG $chan :$nick, [do_seen $nick $uhost $arg $chan]"
				} {
					puthelp "NOTICE $chan :$nick, [do_seen $nick $uhost $arg $chan]"
				}
			}
			putcmdlog "<$nick@$chan> !$hand! seen $arg"
		}
	}
  
	if {$responded && $seen_recommend_private} {
		if {$seen_privmsg} {
			puthelp "PRIVMSG $nick :Next time ask directly me via /msg"
		} {
			puthelp "NOTICE $nick :Next time ask directly me via /msg"
		}
	}
}

proc msg_seen {nick uhost hand arg} {
	global seen_privmsg
	set arg [string trim $arg "\?! "]
	if {[seen_detectflood]} {
		putcmdlog "($nick!$uhost) !$hand! seen $arg (seen flood... not answering!)"
		return ""
	}
	if {$seen_privmsg} {
		puthelp "PRIVMSG $nick :[do_seen $nick $uhost $arg ""]"
	} {
		puthelp "NOTICE $nick :[do_seen $nick $uhost $arg ""]"
	}
	putcmdlog "($nick!$uhost) !$hand! seen $arg"
}

proc cmd_seen {hand idx arg} {
	set arg [string trim $arg "\?! "]
	if {[llength $arg] == 0} {
		putdcc $idx "Usage: .seen <handle>"
		return 0
	}
	putdcc $idx "$hand: [do_seen $hand "dcc" $arg ""]"
	putcmdlog "#$hand# seen $arg"
}

proc chat_seen {nick chan arg} {
	global botnick seen_botnet_note
	set arg [string trim $arg "\?! "]
	if {$seen_botnet_note} {
		sendnote ${botnet-nick} $nick "[do_seen $nick "dcc" [lrange $arg 1 end] ""]"
	} {
		dccputchan $chan "$nick: [do_seen $nick "dcc" [lrange $arg 1 end] ""]"
	}
	putcmdlog "::${nick}:: seen [lrange $arg 1 end]"
}

putlog "- seen 5.5.4 by Ernst loaded"
