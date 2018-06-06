# How to build.
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