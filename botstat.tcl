###########################################################################
#This tcl was made for making statics about your bot
#Below you'll find some settings you may need to change
#This script is free to use but don't forget who made it => Tijmerd:-)
#The script will nog create anymor the error page when the bots goes
#offline, this will be added alter again! sorry for this
#
#Greetz Tijmerd 
#visit http://tijmie.x-plose.be for more info!
#or contact me @ tijmie@perso.be
###########################################################################
#!!!!!!!NOTE!!!!!!!!!!#
#######################
#YOU HAVE TO RESTART THE EGGDROP/WINDROP BEFORE THE SCRIPT *WILL* WORK 
#THIS BECAUSE TIMERS ONLY WILL START ON RESTART EVENT (.restart)
#######################


#following variabel is the path where you want that the html will be saved
#vb /home/tijmerd/public_html/stats/ 
#NOTE: don't forget the "/" on the end!
#Hint: for windrops it's enough to use "" then eggdrop will use the dir where eggdrop.exe is stored
set outputpath "/var/www/html/"

#following variabel contains the name of the html
#NOTE: don't use a "/" before the name!
set outputname "index.html"

#this variabel is the seconds to wait to update the status page
#default: 10
set seconds "1"

#deze variabel bevat de waarde of je ene berichtje in de partyline wilt of niet als de status
#page is geupdated (1 = eneblad, 0 = disabled)
#default = 0
set showinpline "0"

#this variabels are used for the layout of the html page
#because we have a full list of chan stats and else it's not clear
#that we use 1 color we user 2colors
#default = #FFFFFF (white)
set firstforecolor "#FFFFFF"

#The second color
#Default = ##FF0000 (red)
set secondforecolor "#FF0000"

#The border color of the tables
#Default = #0000FF (blue)
set bordercolor "#0000FF"

#This is the alternative color for other information like os, server,...
#Default = #00FF00 (green 
set altcolor "#00FF00"

#Here you can set the background color
#Default = #000000 (black)
set backgroundcolor "#000000"

#followinf variabels are for the links we use
#the color that normal liks should have
#Default = #FF0000 (red)
set linkcolor "#FF0000"

#Visited links
#Default = #FFFFFF (white)
set vlinkcolor "#FFFFFF"

#active links
#default = #FFFFFF (white)
set alinkcolor "#FFFFFF"

#this color is the color of the global stats
#default = #0000FF (blue)
set gscolor "#FF00FF"

#this color is for the king stats
#default = #FFFF00 (yellow)
set kgcolor "#FFFF00"
#####################################
#don't change anything below!!      #
#####################################
bind evnt - loaded pub_ld
#
#
#the bot was just started of restarted, then all timers
#will be killed, to prevent of stop working we call the 
#function to restart the timers

proc pub_ld {uptime} {
pub_timers
}


#this functon is called when you start or restart the bot
#we put 1 time on the seconds bases on the variabel you edited
#then we set a second timer on the same seconds to prevent that
#the bot will stop with making the page

proc pub_timers { } {
global seconds
	utimer $seconds pub_bstats
	utimer $seconds pub_timers
}


#now this is the "core" function, here we will set all needed variabels
#for the status page. if we have done that we call the function
#'writehtml' with all needed variabels to make the page

proc pub_bstats { } {
global server botnick uptime connec server-online
set uptimer [duration [expr [unixtime] - $uptime]]
set online [duration [expr [unixtime] - ${server-online}]]
set pom [expr [unixtime] - ${server-online}]

if {$pom == [unixtime]} {
	set connec "Neen"
	set online "I'm not connected to a server!"
} else {
	set connec "Ja"
}
if {$server == ""} {
	set serverke "I'm not on a server right now!"
} else {
	set serverke $server
}
writehtml $serverke $botnick [unames] $uptimer $online [channels] $connec
}


#in this function we are processing al setting in a html
#file, after that a message will apear in the partyline
#"succesfull..." this you may disable by putting an "#" 
#before the sentence

proc writehtml {server botnick os uptime online chan connected } {
global outputpath outputname showinpline firstforecolor secondforecolor bordercolor altcolor backgroundcolor linkcolor alinkcolor vlinkcolor gscolor kgcolor
#
set totalops 0
set totalvoices 0
set totalnormal 0
set totalusers 0
set king 0
set ochan 0
#
set kleurschema "0"
if {$chan == ""} {
	set chan "No channels supported?!"
}

set fd [open $outputpath$outputname w]
	puts $fd "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"
	puts $fd "<html>"
	puts $fd "<head>"
	puts $fd "<title>Stats page for $botnick</title>"
	puts $fd "<meta http-equiv=\"content-Type\" content=\"text/html; charset=iso-8859-1\">"
	puts $fd "</head>"
	puts $fd "<body bgcolor=$backgroundcolor text=$altcolor link=$linkcolor vlink=$vlinkcolor alink=$alinkcolor>"
	puts $fd "<table width=\"100%\" height=\"445\" border=\"1\" align=\"center\" bordercolor=$bordercolor>"
	puts $fd "  <tr> "
	puts $fd "    <td colspan=\"7\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Status page for $botnick</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "  <tr> "
	puts $fd "    <td width=\"24%\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Server:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$server</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "  <tr> "
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Online?</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$connected</font></div></td>"
	puts $fd "  </tr>"
 	puts $fd " <tr> 	"
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Online time:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$online</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "  <tr> "
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Uptime:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$uptime</font></div></td>"
	puts $fd "  </tr>"
 	puts $fd " <tr> "
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">OS:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$os</font></div></td>"
	puts $fd "  </tr>"
	puts $fd " <tr> "	
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Channels:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">$chan ([llength [split $chan " "]] chans)</font></div></td>"
	puts $fd "  </tr>"

	############################
	#this will make chan stats #
	############################

	foreach pom [channels] {
		set ops 0
		set voices 0
		set normal 0
		set users 0
		#
		#
		if {[botonchan $pom] == 0} {
			set channame "$pom I'm not there on the moment"
			set modes "N/A"
			set topic "N/A"
		} else {
			set channame "$pom"
			foreach user [chanlist $pom] {
				if {[isop $user $pom] == "1"} {
					incr ops 1
				} else {
					if {[isvoice $user $pom] == "1"} {
						incr voices 1
					} else {
						incr normal 1
					}
				}
				incr users 1
			}
			set modes [lindex [getchanmode $channame] 0]
			set topic [topic $channame]
			if {$topic == ""} {
				set topic "No topic set!"
			}
		}
		#
		#
		incr totalops $ops
		incr totalvoices $voices
		incr totalnormal $normal
		incr totalusers $users		
		#
		#
		if {[botisop $pom] == "1"} {
			incr king $users
			incr ochan 1
		}
		#
		#
		if {$kleurschema == 0} {
			set kleur "$firstforecolor"
			incr kleurschema 1
		} else {
			set kleur "$secondforecolor"
			set kleurschema 0
		}
		#
		#
		puts $fd "  <tr>"
		puts $fd "    <td rowspan=\"4\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Chan stats:</font></div></td>"
		puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$channame</font></div></td>"
		puts $fd "  </tr>"
		puts $fd "  <tr> "
		puts $fd "    <td colspan=\"5\" align=\"left\"><font color=$kleur face=\"Fixedsys\">Topic: $topic</font></td>"
		puts $fd "  </tr>"
		puts $fd "<tr> "
		puts $fd "    <td width=\"14%\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Ops</font></div></td>"
		puts $fd "    <td width=\"13%\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Voices</font></div></td>"
		puts $fd "    <td width=\"16%\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Normal</font></div></td>"
		puts $fd "    <td width=\"15%\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Users</font></div></td>"
		puts $fd "    <td width=\"18%\"><div align=\"center\"><font color=$kleur face=\"Fixedsys\">Chan modes</font></div></td>"
		puts $fd "  </tr>"
		puts $fd "  <tr> "
		puts $fd "    <td><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$ops</font></div></td>"
		puts $fd "    <td><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$voices</font></div></td>"
		puts $fd "    <td><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$normal</font></div></td>"
		puts $fd "    <td><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$users</font></div></td>"
		puts $fd "    <td><div align=\"center\"><font color=$kleur face=\"Fixedsys\">$modes</font></div></td>"
		puts $fd "  </tr>"
	}

	############################
	#Total ops, etc stats      #
	############################

	puts $fd "  <tr>"
	puts $fd "    <td rowspan=\"3\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Global stats:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Global chan stats</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "<tr> "
	puts $fd "    <td width=\"14%\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Ops</font></div></td>"
	puts $fd "    <td width=\"13%\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Voices</font></div></td>"
	puts $fd "    <td width=\"16%\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Normal</font></div></td>"
	puts $fd "    <td width=\"15%\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Users</font></div></td>"
	puts $fd "    <td width=\"18%\"><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">Chan modes</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "  <tr> "
	puts $fd "    <td><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">$totalops</font></div></td>"
	puts $fd "    <td><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">$totalvoices</font></div></td>"
	puts $fd "    <td><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">$totalnormal</font></div></td>"
	puts $fd "    <td><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">$totalusers</font></div></td>"
	puts $fd "    <td><div align=\"center\"><font color=$gscolor face=\"Fixedsys\">N/A</font></div></td>"
	puts $fd "  </tr>"

	############################
	#king stats                #
	############################

	puts $fd "  <tr>"
	puts $fd "    <td rowspan=\"1\"><div align=\"center\"><font color=$kgcolor face=\"Fixedsys\">king stats:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$kgcolor face=\"Fixedsys\">I'm opped in $ochan channels of [llength [split $chan " "]] I'm in. That means I'm the King of $king/$totalusers slaves!!</font></div></td>"
	puts $fd "  </tr>"
	puts $fd " <tr> "
	puts $fd "    <td><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">Made on:</font></div></td>"
	puts $fd "    <td colspan=\"5\"><div align=\"center\"><font color=$altcolor face=\"Fixedsys\">[ctime [unixtime]]</font></div></td>"
	puts $fd "  </tr>"
	puts $fd "</table>"
	puts $fd "<p align=\"center\"><font color=$altcolor face=\"Fixedsys\">Status page created with <a href=\"http://tijmie.x-plose.be/tcl/bot-status/\" target=\"_blank\">botstatus.tcl</a></font></p>"
	puts $fd "<p align=\"center\"><font color=$altcolor face=\"Fixedsys\">Created by Tijmerd 2004</font></p>"
	puts $fd "</body>"
	puts $fd "</html>"
close $fd
if {$showinpline == "1"} {
	putlog "Succesfully updated Status page!"
}
} 

putlog "Succesfully loaded Bot-status v2.0 made by Tijmerd"
