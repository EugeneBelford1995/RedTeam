# Mishky's Red Team Auditor
Essentially an idea borrowed from harmj0y &amp; converted into native PowerShell, also checks nested groups.

This little query and it's Blue Team version were the capstones of our Auditing AD Series (https://happycamper84.medium.com/how-many-angels-can-dance-on-the-head-of-a-pin-16fe786e658b). 

The Red Team version pulls all groups, including nexted groups, that the current user is a member of and then enumerates all 'Dangerous Rights' in AD that have been delegated to any of them. It also includes Everyone, Authenticated Users, & Domain Users just in case something was badly [mis]configured.

It only uses Get-ADNestedGroups.ps1 and the PowerShell AD module, so it does not trip Defender and will run on any domain workstation as any Domain User. 

If you do not already have the PowerShell AD module loaded, then see our github repo that hosts it. The files are from Microsoft.

RedTeam.ps1 is the updated, improved version. The other *.ps1 is the orginal PoC.
