# bll.bash
This is a fun Linux Bash script to view the size of files in a path and do some simple file operation in the terminal.

1.  You can do something like "bll -k" to list all files with size of kilobytes under current path or "bll -m" to list with megabytes.
2.  You can also specify the path like "bll /usr/local -b" or "bll ../ -g".
3.  All files including directories in the path will be showed in a bar chart according to their sizes.
4.  The height of a bar indicates the size of the selected file and the color indicates its change time (e.g. red color means the file hasn't been changed for a long time.)
5.  The size of the chart and the size of each bar in the chart is compute automatically according to the size of your screen.
5.  You can type "up/down/left/right" key in your keyboard to switch between files and pages.
6.  You can type "space" key to show the general information of a selected file.
7.  You can type "o" key to view that file or enter the path if the file is actually a directory.
8.  You can type "v" key to open the file with the tool of "vi" for editing.
9.  You can also type "r/m/c" key to remove, move or copy the file.
10. Always type "q" to return if you mistype something.

#### Installation
Add `alias bll="the place <replace with your path>/bll.bash` in /~/.bashrc or /etc/bashrc.

#### Screenshot
![screenshot](https://github.com/edwardxliu/bll.bash/blob/master/image/screenshot.png)
