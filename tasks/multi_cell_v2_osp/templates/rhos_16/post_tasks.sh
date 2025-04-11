#!/bin/bash
source ~/stackrc
mkdir -p /home/stack/inventories

for i in overcloud cell1; do \
    /usr/bin/tripleo-ansible-inventory \
        --static-yaml-inventory /home/stack/inventories/${i}.yaml \
        --stack ${i}; \
done

CELL_CTRL_IP=$(openstack server list -f value -c Networks --name cellcontrol-0 | sed 's/ctlplane=//')
CTRL_IP=$(openstack server list -f value -c Networks --name controller-0 | sed 's/ctlplane=//')
CELL_INTERNALAPI_INFO=$(ssh heat-admin@${CELL_CTRL_IP} egrep cell1.internalapi /etc/hosts)
ansible -i /usr/bin/tripleo-ansible-inventory Controller -b -m lineinfile -a "dest=/etc/hosts line=\"$CELL_INTERNALAPI_INFO\""

ANSIBLE_HOST_KEY_CHECKING=False \
ANSIBLE_SSH_RETRIES=3 \
ansible-playbook -i /home/stack/inventories \
    /usr/share/ansible/tripleo-playbooks/create-nova-cell-v2.yaml \
    -e tripleo_cellv2_cell_name=cell1 \
    -e tripleo_cellv2_containercli=podman

# add all computes
source ~/{{ test.overcloud.stack }}rc
openstack aggregate create cell1 --zone cell1
for i in $(openstack hypervisor list -f value -c 'Hypervisor Hostname'| grep cell1) ; do openstack aggregate add host cell1 $i ; done

##Verify the multi cell deployment by deploying the cell and archiving it

source ~/{{ test.overcloud.stack }}rc
openstack image create --disk-format qcow2 --container-format bare --file ~/cirros-0.4.0-x86_64-disk.img cirros-cell
if [ -z "`openstack network list | grep private-cell1`" ];then
  openstack network create private-cell1
  openstack subnet create --gateway 192.168.100.1 --dhcp --network private-cell1 --subnet-range 192.168.100.0/24 private-cell1
  openstack subnet set --dns-nameserver 10.34.32.1 --dns-nameserver 10.34.32.3 private-cell1
fi
openstack flavor create --public m1.extra_tiny --id auto --ram 128 --disk 1 --vcpus 1
max_retry=5
counter=0
until [ $(openstack image list -f value -c Status --name cirros-cell) == active ]
do
   sleep 1
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   echo "Waiting for cirros-cell image to become active. Trying #$counter time"
   ((counter++))
done

openstack server create --flavor m1.extra_tiny --image cirros-cell --availability-zone nova test1-overcloud

counter=0
until [ $(openstack server list -f value -c Status --name test1-overcloud) == ACTIVE ]
do
   sleep 1
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   echo "Waiting for test1-overcloud to become Active. Trying #$counter time"
   ((counter++))
done

#deploy other instance on cell-1

openstack server create --flavor m1.extra_tiny --image cirros-cell --availability-zone cell1 test1-cell1

counter=0
until [ $(openstack server list -f value -c Status --name test1-cell1) == ACTIVE ]
do
   sleep 1
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   echo "Waiting for test1-cell1 server to become Active. Trying #$counter time"
   ((counter++))
done

counter=0
until [[ $(openstack server list) == "" ]]
do
   openstack server delete test1-overcloud
   openstack server delete test1-cell1
   sleep 2
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   echo "Deleting the test1-overcloud and test-cell1 server. Trying #$counter time"
   ((counter++))
done

source ~/stackrc
CTRL=controller-0
CTRL_IP=$(openstack server list -f value -c Networks --name $CTRL | sed 's/ctlplane=//')
export CONTAINERCLI='podman'
set +e
$(ssh heat-admin@${CTRL_IP} sudo ${CONTAINERCLI} exec -i -u root nova_conductor \
nova-manage db archive_deleted_rows --until-complete --all-cells >> /dev/null 2>&1)
set -e
source ~/{{ test.overcloud.stack }}rc
deleted_servers=$(openstack server list --deleted --all-projects -c ID -f value)
# Fail if any deleted servers were found.
if [[ -n "$deleted_servers" ]]; then
    echo "There were unarchived instances found after archiving; failing."
    exit 1
fi

