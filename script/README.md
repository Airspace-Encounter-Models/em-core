# Scripts

This is a set of boilerplate scripts describing the [normalized script pattern that GitHub uses in its projects](https://github.blog/2015-06-30-scripts-to-rule-them-all/). The [GitHub Scripts To Rule Them All
](https://github.com/github/scripts-to-rule-them-all) was used as a template. They were tested using Ubuntu 18.04.3 LTS on Windows 10 and using GridOS 26, a derivative of Red Hat Fedora 26, on the Lincoln Laboratory Supercomputing Cluster.

- [Scripts](#scripts)
  - [`AEM_DIR_CORE` and Execution](#aem_dir_core-and-execution)
  - [Dependencies](#dependencies)
    - [Linux Shell](#linux-shell)
    - [Proxy and Internet Access](#proxy-and-internet-access)
    - [Superuser Access](#superuser-access)
  - [The Scripts](#the-scripts)
    - [script/bootstrap](#scriptbootstrap)
      - [Packages](#packages)
      - [Git Submodules](#git-submodules)
    - [script/setup](#scriptsetup)
      - [Data](#data)
  - [Distribution Statement](#distribution-statement)

## `AEM_DIR_CORE` and Execution

These scripts assume that `AEM_DIR_CORE` has been set. Refer to the repository root [README](../README.md) for instructions.

## Dependencies

### Linux Shell

The scripts need to be run in a Linux shell. For Windows 10 users, you can use [Ubuntu on Windows](https://tutorials.ubuntu.com/tutorial/tutorial-ubuntu-on-windows#0). Specifically for Windows users, system drive and other connected drives are exposed in the `/mnt/` directory. For example, you can access the Windows C: drive via `cd /mnt/c`.

If you modify these scripts, please follow the [convention guide](https://github.com/Airspace-Encounter-Models/em-overview/blob/master/CONTRIBUTING.md#convention-guide) that specifies an end of line character of `LF (\n)`. If the end of line character is changed to `CRLF (\r)`, you will get an error like this:

```bash
./bootstrap.sh: line 2: $'\r': command not found
```

### Proxy and Internet Access

The scripts will download data using [`curl`](https://curl.haxx.se/docs/manpage.html) and [`wget`](https://manpages.ubuntu.com/manpages/trusty/man1/wget.1.html), which depending on your security policy may require a proxy.

The scripts assume that the `http_proxy` and `https_proxy` linux environments variables have been set.

```bash
export http_proxy=proxy.mycompany:port
export https_proxy=proxy.mycompany:port
```

You may also need to [configure git to use a proxy](https://stackoverflow.com/q/16067534). This information is stored in `.gitconfig`, for example:

```git
[http]
	proxy = http://proxy.mycompany:port
[https]
	proxy = http://proxy.mycompany:port
```

### Superuser Access

Depending on your security policy, you may need to run some scripts as a superuser or another user. These scripts have been tested using [`sudo`](https://manpages.ubuntu.com/manpages/disco/en/man8/sudo.8.html). Depending on how you set up the system variable, `AEM_DIR_CORE` you may need to call [sudo with the `-E` flag](https://stackoverflow.com/a/8633575/363829), preserve env.

If running without administrator or sudo access, try running these scripts using `bash`, such as 

```bash
bash ./setup.sh
```

## The Scripts

Each of these scripts is responsible for a unit of work. This way they can be called from other scripts.

This not only cleans up a lot of duplicated effort, it means contributors can do the things they need to do, without having an extensive fundamental knowledge of how the project works. Lowering friction like this is key to faster and happier contributions.

The following is a list of scripts and their primary responsibilities.

### script/bootstrap

[`script/bootstrap`][bootstrap] is used solely for fulfilling dependencies of the project, such as packages, software versions, and git submodules. The goal is to make sure all required dependencies are installed. This script should be run before
[`script/setup`][setup].

#### Packages

Using [`apt`](https://help.ubuntu.com/lts/serverguide/apt.html), the following linux packages are installed:

| Package        |  Use |
| :-------------| :--  |
`libxml-xpath-perl` | xml parsing
`unzip` | extracting zip archives

The MIT airspace encounter model team has not knowingly modified any of these packages. Any modifications to these packages shall be in compliance with their respective license and outside the scope of this repository.

#### Git Submodules

A [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) is a repository embedded inside another repository. The submodule has its own history; the repository it is embedded in is called a superproject. Submodules are managed by the [.gitmodules](../.gitmodules) file. However  Git doesn’t download submodule contents by default.

Git submodules can be initialized, fetched, and checked out independent of the script via the command line:

```git
git submodule update --init --recursive
```

Any modifications to git submodules ([as these git commits are separate](https://git-scm.com/book/en/v2/Git-Tools-Submodules) from this repository) shall be in compliance with their respective license.

### script/setup

[`script/setup`][setup] is used to set up a project in an initial state. This is typically run after an initial clone, or, to reset the project back to its initial state. This is also useful for ensuring that your bootstrapping actually works well.

#### Data

Commonly used datasets are downloaded by [`script/setup`][setup]. Refer to the [data directory README](../data/README.md) for more details.

<!--  NOT YET IMPLEMENTED BUT COMMENTED FOR FUTURE REFERENCE

### script/update

[`script/update`][update] is used to update the project after a fresh pull.

If you have not worked on the project for a while, running [`script/update`][update] after
a pull will ensure that everything inside the project is up to date and ready to work.

Typically, [`script/bootstrap`][bootstrap] is run inside this script. This is also a good
opportunity to run database migrations or any other things required to get the
state of the app into shape for the current version that is checked out.

### script/server

[`script/server`][server] is used to start the application.

For a web application, this might start up any extra processes that the 
application requires to run in addition to itself.

[`script/update`][update] should be called ahead of any application booting to ensure that
the application is up to date and can run appropriately.

### script/test

[`script/test`][test] is used to run the test suite of the application.

A good pattern to support is having an optional argument that is a file path.
This allows you to support running single tests.

Linting (i.e. rubocop, jshint, pmd, etc.) can also be considered a form of testing. These tend to run faster than tests, so put them towards the beginning of a [`script/test`][test] so it fails faster if there's a linting problem.

[`script/test`][test] should be called from [`script/cibuild`][cibuild], so it should handle
setting up the application appropriately based on the environment. For example,
if called in a development environment, it should probably call [`script/update`][update]
to always ensure that the application is up to date. If called from
[`script/cibuild`][cibuild], it should probably reset the application to a clean state.

### script/cibuild

[`script/cibuild`][cibuild] is used for your continuous integration server.
This script is typically only called from your CI server.

You should set up any specific things for your environment here before your tests
are run. Your test are run simply by calling [`script/test`][test].

### script/console

[`script/console`][console] is used to open a console for your application.

A good pattern to support is having an optional argument that is an environment
name, so you can connect to that environment's console.

You should configure and run anything that needs to happen to open a console for
the requested environment.

-->

## Distribution Statement

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

© 2018, 2019, 2020, 2021 Massachusetts Institute of Technology.

This material is based upon work supported by the Federal Aviation Administration under Air Force Contract No. FA8702-15-D-0001.

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work other than as specifically authorized by the U.S. Government may violate any copyrights that exist in this work.

Any opinions, findings, conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the Federal Aviation Administration.

This document is derived from work done for the FAA (and possibly others), it is not the direct product of work done for the FAA. The information provided herein may include content supplied by third parties.  Although the data and information contained herein has been produced or processed from sources believed to be reliable, the Federal Aviation Administration makes no warranty, expressed or implied, regarding the accuracy, adequacy, completeness, legality, reliability or usefulness of any information, conclusions or recommendations provided herein. Distribution of the information contained herein does not constitute an endorsement or warranty of the data or information provided herein by the Federal Aviation Administration or the U.S. Department of Transportation.  Neither the Federal Aviation Administration nor the U.S. Department of Transportation shall be held liable for any improper or incorrect use of the information contained herein and assumes no responsibility for anyone’s use of the information. The Federal Aviation Administration and U.S. Department of Transportation shall not be liable for any claim for any loss, harm, or other damages arising from access to or use of data or information, including without limitation any direct, indirect, incidental, exemplary, special or consequential damages, even if advised of the possibility of such damages. The Federal Aviation Administration shall not be liable to anyone for any decision made or action taken, or not taken, in reliance on the information contained herein.

<!-- Relative Links -->
[bootstrap]: bootstrap.sh
[setup]: setup.sh
[update]: update.sh
[server]: server.sh
[test]: test.sh
[cibuild]: cibuild.sh
[console]: console.sh
