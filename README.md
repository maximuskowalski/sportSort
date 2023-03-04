# sportSort

NOT READY FOR USE - DO NOT INSTALL
CODE NEEDS TO BE TESTED FIRST
CODE NEEDS CLEANUP TO REMOVE DEVSTUFF LIKE UNUSED FUNCTIONS
CODE SHOULD HAVE SOME COMMENTS AND NOTES REMOVED

## Description

sportSort is a shell script designed to help you easily sort and move .mkv files in a specified directory and its subdirectories. Using this tool, you can easily organize your video files in a way that is compatible with the [SportScanner](https://github.com/mmmmmtasty/SportScanner) Scanner and Metadata Agent for Plex, which leverages the data from [www.thesportsdb.com](http://www.thesportsdb.com/). By automating the sorting and moving process, sportSort helps save you valuable time and tries to ensure your video files are properly categorized and ready for use.

## Background

One day a friend asked me for help getting sports files into plex. I told them it would mean a lot of manual work and was best avoided. I pointed out the [SportScanner](https://github.com/mmmmmtasty/SportScanner) Scanner and Metadata Agent for Plex, showed examples of how things need to be named and reminded them that in the absence of a sportsarr type app this was going to mean a lot of manual work. However, after looking at the consistent naming of the "ten" sample downloaded files, I decided this process would actually be easy to automate.

Initially, I thought it would only take me about 30 minutes to write a script that could accomplish this. However, I soon discovered that there were many different sports, release groups, and naming schemes to account for. Over the course of the last few months, I added case-by-case fixes to the script, resulting in a somewhat messy and inefficient codebase.

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

Once you have made the script executable, and provided the required variables you can run it manually using the following command:

```sh
./sportSort.sh
```

Note that sportSort requires certain environment variables to be set before it can run properly. These variables include the path to the directory where sports files will be placed and the path to the directory where sorted files will be moved. Be sure to set these variables before running the script, as detailed in the following section.

That's it! With these steps, you should now be able to run sportSort on your system. If you run into any issues during installation or setup, don't hesitate to consult the README or reach out to the project's contributors for assistance.

## Usage

Create your config file by copying the sample file to the same directory as the script and renaming it `sportSort.conf`

Assuming you are still in the sportSort directory:

```sh
cp sportSort.conf.sample sportSort.conf
```

Edit the required variables to suit your own setup. Use your editor of choice, for example, nano.

```sh
nano sportSort.conf
```

```toml
########################################
######## CONFIG FILE FOR sportSort
########################################

########################
# Required Variables
########################

# Set the source and destination directories
src_dir="/mnt/unionfs/downloads/nzbs/nzbget/completed/sports"            # where files are to be found for moving and renaming
dst_dir="/mnt/unionfs/Media/sports"                                      # the top level directory where you want renamed files to be placed
man_dst_dir="/mnt/unionfs/downloads/nzbs/nzbget/completed/sportsort_fix" # directory where files should go that aren't able to handled correctly and require manual intervention
log_file_dir="/home/${USER}/logs"                                        # directory to save the logfiles

## ANYTHING AFTER THIS POINT YOU CAN IGNORE FOR NOW, even delete if you wish.
```

The "src_dir" is the directory where all your sports downloads end up, this should be the top level directory, sub folders will also be scraped for content. DO NOT use your completed torrents directory, as the files will be moved not copied and things like .nfo files and empty directories deleted.

Some sort of torrent directory handling is planned for the future but for now I would recommend copying content out to another directory and using that as your source directory to avoid seeding issues.

The "dst_dir" is where the files will end up in sorted and constructed form. In the example below, using /mnt/unionfs/Media/sports as your "dst_dir" you can expect sorting and renaming to look something like this within the sports directory.

```sh
sports
    ├── English Premier League
    │   └── 2021-2022
    │       ├── ENGLISH.PREMIER.LEAGUE.2021-08-13.Brentford.vs.Arsenal.mp4
    │       ├── ENGLISH.PREMIER.LEAGUE.2021-08-14.Chelsea.vs.Crystal.Palace.mp4
    │       ├── ENGLISH.PREMIER.LEAGUE.2021-08-14.Man.United.vs.Leeds.mp4
    │       └── ENGLISH.PREMIER.LEAGUE.2021-08-15.Tottenham.vs.Man.City.mp4
    ├── NFL
    │   └── 2022-2023
    │       ├── NFL.2021-09-12.Buffalo.Bills.vs.Pittsburgh.Steelers.mkv
    │       ├── NFL.2021-09-12.Cincinnati.Bengals.vs.Minnesota.Vikings.mkv
    │       ├── NFL.2021-09-12.Detroit.Lions.vs.San.Francisco.49ers.mkv
    │       └── NFL.2021-09-12.Houston.Texans.vs.Jacksonville.Jaguars.mkv
    ├── NBA
    │   └── 2022-2023
    │       ├── NBA.2023-02-28.denver.nuggets.vs.houston.rockets.mkv
    │       ├── NBA.2023-01-18.atlanta.hawks.vs.dallas.mavericks.mkv
    │       ├── NBA.2023-01-18.charlotte.hornets.vs.houston.rockets.mkv
    │       └── NBA.2023-01-18.cleveland.cavaliers.vs.memphis.grizzlies.mkv
    ├── MLB
    │   └── 2022-2023
    │       ├── MLB.2022-10-19.San.Diego.Padres.vs.Philadelphia.Phillies.mkv
    │       └── MLB.2022-11-02.Philadelphia.Phillies.vs.Houston.Astros.mkv
    ├── NHL
    │   └── 2022-2023
    │       ├── NHL.2022-12-31.Boston.Bruins.vs.Buffalo.Sabres.mkv
    │       ├── NHL.2022-12-31.Columbus.Blue.Jackets.vs.Chicago.Blackhawks.mkv
    │       ├── NHL.2022-12-31.St.Louis.Blues.vs.Minnesota.Wild.mkv
    │       └── NHL.2022-12-31.Tampa.Bay.Lightning.vs.Arizona.Coyotes.mkv
    └── Spanish La Liga
        └── 2022-2023
            ├── SPANISH.LA.LIGA.2023-01-07.villarreal.vs.real.madrid.mkv
            ├── SPANISH.LA.LIGA.2023-01-14.girona.vs.sevilla.mkv
            └── SPANISH.LA.LIGA.2023-01-14.osasuna.vs.mallorca.mkv

```

The "man_dst_dir" is the directory where files should go that aren't able to handled correctly and require manual intervention and some sort of renaming.

The "log_file_dir" is the directory you wish to save the logfiles into. There is a lot of extra logging at the moment while trying to figure out how to deal with each new file naming scheme so I would recommend checking on this if you aren't using a directory with some sort of automatic log rotation as it could potentially grow quite large in time.

## Examples

crontab

```sh
# m h  dom mon dow   command
*/5 * * * * /bin/bash /opt/scripts/sport/sportSort/sportSort.sh >/dev/null 2>&1

```

## Contributing

If you would like to contribute to the development of sportSort it would be most welcome. For the most part this has been constructed with a sledgehammer. A lot of code is repeated and can be streamlined significantly. I have not much experience with regex, and need to look up pretty much everything I try and do in bash. I'd love some help.

- Give feedback in whatever format you choose. Issues, PRs, discussion.
- Submit an issue with examples of filenames that have gone wrong or that need handling. Provide an example of how something should look if possible.
- Open a PR.
- Submit a feature request.
- Chat on discord - you'll likely find me in Saltbox

[![Discord](https://img.shields.io/discord/853755447970758686)](https://discord.gg/ugfKXpFND8)

## License

[MIT](LICENSE)

## Author

Me
