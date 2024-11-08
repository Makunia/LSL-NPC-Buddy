// NPC Buddy 1.4 by Mefi! (mefistophiles) - January 2024
// Drop this script into a prim and follow the commands sent!
// 1.0 (November 2023) - Basic Titler Functionality
// 1.1 (November 2023) - Ability to make invisible/set health values/clear titler
// 1.2 (January 2024) - Edits for Makunia
// 1.3 (January 2024) - Click NPC for menu, dialog boxes. Makunia's suggestion to have channel in title.
// 1.4 (January 2024) - Support for Animesh toggleable animations added. Ensure "Animated Mesh" is checked on the object and the animations defined in the menus/strings are in the object's contents.
//Todo: Notecard based config

// NPC Defaults
//
string monsterName = "A demo NPC!";
integer maxHealth = 100;
integer currentHealth = 100;
vector titlerColor = <1.0,0.0,0.0>;
integer isVisible = 1;
integer channelOn = 1;
integer textMode = 0;
// Comms
//
integer listen_handle; // listener for commands
integer listen_handle2;
integer listenChannel; // command listener channel
integer listenChannel2; // for textboxes
// Security
//
key toucherID;
list allowedUUIDs; // Not currently UUIDs, use resident names here. (ex. mefistophiles Resident)
// Menu Values:
// 
list menuChoices = ["Vis/Invis", "Show Channel", "Allow List", "Set Name", "Set Health", "SetMaxHealth", "(-) Health", "Reset Health", "(+) Health", "Animation"];
list animMenuChoices = ["Stand", "Fight", "Dead", "Stop Animating"];
string menuMessage = "Welcome to Mefi's NPC Buddy! Select an option:";
string  textBoxOperation = "error"; // String for what we are doing with textbox inputs
// Animation Values:
//
integer dieAt0HP = 0;
integer standByDefault = 0; 
string standAnimation = "STAND_RB-01";
string fightAnimation = "Fight";
string dieAnimation = "death-correct";
string nowPlaying = "none";

string animStandDesc;
string animStandName;
string animFightDesc;
string animFightName;
string animDieDesc;
string animDieName;

// Notecard System
//
string      NOTECARD = "config";
string      NOTECARD_ANIMESH = "config-animesh";
integer     intLine1;
key         keyConfigQueryhandle;
key         keyConfigUUID;

// Utility Functions
//
updateTitler() // Repaints titler with current information
{
    if (channelOn == 1)
    {
        llSetText( "(" + (string) listenChannel + ") " + monsterName + "\n" + (string) currentHealth + "/" + (string) maxHealth, titlerColor, 1.0);
    }
    else 
    {
        llSetText( monsterName + "\n" + (string) currentHealth + "/" + (string) maxHealth, titlerColor, 1.0);
    }
        
}

subtractHealth(integer health) // Subtracts NPC Health
{
    currentHealth=currentHealth-health;
    if (currentHealth <= 0)
    {
        currentHealth = 0;
        if (dieAt0HP = 1)
        {
            setAnimation("die");
        }
    }
    updateTitler();
}

addHealth(integer health) // Adds NPC Health, allows for overhealing in instances where players do 'healing' damage.
{
    currentHealth=currentHealth+health;
    updateTitler();
}

resetHealth() // Resets NPC current health to max health
{
    currentHealth=maxHealth;
    updateTitler();
}

setName(string name) // Sets NPC name in titler
{
    monsterName = name;
    updateTitler();
}

setMax(integer max) // Sets maximum NPC health (does not auto-heal to max.
{
    maxHealth = max;
    updateTitler();
}

setCurrent(integer current) // Sets current NPC health
{
    currentHealth = current;
    updateTitler();
}

setAllow(string name) // Adds a user to the menu/communication allow list.
{
    allowedUUIDs = allowedUUIDs + name;    
}

setAnimation(string type) // Animation worker, handles starting and stopping animations.
{
    if (nowPlaying == "none")
    {
        nowPlaying = nowPlaying; // do nothing here
    }
    else
    {
        if ( nowPlaying == "stand")
            llStopObjectAnimation(standAnimation);
        else if ( nowPlaying == "fight")
            llStopObjectAnimation(fightAnimation);
        else if ( nowPlaying == "die" )
            llStopObjectAnimation(dieAnimation);
    }
    if (type == "stand")
    {
        nowPlaying = "stand";
        llStartObjectAnimation(standAnimation);
    } else if (type == "fight")
    {
        nowPlaying = "fight";
        llStartObjectAnimation(fightAnimation);
    } else if (type == "die")
    {
        nowPlaying = "die";
        llStartObjectAnimation(dieAnimation);
    }
        
}

setConfig(list line)
{
    string argument = llList2String(line, 0);
    string value = llList2String(line, 1);
    //llSay(0, argument + value);
    if (argument == "npcName")
    {
        setName(llList2String(line, 1) + " " + llList2String(line, 2) + " " + llList2String(line, 3) + " " + llList2String(line, 4));

    } else if ( argument == "maxHealth" )
    {
        maxHealth = (integer) value;
    } else if ( argument == "currentHealth" )
    {
        currentHealth = (integer) value;
    } else if ( argument == "textMode" )
    {
        textMode = (integer) value;
    } else if ( argument == "titlerColor" )
    {
        titlerColor = (vector) value;
    } else if ( argument == "isVisible" )
    {
         isVisible = (integer) value;
    } else if ( argument == "channelOn" )
    {
        channelOn = (integer) value;
    } else if ( argument == "dieAt0HP" )
    {
        dieAt0HP = (integer) value;
    } else if ( argument == "standByDefault" )
    {
        standByDefault = (integer) value;
    } else if ( argument == "animStandDesc" )
    {
        animStandDesc = value;
    } else if ( argument == "animStandName" )
    {
        animStandName = value;
    } else if ( argument == "animFightDesc" )
    {
        animFightDesc = value;
    } else if ( argument == "animFightName" )
    {
         animFightName = value;
    } else if ( argument == "animDieDesc" )
    {
        animDieDesc = value;
    } else if ( argument == "animDieName" )
    {
        animDieName = value;
    } 
    else
    {
        //llOwnerSay("Invalid data found in config file: " + argument);
    }
}


default
{
    state_entry()
    {
        if (llGetInventoryType(NOTECARD) == INVENTORY_NONE && llGetInventoryType(NOTECARD_ANIMESH) == INVENTORY_NONE)
        {
            llOwnerSay("The notecard '"+NOTECARD+"'  is not found, using system defaults!");
            state main;
        }
        keyConfigQueryhandle = llGetNotecardLine(NOTECARD, intLine1);
        keyConfigUUID = llGetInventoryKey(NOTECARD);
    }

    dataserver(key keyQueryId, string strData)
    {
        if (keyQueryId == keyConfigQueryhandle)
        {
            if (strData == EOF)
            {
                llOwnerSay("Notecard Found: " + (string) intLine1 + " lines read.");
                state main;
            }

            keyConfigQueryhandle = llGetNotecardLine(NOTECARD, ++intLine1);

            strData = llStringTrim(strData, STRING_TRIM_HEAD);      // Trim Whitespace; (not mandatory; if you use a space as marker you must erase this line
            if (llGetSubString (strData, 0, 0) != "#")              // is it a comment?
            {
                list notecardLine = llParseString2List(strData,[" "], [""]);
                //llSay(0, "Test: " + llList2String(notecardLine, 1));
                setConfig(notecardLine);
                
            }
        }
    }
    
    
            
            
}

state main
{
    on_rez(integer start_param)
    {
        // Restarts the script every time the object is rezzed
        llResetScript(); 
    }
    
    changed(integer intChange)
    {
        if (intChange & CHANGED_INVENTORY)
        {   // If the notecard has changed, then reload the notecard
            if (keyConfigUUID != llGetInventoryKey(NOTECARD))
                llResetScript();
        }
    }
    
    state_entry()
    {
         // See if our notecard is there, if so- read it.
         // Comms Initialization
         float randomFloat = llFrand(800.0);
         listenChannel = 100 + (integer) randomFloat;
         listenChannel2 = 1000 + (integer) randomFloat;
         if (listenChannel == 333)
             listenChannel = listenChannel + 233;  // so we don't use the same listener as the highlight prim's listener
        
         listen_handle = llListen(listenChannel, "", NULL_KEY, "");
         listen_handle2 = llListen(listenChannel2, "", NULL_KEY, "");
         if (textMode == 1)
         {
             llOwnerSay("------------------------------------------ ");
             llOwnerSay("Welcome to NPC Buddy Manager by Mefi! (mefistophiles)");
             llOwnerSay("Change the titler and keep track of health without editing scripts!");
             llOwnerSay("Listening on " + (string) listenChannel + "!");
             llOwnerSay("Click the NPC for a dialog menu with all of these commands!");
             llOwnerSay("--(Setup Commands)------------------------- ");
             llOwnerSay("/" + (string) listenChannel + " setName {name} - Sets the name of your NPC!");
             llOwnerSay("/" + (string) listenChannel + " setMax {number} - Sets the maximum health of your NPC!");
             llOwnerSay("/" + (string) listenChannel + " setCurrent {number} - Sets the current health of your NPC!");
             llOwnerSay("/" + (string) listenChannel + " reset - Resets the monster to full health!");
             llOwnerSay("/" + (string) listenChannel + " clear - Clears the titler!");
             llOwnerSay("/" + (string) listenChannel + " visible - Toggles the NPC visible or invisible!");
             llOwnerSay("/" + (string) listenChannel + " channel - Toggles the channel visibility in the NPC titler.");
             llOwnerSay("--(Usage)------------------------- ");
             llOwnerSay("/" + (string) listenChannel + " damage {number} - Subtracts # of health from NPC.");
             llOwnerSay("/" + (string) listenChannel + " heal {number} - Adds # of health to NPC.");
        }
        else
        {
            llOwnerSay("Welcome to NPC Buddy Manager by Mefi! (mefistophiles)");
            llOwnerSay("Listening on " + (string) listenChannel + "!");
            llOwnerSay("Text mode is OFF, click the NPC to interact with the menu.");
             updateTitler();
        }
    }
    
    listen( integer channel, string name, key id, string message )
    {  
        if (id != llGetOwner() && (llKey2Name(id) != llList2String(allowedUUIDs, 0)) && (id != llList2String(allowedUUIDs, 1)))
        {
            return;
        }
        
        if (channel == listenChannel2)
        {
            if (textBoxOperation == "heal")
            {
                addHealth((integer) message);
                textBoxOperation = "error";
            } else if (textBoxOperation == "damage")
            {
                subtractHealth((integer) message);
                textBoxOperation = "error";
            } else if (textBoxOperation == "name")
            {
                setName(message);
            } else if (textBoxOperation == "current")
            {
                 setCurrent((integer) message);
                 textBoxOperation = "error";
            } else if ( textBoxOperation == "setmax")
            {
                 setMax((integer) message);
                 textBoxOperation = "error";
            } else if (textBoxOperation == "allow")
            {
                allowedUUIDs = allowedUUIDs + message;
                textBoxOperation = "error";
            }
            //else
                // ignore everything else
        }
        else
        {
                // Main Listener on RANDOM channel
            
                list parseList = llParseString2List(message,[" "],[" "]);
                string arg1 = llList2String(parseList, 0);
                string arg2 = llList2String(parseList, 1);
                string arg3 = llList2String(parseList, 2);
                string arg4 = llList2String(parseList, 3);
                if ( llToLower(arg1) == "setname" || message == "Set Name")
                {
                    if (message != "Set Name")
                        setName(arg2 + " " + arg3 + " " + arg4);
                    else
                    { 
                        textBoxOperation = "name";
                        llTextBox(id, "Enter a new name for this NPC:", listenChannel2);
                    }
                } else if ( llToLower(arg1) == "setmax" || message == "SetMaxHealth")
                {
                    if (message != "SetMaxHealth")
                        setMax((integer) arg2);
                    else
                    { 
                        textBoxOperation = "setmax";
                        llTextBox(id, "Enter a positive value to set the maximum amount of HP this NPC can have:", listenChannel2);
                    }
                    
    
                } else if ( llToLower(arg1) == "setcurrent" || message == "Set Current")
                {
                    if (message != "Set Current")
                        setCurrent((integer) arg2);
                    else
                    { 
                        textBoxOperation = "current";
                        llTextBox(id, "Enter a positive value to set the current amount of HP this NPC has:", listenChannel2);
                    }
                    
                } else if ( llToLower(arg1) == "reset" || message == "Reset Health")
                {
                    resetHealth();
                } 
                else if ( llToLower(arg1) == "damage" || message == "(-) Health" )
                {
    
                    if (message != "(-) Health")
                        subtractHealth((integer) arg2);
                    else
                    { 
                        textBoxOperation = "damage";
                        llTextBox(id, "Enter a positive value for how many hitpoints you would like to damage this NPC:", listenChannel2);
                    }
                        

                } 
                else if ( llToLower(arg1) == "heal" || message == "(+) Health")
                {
                    if (message != "(+) Health")
                        addHealth((integer) arg2);
                    else
                    { 
                        textBoxOperation = "heal";
                        llTextBox(id, "Enter a positive value for how many hitpoints you would like to heal this NPC:", listenChannel2);
                    }
                        
                } 
                else if ( llToLower(arg1) == "clear" || message == "Clear Titler")
                {
                    llSetText( "", titlerColor, 1.0);
                }
                else if ( llToLower(arg1) == "visible" || message == "Vis/Invis")
                {
                    if (isVisible == 0)
                    {
                        isVisible = 1;
                        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                        updateTitler();
                    }
                    else
                    {
                        llSetText( "", titlerColor, 1.0);
                        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                        isVisible = 0;
                    }
                } else if ( llToLower(arg1) == "channel" || message == "Show Channel")   
                {                
                    if (channelOn == 1)
                    {
                        channelOn = 0;
                        updateTitler();
                    }
                    else
                    {
                        channelOn = 1;
                        updateTitler();
                    }
                } else if ( llToLower(arg1) == "allow" || message == "Allow List")
                {
                     if (message != "Allow List")
                        setAllow(arg2 + " " + arg3 + " " + arg4);
                    else
                    { 
                        textBoxOperation = "allow";
                        llTextBox(id, "Enter the resident you wish to add to the NPC's allow list:", listenChannel2);
                    }
                    
                } else if ( llToLower(arg1) == "animate" || message == "Animation")
                {
                    if (message != "Animation")
                        llOwnerSay("Text options for animation not yet implemented, use the click menu for the time being.");
                    else
                    {
                        llDialog(toucherID, menuMessage, animMenuChoices, listenChannel);
                    }
                } else if ( message == "Stand")
                {
                    setAnimation("stand");
                } else if ( message == "Fight")
                {
                    setAnimation("fight");
                } else if ( message == "Dead" )
                {
                    setAnimation("die");
                } else if ( message == "Stop Animating")
                {
                    setAnimation("none");
                }
                    
                        
               // else 
            }
                   //llOwnerSay("Not a command: " + arg2);
    }

    touch_start(integer total_number)
    {
        toucherID = llDetectedKey(0);
        if (toucherID != llGetOwner() && (llKey2Name(toucherID) != llList2String(allowedUUIDs, 0)) && (llKey2Name(toucherID) != llList2String(allowedUUIDs, 1)))
        {
            //stuff
        }
        else
        {
            llDialog(toucherID, menuMessage, menuChoices, listenChannel);
        }
    }
    
}
