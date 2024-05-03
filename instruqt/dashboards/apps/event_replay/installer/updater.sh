repoOwner="Graylog2"
repo="sales-engineering"
branch="deploy"
childFolderInGithubRepo="Demo Event Replay"

updaterWorkingPath="/opt/graylog/log-replay-updater/"
updaterPathEscaped=$(echo $updaterWorkingPath | sed 's/\//\\\//g')

tokenFile="${updaterWorkingPath}token"
commitShaCacheFile="${updaterWorkingPath}lastcommit"
tarFile="${updaterWorkingPath}tar.tar"
newDirContentsTemp="${updaterWorkingPath}dircontents.txt"

targetLogReplayDir="/opt/graylog/log-replay/"

iFileExists=0
iFoundInLoop=0

iNewCommit=0

if [ -f "$commitShaCacheFile" ]; then
    iFileExists=1
fi

# read token
token=$(cat $tokenFile)

# get most recent commit from branch
echo "Checking latest commit for branch '$branch'"
latestCommitSha=$(curl -s --request GET --url "https://api.github.com/repos/$repoOwner/$repo/branches" --header "Accept: application/vnd.github+json" --header "Authorization: Bearer $token" | jq ".[] | select(.name==\"$branch\").commit.sha" | grep -oP "[a-f0-9]+")
# todo - 
#   verify successful result, if failed, log/alert?
#   for example, if token expires, this file will be changed.
#       when setting a new token, this updater will think there are updates
#       even though there are not any new updates, and it will run its update tasks
#       not the destructive or the end of the world but it should be avoided

echo "Most Recent Commit: $latestCommitSha"

if [[ "$iFileExists" == "1" ]]; then
    # compare with existing file
    existingCommitSha=$(cat $commitShaCacheFile | grep -oP "[a-f0-9]+")
    echo "existingCommitSha = $existingCommitSha"
    echo "latestCommitSha = $latestCommitSha"
    if [[ "$existingCommitSha" != "$latestCommitSha" ]]; then
        iNewCommit=1
    fi
else
    # no file to compare to
    iNewCommit=1
fi

if [[ "$iNewCommit" == "1" ]]; then
    # there is a new commit, lets run updater actions
    echo "There is a new commit! UPDATING..."

    # save commit in cache
    echo "$latestCommitSha" > $commitShaCacheFile

    # Download latest tar
    rm -rf "$tarFile"
    curl --request GET --url "https://api.github.com/repos/$repoOwner/$repo/tarball/$latestCommitSha" --header "Accept: application/vnd.github+json" --header "X-GitHub-Api-Version: 2022-11-28" --header "Authorization: Bearer $token" -v -L --output "$tarFile"
    
    # expand tar
    tar -xzf "$tarFile" -C "$updaterWorkingPath"
    
    # get correct extracted dir
    ls -d /opt/graylog/log-replay-updater/*/ > "${updaterWorkingPath}dir.txt"
    for i in $(cat ${updaterWorkingPath}dir.txt); do
        thisDirInThisLoopOrig=$i
        thisDirInLoop=$(echo "$i" | sed "s/$updaterPathEscaped//" | sed 's/\///')
        echo $thisDirInLoop

        if echo "$thisDirInLoop" | grep -q "$latestCommitSha"; then
            # echo "Found dir: $thisDirInThisLoopOrig"
            updatedContentDir="$thisDirInThisLoopOrig"
            iFoundInLoop=1
            break
        fi
    done

    if [[ "$iFoundInLoop" == "1" ]]; then
        # we have a valid directory extracted from the downloaded tar
        # get child dir
        whatChildIsThis="${thisDirInThisLoopOrig}${childFolderInGithubRepo}"
        echo "New Contents Dir: $whatChildIsThis"
        
        # escapedPath=$(echo $whatChildIsThis | sed 's/ /\\ /g')
        # echo $escapedPath

        ls "${whatChildIsThis}/" > $newDirContentsTemp
        for f in $(cat $newDirContentsTemp)
        do
            echo "Processing $f file..."
            # copy python files
            if echo "$f" | grep -qP "\.py$|\.events$|\.yml$"; then
                if echo "$f" | grep -qP "^overrides.yml$"; then
                    echo "    ignoring excluded file."
                else
                    echo "    Will copy...."
                    sudo cp -f "${whatChildIsThis}/$f" "$targetLogReplayDir"
                fi
            fi
        done

        # set owner
        sudo chown gl_replay_service:gl_replay_service $targetLogReplayDir/*

        # restart service
        sudo systemctl restart gl-log-replay

        # cleanup
        rm -rf $thisDirInThisLoopOrig
        rm -f $tarFile

        # =====================================================================

    else
        echo "ERROR - cannot find a valid directory extracted from downlaoded tar!"
    fi

else
    echo "Latest commit for branch '$branch' is not new. Nothing to do."
fi
