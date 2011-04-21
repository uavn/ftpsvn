#!/bin/bash

# FTP updater using svn
#
# Ver 0.31
#
# Changelog:
#  * 0.31 Fix start revision number
#
# Author avi<artem.ria@gmail.com>
#
# Notice:
#  * You must setup config variables and execute script "./ftpsvn" 
#    (Do not run ". ftpsh" or "sh ftpsh" - Ubuntu does not understand source command) 
#  * File .ftpsvn on FTP in version 0.2 contains spaces, that must be necessarily removed to work with 0.3!  
# 
# Require:
#  - bash
#  - subversion client
#  - lftp
#  - wget
#
# ToDo:
#  - Make crossCVS script using CVS drivers (SVN, Mercurial, etc)
#  - Try to get revision word from locale
#  - Delete deleted files
#  - Logging
#  - "svn up" and conflicts
#  - Fix ubuntu ". " and "sh "
#
#
# Config (settings.properties) sample:
#
# path=/var/www/projectundersvn
# ftp_host=ftp.example.com
# ftp_user=username
# ftp_password=password
# ftp_root=/www
# revisionWord=Редакция

# variables init
source settings.properties;
tmpDir=/tmp/ftpsvn;

# updating project
echo Updating project...;
cd $path;
svn up >> /dev/null;

# parsing svn info
echo Parsing svn info...;
lastRevision=$(svn info | sed -ne 's/^'$revisionWord': //p');

echo Trying to get current revision...;

revision=1;

# Trying to get current revision on FTP
wget ftp://$ftp_user:$ftp_password@$ftp_host$ftp_root/.ftpsvn 2> /dev/null
source .ftpsvn
rm .ftpsvn

echo "Server revision is "$revision" and last is "$lastRevision;

if (( revision < lastRevision )); then
    (( revision+=1 ))

    # Getting changed files
    echo Getting changed files list...;
    files=$(svn log -vqr$lastRevision:$revision | egrep '^\ +[M|A]' | uniq | awk '{print $2};');

    echo Coping files to temporary dir...;
    for file in $files; do
		#echo "Copying "$file" ...";
        # Cutting /trunk
        file=${file/#\/trunk/""}
        # Make directory structure
        mkdir -p $(dirname $tmpDir$file);
        # Copying file
        cp $path$file $tmpDir$file; 
    done

    echo "revision=$lastRevision" >> $tmpDir/.ftpsvn;

# Commiting to FTP
echo Commiting files to FTP...;
lftp ${ftp_user}:${ftp_password}@${ftp_host} <<EOF
mirror -R $tmpDir $ftp_root;
quit
EOF

    # Remove temporary directory
    rm -rf $tmpDir;

fi

echo Done!;
