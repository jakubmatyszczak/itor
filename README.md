# ITOR

`itor` is a VIM-like, modal, text editor (attempt) written in JAI, that is mainly for education
purposes. It is a result of my frustration with other editors.

## Frustrations

Normally nvim would be sufficient, by for gods sake **why LUA** and **why overcomplication of
plugins? **

*Why* do I need to have a plugin manager, that installs a package manager, that installs LSP?
and more importantely, after all of that, **WHY does it still fail to install** because of unmet
dependencies??

## Why?

I just want an efficient way to:
- write code,
- with multiple buffers,
- with basic syntax highlighting,
- (very basic) Go-To-Definition, 
- fast Go-To-File,
- and quick way to jump to terminals;

without getting hit in the face with exceptions of poorly documented plugins, that are impossible
to configure, without a tutorial or diving into the repository, that is full of recursive, 
unnavigatable spagetti functions that cannot be tracked.

## Build

Well, its Jai so just:
```
jai first.jai
```
Done. That is it.

Developed with Jai Version: beta 0.2.009, built on 6 February 2025.

