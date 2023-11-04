# vlibman

A mananger for my libraries. You can pull libs, update libs, and ... erm... that's it.

## usage:
```
usage: vlibman [-g] [-h|--help] action [action args:]
  -g : global: operate on a global instance instead of first instance found in tree.
  -h : help  : display this help
 
 actions:
  init    : Does nothing, but usefull to install only.
  pull    : Get a lib. Use the lib's name, or it's id using id=<id>. Asks which lib to pull when multiple libs with the same name exist.
  search  : Search the libs index. Searches all fields, and displays name, description, and language in a nice table.
  refresh : Download the latest libs index
  reinit  : deletes .vlibman directory, and reruns installation.
 
 error codes:
  0: no errors
  1: user error
  2: system error
  anything else: please make a bug report, that shouldn't happen!
  
 If no valid .vlibman directory was found in the current directory or any of its parent, the user is prompted if vlibman should install one.
```

## install:
Just put vlibman.sh somewhere in your path (like `~/.local/bin`) as `vlibman` and make it executable, then just do a `vlibman init` in a project folder.

