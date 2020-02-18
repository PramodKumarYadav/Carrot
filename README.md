# 🥕🐇>_ : Carrot 

This is a template framework in Powershell that you can use as a reference, if you have a need to test RabbitMQ.
Framework uses open source tools such as rabtap for tapping RabbitMQ and jq for parsing jsons. 

Most general purpose functions, should be usable for your projects with minimum customization. 
Special thanks to https://github.com/jandelgado/rabtap for making this project possible with his awesome tool rabtap!

# Credits
This framework is heavily based on the open source work of jandelgado and his tool rabtap. My compliments and thanks to him for building this tool!
You can learn more about the tool @ Github location: https://github.com/jandelgado/rabtap

# Scope
Todo

# Design
Specify the project structure here:
1. TestData
2. TestApplications
3. TestEnvironment
4. TestModules
5. TestReport
6. TestMaintenance

# Requirements
Todo

## If installing local
* Windows OS.
* Softwares:
    * docker desktop
    * Powershell 5 or more
    * git
* Project:
    * This project cloned directly in your C: drive
* Docker logged in 
    * If in future, you put any images on your localhost.
* Extensions in Visual studio Code:
    * Powershell
    * Docker extension.
    * Remote containers
    * kubernetes 
* Extensions in Visual studio Code (container):
    * Powershell
        * In settings- > Extensions ->remote -containers -> add ms-vscode.powershell (To have powershell in container)
* More steps to add here. 

## If runing on docker 
* Docker desktop installed.
* Clone the project.
* To specify here...
* PS D:\Carrot> docker image build -t carrot:v1 .
* PS D:\Carrot> docker container run --name rabtap -it carrot:v1 
* PS /carrot> ./main.ps1

# Execute 
Write down steps to execute here.
1. Steps to execute, set up here. 

# Feature List (to add in future)
* - [ ] to do.
* - [x] done.

# [Naming conventions](https://medium.com/better-programming/string-case-styles-camel-pascal-snake-and-kebab-case-981407998841)
* Naming directories and files
    * Directory names: PascalCase
    * File names: kebab-case
* [Naming functions, parameters and variables](https://powershell.org/forums/topic/parameter-and-variable-naming-camelcase/)
    * Function Names: PascalCase
    * Parameters: PascalCase
    * Variables: camelCase
    * Constants: SNAKE_CASE
    * Database fields: snake_case
    * urls: kebab-case

# Reference
* [Readme markdown-cheatsheet](https://github.com/tchapi/markdown-cheatsheet/blob/master/README.md "Readme markdown-cheatsheet")
* [emoji-cheat-sheet](https://www.webfx.com/tools/emoji-cheat-sheet/ "emoji-cheat-sheet")
* [a cool website to refer for powershell tips and tricks](https://thinkpowershell.com/)
* [Use of $PSScriptRoot  to get script location](https://thinkpowershell.com/add-script-flexibility-relative-file-paths/)
