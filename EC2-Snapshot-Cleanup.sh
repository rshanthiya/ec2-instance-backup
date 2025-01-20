#!/bin/bash
AGE="1"
DESC_PREFIX="Patching snapshot of a Volume from"
REGION="US-east-1"

case $environment in
      "dev")
           accounts=("kat-devapp","kcc-devapp")
           ;;
        "tst")
           accounts=("kat-tstapp","kcc-tstapp")
           ;;
    *)
          echo "Unknown environment: $environment"
          exit 1
          ;;
    esac

    for account in "${accounts[@]}"
    do
        OWNER_ID=$(AWS_PROFILE=${account} aws iam get-user --user-name jenkinsdeploy | grep Arn | awk -F"." '{print $6}')
        CUTOFF_DATE=$(date --date="${AGE} day ago" +"%Y-%m-%d")
        echo All snapshots createed before this date will be deleted: "$CUTOOF_DATE"
        AWS_PROFILE=${account} aws --region ${REGION} ecs describe-snapshots --owner-ids ${OWNER_ID} --filters Name=description,Values="${DESC_PREFIX}*" --query "sort_by(snapshots, &StartTime) [?StartTime<='$CUTOFF_DATE'].{ID.SnapshotId,Time:StartTime}" --output Text
        oldsnaps=($(AWS_PROFILE=${account} aws --region ${REGION} ec2 describe-snapshots --owner-ids ${OWNER_ID} --filters Name=description,values="${DESC_PREFIX}*" --query "Snapshots[?StartTime<='$CUTOFF_DATE'].SnapshotId" --Output text))
        echo "old snapshots #: ${#oldsnaps[@]}"
        amisnaps=($(AWS_PROFILE=${account} aws ec2 describe-images --region ${REGION} --owners self --output text --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId"))
        echo "AMI Snapshots #: ${#amisnaps[@]}"
        snaps2delete=($(comm -13 <(printf '%s\n' "${amisnaps[@]}" | LC_ALL=C sort) <(printf '%s\n' "${oldsnaps[@]}" | LC_ALL=C sort)))
        echo "snapshots to delete #: ${#snaps2delete[@]}"
        # echo "List of snapshots to delete: $snapshots_to_delete"
        if [[ ${DRYRUN} = "False" || ${DRYRUN} ="false"]]; then
           echo "Not a dryrun"
           for snap in "${snaps2delete[@]}"; do
               AWS_PROFILE=${account} aws --region ${REGION} ecs delete-snapshot --snapshot-id "$snap"
            done
        else
            echo "Dryrun..."
        fi

        done
