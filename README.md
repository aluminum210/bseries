# BSeries add-on pack.
A series of add-ons for World of WarCraft: Wrath of the Lich King game.
The purpose is to provide a collection of core minimalist add-ons.
The main goals are high performance and minimum user configuration.
Currently in-game to-do list, inventory manager and keybind manager are planned. 
## Developers.
The project is built using Gradle 4.7.
Gradle wrapper is omitted. 
Therefore, in order to build the cloned project,
a developer will have to install Gradle manually.
See https://gradle.org/

In order to run the build the developer will have to create `local.properties` file in the project directory.
The file is used to define environment specific properties.
See https://github.com/b3er/gradle-local-properties-plugin

It is possible to simply extract the source files and ToC files for the add-ons and work with them.
However, future releases of the add-ons might rely on more sophisticated features of the Gradle build tool.
This might make project set-ups incompatible or in some other way introduce problems for developers and users alike.