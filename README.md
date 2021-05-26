# SpellNotifications
_**Now compatible with Retail, Classic & BC Classic**_

Available at: [Curse], [Wago], [WowInterface] or [Github]

## About 
_All credit to the original author Veev._

This is a reupload of Veevs original SpellNotifications from [Veevs Vault](http://www.veevsvault.com/addons/) which has been offline for some time now. The addon has been increasingly hard to get your hands on but has been working well up until the recent BFA 8.0 patch where it broke down entirely (due to some Blizzard [api changes](https://us.battle.net/forums/en/wow/topic/20762318007)), so I decided to try and bring it back to life.

# What does the addon do?
For those who are new to Spellnotifications it is an addon that textually displays:

- When you dispel (offensively, defensively, or spellstolen), what was dispelled
- When you interrupt a spell and what school was interrupted
- When you reflect or ground a spell
- When your attacks, spells or heals are _immuned_, _evaded_ or similar effects.
- Announces when your pet dies
  - This also plays a quick _buzz_ sound (_credit to @oscarwika for bringing this back_)

# What has changed from the original?
It has been updated for BFA's 8.0 change to combat log events, which had made the original addon unusable, and also cleaned up from old contents that was using Pandaria era spells and talents. There were also a bunch of unused code blocks and commented out code that seemed to be have been used by Veev personally for notifying his friends of spells and such, they are now gone. Other than that it should work just like it did before, announcing dispels, kicks, immunities etc.

The code has also been cleaned up and refactored into more files for the sake of readability and maintainability (thanks to @oscarwika). 

# Showcase
![Missed spells](https://cdn.discordapp.com/attachments/249637569636204555/483729453260865536/unknown.png)
![evaded spells](https://user-images.githubusercontent.com/732505/119417757-d5361480-bcf6-11eb-98f6-a53e9d869633.png)
![stolen spells](https://user-images.githubusercontent.com/732505/119417851-0d3d5780-bcf7-11eb-9508-bb57e6a3fd4c.png)
![interrupts](https://user-images.githubusercontent.com/732505/119710366-8e632e80-be5e-11eb-8359-3cc99b46a86e.jpg)


_More image examples coming soon™_


[Curse]: https://www.curseforge.com/wow/addons/spellnotifications
[Wago]: https://addons.wago.io/addons/spellnotifications
[WowInterface]: https://www.wowinterface.com/downloads/fileinfo.php?id=26039
[Github]: https://github.com/jobackman/SpellNotifications/releases
