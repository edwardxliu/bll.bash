#!/bin/bash

##########################################################################################################################################
#
# Program Name:		bll
# File Name: 		bll.bash
# Creation Date:	Mar 2015
# Programmer:		Edward Liu
# Abstract: 		This script is used to list all files or directories under a given path according to their sizes
# Entry Codition:	N/A
# Exit Condition:	N/A
# Example:			bll -k
#					bll /xxx/xxx/ -m
#					bll ../ -g
# Program Message:	N/A
# Remarks:			N/A
# Amendment History:
#		Version:
#		Date:
#		Porgrammer:
#		Reason:
#
##########################################################################################################################################

declare -i height=$((`tput lines`-4))
declare -i width=$((`tput cols`-5))

########################
# Month to number
########################
function Month2Num() {
	case $file_month in
		Jan)
			file_month=1
			;;
		Feb)
			file_month=2
			;;
		Mar)
			file_month=3
			;;
		Apr)
			file_month=4
			;;
		May)
			file_month=5
			;;
		Jun)
			file_month=6
			;;
		Jul)
			file_month=7
			;;
		Aug)
			file_month=8
			;;
		Sep)
			file_month=9
			;;
		Oct)
			file_month=10
			;;
		Nov)
			file_month=11
			;;
		Dec)
			file_month=12
			;;
		*)
			;;
	esac
}

########################
# Split size list
########################
function SplitList() {
	local i=0	# the index of the whole size list
	local k=0	# the index of the sub size list

	#############################################
	# Comput how many sub lists are required
	#############################################
	if [ $((list_len*2%width)) -eq 0 ]; then
		num_list=$((list_len*2/width))
	else
		num_list=$((list_len*2/width+1))
	fi

	#############################################
	# Split the size list
	#############################################
	for ((i=0;i<num_list;i++)); do
		while [[ $j -lt $list_len ]]; do
			# Compute and initialize the size of each column according to the maximum size
			eval "size$i[$k]=`echo $((height-1))*${size_list[$j]}/$max_size |bc`"
			#eval "echo \${size$i[@]}"
			((j++))
			((k++))
			if [ $((k%(width/2))) -eq 0 ]; then
				break
			fi
		done
		k=0
	done
}

#############################################
# Initialize variables
#############################################
function Initvar() {
	echo 'Initializing......'
	file_month=`date "+%m"`
	today_date=`date "+%d"`
	today_year=`date "+%Y"`
	file_month=`expr $file_month + 0` && today_month=$file_month && unset file_month
	today_date=`expr $today_date + 0`
	today_year=`expr $today_year + 0`

	file_list=($files) # file list
	# sort the files according to their sizes
	file_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |sort -k5 -n -r |tr ' ' '@'`)
	# initiate size list
	size_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |awk '{print $5}' |tr -d [KMG]`)
	# initiate directory list
	dir_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |awk '{print $1}' |tr ' ' '@'`)
	# get the maximum size
	max_size=`echo ${file_list[0]} |tr '@' ' '|awk '{print $5}' |tr -d [KMG]`
	file_year_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |awk '{print $8}'`)	# year list
	file_date_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |awk '{print $7}'`)	# date list
	file_month_list=(`echo ${file_list[@]} |tr ' ' '\n' |tr '@' ' ' |awk '{print $6}'`)	# month list

	list_len=$((${#size_list[@]}))

	#############################################
	# Set the months in month list to integer
	#############################################
	for i in `seq 0 $((list_len-1))`; do
		file_month=${file_month_list[$i]} && Month2Num
		file_month_list[$i]=$file_month
	done

	#############################################################
	# If the length of the size list < half of the window width
	# then split the size list
	# and set the column_width to 1
	#############################################################
	if [ $list_len -le $((width/2)) ]; then	# the window can show the whole list
		num_list=1
		column_width=$((width/list_len/2))	# set the column width
		for i in `seq 0 $((list_len-1))`; do
			# compute and initialize the size of each column according to the maximum size
			size0[$i]=`echo $((height-1))*${size_list[$i]}/$max_size |bc`
		done
	else				# the window cannot show the whole list
		column_width=1 	# set the column_width to 1
		SplitList		# split the list
	fi
}

#############################################
# Locate the cursor
#############################################
function LocationCursor() {
	local h=$1
	local l=$2
	printf "\e[$h;$l;H"
}

#############################################
# Move the cursor
#############################################
function MovingCursor() {
	stty cbreak -echo	# diable echo command
	dd if=/dev/tty bs=1 count=1 2>/dev/null	# receive ONE char of input from keyboard
	# stty -cbreak echo
}

#############################################
# Move the cursor to the location of ($1,$2)
# then print $3
#############################################
function MoveAndDraw() {
	printf "\E[${1};${2}H$3"
}

#############################################
# Draw a column with a color
#############################################
function DrawColorColumn() {
	######################################################################
	# Draw a $column_width column from bottom $i to top $j with color $3
	######################################################################
	for ((j=height;j>$1;j--)); do
		MoveAndDraw $j $2 "\E[$3%"$column_width"s\E[0m"
	done
}

#############################################
# Draw/Select a column
#############################################
function DrawOneColumn() {
	local draw=$1 	# determine whether to draw or select a column(0: draw; 1: select)
	local sub_l=$2 	# determine the start index of the file list and the corresponding sub size list index
	local x=$3 		# the index of the file list and size list
	local cur=$4 	# the horizontal coordinate of a column
	local index=$((sub_l*(width/2)+x))
	local file_date=${file_date_list[$index]}
	local file_year=${file_year_list[$index]}
	local file_month=${file_month_list[$index]}

	#local file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
	#local file="$path/$file_name"

	##########################################################################################
	# if a column height is less than 1, still draw 1 height
	##########################################################################################
	eval "column_height=\$((height-size$sub_l[$x]))"
	if [ $column_height -eq $height ]; then
		((column_height--))
	fi
	#echo "today_year, file_year : $today_year-$file_year"
	if [ $draw -eq 0 ]; then	# draw a column
		if [ ${#file_year} -gt 4 ] && [ $file_month -eq $today_month ] && [ $((today_date-file_date)) -lt 7 ]; then
			DrawColorColumn $column_height $cur 47m		# white -- this week
		elif [ ${#file_year} -gt 4 ] && [ $file_month -eq $today_month ]; then
			DrawColorColumn $column_height $cur 42m		# green -- this month
		elif [ ${#file_year} -gt 4 ] || [ ${file_year} -eq $today_year ] && [ $((today_month-file_month)) -lt 6 ]; then
			DrawColorColumn $column_height $cur 43m 	# yellow -- 6 months
		elif [ ${#file_year} -gt 4 ] || [ ${file_year} -eq $today_year ] && [ $((today_month-file_month)) -lt 12 ]; then
			DrawColorColumn $column_height $cur 46m 	# sky -- 12 months
		elif [ ${#file_year} -eq 4 ] && [ $((today_year-file_year)) -eq 1 ]; then
			DrawColorColumn $column_height $cur 44m 	# blue -- last year
		elif [ ${#file_year} -eq 4 ] && [ $((today_year-file_year)) -gt 1 ]; then
			DrawColorColumn $column_height $cur 41m 	# red -- 2 years ago
		fi

		if [[ ${dir_list[$index]} =~ ^d ]]; then
			DrawColorColumn $column_height $cur 45m 	# pink -- directory
		fi

	elif [ $draw -eq 1 ]; then 	# select a column
		for ((j=height;j>column_height;j--));do
			MoveAndDraw $j $cur "\E[7m%"$column_width"s\E[0m"
		done
	fi	
}

#############################################
# Initialize chart board
#############################################
function InitBoard() {
	clear
	for((i=0;i<height;i++)); do
		for((j=0;j<width;j++)); do
			eval "arr$i[$j]=' '"
		done
	done
}

#############################################
# Draw chart board
#############################################
function DrawBoard() {
	MoveAndDraw 1 1 "^"
	echo
	for((i=2;i<=height;i++)); do
		MoveAndDraw $i 1 "|"
		eval echo -en "\${arr$i[*]}"
	done

	MoveAndDraw $((height+1)) 1 "+"
	for((i=2;i<=width;i++)); do
		MoveAndDraw $((height+1)) $i "-"
	done
	MoveAndDraw $((height+1)) $((width+2)) ">"
	echo
}

#############################################
# Draw all columns of a sub size list
#############################################
function DrawData() {
	local x_pos=3		# start from x coordinate at 3
	local sub_l=$1 		# the index of sub size list
	# the first/max size of a sub size list
	local firt_size=`echo ${file_list[$((sub_l*(width/2)))]} |tr '@' ' ' |awk '{print $5}'`
	local col_size 		# determine whether a column has size (used for handling deletion)

	eval "size_len=\${#size$sub_l[@]}"
	for i in `seq 0 $((size_len-1))`; do
		eval "col_size=\${size$sub_l[$i]}"
		if [ ! -z $col_size ]; then
			DrawOneColumn 0 $sub_l $i $x_pos
			if [ $i -eq 0 ]; then
				MoveAndDraw $column_height 3 $firt_size 	# draw the actual size of the first column of a sub size list
			fi
			if [ $column_width -eq 1 ]; then
				x_pos=$((x_pos+2))
			else
				x_pos=$((x_pos+column_width+column_width/2))
			fi
		fi
	done
	tput sc 	# save the position of cursor
}

#############################################
# Function for selecting
#############################################
function Choose() {
	trap "" SIGINT			# disable Ctrl+C
	local x=0 				# index starts from 0
	local cur_x=3			# x corrdinate starts from 3
	local sub_l=$1 			# sub size list index
	local file_name
	local file
	local remove_code=255	# determine whether the remove function is executed successfully
	local last_len 			# the length of the last sub list
	local pos 				# store the position of the cursor

	LocationCursor $height $cur_x 	# start draw from bottom left
	while true; do
		if [ $x -le $size_len ] && [ $x -ge 0 ]; then
			#############################################
			# the first column is selected as default
			#############################################
			if [ $x -eq 0 ]; then
				DrawOneColumn 1 $sub_l $x $cur_x
			fi

			case $(MovingCursor) in
				C) 	# move right
					DrawOneColumn 0 $sub_l $x $cur_x		# redraw the current column before select the next column
					if [ $x -lt $((size_len-1)) ]; then
						if [ $column_width -eq 1 ]; then 	# if the column width is 1, set the gap to 1
							cur_x=$((cur_x+2)) 				# so the x coordinate of the next column is cur_x+2
						else								# if the column width is not 1, set the gap to half of the column width
							cur_x=$((cur_x+column_width+column_width/2))
						fi
						((x++))
					elif [ $x -eq $((size_len-1)) ]; then 	# if the index reaches the last element of the list
						x=0 								# reset the index from 0
						cur_x=3								# reset the x coordinate to start position 3
					fi
					;;
				D) 	# move left
					DrawOneColumn 0 $sub_l $x $cur_x
					if [ $x -gt 0 ]; then
						if [ $column_width -eq 1 ]; then
							cur_x=$((cur_x-2))
						else
							cur_x=$((cur_x-column_width-column_width/2))
						fi
						((x--))
					elif [ $x -eq 0 ] && [ $size_len -gt 1 ]; then 	# if the index reaches the start of the list
						x=$((size_len-1))							# reset the index to the last element of the list
						tput rc 									# load the position of the cursor
						printf '\e[6n'
						read -sdR pos
						pos=${pos#*[}
						IFS=';'
						pos=($pos)
						cur_x=$((pos[1]-column_width))
						unset IFS
					fi
					;;
				B) 	# move down (next page)
					if [ $sub_l -lt $((num_list-1)) ]; then
						((sub_l++))
						InitBoard 	# draw the next sub size list
						DrawBoard
						DrawData $sub_l
						Choose $sub_l
					fi
					;;
				A)	# move up (previous page)
					if [ $sub_l -gt 0 ]; then
						((sub_l--))
						InitBoard 	# draw the previous sub size list
						DrawBoard
						DrawData $sub_l
						Choose $sub_l
					fi
					;;
				r|R)	# delete a file
					stty -cbreak echo 				# enable echo command
					echo -ne "\033[?25h"			# show cursor
					LocationCursor $((height+2)) 3 	# locate the cursor to print information
					printf "\e[K" 					# refresh the line
					file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
					file="$path/$file_name"
					rm -i $file
					ls $file 2>/dev/null
					remove_code=$?

					##########################################################################################
					# if a file is removed successfully
					# then re-organise all lists
					# by moving the next element of the deleted file one forward
					##########################################################################################
					if [ ! $remove_code -eq 0 ]; then
						for((i=sub_l*(width/2)+x; i<list_len-1;i++)); do
							file_list[$i]=${file_list[$((i+1))]}
							file_date_list[$i]=${file_date_list[$((i+1))]}
							file_year_list[$i]=${file_year_list[$((i+1))]}
							file_month_list[$i]=${file_month_list[$((i+1))]}
						done
						unset file_list[$((list_len-1))]
						unset file_date_list[$((list_len-1))]
						unset file_year_list[$((list_len-1))]
						unset file_month_list[$((list_len-1))]
						for ((i=x;i<size_len-1;i++)); do
							eval "size$sub_l[$i]=\${size$sub_l[$((i+1))]}"
						done
						eval "last_len=\${#size$((num_list-1))[@]}"
						eval "unset \size$((num_list-1))[$((last_len-1))]"
					fi

					#############################################
					# Redraw the chart
					#############################################
					echo -ne "\033[?25l"
					InitBoard
					DrawBoard
					DrawData $sub_l
					Choose $sub_l
					;;

				c)	# Copy function
					stty -cbreak echo 				# enable echo command
					echo -ne "\033[?25h"			# show cursor
					LocationCursor $((height+2)) 3 	# locate the cursor to print information
					printf "\e[K" 					# refresh the line
					file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
					file="$path/$file_name"
					
					#local msg="Please input the copy path : "
					read -p "Copy file to path : " cpy_path
					LocationCursor $((height+2)) 3 
					if [ ! -d "$cpy_path" ]; then
						echo "Error: the target path does not exist!"
					else
						if [ -f $file ]; then
							cp -i "$file" "$cpy_path"
						elif [ -d $file ]; then
							cp -rf "$file" "$cpy_path"
						else
							echo "Error: The file you select cannot be copied!!"	
						fi
						ls "$cpy_path/$file_name" 2>/dev/null 1>&2
						[ $? -eq 0 ] && echo "$file has been successfully copied to path $cpy_path" || echo "Error: the file copy failed!"
					fi
					echo -ne "\033[?25l"
					;;

				m|M) # Move function
					stty -cbreak echo 				# enable echo command
					echo -ne "\033[?25h"			# show cursor
					LocationCursor $((height+2)) 3 	# locate the cursor to print information
					printf "\e[K" 					# refresh the line
					file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
					file="$path/$file_name"
					
					#local msg="Please input the copy path : "
					read -p "Move file to path : " mv_path
					LocationCursor $((height+2)) 3 
					if [ ! -d "$mv_path" ]; then
						echo "Error: the copy target does not exist!"
					else
						if [ -f $file ]; then
							mv -i "$file" "$mv_path"
						elif [ -d $file ]; then
							mv -rf "$file" "$mv_path"
						else
							echo "Error: The file you select cannot be moved!!"	
						fi
						ls "$mv_path/$file_name" 2>/dev/null 1>&2
						remove_code = $?
						#[ $? -eq 0 ] && echo "$file has been successfully moved to path $mv_path" || echo "Error: the file move failed!"
					fi

					##########################################################################################
					# if a file is removed successfully
					# then re-organise all lists
					# by moving the next element of the deleted file one forward
					##########################################################################################
					if [ $remove_code -eq 0 ]; then
						echo "$file has been successfully moved to path $mv_path" 
						for((i=sub_l*(width/2)+x; i<list_len-1;i++)); do
							file_list[$i]=${file_list[$((i+1))]}
							file_date_list[$i]=${file_date_list[$((i+1))]}
							file_year_list[$i]=${file_year_list[$((i+1))]}
							file_month_list[$i]=${file_month_list[$((i+1))]}
						done
						unset file_list[$((list_len-1))]
						unset file_date_list[$((list_len-1))]
						unset file_year_list[$((list_len-1))]
						unset file_month_list[$((list_len-1))]
						for ((i=x;i<size_len-1;i++)); do
							eval "size$sub_l[$i]=\${size$sub_l[$((i+1))]}"
						done
						eval "last_len=\${#size$((num_list-1))[@]}"
						eval "unset \size$((num_list-1))[$((last_len-1))]"

						#############################################
						# Redraw the chart
						#############################################
						echo -ne "\033[?25l"
						InitBoard
						DrawBoard
						DrawData $sub_l
						Choose $sub_l
					else
						echo "Error: the file move failed!"
						echo -ne "\033[?25l"
						#sleep 3
					fi					
					;;

				v|V) 	# edit file via vi
					LocationCursor $((height+2)) 3
					printf "\e[K"
					file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
					file="$path/$file_name"

					if [ -f $file ]; then
						vi $file
						echo -ne "\033[?25l"
						InitBoard
						DrawBoard
						DrawData $sub_l
						Choose $sub_l
					else
						echo "Error: the file can not be edit!"
					fi
					;;

				o|O)	# open a file/directory
					LocationCursor $((height+2)) 3
					printf "\e[K"
					file_name=`echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' ' |awk '{print $9}'`
					file="$path/$file_name"
					if [ ! -d $file ]; then
						cat $file |less
				
						#read input
						# while read -s -n 1 key; do
						# 	case ${key} in
						# 		q|Q)
						# 			InitBoard
						# 			DrawBoard
						# 			DrawData $sub_l
						# 			Choose $sub_l
						# 			;;
						# 		*)
						# 			:
						# 			;;
						# 	esac
						# done
					else		# open directry
						printf "Are you sure to go into foler $path/$file_name : Yes No"
						#local Y_pos=`expr index "Are you sure to go into folder $path/$file_name : Yes No" "Y"`
						local Y_pos=`echo "Are you sure to go into folder $path/$file_name : Yes No" |sed -n "s/[Y].*//p" |wc -c`
						((Y_pos+=1))
						#local N_pos=`expr index "Are you sure to go into folder $path/$file_name : Yes No" "N"`
						local N_pos=`echo "Are you sure to go into folder $path/$file_name : Yes No" |sed -n "s/[N].*//p" |wc -c`
						((N_pos+=1))
						local new_path_choice=true
						MoveAndDraw $((height+2)) $Y_pos "\E[7mYes\E[0m"
						while true; do
							case $(MovingCursor) in
								C)
									MoveAndDraw $((height+2)) $Y_pos "\E[0mYes"
									MoveAndDraw $((height+2)) $N_pos "\E[7mNo\E[0m"
									new_path_choice=false
									;;
								D)
									MoveAndDraw $((height+2)) $N_pos "\E[0mNo"
									MoveAndDraw $((height+2)) $Y_pos "\E[7mYes\E[0m"
									new_path_choice=true
									;;
								" "|"")
									if [ $new_path_choice == true ]; then
										local size_opt=(B K M G)
										local size_opt_len=${#size_opt[@]}
										local size_opt_i=0
										LocationCursor $((height+2)) 3
										printf "\e[K"
										printf "Please select the size range : B K M G"
										local s_pos=`echo "Please select the size range : B K M G" |sed -n "s/[B].*//p" |wc -c`
										((s_pos+=2))
										MoveAndDraw $((height+2)) $s_pos "\E[7mB\E[0m"
										while true; do
											case $(MovingCursor) in
												C)	# move right
													if [ $size_opt_i -lt $((size_opt_len-1)) ]; then
														MoveAndDraw $((height+2)) $s_pos "\E[0m${size_opt[$size_opt_i]}"
														((size_opt_i++))
														((s_pos+=2))
														MoveAndDraw $((height+2)) $s_pos $"\E[7m${size_opt[$size_opt_i]}\E[0m"
													fi
													;;
												D)	# move left
													if [ $size_opt_i -gt 0 ]; then
														MoveAndDraw $((height+2)) $s_pos "\E[0m${size_opt[$size_opt_i]}"
														((size_opt_i--))
														((s_pos-=2))
														MoveAndDraw $((height+2)) $s_pos "\E[7m${size_opt[$size_opt_i]}\E[0m"
													fi
													;;
												q|Q)
													break
													;;
												" "|"")
													path="$path/$file_name"
													[ $size_opt_i -eq 0 ] && clear && ClearVar && args="$path -b" && Start
													[ $size_opt_i -eq 1 ] && clear && ClearVar && args="$path -k" && Start
													[ $size_opt_i -eq 2 ] && clear && ClearVar && args="$path -m" && Start
													[ $size_opt_i -eq 3 ] && clear && ClearVar && args="$path -g" && Start
													;;
											esac
										done
									fi
									break
									;;
								q|Q)
									break
									;;
							esac
						done
					fi
					LocationCursor $((height+2)) 3
					printf "\e[K"
					;;
				" "|"")		# print general info of a file
					stty -cbreak echo
					LocationCursor $((height+2)) 3
					printf "\e[K"
					#echo "position: $((height+2)) 3"
					#LocationCursor 46 3
					echo -en "${file_list[$((sub_l*(width/2)+x))]}" |tr '@' ' '
					LocationCursor $height $cur_x
					;;
				q|Q)
					break 0 2>/dev/null
					;;
			esac
			DrawOneColumn 1 $sub_l $x $cur_x 	# select a column
		fi
	done
	trap -INT 		# enable Ctrl+C
}

#############################################
# Get parameters
#############################################
function GetOpt() {
	local arg_list=($args)
	local opt
	args_error=false

	if [ ${#arg_list[@]} -eq 0 ]; then  	# if no parm is input, set path to current path
		path=`pwd`
	elif [ ${#arg_list[@]} -eq 2 ]; then 	# if 2 parms are input, set the 1st to be path, 2nd to be size range option
		path=${arg_list[0]}
		opt=${arg_list[1]}
	elif [ ${#arg_list[@]} -eq 1 ]; then 	# when only one parm is input, then check if it is a path, if it is not, then treat it as a size opt
		if [ -d ${arg_list[0]} ]; then
			path=${arg_list[0]}
		else
			path=`pwd`
			opt=${arg_list[0]}
		fi
	else
		go='N'
		args_error=true
		echo "Error: The number of paramaters is wrong!"
	fi

	if [ -z $opt ]; then
		b_flag=true
	elif [ $opt == "-k" ] || [ $opt == "-K" ]; then
		kb_flag=true
	elif [ $opt == "-m" ] || [ $opt == "-M" ]; then
		mb_flag=true
	elif [ $opt == "-g" ] || [ $opt == "-G" ]; then
		gb_flag=true
	elif [ $opt == "-b" ] || [ $opt == "-B" ]; then
		b_flag=true
	else
		go='N'
		args_error=true
		echo "Error: option not support!"
	fi
}

#############################################
# Start Function
#############################################
function Start() {
	kb_flag=false
	mb_flag=false
	gb_flag=false
	b_flag=false
	go="Y"

	GetOpt
	
	$kb_flag && files=$(ls -lh $path |awk '$5~/K/ {print $0}' |tr ' ' '@')
	$mb_flag && files=$(ls -lh $path |awk '$5~/M/ {print $0}' |tr ' ' '@')
	$gb_flag && files=$(ls -lh $path |awk '$5~/G/ {print $0}' |tr ' ' '@')
	$b_flag  && files=`ls -lh $path  |awk '$5~/B/ {print $0}' |tr ' ' '@'`

	if [ $go == "Y" ] && [ "$files" ]; then
		sub_l=0 	# start from the size list of size()
		#echo "Initial Variables..."
		Initvar
		#echo "Initial Board ...."
		InitBoard
		#echo "Draw Board..."
		DrawBoard
		#echo "Draw Data..."
		DrawData $sub_l
		echo -en "\033[?25l" 	# hide cursor
		stty cbreak -echo 		# disable echo
		Choose $sub_l
	else
		stty -cbreak echo 		# enable echo
		echo -e "\033[?25h"		# show cursor
		exit 0
	fi
}

#############################################
# Clear variables
#############################################
function ClearVar() {
	unset size_list
	unset dir_list
	unset files
	unset file_list
	unset list_len
	for ((i=0;i<num_list;i++)); do
		unset size$i
	done
	unset num_list
	unset max_size
	unset kb_flag
	unset mb_flag
	unset gb_flag
	unset b_flag
	unset size_len
	unset go
	unset args_error
	unset go
	unset args_error
	unset x
	unset cur_x
	unset sub_l
	unset file_month
	unset file_date
	unset file_year
	unset today_date
	unset today_year
	unset today_month
}

#############################################
# Main
#############################################
args=$*
Start
$args_error || clear
stty -cbreak echo
echo -e "\033[?25h"
tput sgr0
unset height
unset width
exit 0

