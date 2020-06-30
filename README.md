## Core

Core is a central bash library that is intended to be the control point for many bash functions, instead of bash scripts.  

The reason for leveraging a control framework is to benefit from features like, autohelp, fzf completion, tab completion, auto input detection, etc.

all files included in the lib directory that end with `.sh` will be autoloaded in by core.   If it does not end with sh, you can load it directory with `import` of the file path. `reimport` can be used an the end to reload a file after its already been loaded (e.g. dependency ordering)


Core is meant to be used inside a git repo and linked into your path.   Once in your path, it can be run anywhere.   Core will always run inside its own repository by default,  however should you want to leverage core with other git repos, simply add a `.core_enabled` file to the top level of the git repo and core can then function inside that repository as well (when CWD is inside that directory).


bash completion 
```
source <(core _completion)
```

zsh completion 
```
source <(core _completion zsh)
```

fish completion
```
core _completion fish | source
```

fzf is recommended to be installed,   if fzf is installed, it will allow selection of the closest match,  core history keeps track of previous commands and orders core history based on history priority. 