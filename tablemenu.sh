#!/bin/bash
shopt -s extglob

database_dir="dbms"
dbname="$1"
result=""

display_separator() {
    echo "----------------------------------------"
}

display_banner() {
    echo "****************************************"
    echo "$1"
    echo "****************************************"
}

# Function to check if a table exists in the current database
table_exists() {
    local check_name="$1"
    for exist in "$database_dir"/${dbname}/*; do
        if [ -f "$exist" ] && [ "$(basename "$exist")" == "$check_name"_meta.txt ]; then
            #echo "Table '$check_name' already exists. Please choose a different name or enter 0 to go back to the Main Menu."
            return 0
        fi
    done
    return 1
}

# Function to create a new table
nameIsValid() {
    name="$1"
    newname=$name
    # Remove spaces and replace with underscores
    if [[ $name =~ [[:space:]] ]]; then
        newname=${name// /_}
    fi
    # Check if the name follows the naming convention
    if [[ $newname =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "$newname"
        #return 0 
    else
        echo ""
        #return 1 
    fi
}

create_table() {
    read -p "Enter the name of the table: " table_name

    if [ "$table_name" == "0" ]; then
        echo "Returning to the Main Menu."
        return
    fi

    ##table name validations
    modified_name=$(nameIsValid "$table_name")

    if [ -z "$modified_name" ]; then
        echo "Invalid Name"
        return
    fi

    table_name="$modified_name" 
    if table_exists "$table_name"; then
        echo "Table Already Exists"
        return
    fi

    # Ask the user for column names
    echo "Enter columns for the table."
    declare -a columns=()
    declare -A column_types=()
    while true; do
        echo ""
        read -p "Enter column name (Enter "/q" To Finish): " col_name
        # if [ -z "$col_name" ]; then
        #     break
        # fi

        if [ "$col_name" == '/q' ]; then
            break
        fi

        mod_col_name=$(nameIsValid "$col_name")
        if [ -z "$mod_col_name" ]; then
            echo "Invalid Column Name"
            continue
        fi

        col_type=""
        while [[ "$col_type" != "string" && "$col_type" != "integer" ]]; do
            read -p "Enter column type (string/integer) for column '$mod_col_name': " col_type
        done 

        #columns["$mod_col_name"]="$col_type"
        columns+=("$mod_col_name")
        column_types[$mod_col_name]="$col_type"
    done

    if [ "${#columns[@]}" -eq 0 ]; then
        echo "Error: Table creation canceled. No columns provided."
        return
    fi

    # Ask the user to choose a primary key for the first column
    local is_primary_key
    for column in "${columns[@]}"; do
        echo ""
        read -p "Is '$column' a primary key? (y/n): " is_primary_key
        while [[ "$is_primary_key" != "y" && "$is_primary_key" != "n" ]]; do
            read -p "Invalid input. Please enter 'y' or 'n': " is_primary_key
        done
        if [ "$is_primary_key" == "y" ]; then
            echo "Setting the column '$column' as the primary key."
            echo "$column:PK" >> "${database_dir}/${dbname}/${table_name}_meta.txt"
            break
        fi
    done

   # If no primary key is chosen, set the first column as the default primary key
    if [ "$is_primary_key" != "y" ]; then
        echo "Setting the first column '${columns[0]}' as the primary key by default."
        echo "${columns[0]}:PK" >> "${database_dir}/${dbname}/${table_name}_meta.txt"
    fi

    # Create meta file and table file
    echo "${#columns[@]}" >> "${database_dir}/${dbname}/${table_name}_meta.txt"
    for column_name in "${columns[@]}"; do
        echo "$column_name:${column_types[$column_name]}">> "${database_dir}/${dbname}/${table_name}_meta.txt"
    done

    touch "${database_dir}/${dbname}/${table_name}.csv"
    echo "Table '$table_name' created successfully."
}

# Function to list all tables
list_tables() {
    echo -e "\nList of Tables:"
    for meta_file in "$database_dir"/${dbname}/*_meta.txt; do
        table_name=$(basename "$meta_file" _meta.txt 2>/dev/null)
    if [ -n "$table_name" ]; then
        echo "$table_name"
    fi
    done

}

# Function to drop a table
drop_table() {
    read -p "Enter the name of the table to drop: " table_name

    if [ "$table_name" == "0" ]; then
        echo "Returning to the Main Menu."
        return
    fi

    if ! table_exists "$table_name"; then
        echo "Table '$table_name' does not exist."
        return
    fi

    # Confirm with the user before dropping the table
    read -p "Are you sure you want to drop '$table_name'? (y/n): " confirm_drop

    if [ "$confirm_drop" == "y" ]; then
        # Remove meta file and table file
        rm "${database_dir}/${dbname}/${table_name}_meta.txt"
        rm "${database_dir}/${dbname}/${table_name}.csv"

        echo "Table '$table_name' dropped successfully."
    else
        echo "Table drop canceled."
    fi
}

select_from_table() {
    read -p "Enter Table Name: " table

    if table_exists "$table"; then
	    # echo "Table '$table' table exists."

	    meta_file="${database_dir}/${dbname}/${table}_meta.txt"
    
        col_num=$(head -n 2 "$meta_file" | tail -n 1)

        #reading column names from metedata file
        columns=()
        columnTypes=()
    
        for((i=0; i< col_num; i++)); do
            col_name=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f1)
            col_type=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f2)
            # read col_name and type name
            columns+=("$col_name")
            columnTypes+=("$col_type")
        done 


        echo ""
        echo "Do you want to select using specified column or select all? "
        echo "1. Select Using Column"
        echo "2. Select All"

        read -p "Enter your choice (1 or 2): " opt
        if [[ "$opt" == "1" ]]; then
 
            echo "Select a Column"
            echo "Column names: "
            count=1
            for name in "${columns[@]}"; do
                echo "$count. $name"
                ((count++))
            done

            selected_type=""
            chosen_col=""
            while true; do
                echo ""
                read -p "Enter the number of the column you want to select (1-$col_num): " chosen_col

                if [[ "$chosen_col" =~ ^[1-$col_num]$ ]]; then
                    index=$((chosen_col -1))
                    selected_type=${columnTypes[$index]}
                    echo "Selected column: ${columns[$index]} with type $selected_type"
                    break
                else
                    echo "Invalid input. Please enter a number from 1 to $col_num."
                fi
            done

            echo "Out Selected Type is $selected_type"
            value=""
            #validate on the type
            while true; do
                if [[ $selected_type == "string" ]]; then
                    echo "" 
                    read -p "Enter a value and must be string: " value
                    if [[ "$value" =~ ^[a-zA-Z][a-zA-Z0-9@._[:space:]-]*$ ]]; then
                        echo "Valid input: $value"
                        break
                    else
                        echo "Invalid input. Please enter only letters"
                    fi
                else
                    read -p "Enter a value and must be numbers: " value
                    if [[ "$value" =~ ^[0-9]+$ ]]; then
                        echo "Valid input: $value"
                        break
                    else
                        echo "Invalid input. Please enter only numbers"
                    fi
                fi
            done

            #displaying the columns
            echo "----------------------------------------"
            IFS=:; echo "${columns[*]}"
            result=$(awk -F: -v col="$chosen_col" -v val="$value" '$col == val' "dbms/${dbname}/$table.csv")
            if [[ -z "$result" ]]; then
                echo "No Such Data"
            else
                echo "$result"
            fi
            
        elif [[ "$opt" == "2" ]]; then
            echo "----------------------------------------"
            IFS=:; echo "${columns[*]}"
            result=$(cat dbms/${dbname}/$table.csv)
            if [[ -z "$result" ]]; then
                echo "Table is Empty"
            else
                echo "$result"
            fi
            
        else
            echo "Invalid Choice"
        fi
    else
        echo "Table '$table' doesn't exist."	

    fi
}

type_validation() {
    colType="$1"
    input="$2"

    if [[ "$colType" == "string" ]]; then
        if [[ "$input" =~ ^[a-zA-Z][a-zA-Z0-9@._[:space:]-]*$ ]]; then
            return 0
        else
            return 1
        fi
    else
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            return 0
        else
            return 1
        fi
    fi

}

check() {
    table="$1"
	meta_file="${database_dir}/${dbname}/${table}_meta.txt"
    primaryKey=$(awk -F: '{print $1;}' "$meta_file" | head -n 1)
    # echo "PK is $primaryKey"

    
    col_num=$(head -n 2 "$meta_file" | tail -n 1)

    #reading column names from metedata file
    columns=()
    columnTypes=()

    for((i=0; i< col_num; i++)); do
        col_name=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f1)
        col_type=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f2)
        # read col_name and type name
        columns+=("$col_name")
        columnTypes+=("$col_type")
    done

    pkCol=-1
    for ((i = 0; i < "${#columns[@]}"; i++)); do
        if [[ "${columns[i]}" == "$primaryKey" ]]; then
            pkCol=$i
            break
        fi
    done

    inserted=()
    for((i=0; i< "${#columns[@]}"; i++)); do
        while true; do
            echo ""
            read -p "Enter value for ${columns[i]} and must be of type (${columnTypes[i]}): " val

            if [[ "${columns[i]}" == "$primaryKey" ]]; then
                if ! cut -d: -f"$((pkCol + 1))" "dbms/${dbname}/${table}.csv" | grep -q "^$val$"; then            
                    if type_validation "${columnTypes[i]}" "$val"; then
                        inserted+=("$val")
                        break  # Break the loop if a valid value is entered
                    else
                        echo "Invalid input  '${columns[i]}'. Please enter only ${columnTypes[i]}." 
                    fi
                else
                    echo "Primary key '$val' already exists in the table."
                fi
            else
                if type_validation "${columnTypes[i]}" "$val"; then
                    inserted+=("$val")
                    break
                else
                    echo "Invalid input. Please enter only ${columnTypes[i]}."
                fi
            fi
        
        done
    done
    echo "Entered values: ${inserted[@]}"
    IFS=':' line="${inserted[*]}"
    echo "$line" >> "dbms/${dbname}/${table}.csv"

}

insertInto_table() {
    read -p "Enter Table Name: " table

    if table_exists "$table"; then
        check $table
    else
        echo "Table '$table' doesn't exist"
    fi

}

# Function to delete records from a database table
delete_from_table() {
    delete_record "$table"
}

# Function to delete a record from the specified table
delete_record() {
    echo "Select the table and row/rows you want to delete"

    select_from_table
    if [[ -z "$result" ]]; then
        echo "No records selected. Deletion cancelled."
        return
    fi
    echo ""
    read -p "Do you want to delete all the selected records? (y/n): " confirm_delete
    
    if [[ "$confirm_delete" == "y" || "$confirm_delete" == "Y" ]]; then
    # Delete all selected records
    echo "$result" | while IFS= read -r line; do
        sed -i "/^$line$/d" "dbms/${dbname}/${table}.csv"
    done


    #sed -i "/$result$/d" "dbms/${dbname}/${table}.csv"    
    echo "Selected records deleted successfully."
    else
        echo "Deletion cancelled."
    fi
}


# delete_from_table() {
#     read -p "Enter Table Name: " table

#     if table_exists "$table"; then
#         delete_record "$table"
#     else
#         echo "Table '$table' doesn't exist"
#     fi
# }

# Function to delete a record from the specified table
# delete_record() {
#     local table="$1"

#     # Display existing records
#     echo "Existing records in table '$table':"
#     cat "dbms/${dbname}/${table}.csv"

#     # Prompt user for the primary key value of the record to delete
#     read -p "Enter the primary key value of the record to delete: " pk_value

#     # Check if the primary key value exists in the table
#     if grep -q "^$pk_value:" "dbms/${dbname}/${table}.csv"; then
#         # Remove the record from the table
#         sed -i "/^$pk_value:/d" "dbms/${dbname}/${table}.csv"
#         echo "Record with primary key '$pk_value' deleted successfully."
#     else
#         echo "Record with primary key '$pk_value' not found in table '$table'."
#     fi
# }



# Function to update records in a database table
update_table() {
    read -p "Enter Table Name: " table

    if table_exists "$table"; then
        update_record "$table"
    else
        echo "Table '$table' doesn't exist"
    fi
}

# Function to update a record in the specified table
update_record() {
    local table="$1"
    meta_file="${database_dir}/${dbname}/${table}_meta.txt"
    primaryKey=$(awk -F: '{print $1;}' "$meta_file" | head -n 1)
    # Read the number of columns from metadata file
    col_num=$(head -n 2 "$meta_file" | tail -n 1)

    # Reading column names and types from metadata file
    columns=()
    columnTypes=()

    for ((i=0; i< col_num; i++)); do
        col_name=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f1)
        col_type=$(sed -n "$((i + 3))p" "$meta_file" | cut -d':' -f2)
        columns+=("$col_name")
        columnTypes+=("$col_type")
    done 

    # Prompt user to choose a column to update
    echo "Select a Column to Update"
    echo "Column names: "
    count=1
    for name in "${columns[@]}"; do
        echo "$count. $name"
        ((count++))
    done

    chosen_col=""
    while true; do
        read -p "Enter the number of the column you want to update (1-$col_num): " chosen_col

        if [[ "$chosen_col" =~ ^[1-$col_num]$ ]]; then
            index=$((chosen_col - 1))
            selected_col="${columns[$index]}"
            selected_type="${columnTypes[$index]}"
            echo "Selected column: $selected_col with type $selected_type"
            break
        else
            echo "Invalid input. Please enter a number from 1 to $col_num."
        fi
    done

    # Prompt user to enter the new value for the selected column
    echo ""
    read -p "Enter the new value for $selected_col ($selected_type): " new_value

    # Validate the new value based on column type
    if ! type_validation "$selected_type" "$new_value"; then
        echo "Invalid input. Please enter only $selected_type for $selected_col."
        return 1
    fi

    # Check if the chosen column is the primary key
    if [[ "$selected_col" == "$primaryKey" ]]; then
        # Check if the new primary key already exists in the table
        if grep -q "^$new_value:" "dbms/${dbname}/${table}.csv"; then
            echo "Primary key '$new_value' already exists in the table. Please enter a different value."
            return 1
        fi
    fi

    # Prompt user to choose a condition column for updating
    echo ""
    echo "Select a Column for Condition"
    echo "Column names: "
    count=1
    for name in "${columns[@]}"; do
        echo "$count. $name"
        ((count++))
    done

    condition_col=""
    while true; do
        echo ""
        read -p "Enter the number of the column for condition (1-$col_num), or 0 to update all rows: " condition_col

	if [[ "$selected_col" == "$primaryKey" ]] && [[ "$condition_col" == "0" ]]; then
        echo "You must specify a condition when updating the primary key."
        return 1
        elif [[ "$condition_col" == "0" ]]; then
            break
        elif [[ "$condition_col" =~ ^[1-$col_num]$ ]]; then
            index=$((condition_col - 1))
            condition_column="${columns[$index]}"
            condition_type="${columnTypes[$index]}"
            echo "Condition column: $condition_column with type $condition_type"
            break
        else
            echo "Invalid input. Please enter a number from 0 to $col_num."
        fi
    done

    # Prompt user to enter the condition value
    if [[ "$condition_col" != "0" ]]; then
        echo ""
        read -p "Enter the condition value: " condition_value

        # Validate the condition value based on column type
        if ! type_validation "$condition_type" "$condition_value"; then
            echo "Invalid input. Please enter only $condition_type for $condition_column."
            return 1
        fi
    fi

    # Update the records based on the chosen condition
    if [[ "$condition_col" == "0" ]]; then
        # Update all rows for the selected column
        awk -F':' -v col="$chosen_col" -v val="$new_value" 'BEGIN{OFS=":"} {$col=val; print $0}' "dbms/${dbname}/${table}.csv" > "dbms/${dbname}/${table}_tmp.csv" && mv "dbms/${dbname}/${table}_tmp.csv" "dbms/${dbname}/${table}.csv"
        echo "All rows updated successfully."
    elif [[ "$selected_col" == "$primaryKey" ]] && [[ "$condition_col" != "0" ]]; then
            rows_matched=$(awk -F':' -v cond_col="$condition_col" -v cond_val="$condition_value" 'BEGIN{count=0} {if ($cond_col == cond_val) {count++}} END{print count}' "dbms/${dbname}/${table}.csv")
        if [[ $rows_matched -gt 1 ]]; then
            echo "Error: Condition '$condition_column = $condition_value' matches multiple rows. Please refine your condition."
            return 1
        elif [[ $rows_matched -eq 0 ]]; then
            echo "No records found with '$condition_column = $condition_value'."
        else
            # Update the specified row based on the condition
            awk -F':' -v col="$chosen_col" -v val="$new_value" -v cond_col="$condition_col" -v cond_val="$condition_value" 'BEGIN{OFS=":"} {if ($cond_col == cond_val) {$col=val}; print $0}' "dbms/${dbname}/$table.csv" > "dbms/${dbname}/${table}_tmp.csv" && mv "dbms/${dbname}/${table}_tmp.csv" "dbms/${dbname}/$table.csv"
            echo "Record with $condition_column '$condition_value' updated successfully."
        fi
    else
        # Update the specified rows based on the condition
        if awk -F':' -v cond_col="$condition_col" -v cond_val="$condition_value" 'BEGIN{found=0} {if ($cond_col == cond_val) {found=1; exit}} END{exit !found}' "dbms/${dbname}/${table}.csv"; then
            awk -F':' -v col="$chosen_col" -v val="$new_value" -v cond_col="$condition_col" -v cond_val="$condition_value" 'BEGIN{OFS=":"} {if ($cond_col == cond_val) {$col=val}; print $0}' "dbms/${dbname}/$table.csv" > "dbms/${dbname}/${table}_tmp.csv" && mv "dbms/${dbname}/${table}_tmp.csv" "dbms/${dbname}/$table.csv"
            echo "Records with $condition_column '$condition_value' updated successfully."
        else
            echo "Records with $condition_column '$condition_value' not found in the table."
        fi
    fi
}


# Main Menu
while true; do
    display_banner "Table Menu"
    display_separator
    echo "You are connected to database '${dbname}'"
    echo ""

    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Select From Table"
    echo "5. Insert Into Table"
    echo "6. Delete From Table"
    echo "7. Update Row"
    echo "8. Exit"
    display_separator
    read -p "Enter your choice (1-8): " choice
    display_separator
    case $choice in
        1) create_table ;;
        2) list_tables ;;
        3) drop_table ;;
        4) select_from_table;;
        5) insertInto_table;;
        6) delete_from_table;;
        7) update_table;;
        8) break ;;
        *) echo "Invalid choice. Please enter a number between 1 and 8." ;;
    esac

    display_separator
    read -n 1 -s -r -p "Press any key to continue..."
    echo
    display_separator
done

