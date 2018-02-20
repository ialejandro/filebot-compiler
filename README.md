# Filebot Compiler
Filebot Compiler is a simply script to compiler the latest version of [Filebot](https://github.com/filebot/) (by [@rednoah](https://github.com/rednoah)). 

**Version**: 1.0.0

## Content
The script installs all requirements (packages, dirs, compile-software, downloads latest repos...) to compile automatically the latest commit.

### Script Steps
1. Install Packages (root privileges)
2. Download and Update Repos
3. Install Dependencies
4. Compile Filebot

## Execute
```bash
chmod +x filebot-compiler.sh
./filebot-compiler.sh
```

### Checked in this platforms
* Debian GNU/Linux 9.X (stretch)
* Ubuntu 16.04

## Dependences
* **jq**: parser json
* **git**: tool to download the repository
* **curl**: to check the new commit
* **apache-ant**: tool to compile Filebot
* **dirmngr**: takes care of accessing the OpenPGP keyservers
* **oracle-java**: libraries to compile Filebot (by [webupd8team-java](http://www.webupd8.org))
* **openjfx**: libraries to compile Filebot
* **apache-ivy**: to download the dependencies of Filebot build

### Apache Ivy Cache
I upload de apache-ivy cache. Often the dependencies are down and Apache Ivy can't download, you can download my cache from Github and create symbolic link to the home user compiles filebot. Like this:

```bash
ln -s <repo-local-dir>/.ivy2 ~/.ivy2
```

## TODO
- [ ] Menu
- [ ] Trace log

## Other information
If you wan't to compile, you can download in my website: [https://filebot.ialejandro.rocks](https://filebot.ialejandro.rocks) (***ONLY WORKS WITH JAVA9***). The latest version will automatically appear.

### More easy...
You can download the latest version with `wget` or `curl`.
```bash
wget https://filebot.ialejandro.rocks/FileBot.jar
```
or
```bash
curl -s https://filebot.ialejandro.rocks/FileBot.jar -o FileBot.jar
```

## Contributing
I would be happy to upgrade the code, you are free to collaborate and improve my code. Thanks [@sbr481](https://github.com/sbr481) for you help.
