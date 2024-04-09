#!/bin/bash
shopt -s extglob

#checking if the dbms directory exists or not 
if [ -d "./dbms" ] 
then
    echo "" 
else
    mkdir ./dbms
    #echo "Error: Directory ./dbms created successfully."
fi


# go to the project directory
#cd dbms

##separators function
display_separator() {
    echo "----------------------------------------"
}

display_banner() {
    echo "****************************************"
    echo "$1"
    echo "****************************************"
}

######Create DB Function
###Validation function
ifExist(){
	checkName="$1"
##check if it already exists
	database_exists=false	
	for exist in "dbms"/*;
	do 
		if [ -d "$exist" ] && [ "$(basename "$exist")" == "$checkName" ];
		then
			#echo "Database '$checkName' already exists." 
			#echo "Please choose a different name or Enter a Valid Name or Type 0 to Go Back to The Main Menu"
			return 1
		fi
	done
	return 0
}

createDB(){
while true; do
##Read the input
	read -p "Enter DB Name: " name

##Check if the input has spaces
	if [[ $name =~ [[:space:]] ]]; then
	#Remove spaces and replace with underscores
		name=${name// /_}
	fi
##Check if the user didn't enter an input
	if [[ -z $name ]]; then
		echo "Please Enter a Value: "  
##Make sure it starts with a letter and doesn't contain special characters 
	elif [[ $name == 0 ]]; then
		break
	elif [[ $name =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
	#Check if the DB name already exists
		#ifExist $name
		if ifExist "$name"; then
			mkdir -p "dbms/$name"
			echo "Database '$name' created successfully."
			break
		else
			echo "Database Already Exists"
		fi
	else
		echo "Invalid Name"
		echo "Enter a Valid Name or Type 0 to Go Back to The Main Menu"
	fi
done
}

######List all Databases Function
listDB(){
listRes=$(ls -a dbms/)
if [ -z "$listRes" ]; then
	echo "There is no created databases"
else
	echo "The Available Databases Are:"
	ls -F dbms/ | grep "/" | sed 's#/##' 
fi
}


######Drop Database Function
dropDB() {
read -p "Enter the Database Name: " dropname

if ifExist "$dropname"; then
	echo "Invalid Name or the Database Doesn't Exist"
else
	rm -r "dbms/$dropname"
	echo "Database was Removed Successfully"
fi
	
}



#########################################################Tables Logic
######Connect to a Database Function

connectDB() {
read -p "Enter the Database Name: " connectname

if ifExist "$connectname"; then
	echo "Invalid Name or the Database Doesn't Exist"
else
	./tablemenu.sh "$connectname"	
fi
}

#mainmenu
while true; do
	display_banner "Main Menu"
	display_separator
	options=("Create DB" "List Records" "Drop DB" "Connect to DB" "Exit")
	COLUMNS=1
	select opt in "${options[@]}"
	do
		case $opt in
			"Create DB")
			echo 
			echo "Creating database..."
			createDB
			echo "Press any key to see the options again"
			;;
			"List Records")
			echo
			echo "Listing database..."
			listDB
			echo "Press any key to see the options again"
			;;
			"Drop DB")
			echo
			echo "Dropping database..."
			dropDB
			echo "Press any key to see the options again"
			;;
			"Connect to DB")
			echo
			echo "Connecting to database..."
			connectDB
			echo "Press any key to see the options again"
			;;
			"Exit")
			echo
			echo "Exiting..."
			break 2
			;;
			*)
			echo
			echo "Invalid option. Please enter a number between 1 and 5."
			;;
		esac
		break
	done
    display_separator
    read -n 1 -s -r -p "Press any key to continue..."
    echo
    display_separator

done




