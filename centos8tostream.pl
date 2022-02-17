Preparation

1. Make a backup of all important files before upgrading. If you need help, contact our support team - we'll make a backup for you.
2. Start from checking the current OS version:
$ cat /etc/centos-release​
You'll see an output that should look like this: CentOS Linux release 8.0.1905 (Core)

Installation

1. Install the CentOS Stream repository:
$ dnf install centos-release-stream​
2. Wait until the system loads the packages list and asks for confirmation. Confirm the updating by typing "y":
3. Wait until all the packages are downloaded.
4. Set the new repository as default:
$ dnf swap centos-{linux,stream}-repos​
5. Wait until the system loads the packages list and asks for confirmation. Confirm the updating by typing "y"
6. Wait until all the packages are installed.

Synchronization

1. Run the synchronization with the new repository:
$ dnf distro-sync​
2. Wait until the system loads the packages list and confirm the installation by typing "y":
3. To make sure that the update was successful, run the check OS version command again:
$ cat /etc/release​
The output should look like this: CentOS Stream release 8