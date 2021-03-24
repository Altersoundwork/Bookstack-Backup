#!/bin/bash

########################################################################################################
###                                      v0.1 - 10th of May, 2020                                    ###
### This script sets up automated backup on a remote server for your local installation of Bookstack ###
###                         By Altersoundwork - https://github.com/Altersoundwork                    ###
########################################################################################################
# Requirements & initial variables
if [ "$EUID" -ne 0 ]
  then echo "Please run as root (sudo bash)"
  exit
fi
clear
bold=$(tput bold)
normal=$(tput sgr0)
########################################################################################################
echo ${bold}
echo "######################"
echo "Bookstack Backup Setup"
echo "######################"
echo ${normal}
########################################################################################################
echo
echo "This setup script assumes the following. If any of it is erronous, please do not continue until it matches your scenario:"
echo
echo "${bold}- You're running this script on the Bookstack server${normal}"
echo "- Your Bookstack is fully setup and you have SSH access to the server it's on."
echo "- You have another server/vm/pc/instance/nas/whatever where the backups will live."
echo "- You have SSH access to the backup server."
echo "- If both servers aren't on the same LAN, your Backup server can be accessed via IP or Domain name"
echo "${bold}- You're running this script on the Bookstack server${normal}"
echo
read -p "${bold}Do you meet these requirements?${normal}" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && echo && echo "${bold}Please meet the requirements prior to continuing with the Bookstack Backup Setup.${normal}" && echo && exit 1 || return 1
fi
clear
########################################################################################################
echo ${bold}
echo "######################"
echo "Bookstack Backup Setup"
echo "######################"
echo ${normal}
########################################################################################################
echo
echo "This setup script will install the SSHPASS package and any dependendcies it may require. More info can be found on https://bit.ly/2YK9TrC:"
echo
read -p "${bold}Are you ok with this?${normal}" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && echo && echo "${bold}SSHPASS is required for this script to continue.${normal}" && echo && exit 1 || return 1
fi
echo
sudo apt install sshpass -y
clear
########################################################################################################
echo ${bold}
echo "###############################################"
echo "Bookstack Backup Setup || Step 1: Backup Server"
echo "###############################################"
echo ${normal}
########################################################################################################
echo
echo ${bold}What is the IP or domain for the Backup server?${normal}
read serverbackup
echo
echo ${bold}What SSH user should you use to connect to it for the initial setup?${normal}
read bkupserveruser
echo
echo ${bold}and what password?${normal}
read -s bkupserverpw
echo
ping -c4 $serverbackup
echo
read -p "${bold}Did the ping to $serverbackup succeed?${normal}" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && echo && echo "${bold}Check connectivity. Is $serverbackup the correct address?${normal}" && echo && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi
clear
########################################################################################################
echo ${bold}
echo "###############################################"
echo "Bookstack Backup Setup || Step 1: Backup Server"
echo "###############################################"
echo ${normal}
########################################################################################################
echo "${bold}Do you want to create and limit a user on your Backup Server specifically for Bookstack Backups?${normal}"
options=("Yes" "No or the user info I've provided is already that user")
echo
select opt in "${options[@]}"; do
echo
    case "$REPLY" in

### Option 1 allows the user to choose a new username to use for the Backup
### it also asks if the standard folder structure is ok.

    1 )
    echo ${bold}What is the username you\'d like to create?${normal}
    read bkupserveruser2
    echo
    echo ${bold}and password?${normal}
    read -s bkupserverpw2
    echo
    sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo adduser --disabled-password --no-create-home --gecos \"Bookstack\" $bkupserveruser2 && sudo echo -e \"$bkupserverpw2\n$bkupserverpw2\" | sudo passwd $bkupserveruser2"
    echo
    clear
    ########################################################################################################
    echo ${bold}
    echo "###############################################"
    echo "Bookstack Backup Setup || Step 1: Backup Server"
    echo "###############################################"
    echo ${normal}
    ########################################################################################################
    echo ${bold}"Is this folder structure ok for your Bookstack Backups in your Backup Server: \"/home/$bkupserveruser2/Bookstack_Backups/\"?"${normal}
    echo
    options=("Yes" "No, please let me specify a folder")
    echo
    select opt in "${options[@]}"; do
    echo
        case "$REPLY" in

####### Option 1 Says that YES, the standard structure is fine and sets the variable declaring it so
####### It also creates the folder and gives it the correct permissions.

        1 )
        echo "Ok, we'll continue with \"/home/$bkupserveruser2/Bookstack_Backups/\" as the folder structure"
        sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo mkdir /home/$bkupserveruser2 && sudo usermod -d /home/$bkupserveruser2 $bkupserveruser2"
        bkupfolder="/home/$bkupserveruser2/Bookstack_Backups"
        sleep 2
        clear
        ########################################################################################################
        echo ${bold}
        echo "###############################################"
        echo "Bookstack Backup Setup || Step 1: Backup Server"
        echo "###############################################"
        echo ${normal}
        ########################################################################################################
        echo
        echo ...Attempting to create folder on the Backup Server
        echo
        sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo mkdir $bkupfolder && sudo chown -R $bkupserveruser2:$bkupserveruser2 $bkupfolder"
        echo
        read -p "${bold}Did everything go alright (\"Connection to X closed\" messages are OK, other messages are NOT OK)?${normal}" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}Sorry, something went wrong with creating the folder, restart the script and make sure the user you specified has permissions to do so.${normal}" && echo && exit 1 || return 1
        fi
        echo
        ;;

####### Option 2 Says that NO and asks the user what folder to use. Either case will set the variable accordingly
####### It also creates the folder and gives it the correct permissions.

        2 )
        echo ${bold}What folder would you like \(please type the whole path\)?${normal}
        read bkupfolder
        echo
        options=("Yes" "No, let me try again")
        echo ${bold}Is this correct?${normal}
        echo
        echo $bkupfolder
        echo
        select opt in "${options[@]}"; do
        echo
            case "$REPLY" in

########### Option 1 confirms that the folder specified is OK.

            1 )
            echo "Ok, we'll continue with \"$bkupfolder\""
            ;;

########### Option 2 is a final chance to correct the specified folder, if mistaken again, the script will end.

            2)
            echo ${bold}What folder would you like \(please type the whole path\)?${normal}
            read bkupfolder
            echo
            read -p "${bold}Is this correct?${normal}" -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]
            then
              [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}I'm not fond of loops so... the script is ending now, figure out the issue and run me again.${normal}" && echo && exit 1 || return 1
            fi
            ;;

        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
        *) echo "Invalid option. Try another one.";continue;;
        esac
        break
        done
        clear
        ########################################################################################################
        echo ${bold}
        echo "###############################################"
        echo "Bookstack Backup Setup || Step 1: Backup Server"
        echo "###############################################"
        echo ${normal}
        ########################################################################################################
        echo
        echo ...Attempting to create folder on the Backup Server and make it the home folder for $bkupserveruser2
        echo
        sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo mkdir $bkupfolder && sudo chown -R $bkupserveruser2:$bkupserveruser2 $bkupfolder && sudo usermod -d $bkupfolder $bkupserveruser2"
        echo
        read -p "${bold}Did everything go alright (\"Connection to X closed\" messages are OK, other messages are NOT OK)?${normal}" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}Sorry, something went wrong with creating the folder, restart the script and make sure the user you specified has permissions to do so.${normal}" && echo && exit 1 || return 1
        fi
        echo
        bkupserveruser="$bkupserveruser2"
        bkupserverpw="$bkupserverpw2"
        ;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
    break
    done
    ;;

### Option 2 continues with the originally provided Backup Server credentials
### it also aks if the standard folder structure is ok.

    2 )
    echo "Ok, we'll continue with the already provided credentials"
    sleep 2
    echo
    echo ${bold}"Is this folder structure ok for your Bookstack Backups in your Backup Server: \"/home/$bkupserveruser/Bookstack_Backups/\"?"${normal}
    echo
    clear
    ########################################################################################################
    echo ${bold}
    echo "###############################################"
    echo "Bookstack Backup Setup || Step 1: Backup Server"
    echo "###############################################"
    echo ${normal}
    ########################################################################################################
    echo ${bold}"Is this folder structure ok for your Bookstack Backups in your Backup Server: \"/home/$bkupserveruser/Bookstack_Backups/\"?"${normal}
    echo
    options=("Yes" "No, please let me specify a folder")
    echo
    select opt in "${options[@]}"; do
    echo
        case "$REPLY" in

####### Option 1 Says that YES, the standard structure is fine and sets the variable declaring it so.

        1 )
        echo "Ok, we'll continue with \"/home/$bkupserveruser/Bookstack_Backups/\" as the folder structure"
        bkupfolder="/home/$bkupserveruser/Bookstack_Backups"
        sleep 2
        clear
        ########################################################################################################
        echo ${bold}
        echo "###############################################"
        echo "Bookstack Backup Setup || Step 1: Backup Server"
        echo "###############################################"
        echo ${normal}
        ########################################################################################################
        echo
        echo ...Attempting to create folder on the Backup Server
        echo
        sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo mkdir $bkupfolder && sudo chown -R $bkupserveruser:$bkupserveruser $bkupfolder"
        echo
        read -p "${bold}Did everything go alright (\"Connection to X closed\" messages are OK, other messages are NOT OK)?${normal}" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}Sorry, something went wrong with creating the folder, restart the script and make sure the user you specified has permissions to do so.${normal}" && echo && exit 1 || return 1
        fi
        echo
        ;;

####### Option 2 Says that NO and asks the user what folder to use. Either case will set the variable accordingly but choosing a custom folder will also set it as the user's home folder.

        2 )
        echo ${bold}What folder would you like \(please type the whole path\)?${normal}
        read bkupfolder
        echo
        options=("Yes" "No, let me try again")
        echo ${bold}Is this correct?${normal}
        echo
        echo $bkupfolder
        echo
        select opt in "${options[@]}"; do
        echo
            case "$REPLY" in

########### Option 1 confirms that the folder specified is OK.

            1 )
            echo "Ok, we'll continue with \"$bkupfolder\""
            ;;

########### Option 2 is a final chance to correct the specified folder, if mistaken again, the script will end.

            2)
            echo ${bold}What folder would you like \(please type the whole path\)?${normal}
            read bkupfolder
            echo
            read -p "${bold}Is this correct?${normal}" -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]
            then
              [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}I'm not fond of loops so... the script is ending now, figure out the issue and run me again.${normal}" && echo && exit 1 || return 1
            fi
            ;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
        *) echo "Invalid option. Try another one.";continue;;
        esac
        break
        done
        clear
        ########################################################################################################
        echo ${bold}
        echo "###############################################"
        echo "Bookstack Backup Setup || Step 1: Backup Server"
        echo "###############################################"
        echo ${normal}
        ########################################################################################################
        echo
        echo ...Attempting to create folder on the Backup Server
        echo
        sshpass -p $bkupserverpw ssh -t -oStrictHostKeyChecking=no $bkupserveruser@$serverbackup "sudo mkdir $bkupfolder && sudo chown -R $bkupserveruser:$bkupserveruser $bkupfolder"
        echo
        read -p "${bold}Did everything go alright (\"Connection to X closed\" messages are OK, other messages are NOT OK)?${normal}" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}Sorry, something went wrong with creating the folder, restart the script and make sure the user you specified has permissions to do so.${normal}" && echo && exit 1 || return 1
        fi
        echo
        ;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
    break
    done
    ;;

$(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
*) echo "Invalid option. Try another one.";continue;;
esac
break
done
clear
########################################################################################################
echo ${bold}
echo "##################################################"
echo "Bookstack Backup Setup || Step 2: Bookstack Server"
echo "##################################################"
echo ${normal}
########################################################################################################
echo
echo "${bold}What is the password for the bookstack database user?${normal}"
echo ${bold}\(You would\'ve specified this during the Bookstack install. If you don\'t remember, you can find it in ~/bookstack/.env under \"DB_PASSWORD\"\)${normal}
read -s bookstackpw
clear
########################################################################################################
echo ${bold}
echo "##################################################"
echo "Bookstack Backup Setup || Step 2: Bookstack Server"
echo "##################################################"
echo ${normal}
########################################################################################################
echo
echo "${bold}We are now going to create the backup script that will run periodically. Should we store it in $HOME?${normal}"
options=("Yes" "No, let me choose where to store it")
echo ${bold}${normal}
echo
select opt in "${options[@]}"; do
echo
    case "$REPLY" in

### Option 1 confirms that the folder specified is OK.

    1 )
    echo "Ok, we'll continue with \"$HOME\""
    bkupscriptfolder=$HOME
    sleep 2
    ;;

### Option 2 allows the user to choose which folder the script will be stored in.

    2)
    echo ${bold}What folder would you like \(please type the whole path\)?${normal}
    read bkupscriptfolder
    echo
    echo "${bold}Is this correct?${normal}"
    echo
    echo $bkupscriptfolder
    echo
    options=("Yes" "No, let me try again")
    echo ${bold}${normal}
    echo
    select opt in "${options[@]}"; do
    echo
        case "$REPLY" in

####### Option 1 confirms that the folder specified is OK.

        1 )
        echo "Ok, we'll continue with \"$bkupscriptfolder\""
        sleep 2
        ;;

####### Option 2 gives user one last chance to choose which folder the script will be stored in. If this fails, the script will end.

        2)
        echo ${bold}What folder would you like \(please type the whole path\)?${normal}
        read bkupscriptfolder
        echo
        read -p "${bold}$bkupscriptfolder -> Is this correct?${normal}" -n 1 -r
        echo
        echo
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          [[ "$0" = "$BASH_SOURCE" ]] && clear && echo && echo "${bold}I'm not fond of loops so... the script is ending now, figure out the issue and run me again.${normal}" && echo && exit 1 || return 1
        fi
        ;;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
    break
    done
    clear
    ;;

$(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
*) echo "Invalid option. Try another one.";continue;;
esac
break
done
clear
########################################################################################################
echo ${bold}
echo "##################################################"
echo "Bookstack Backup Setup || Step 2: Bookstack Server"
echo "##################################################"
echo ${normal}
########################################################################################################
### start of bookstack_bkup.sh creation.
date1='date=$(date +"%d-%m-%Y@%H-%M")'
date2='$date'
echo
cd $bkupscriptfolder && sudo rm bookstack_bkup.sh && sudo touch bookstack_bkup.sh && sudo chmod +x bookstack_bkup.sh
sudo bash -c "echo \#!/bin/bash >> $bkupscriptfolder/bookstack_bkup.sh"
sudo tee -a $bkupscriptfolder/bookstack_bkup.sh > /dev/null <<< "$date1"
sudo bash -c "echo \#\#\# >> $bkupscriptfolder/bookstack_bkup.sh"
sudo bash -c "echo cd $bkupscriptfolder >> $bkupscriptfolder/bookstack_bkup.sh"
sudo bash -c "echo mysqldump -u bookstack bookstack \> bookstack_db_backup.sql >> $bkupscriptfolder/bookstack_bkup.sh"
### These next 2 lines are different because they need to mantain $date as such instead of the actual date. $date2 is declared as $date at the beggining of this block.
### If sudo bash -c was used, $date2 would equeal $date which would equal the actual date. With sudo tee -a, it stops after the first output so ""$date" remains on the file.
### $bkupscriptfolder isn't affect as it resolves once and outputs the folder structure specified by the user earlier.
sudo tee -a $bkupscriptfolder/bookstack_bkup.sh > /dev/null <<< "sudo tar cvf bookstack_db_bkup_$date2.tar.gz bookstack_db_backup.sql"
sudo tee -a $bkupscriptfolder/bookstack_bkup.sh > /dev/null <<< "sudo tar cvf bookstack_files_bkup_$date2.tar.gz /var/www/bookstack"
sudo bash -c "echo sshpass -p $bkupserverpw scp -oStrictHostKeyChecking=no bookstack_db_bkup_* $bkupserveruser@$serverbackup:$bkupfolder >> $bkupscriptfolder/bookstack_bkup.sh"
sudo bash -c "echo sshpass -p $bkupserverpw scp -oStrictHostKeyChecking=no bookstack_files_bkup_* $bkupserveruser@$serverbackup:$bkupfolder >> $bkupscriptfolder/bookstack_bkup.sh"
sudo bash -c "echo rm -rf bookstack_files_bkup_* bookstack_db_bkup_* bookstack_db_backup.sql >> $bkupscriptfolder/bookstack_bkup.sh"
### end of bookstack_bkup.sh creation.
cd $HOME
### start of .my.cnf creation.
touch .my.cnf
bash -c "echo [mysqldump] >> $HOME/.my.cnf"
bash -c "echo user = bookstack >> $HOME/.my.cnf"
bash -c "echo password = $bookstackpw >> $HOME/.my.cnf"
### end of .my.cnf creation.
clear
########################################################################################################
echo ${bold}
echo "#####################################################"
echo "Bookstack Backup Setup || Step 3: Cronjob for Backups"
echo "#####################################################"
echo ${normal}
########################################################################################################
content=$bkupscriptfolder/bookstack_bkup.sh
echo
echo "Please answer the following questions to set the cronjob up, respond with asterisk if it doesn't apply"
echo
echo ${bold}What day of the week do you want it to run \(Choose from 0 to 7 or a range, i.e. 0-7 is every day, Sunday=0\)?${normal}
read dayofweek
echo
echo ${bold}What Month do you want it to run \(Choose from 1 to 12\)?${normal}
read month
echo
echo ${bold}What day of the month do you want it to run \(Choose from 1 to 31\)${normal}
read dayofmonth
echo
echo ${bold}What hour do you want it to run \(Choose from 0 to 23 or a range, i.e. 0-23 is every hour\)?${normal}
read hour
echo
echo ${bold}What minute do you want it to run \(Choose from 0 to 59 or a range, i.e. 0-59 is every minute\)?${normal}
read minute
########################################################################################################
echo "$minute $hour $dayofmonth $month $dayofweek root bash $content" >> /etc/crontab
########################################################################################################
echo ${bold}
echo "#####################################################"
echo "Bookstack Backup Setup || Step 3: Cronjob for Backups"
echo "#####################################################"
echo ${normal}
########################################################################################################
echo
echo "All done, do you want to perform an initial backup to make sure all is ok?"
echo
options=("Yes" "No")
echo
select opt in "${options[@]}"; do
echo
    case "$REPLY" in

    1 )
    sudo bash $bkupscriptfolder/bookstack_bkup.sh
    clear
    ########################################################################################################
    echo ${bold}
    echo "#####################################################"
    echo "Bookstack Backup Setup || Step 3: Cronjob for Backups"
    echo "#####################################################"
    echo ${normal}
    ########################################################################################################
    echo
    echo "Did everything go ok (go and check the Backup Server)?"
    echo
    options=("Looks like it!" "No")
    echo
    select opt in "${options[@]}"; do
    echo
        case "$REPLY" in

        1 )
        echo
        echo "${bold}All done then, have a nice day!${normal}" && echo && sleep 2 && clear && exit 1 || return 1
        ;;

        2 )
        echo
        echo "${bold}Please check want went wrong and go through the setup again if required.${normal}" && echo && exit 1 || return 1
        ;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
        *) echo "Invalid option. Try another one.";continue;;
    esac
    break
    done
    clear
    ;;

    2 )
    echo
    echo "${bold}All done then, have a nice day!${normal}" && echo && sleep 2 && clear && exit 1 || return 1
    ;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
esac
break
done
clear

