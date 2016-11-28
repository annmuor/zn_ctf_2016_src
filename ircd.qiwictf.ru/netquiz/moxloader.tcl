### moxquizz.tcl -- quizzbot for eggdrop 1.6.9+
##
### Author: Moxon <moxon@meta-x.de> (AKA Sascha Lüdecke)
##
### Copyright (C) 2000 Moxon AKA Sascha Lüdecke
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##

### Note about prior versions:
##
##
## Versions before 0.9.0 contained all the functions in a single file,
## which got more and more messy over the time.  Since I didn't
## refactor in time, I ended up with features spread all over the
## code, badly orthogonalized and hard to maintain (boiling frog,
## *quak*).  This version aims at changing this.

package require msgcat

namespace import -force msgcat::*

source netquiz/src/allstars.tcl
source netquiz/src/color.tcl
source netquiz/src/config.tcl
source netquiz/src/gamestate.tcl
source netquiz/src/help.tcl
source netquiz/src/irc.tcl
source netquiz/src/misc.tcl
source netquiz/src/questions.tcl
source netquiz/src/ranking.tcl
source netquiz/src/userquest.tcl
source netquiz/src/users.tcl
source netquiz/src/util.tcl

source netquiz/src/moxquizz.tcl

source netquiz/src/bindings.tcl

# You don't need this as it produced large files with little or no
# useful information
# [pending] This doesn't work on moxquizz.de due to tcl version!
#source netquiz/src/debug.tcl

# Main initialization routine
namespace eval ::moxquizz {

    set version_moxquizz "0.9.0"

    #
    # Initialize
    #

    cfg_read $configfile

    puts $configfile
    puts $quizconf(questionset)
    puts $quizconf(language)

    log "**********************************************************************"
    log "--- $botnick started"

    # this makes sure, that the funstuff will be initialized correcty, if loaded
    cfg_apply "language" $quizconf(language)

    questions_load $quizconf(questionset)

    rank_load $botnick 0 {}
    allstars_load $botnick 0 {}

    if {$quizconf(quizchannel) != ""} {
        set quizconf(quizchannel) [string tolower $quizconf(quizchannel)]
        channel add $quizconf(quizchannel)
    }
}
