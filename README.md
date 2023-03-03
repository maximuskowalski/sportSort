# sportSort

NOT READY FOR USE - DO NOT INSTALL
CODE NEEDS TO BE TESTED FIRST
CODE NEEDS CLEANUP TO REMOVE DEVSTUFF LIKE UNUSED FUNCTIONS
CODE SHOULD HAVE SOME COMMENTS AND NOTES REMOVED

## Description

sportSort is a shell script designed to help you easily sort and move .mkv files in a specified directory and its subdirectories. Using this tool, you can easily organize your video files in a way that is compatible with the [SportScanner](https://github.com/mmmmmtasty/SportScanner) Scanner and Metadata Agent for Plex, which leverages the data from [www.thesportsdb.com](http://www.thesportsdb.com/). By automating the sorting and moving process, sportSort helps save you valuable time and tries to ensure your video files are properly categorized and ready for use.

## Background

One day a friend asked me for help getting sports files into plex. I told them it would mean a lot of manual work and was best avoided. I pointed out the [SportScanner](https://github.com/mmmmmtasty/SportScanner) Scanner and Metadata Agent for Plex, showed examples of how things need to be named and reminded them that in the absence of an sportsarr type app this was going to mean a lot of manual work.

The idea for sportSort came about when a friend asked for help organizing sports files for use in Plex. I realized that this would require a lot of manual work, and pointed them to  the [SportScanner](https://github.com/mmmmmtasty/SportScanner) Scanner and Metadata Agent for Plex, which requires specific naming conventions for video files. However, after looking at the consistent naming of the "ten" sample downloaded files, I realized that this process could easily be automated.

Initially, I thought it would only take me about 30 minutes to write a script that could accomplish this. However, I soon discovered that there were many different sports, release groups, and naming schemes to account for. Over the course of two months, I added case-by-case fixes to the script, resulting in a somewhat messy and inefficient codebase.

Despite its limitations, I decided to share sportSort on GitHub in the hopes that others could benefit from it and help improve the codebase. While it may not be perfect, sportSort remains a useful tool for organizing sports files in Plex and can save users valuable time in the process.

## Prerequisites

- A Linux or Unix-based system
- Bash shell
- A process that regularly places sports files in a directory
- Basic knowledge of how to set up and run cron jobs or systemd services (depending on your preferred method of triggering the script)
- Familiarity with setting environment variables (specific variables required by sportSort will be outlined in the "Installation" section)
- Supervision of the script during use (as it may not be completely foolproof yet)

## Installation

To install sportSort, simply clone the repository from GitHub:

I personally use a scripts directory in ''/opt' but many people use their home directory.
Change directory to where you wish to clone:

```shell
cd /opt/scripts/sport
```

Clone the repo

```sh
git clone https://github.com/maximuskowalski/sportSort.git
```

After cloning the repository, make sure that the script is executable by running the following command:

```sh
cd sportSort
chmod +x sportSort.sh
```

Once you have made the script executable, you should provide the required variables you can run it manually using the following command:

```sh
./sportSort.sh
```

Note that sportSort requires certain environment variables to be set before it can run properly. These variables include the path to the directory where sports files will be placed and the path to the directory where sorted files will be moved. Be sure to set these variables before running the script, as detailed in the following section.

That's it! With these steps, you should now be able to run sportSort on your system. If you run into any issues during installation or setup, don't hesitate to consult the README or reach out to the project's contributors for assistance.

## Usage

## Examples

crontab

```sh
# m h  dom mon dow   command
*/5 * * * * /bin/bash /opt/scripts/sport/sportSort/sportSort.sh >> /home/USERNAME/logs/sportSortrun.log 2>&1

```

## Contributing

If you would like to contribute to the development of sportSort...

## License

MIT

## Author

Me
