set regnick "IME-BOT"

set nspass "parolkataetuk"

set nsserv "NS!NickServ@services.bg"

set csserv "CS!ChanServ@services.bg"

set csnick "ChanServ"
set nsnick "NickServ"

proc deban {arg} {
global botnick regnick csnick
if {[string match "*[string toupper $botnick]*" [string toupper $regnick]]} {
	set c [lindex $arg 0]
	putlog "Requesting UNBAN on $c from CS.."
	putserv "PRIVMSG $csnick :UNBAN $c"
	putserv "PRIVMSG $csnick :INVITE $c"
	}

proc getop {arg} {
global botnick regnick csnick
if {[string match "*[string toupper $botnick]*" [string toupper $regnick]]} {
	set c [lindex $arg 0]
	putlog "Requesting OP on $c from CS ..."
	putserv "PRIVMSG $csnick :OP $c $botnick"
	}
}

proc invite {arg} {
global botnick regnick
if {[string match "*[string toupper $botnick]*" [string toupper $regnick]]} {
	set c [lindex $arg 0]
	putlog "Requesting INVITE on $c from CS.."
	putserv "PRIVMSG CS :INVITE $c"
	}
}

# .prot #ibiza     -> turn ON service support.
# .prot #ibiza off -> turn OFF service support.

proc sup_proc {hand idx  arg} {
if {[lindex $arg 1]!="off"} {
	channel set [lindex $arg 0] need-op "getop [lindex $arg 0]"
	channel set [lindex $arg 0] need-unban "deban [lindex $arg 0]"
	channel set [lindex $arg 0] need-invite "invite [lindex $arg 0]"
	putlog "turn ON [lindex $arg 0] services support"
	} {
	channel set [lindex $arg 0] need-op ""
	channel set [lindex $arg 0] need-unban ""	
	channel set [lindex $arg 0] need-invite ""
	putlog "turn OFF [lindex $arg 0] service support"
}
}

proc notice_a {from keyword arg} {
global nsnick csnick nspass nsserv csserv
set servresp [lindex $arg 1]
set msg [lrange $arg 0 end]

if {$from==$nsserv} {
        if {[lindex $arg 1]==":This"} {
        putserv "PRIVMSG $nsnick :IDENTIFY $nspass"
        putlog "$nsnick want IDENTIFY..." }
	}

f {$from==$csserv} {
        if {[lindex $arg 2]=="denied."} {
        	putlog "$csnick can't recognized me ..identifing.."
        	putserv "PRIVMSG $nsnick :IDENTIFY $nspass" }
	}

unbind dcc o|o msg *dcc:msg
bind dcc n|- msg *dcc:msg

bind dcc n prot sup_proc
bind raw - notice notice_a

putlog "ShakeItSup.tcl @ Holandec | Download from http://mIRCHelp.free.tcl/tcl.html"