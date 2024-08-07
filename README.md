# srpm-full-context-diff

## Introduction

This is a simple tool for comparing difference between 2 `source RPM` packages. It is alternative for using classical `rpmdiff` and it focuses on showing graphically difference of those 2 packages.

The main purpose of this tool is to be able to review changes made by patches and to keep *full context* and understanding of **what** and **where** changed between 2 packages.

Both packages can even be a lot divergent from each other. The tool still tries to find difference no mather what happened which means it can be used for comparing 2 source packages across 2 different major versions.

## How does it works?

### Input files types
It expects 2 `URI`s for **old** and **new** package on command line. There are 2 types of files identification: 

1) absolute or relative path in filesystem

2) `URL` address of those files on web.

### Processing
It unpacks both `sprm` packages/containers in current directory to `data_old` and `data_new` folders. Then it applies `patches`.

### Output

It displays difference between those 2 packages.

1) It compares **all files** and **folders** in `meld` tool which is designed for  comparing difference between 2 files or directory structures in general.

2) It compares both [spec](https://docs.fedoraproject.org/en-US/packaging-guidelines/#_spec_files) files

## Configuration

You just need to add this program to your `$PATH` or add this to you `~/.bashrc`

```
export SFCD_REPO_PATH="<path_to_this_repo>"
alias sfcd="bash ${SFCD_REPO_PATH}/srpm-full-context-diff.sh"
```

## Usage

Supported ussage: You run program from terminal in the current directory.

There are 2 modes how to get input files:

1) You can compare 2 RPMS files stored on Web. It  will be downloaded to your local system:

```
sfcd https://fedora.com/srpms/my_older_package.src.rpm https://fedora.com/srpms/my_newer_package.src.rpm --wget
```

2) You can compare 2 RPMS files already stored in your file system:
```
sfcd my_older_package.src.rpm my_newer_package.src.rpm
```

## Requirements

- It requires the program [meld](https://meldmerge.org/) for graphical comparision.

- It should support `BASH` version `4.2` or newer.

## LICENSE
[MIT LICENSE](LICENSE)
