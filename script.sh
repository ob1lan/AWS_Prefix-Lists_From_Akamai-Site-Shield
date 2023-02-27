#!/bin/sh

NOW=$(date +"%Y-%b-%d_%H:%M:%S")
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

mkdir /root/output
LOG_FILE="/root/output/$NOW.log"

logit() 
{
  echo -e "[$(date +"%Y-%b-%d_%H:%M:%S")] - ${*}" 2>&1 | tee -a ${LOG_FILE}
}

evaluate_pl() {
  local plid="$1"
  local mapname="$2"
  local region="$3"

  logit "Going to evaluate $1 ($3) against $2"

  PROP="/root/output/"$mapname"_proposed.txt"

  # First get the specified Akamai map file in JSON format (showing both current and proposed CIDRs), and extract proposed to MAP-NAME_proposed.txt
  akamai ss --section "default" list-cidrs --map-name $mapname --json | jq -r '.proposedCidrs[]' | sort > $PROP
  logit "Logged $2 proposed CIDRs into $PROP"

  # Then, get the specified AWS Managed Prefix List CIDRs into a PL-ID_Vxx_Current-CIDRs.txt
  currentVersion=$(aws ec2 describe-managed-prefix-lists --region $3 --filters Name=prefix-list-id,Values=$plid | jq -r '.PrefixLists[].Version')
  CURRENT="/root/output/"$plid"_V"$currentVersion"_Current-CIDRs.txt"
  aws ec2 get-managed-prefix-list-entries --prefix-list-id $plid --region $3 | jq -r '.Entries[].Cidr' | sort > $CURRENT
  logit "Logged $1 current CIDRs into $CURRENT"

  # Finally, evaluate the content of the PL-ID_Vxx_Current-CIDRs.txt against the MAP-NAME_proposed.txt to obtain details on the changes: PL-ID_Vxx_ToBeAdded.txt and PL-ID_Vxx_ToBeRemoved.txt
  # Show what is to be removed
  TBD="/root/output/"$plid"_V"$currentVersion"_ToBeDeletedFromCurrent.txt"
  comm -23 $CURRENT $PROP > $TBD

  # Check if the file is empty
  if [ ! -s "${TBD}" ]; then
    logit "Nothing to remove from $1"
    rm $TBD
  else
    logit "Logged CIDRs to be deleted from $1 into $TBD"
    echo -e "${RED}Will delete those CIDRs:"
    echo -e "$(cat $TBD)${NC}"
  fi

  # Show what is to be added
  TBA="/root/output/"$plid"_V"$currentVersion"_ToBeAddedFromCurrent.txt"
  comm -13 $CURRENT $PROP > $TBA

  # Check if the file is empty
  if [ ! -s "${TBA}" ]; then
    logit "Nothing to add in $1"
    rm $TBA
  else
    logit "Logged CIDRs to be added to $1 into $TBA"
    echo -e "${GREEN}Will add those CIDRs:"
    echo -e "$(cat $TBA)${NC}"
  fi

  # Show what doesn't change
  UNC="/root/output/"$plid"_V"$currentVersion"_UnchangedFromCurrent.txt"
  comm -12 $CURRENT $PROP > $UNC
  logit "Logged unchanged CIDRs in $1 into $UNC"
  logit "Finished to evaluate $1 ($3) against $2"
}

refresh_pl() {
  local plid="$1"
  local mapname="$2"
  local region="$3"
  logit "Going to refresh $1 ($3) with values from $2"

  evaluate_pl $1 $2
  if [ ! -s "${TBD}" ] && [ ! -s "${TBA}" ]; then
    logit "Nothing to change in $1, exiting now"
    exit 125
  else
    logit "Changes to be applied on $1 ($3), will continue now"
  fi

  # Removes entries from the specified Prefix List
  CIDRs_RM=""
  TBD="/root/output/"$plid"_V"$currentVersion"_ToBeDeletedFromCurrent.txt"

  # Check if the file is empty
  if [ ! -s "${TBD}" ]; then
    logit "Nothing to remove from $1 ($3)"
  else
    for CIDR in $(cat $TBD); do CIDRs_RM="$CIDRs_RM""Cidr=""$CIDR "; done

    currentVersion=$(aws ec2 describe-managed-prefix-lists --region $3 --filters Name=prefix-list-id,Values=$plid | jq -r '.PrefixLists[].Version')
    logit "Current version of $1 ($3) is V$currentVersion"
    aws ec2 modify-managed-prefix-list --prefix-list-id $plid --region $3 --remove-entries $CIDRs_RM --current-version $currentVersion >> $LOG_FILE
    logit "Removed entries from $1 ($3) using content of $TBD"
    echo -e "${RED}Those CIDRs have been removed:"
    echo -e "$CIDRs_RM"${NC}
  fi


  # Now add new content to the Prefix List
  CIDRs_ADD=""
  TBA="/root/output/"$plid"_V"$currentVersion"_ToBeAddedFromCurrent.txt"

  # Check if the file is empty
  if [ ! -s "${TBA}" ]; then
    logit "Nothing to add in $1 ($3)"
  else
    for CIDR_ADD in $(cat $TBA) ; do CIDRs_ADD="$CIDRs_ADD""Cidr=""$CIDR_ADD "; done
    logit "Will now add entries to $1 ($3) using content of $TBA"

    currentVersion=$(aws ec2 describe-managed-prefix-lists --region $3 --filters Name=prefix-list-id,Values=$plid | jq -r '.PrefixLists[].Version')
    aws ec2 modify-managed-prefix-list --prefix-list-id $plid --region $3 --add-entries $CIDRs_ADD --current-version $currentVersion >> $LOG_FILE
    echo -e "${GREEN}Those CIDRs have been added:"
    echo -e "$CIDRs_ADD"${NC}

    # Finally, get the latest version of the Prefix List for documentation and to confirm the changes
    currentVersion=$(aws ec2 describe-managed-prefix-lists --region $3 --filters Name=prefix-list-id,Values=$plid | jq -r '.PrefixLists[].Version')
    logit "Updated version of $1 ($3) is V$currentVersion"
    UPDT="/root/output/"$plid"_V"$currentVersion"_Current-CIDRs.txt"
    aws ec2 get-managed-prefix-list-entries --prefix-list-id $plid --region eu-central-1 | jq -r '.Entries[].Cidr' | sort > $UPDT
    logit "Logged new version of $1 ($3) into $UPDT"
  fi
}

# The following function is used for testing only, as a mean to quickly empty a test Prefix List
empty_pl() {
  local plid="$1"
  local region="$2"
  # Empties the specified Prefix List
  toBeRemoved=$(aws ec2 get-managed-prefix-list-entries --prefix-list-id $plid --region $2 | jq -r '.Entries[].Cidr')

  CIDRs_RM=""
  for CIDR in $toBeRemoved; do CIDRs_RM="$CIDRs_RM""Cidr=""$CIDR "; done

  currentVersion=$(aws ec2 describe-managed-prefix-lists --region $2 --filters Name=prefix-list-id,Values=$plid | jq -r '.PrefixLists[].Version')
  aws ec2 modify-managed-prefix-list --prefix-list-id $plid --region $2 --remove-entries $CIDRs_RM --current-version $currentVersion
}

case "$1" in
  "") ;;
  evaluate_pl) "$@"; exit;;
  refresh_pl) "$@"; exit;;  
  empty_pl) "$@"; exit;;      
  *) log_error "Unkown function: $1()"; exit 2;;
esac
