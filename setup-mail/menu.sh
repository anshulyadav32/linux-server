#!/bin/bash
# Mail System Management Menu

while true; do
    clear
    echo "======================================"
    echo "      Mail System Management"
    echo "======================================"
    echo "1) Install Mail System"
    echo "2) Email Account Management"
    echo "3) Maintain Mail System"
    echo "4) Update Mail System"
    echo "5) Back to Main Menu"
    echo "======================================"
    read -p "Choose an option [1-5]: " choice

    case $choice in
        1) 
            bash setup-mail/install.sh 
            ;;
        2) 
            # Email Account Management Submenu
            while true; do
                clear
                echo "======================================"
                echo "    Email Account Management"
                echo "======================================"
                echo "1) Add Email Account"
                echo "2) List Email Accounts"
                echo "3) Change Password"
                echo "4) Delete Email Account"
                echo "5) View Mail Queue"
                echo "6) Back"
                echo "======================================"
                read -p "Choose an option [1-6]: " email_choice
                
                case $email_choice in
                    1) 
                        read -p "Enter email address (e.g., user@domain.com): " email
                        if [[ -z "$email" ]]; then
                            echo "❌ Email address cannot be empty!"
                            sleep 2
                            continue
                        fi
                        
                        username=$(echo $email | cut -d'@' -f1)
                        domain=$(echo $email | cut -d'@' -f2)
                        
                        # Create system user for email
                        if id "$username" &>/dev/null; then
                            echo "❌ User $username already exists!"
                        else
                            useradd -m -s /bin/bash $username
                            echo "✅ User $username created!"
                            
                            # Set password
                            read -s -p "Enter password for $email: " password
                            echo
                            echo "$username:$password" | chpasswd
                            
                            # Create Maildir
                            mkdir -p /home/$username/Maildir/{cur,new,tmp}
                            chown -R $username:$username /home/$username/Maildir
                            
                            echo "✅ Email account $email created successfully!"
                        fi
                        sleep 3
                        ;;
                    2)
                        echo "======================================"
                        echo "         Email Accounts"
                        echo "======================================"
                        getent passwd | grep -E '/home/.*:/bin/bash$' | cut -d: -f1
                        echo "======================================"
                        read -p "Press Enter to continue..."
                        ;;
                    3) 
                        read -p "Enter username to change password: " username
                        if id "$username" &>/dev/null; then
                            read -s -p "Enter new password for $username: " password
                            echo
                            echo "$username:$password" | chpasswd
                            echo "✅ Password changed for $username!"
                        else
                            echo "❌ User $username does not exist!"
                        fi
                        sleep 3
                        ;;
                    4)
                        read -p "Enter username to delete: " username
                        if id "$username" &>/dev/null; then
                            read -p "Are you sure you want to delete $username? (y/N): " confirm
                            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                                userdel -r $username 2>/dev/null
                                echo "✅ User $username deleted!"
                            else
                                echo "❌ Operation cancelled."
                            fi
                        else
                            echo "❌ User $username does not exist!"
                        fi
                        sleep 2
                        ;;
                    5)
                        echo "======================================"
                        echo "           Mail Queue"
                        echo "======================================"
                        postqueue -p
                        echo "======================================"
                        read -p "Press Enter to continue..."
                        ;;
                    6) 
                        break 
                        ;;
                    *) 
                        echo "Invalid choice!" 
                        sleep 2
                        ;;
                esac
            done
            ;;
        3) 
            bash setup-mail/maintain.sh 
            ;;
        4) 
            bash setup-mail/update.sh 
            ;;
        5) 
            break 
            ;;
        *) 
            echo "Invalid choice!" 
            sleep 2
            ;;
    esac
done
