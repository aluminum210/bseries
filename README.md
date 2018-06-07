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

Gradle provides many advantages. One of them, that the projects series relies most upon, is as follows.
With a single console command, run LuaCheck, assemble archives and copy the files into the game's AddOns directory.

In order to run the build the developer will have to create `local.properties` file in the project directory.
The file is used to define environment specific properties.
See https://github.com/b3er/gradle-local-properties-plugin
For the exact properties that needs to be defined see `build.gradle` of corresponding projects.

It is possible to simply extract the source files and ToC files for the add-ons and work with them.
However, future releases of the add-ons might rely on more sophisticated features of the Gradle build tool.
This might make project set-ups incompatible or in some other way introduce problems for developers and users alike.
### How to build.
Assuming Windows OS.

1. Get Chocolatey (https://chocolatey.org/).
See https://chocolatey.org/install
Optionally also see https://github.com/tilkinsc/LuaConsole/wiki/LuaRocks-Support-Windows-MinGW

2. Get LuaRocks (https://luarocks.org/) via Chocolatey.
```
choco install -y lua51 luarocks
```

3. Get LDoc (https://github.com/stevedonovan/LDoc) via LuaRocks.
```
luarocks install ldoc
```
If this step fails, possibly you need to adjust LuaRocks configuration.
See step 1 for details.

4. Get Gradle (https://gradle.org/).

5. Build.
```
gradle clean assemble 
```
Visit `${projectDir}/build/distributions/`
Alternatively:
```
gradle clean assemble deployLocal 
```
Remember to adjust environment properties in `local.properties` file.