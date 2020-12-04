AZ="dcn0"
CROSS_AZ="control-plane"
IMAGE=cirros
VOLUME_NAME="pet-volume-${AZ}"
RC=~/control-planerc

CLEAN=0
CINDER=0
BACKUP=1

if [[ ! -e $RC ]]; then
    echo "$RC is missing. Aborting."
    exit 1
fi
source $RC

IMG_ID=$(openstack image show $IMAGE -c id -f value)
if [[ $? != 0 ]]; then
    echo "Unable to find Glance image: $IMAGE . Aborting."
    exit 1
fi

if [[ $CLEAN -eq 1 ]]; then
    echo "Deleting previous Cinder volume(s)"
    for ID in $(openstack volume list -f value -c ID); do
        openstack volume delete $ID;
    done
fi

if [[ $CINDER -eq 1 ]]; then
    echo "Creating Cinder volume $VOLUME_NAME from $IMG_ID"
    openstack volume create --size 8 --availability-zone $AZ $VOLUME_NAME --image $IMG_ID
    VOL_ID=$(openstack volume show -f value -c id $VOLUME_NAME)
    if [[ $? != 0 ]]; then
        echo "Unable to find volume: $VOLUME_NAME. Aborting."
        exit 1
    fi
else
    VOL_ID=$(openstack volume show -f value -c id $VOLUME_NAME)
fi


if [[ $BACKUP -eq 1 ]]; then
    echo "backing up $VOL_ID"
    cinder --os-volume-api-version 3.51 backup-create $VOL_ID --availability-zone $CROSS_AZ
    BACKUP_ID=$(openstack volume backup list -c ID -f value)
    openstack volume show $BACKUP_ID
    STATUS=$(openstack volume backup list -c Status -f value)
    if [[ $STATUS == 'error' ]]; then
        echo "cinder backup-create failed"
        exit 1
    fi
    sleep 30
    openstack volume list
    cinder --os-volume-api-version 3.47 create --backup-id $BACKUP_ID --availability-zone $CROSS_AZ
fi
