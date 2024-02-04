#****************************************************************************#
# There is no configuration part in this tcl. You can switch the seen result #
# message type via dcc for each channel using the command:                   #
#            .chanset <#channel> -pubseen - switsch to notice message        #
#            .chanset <#channel> +pubseen - switch to normal channel message #
#                                                                            #
# or using the public comammands in the certain channel                      #
#            !pubseen off - switsch to notice message                        #
#            !pubseen on  - switch to normal channel message                 #
#                                                                            #
# You can use the folowing seen commands (seen equals !seen):                #
#             seen <nick>                                                    #
#             seen <ident@host>                                              #
#                                                                            #
#             (copied seen bot help menu)                                    #
#             SEEN <mask> [flags] - searches for users matching <mask>       #
#             <mask> = <nick> | <ident>@<host> | <nick>!<ident> |            #
#             <nick>!<ident>@<host>                                          #
#             wildcards ? and * are allowed                                  #
#             [flags] = [d<num>][s<num>][f][a][c][+][-][@][=]                #
#             d<num> = show <num> results (max is 5)                         #
#             s<num> = start from result <num>                               #
#             '+' = only show NS identified                                  #
#             '-' = only show not NS identified                              #
#             '@' = only show OS identified                                  #
#             '=' = only show not OS identified                              #
#             'f' = show full info (verbose)                                 #
#             'a' = show absolute time                                       #
#             'c' = case sensitive                                           #
#                                                                            #
# or just use help command on private. Have fun                              #
#                                                                            #
# Copyright © 2006 BadGod				                                     #
#                                                                            #
# This program is free software; you can redistribute it and/or modify       #
# it under the terms of the GNU General Public License as published by       #
# the Free Software Foundation; either version 2 of the License, or          #
# (at your option) any later version.                                        #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  #
#                                                                            #
# Report bugs/suggestions to demon@demonsteam.net or                         #
# in channel #demons @UniBG                                                  #
#****************************************************************************#


#*************************************************#
# Please do not edit anything unless you know TCL #
#*************************************************#

bind pub - !seen seen:pub:who
bind pub - seen seen:pub:who
bind msg - seen seen:priv:who
bind PUB n !pubseen seen:switch 
bind raw - 401 seen:error
bind msgm - * seen:result
bind ctcp - version seen:ctcp:reply

# Unbind stadard help menu and bind it to seen:help
unbind msg - help *msg:help
bind msg - help seen:priv:help
bind pub - help seen:pub:help

# Channel flags
setudef flag pubseen

# Copyrights. Please do not remove the copyrights and respect the work of the programer
set seen(version) "2.3"
set seen(autor) "BadGod"
set seen(name) "Alternate Seen System v$seen(version) released by $seen(autor)"
set ::realname $seen(name)

set seen(blocked) 0

proc seen:error {from key arg} {
 global to botnick
 set nick [lindex [split $arg] 1]
  if {$nick == "SeenServ"} {
  putserv "PRIVMSG seen :seen $to(who) f"
  } else {
  putserv "NOTICE $to(nick) :Services are currently unavailable. Sorry, just try later"
  }
} 
   
proc seen:switch {nick host hand chan text} {
 set option [lindex [split $text] 0]
 switch -- $option {
  "on" {
   channel set $chan +pubseen 
   puthelp "NOTICE $nick :Seen method is switched to public"
  }
  "off" {
   channel set $chan -pubseen
   puthelp "NOTICE $nick :Seen method is switched to notice"
  }
 }
}
 
proc seen:result {nick host hand text} {
 global to seen
 set seenargument [lindex $text 0]
 if {$nick == "SeenServ" || $nick == "seen"} {
    if {[validchan $to(chan)]} {
	   if {[channel get $to(chan) pubseen]} {
       putserv "PRIVMSG $to(chan) :$to(nick) : $text"
       } else {
         putserv "NOTICE $to(nick) :$text"
       }
	} else {
	putserv "PRIVMSG $to(nick) :$text"
	}
 } elseif {$seenargument != "seen"} {
			if {($seenargument != "op") && ($seenargument != "pass") && ($seenargument != "voice") && ($seenargument != "help")} {
				putserv "PRIVMSG $to(nick) :I dont know what \"[lrange $text 0 1] ...\" is. Use \"seen <nick>\" or \"help\" for the help options"
			}
 }
 set seen(blocked) 0
}

proc seen:pub:who {nick host hand chan arg} {
 global to seen
 if {$seen(blocked) == 1} {
   if {[channel get $chan pubseen]} {
   putserv "PRIVMSG $chan :$nick : Try again in a few seconds."
   } else {
	 putserv "NOTICE $nick :Try again in a few seconds."
   }
   return;
 }
 set seen(blocked) 1
 set to(nick) $nick
 set to(chan) $chan
 set to(who) [string tolower [lindex $arg 0]];
  if {[string tolower [lindex $arg 1]] != "" || [regexp -all {@} $to(who)] > 0} {
  set option [string tolower [lindex $arg 1]]
  putserv "PRIVMSG seen :seen $to(who) $option"
  } else {
    putserv "PRIVMSG SeenServ :seen $to(who)"
 }
}

proc seen:priv:who {nick host hand arg} {
 global to seen
 if {$seen(blocked) == 1} {
	putserv "PRIVMSG $nick :Try again in a few seconds."
	return;
 }
 set seen(blocked) 1
 set to(nick) $nick
 set to(chan) " "
 set to(who) [string tolower [lindex $arg 0]];
  if {[string tolower [lindex $arg 1]] != "" || [regexp -all {@} $to(who)] > 0} {
  set option [string tolower [lindex $arg 1]]
  putserv "PRIVMSG seen :seen $to(who) $option"
  } else {
    putserv "PRIVMSG SeenServ :seen $to(who)"
 }
}

proc seen:pub:help {nick host hand chan arg} {
 global to seen
 if {$seen(blocked) == 1} {
   if {[channel get $chan pubseen]} {
     putserv "PRIVMSG $chan :$nick : Try again in a few seconds."
   } else {
	 putserv "NOTICE $nick :Try again in a few seconds."
   }
   return;
 }
 set seen(blocked) 1
 set to(nick) $nick
 set to(chan) $chan
 set to(who) [string tolower [lindex $arg 0]];
 putserv "PRIVMSG seen :help"
}

proc seen:priv:help {nick host hand arg} {
 global to seen
 if {$seen(blocked) == 1} {
	putserv "PRIVMSG $nick :Try again in a few seconds."
	return;
 }
 set seen(blocked) 1
 set to(nick) $nick
 set to(chan) " "
 set to(who) [string tolower [lindex $arg 0]];
 putserv "PRIVMSG seen :help"
}

proc seen:ctcp:reply {nick uhost handle dest keyword text} {
global ctcp-version seen
set {ctcp-version} "using $seen(name)"
}

putlog "seen.tcl v$seen(version) by Demons Team loaded"